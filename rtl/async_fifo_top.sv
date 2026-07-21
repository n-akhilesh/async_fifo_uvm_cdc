// ============================================================
// Module      : async_fifo_top
// Project     : async_fifo_uvm_cdc
// Description : Top-level integration of all 8 sub-modules.
//               Instantiates and wires up the full async FIFO.
//
// Reset Architecture (Qualcomm RDC pattern):
//   Single arst_n input feeds BOTH rst_sync_wr and rst_sync_rd.
//   Each produces an independent domain-local sync reset:
//     srst_n_wr → wr_clk domain modules
//     srst_n_rd → rd_clk domain modules
//   This is intentional — the two domains deassert reset
//   independently at their own clock edges. This is the
//   Qualcomm-approved RDC reset crossing methodology.
//
// Port Map:
//   wr_clk, wr_en, wr_data → write domain inputs
//   rd_clk, rd_en          → read domain inputs
//   arst_n                 → async global reset (active low)
//   rd_data                → read domain output
//   full, almost_full      → write domain status flags
//   empty, almost_empty    → read domain status flags
//
// Parameters:
//   DEPTH      — FIFO depth (default 16, must be power of 2)
//   DATA_WIDTH — data bus width (default 8)
//   AF_THRESH  — almost_full threshold (default 4)
//   AE_THRESH  — almost_empty threshold (default 4)
// ============================================================

`timescale 1ns/1ps

module async_fifo_top #(
  parameter int DEPTH      = 16,
  parameter int DATA_WIDTH = 8,
  parameter int AF_THRESH  = 4,
  parameter int AE_THRESH  = 4,
  // Derived — do not override at instantiation
  parameter int PTR_WIDTH  = $clog2(DEPTH) + 1  // = 5 for DEPTH=16
)(
  // ---- Write Domain ----
  input  logic                  wr_clk,    // Write clock (e.g. 100 MHz)
  input  logic                  wr_en,     // Write enable
  input  logic [DATA_WIDTH-1:0] wr_data,   // Write data

  // ---- Read Domain ----
  input  logic                  rd_clk,    // Read clock (e.g. 73 MHz)
  input  logic                  rd_en,     // Read enable

  // ---- Global Async Reset ----
  input  logic                  arst_n,    // Async reset active low

  // ---- Read Data Output ----
  output logic [DATA_WIDTH-1:0] rd_data,   // Read data output

  // ---- Write Domain Status Flags ----
  output logic                  full,      // FIFO full
  output logic                  almost_full, // FIFO almost full

  // ---- Read Domain Status Flags ----
  output logic                  empty,     // FIFO empty
  output logic                  almost_empty // FIFO almost empty
);

  // ----------------------------------------------------------------
  // Internal Signal Declarations
  // ----------------------------------------------------------------

  // Reset signals — one per clock domain
  logic srst_n_wr;  // Write domain synchronous reset
  logic srst_n_rd;  // Read domain synchronous reset

  // Pointer buses
  logic [PTR_WIDTH-1:0] wptr_gray;      // Gray wptr (wr_clk domain) → sync_w2r
  logic [PTR_WIDTH-1:0] rptr_gray;      // Gray rptr (rd_clk domain) → sync_r2w
  logic [PTR_WIDTH-1:0] wptr_gray_sync; // Gray wptr synchronized to rd_clk
  logic [PTR_WIDTH-1:0] rptr_gray_sync; // Gray rptr synchronized to wr_clk

  // Memory address buses
  logic [PTR_WIDTH-2:0] wr_addr;  // Binary write address (N bits)
  logic [PTR_WIDTH-2:0] rd_addr;  // Binary read address (N bits)

  // Write enable gated — only write when not full
  logic wr_en_gated;
  assign wr_en_gated = wr_en & ~full;

  // ----------------------------------------------------------------
  // Instance 1: rst_sync_wr — Write Domain Reset Synchronizer
  // Qualcomm RDC pattern: async assert, sync deassert on wr_clk
  // ----------------------------------------------------------------
  rst_sync_wr u_rst_sync_wr (
    .wr_clk   (wr_clk),
    .arst_n   (arst_n),
    .srst_n_wr(srst_n_wr)
  );

  // ----------------------------------------------------------------
  // Instance 2: rst_sync_rd — Read Domain Reset Synchronizer
  // Independent of rst_sync_wr — deasserts on rd_clk edges
  // ----------------------------------------------------------------
  rst_sync_rd u_rst_sync_rd (
    .rd_clk   (rd_clk),
    .arst_n   (arst_n),
    .srst_n_rd(srst_n_rd)
  );

  // ----------------------------------------------------------------
  // Instance 3: fifo_mem — Dual-Port SRAM Behavioral Model
  // Write: synchronous on wr_clk
  // Read:  asynchronous (combinational)
  // ----------------------------------------------------------------
  fifo_mem #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH     (DEPTH)
  ) u_fifo_mem (
    .wr_clk  (wr_clk),
    .wr_en   (wr_en_gated), // Gated — no writes when full
    .wr_addr (wr_addr),
    .wr_data (wr_data),
    .rd_addr (rd_addr),
    .rd_data (rd_data)
  );

  // ----------------------------------------------------------------
  // Instance 4: wptr_full — Write Pointer + Full Flag Logic
  // Clocked on wr_clk, reset by srst_n_wr
  // ----------------------------------------------------------------
  wptr_full #(
    .DEPTH     (DEPTH),
    .DATA_WIDTH(DATA_WIDTH),
    .AF_THRESH (AF_THRESH),
    .PTR_WIDTH (PTR_WIDTH)
  ) u_wptr_full (
    .wr_clk       (wr_clk),
    .wr_rstn      (srst_n_wr),   // Write domain sync reset
    .wr_en        (wr_en),
    .rptr_gray_sync(rptr_gray_sync), // Sync'd rptr from wr domain
    .wptr_gray    (wptr_gray),   // Gray wptr → sync_w2r
    .wr_addr      (wr_addr),
    .full         (full),
    .almost_full  (almost_full)
  );

  // ----------------------------------------------------------------
  // Instance 5: rptr_empty — Read Pointer + Empty Flag Logic
  // Clocked on rd_clk, reset by srst_n_rd
  // ----------------------------------------------------------------
  rptr_empty #(
    .DEPTH     (DEPTH),
    .DATA_WIDTH(DATA_WIDTH),
    .AE_THRESH (AE_THRESH),
    .PTR_WIDTH (PTR_WIDTH)
  ) u_rptr_empty (
    .rd_clk       (rd_clk),
    .rd_rstn      (srst_n_rd),   // Read domain sync reset
    .rd_en        (rd_en),
    .wptr_gray_sync(wptr_gray_sync), // Sync'd wptr from rd domain
    .rptr_gray    (rptr_gray),   // Gray rptr → sync_r2w
    .rd_addr      (rd_addr),
    .empty        (empty),
    .almost_empty (almost_empty)
  );

  // ----------------------------------------------------------------
  // Instance 6: sync_w2r — Write→Read 2-FF Synchronizer
  // Synchronizes wptr_gray into rd_clk domain
  // ----------------------------------------------------------------
  sync_w2r #(
    .PTR_WIDTH  (PTR_WIDTH),
    .SYNC_STAGES(2)
  ) u_sync_w2r (
    .rd_clk        (rd_clk),
    .rd_rstn       (srst_n_rd),    // Read domain sync reset
    .wptr_gray     (wptr_gray),
    .wptr_gray_sync(wptr_gray_sync)
  );

  // ----------------------------------------------------------------
  // Instance 7: sync_r2w — Read→Write 2-FF Synchronizer
  // Synchronizes rptr_gray into wr_clk domain
  // ----------------------------------------------------------------
  sync_r2w #(
    .PTR_WIDTH  (PTR_WIDTH),
    .SYNC_STAGES(2)
  ) u_sync_r2w (
    .wr_clk        (wr_clk),
    .wr_rstn       (srst_n_wr),    // Write domain sync reset
    .rptr_gray     (rptr_gray),
    .rptr_gray_sync(rptr_gray_sync)
  );

endmodule
// ============================================================
// End of async_fifo_top.sv
// ============================================================