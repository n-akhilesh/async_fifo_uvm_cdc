// ============================================================
// Module      : fifo_assertions
// Project     : async_fifo_uvm_cdc
// Description : Standalone CDC-aware SVA bind file.
//               Contains all 12 SVA properties for the
//               async_fifo_top module.
//
// CDC FIX APPLIED:
//   almost_full  → uses rptr_gray_sync (already in wr_clk domain)
//   almost_empty → uses wptr_gray_sync (already in rd_clk domain)
//   Gray→Binary conversion done INSIDE module via function —
//   never subtract raw pointers from different clock domains!
//
// BIND INSTANTIATION (in tb_top.sv):
//   bind async_fifo_top fifo_assertions #(
//     .DEPTH     (DEPTH),
//     .DATA_WIDTH(DATA_WIDTH),
//     .PTR_WIDTH (PTR_WIDTH),
//     .AF_THRESH (AF_THRESH),
//     .AE_THRESH (AE_THRESH)
//   ) u_assertions (
//     .wr_clk         (wr_clk),
//     .rd_clk         (rd_clk),
//     .wr_rstn        (srst_n_wr),
//     .rd_rstn        (srst_n_rd),
//     .wr_en          (wr_en),
//     .rd_en          (rd_en),
//     .full           (full),
//     .empty          (empty),
//     .almost_full    (almost_full),
//     .almost_empty   (almost_empty),
//     .wptr_gray      (wptr_gray),
//     .rptr_gray      (rptr_gray),
//     .wptr_bin       (wbin),
//     .rptr_bin       (rbin),
//     .rptr_gray_sync (rptr_gray_sync),
//     .wptr_gray_sync (wptr_gray_sync)
//   );
//
// HOW TO INTENTIONALLY BREAK + TEST:
//   In wptr_full.sv:  force full_next = 1'b0 (always deassert)
//   In rptr_empty.sv: force empty_next = 1'b0 (always deassert)
//   → p_no_write_when_full and p_no_read_when_empty WILL fire
// ============================================================

`timescale 1ns/1ps

module fifo_assertions #(
  parameter int DEPTH      = 16,
  parameter int DATA_WIDTH = 8,
  parameter int PTR_WIDTH  = $clog2(DEPTH) + 1,  // 5 bits for DEPTH=16
  parameter int AF_THRESH  = 4,                   // Almost-full threshold
  parameter int AE_THRESH  = 2                    // Almost-empty threshold
)(
  // ---- Clocks + Resets ----
  input logic wr_clk,
  input logic rd_clk,
  input logic wr_rstn,          // Synchronized write domain reset
  input logic rd_rstn,          // Synchronized read domain reset

  // ---- Control Signals ----
  input logic wr_en,
  input logic rd_en,

  // ---- Status Flags ----
  input logic full,
  input logic empty,
  input logic almost_full,
  input logic almost_empty,

  // ---- Pointers — Same Domain (safe to use directly) ----
  input logic [PTR_WIDTH-1:0] wptr_gray,       // Gray wptr — wr_clk domain
  input logic [PTR_WIDTH-1:0] rptr_gray,       // Gray rptr — rd_clk domain
  input logic [PTR_WIDTH-1:0] wptr_bin,        // Binary wptr — wr_clk domain
  input logic [PTR_WIDTH-1:0] rptr_bin,        // Binary rptr — rd_clk domain

  // ---- CDC-Safe Synchronized Pointers ----
  input logic [PTR_WIDTH-1:0] rptr_gray_sync,  // rptr synced → wr_clk (from sync_r2w)
  input logic [PTR_WIDTH-1:0] wptr_gray_sync   // wptr synced → rd_clk (from sync_w2r)
);

  // ============================================================
  // Gray → Binary Conversion Function
  // Used ONLY inside this assertion module for threshold checks.
  // Standard algorithm: bin[MSB] = gray[MSB],
  //   bin[i] = bin[i+1] ^ gray[i] for i < MSB
  // This is combinational — safe for use in SVA local vars.
  // ============================================================
  function automatic [PTR_WIDTH-1:0] gray2bin;
    input [PTR_WIDTH-1:0] gray;
    logic [PTR_WIDTH-1:0] bin;
    integer i;
    begin
      bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];       // MSB same as Gray MSB
      for (i = PTR_WIDTH-2; i >= 0; i--)
        bin[i] = bin[i+1] ^ gray[i];              // XOR chain downward
      gray2bin = bin;
    end
  endfunction

  // ============================================================
  // PROPERTY 1 — p_gray_single_bit_wr
  // Category   : Critical CDC Property
  // Checks     : Write pointer Gray code changes by exactly
  //              1 bit per wr_clk cycle when pointer increments.
  // WHY        : Gray code safety guarantee — multiple bit
  //              flips simultaneously = invalid CDC crossing.
  // $onehot()  : True only if exactly 1 bit set in XOR result.
  // ============================================================
  property p_gray_single_bit_wr;
    @(posedge wr_clk) disable iff (!wr_rstn)
    $changed(wptr_gray) |-> $onehot(wptr_gray ^ $past(wptr_gray));
  endproperty

  ap_gray_single_bit_wr: assert property (p_gray_single_bit_wr)
    else $error("[SVA FAIL] p_gray_single_bit_wr: wptr_gray changed by more than 1 bit! wptr_gray=%0b past=%0b XOR=%0b",
                wptr_gray, $past(wptr_gray), wptr_gray ^ $past(wptr_gray));

  // ============================================================
  // PROPERTY 2 — p_gray_single_bit_rd
  // Category   : Critical CDC Property
  // Checks     : Read pointer Gray code changes by exactly
  //              1 bit per rd_clk cycle when pointer increments.
  // ============================================================
  property p_gray_single_bit_rd;
    @(posedge rd_clk) disable iff (!rd_rstn)
    $changed(rptr_gray) |-> $onehot(rptr_gray ^ $past(rptr_gray));
  endproperty

  ap_gray_single_bit_rd: assert property (p_gray_single_bit_rd)
    else $error("[SVA FAIL] p_gray_single_bit_rd: rptr_gray changed by more than 1 bit! rptr_gray=%0b past=%0b XOR=%0b",
                rptr_gray, $past(rptr_gray), rptr_gray ^ $past(rptr_gray));

  // ============================================================
  // PROPERTY 3 — p_full_when_equal_msb
  // Category   : Full Flag Correctness
  // Checks     : Full asserted when top 2 MSBs of wptr_gray
  //              are inverted relative to rptr_gray_sync and
  //              lower bits are equal. (Cummings MSB XOR method)
  // DOMAIN     : wr_clk — rptr_gray_sync already in wr_clk ✅
  // ============================================================
  property p_full_when_equal_msb;
    @(posedge wr_clk) disable iff (!wr_rstn)
    // MSB XOR full condition: top 2 bits inverted, lower bits equal
    ({~rptr_gray_sync[PTR_WIDTH-1:PTR_WIDTH-2],
       rptr_gray_sync[PTR_WIDTH-3:0]} == wptr_gray) |-> full;
  endproperty

  ap_full_when_equal_msb: assert property (p_full_when_equal_msb)
    else $error("[SVA FAIL] p_full_when_equal_msb: full not asserted! wptr_gray=%0b rptr_gray_sync=%0b",
                wptr_gray, rptr_gray_sync);

  // ============================================================
  // PROPERTY 4 — p_empty_when_equal_ptrs
  // Category   : Empty Flag Correctness
  // Checks     : Empty asserted when wptr_gray_sync == rptr_gray.
  //              Direct Gray equality — no conversion needed.
  // DOMAIN     : rd_clk — wptr_gray_sync already in rd_clk ✅
  // ============================================================
  property p_empty_when_equal_ptrs;
    @(posedge rd_clk) disable iff (!rd_rstn)
    (wptr_gray_sync == rptr_gray) |-> empty;
  endproperty

  ap_empty_when_equal_ptrs: assert property (p_empty_when_equal_ptrs)
    else $error("[SVA FAIL] p_empty_when_equal_ptrs: empty not asserted! wptr_gray_sync=%0b rptr_gray=%0b",
                wptr_gray_sync, rptr_gray);

  // ============================================================
  // PROPERTY 5 — p_no_write_when_full
  // Category   : Overflow Protection
  // Checks     : Write pointer must NOT increment when full=1.
  //              If full and wr_en both high → wptr_bin must
  //              hold its value (no phantom write).
  // ============================================================
  property p_no_write_when_full;
    @(posedge wr_clk) disable iff (!wr_rstn)
    (full && wr_en) |=> (wptr_bin == $past(wptr_bin));
  endproperty

  ap_no_write_when_full: assert property (p_no_write_when_full)
    else $error("[SVA FAIL] p_no_write_when_full: wptr_bin incremented while full! wptr_bin=%0d",
                wptr_bin);

  // ============================================================
  // PROPERTY 6 — p_no_read_when_empty
  // Category   : Underflow Protection
  // Checks     : Read pointer must NOT increment when empty=1.
  //              If empty and rd_en both high → rptr_bin must
  //              hold its value (no phantom read).
  // ============================================================
  property p_no_read_when_empty;
    @(posedge rd_clk) disable iff (!rd_rstn)
    (empty && rd_en) |=> (rptr_bin == $past(rptr_bin));
  endproperty

  ap_no_read_when_empty: assert property (p_no_read_when_empty)
    else $error("[SVA FAIL] p_no_read_when_empty: rptr_bin incremented while empty! rptr_bin=%0d",
                rptr_bin);

  // ============================================================
  // PROPERTY 7 — p_almost_full_threshold
  // Category   : Threshold Correctness
  // CDC FIX    : Uses rptr_gray_sync (wr_clk domain) converted
  //              to binary via gray2bin() — NEVER raw rptr_bin!
  //              Both wptr_bin and rbin_wr are in wr_clk → safe ✅
  // ============================================================
  property p_almost_full_threshold;
    logic [PTR_WIDTH-1:0] rbin_wr;  // Local: rptr in wr_clk domain
    @(posedge wr_clk) disable iff (!wr_rstn)
    // Capture gray2bin conversion as local variable
    (1'b1, rbin_wr = gray2bin(rptr_gray_sync)) |->
    (((wptr_bin - rbin_wr) >= AF_THRESH) == almost_full);
  endproperty

  ap_almost_full_threshold: assert property (p_almost_full_threshold)
    else $error("[SVA FAIL] p_almost_full_threshold: almost_full mismatch! wptr_bin=%0d rbin_wr=%0d diff=%0d AF_THRESH=%0d almost_full=%0b",
                wptr_bin, gray2bin(rptr_gray_sync),
                wptr_bin - gray2bin(rptr_gray_sync),
                AF_THRESH, almost_full);

  // ============================================================
  // PROPERTY 8 — p_almost_empty_threshold
  // Category   : Threshold Correctness
  // CDC FIX    : Uses wptr_gray_sync (rd_clk domain) converted
  //              to binary via gray2bin() — NEVER raw wptr_bin!
  //              Both rptr_bin and wbin_rd are in rd_clk → safe ✅
  // ============================================================
  property p_almost_empty_threshold;
    logic [PTR_WIDTH-1:0] wbin_rd;  // Local: wptr in rd_clk domain
    @(posedge rd_clk) disable iff (!rd_rstn)
    (1'b1, wbin_rd = gray2bin(wptr_gray_sync)) |->
    (((wbin_rd - rptr_bin) <= AE_THRESH) == almost_empty);
  endproperty

  ap_almost_empty_threshold: assert property (p_almost_empty_threshold)
    else $error("[SVA FAIL] p_almost_empty_threshold: almost_empty mismatch! wbin_rd=%0d rptr_bin=%0d diff=%0d AE_THRESH=%0d almost_empty=%0b",
                gray2bin(wptr_gray_sync), rptr_bin,
                gray2bin(wptr_gray_sync) - rptr_bin,
                AE_THRESH, almost_empty);

  // ============================================================
  // PROPERTY 9 — p_wptr_increment
  // Category   : Pointer Integrity
  // Checks     : wptr_bin increments by exactly 1 on every
  //              valid write (wr_en=1 and full=0).
  // |=>         : Next clock cycle check (non-overlapping)
  // ============================================================
  property p_wptr_increment;
    @(posedge wr_clk) disable iff (!wr_rstn)
    (wr_en && !full) |=> (wptr_bin == ($past(wptr_bin) + 1'b1));
  endproperty

  ap_wptr_increment: assert property (p_wptr_increment)
    else $error("[SVA FAIL] p_wptr_increment: wptr_bin did not increment! past=%0d current=%0d",
                $past(wptr_bin), wptr_bin);

  // ============================================================
  // PROPERTY 10 — p_rptr_increment
  // Category   : Pointer Integrity
  // Checks     : rptr_bin increments by exactly 1 on every
  //              valid read (rd_en=1 and empty=0).
  // ============================================================
  property p_rptr_increment;
    @(posedge rd_clk) disable iff (!rd_rstn)
    (rd_en && !empty) |=> (rptr_bin == ($past(rptr_bin) + 1'b1));
  endproperty

  ap_rptr_increment: assert property (p_rptr_increment)
    else $error("[SVA FAIL] p_rptr_increment: rptr_bin did not increment! past=%0d current=%0d",
                $past(rptr_bin), rptr_bin);

  // ============================================================
  // PROPERTY 11 — p_reset_clears_wptr
  // Category   : Reset Correctness
  // Checks     : wptr_bin is 0 exactly 1 wr_clk cycle after
  //              wr_rstn deasserts (sync-deassert pattern).
  // |=>         : Checks the cycle AFTER reset releases
  // ============================================================
  property p_reset_clears_wptr;
    @(posedge wr_clk)
    // Detect rising edge of wr_rstn (reset releasing)
    $rose(wr_rstn) |=> (wptr_bin == '0);
  endproperty

  ap_reset_clears_wptr: assert property (p_reset_clears_wptr)
    else $error("[SVA FAIL] p_reset_clears_wptr: wptr_bin not 0 after reset! wptr_bin=%0d",
                wptr_bin);

  // ============================================================
  // PROPERTY 12 — p_reset_clears_rptr
  // Category   : Reset Correctness
  // Checks     : rptr_bin is 0 exactly 1 rd_clk cycle after
  //              rd_rstn deasserts.
  //              NOTE: rd_rstn and wr_rstn are INDEPENDENT —
  //              intentional by design (separate reset sync FFs).
  // ============================================================
  property p_reset_clears_rptr;
    @(posedge rd_clk)
    $rose(rd_rstn) |=> (rptr_bin == '0);
  endproperty

  ap_reset_clears_rptr: assert property (p_reset_clears_rptr)
    else $error("[SVA FAIL] p_reset_clears_rptr: rptr_bin not 0 after reset! rptr_bin=%0d",
                rptr_bin);

endmodule
// ============================================================
// End of fifo_assertions.sv
// ============================================================