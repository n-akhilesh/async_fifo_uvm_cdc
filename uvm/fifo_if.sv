// ============================================================
// File        : fifo_if.sv
// Project     : async_fifo_uvm_cdc
// Description : SystemVerilog interface with separate clocking
//               blocks for wr_cb (100 MHz) and rd_cb (73 MHz).
//               Virtual interface handle passed to UVM via
//               uvm_config_db.
// ============================================================
`timescale 1ns/1ps

interface fifo_if #(
  parameter int DATA_WIDTH = 8
)(
  input logic wr_clk,
  input logic rd_clk
);

  // ---- DUT Signals ----
  logic                  wr_en;
  logic [DATA_WIDTH-1:0] wr_data;
  logic                  rd_en;
  logic                  arst_n;

  // ---- DUT Outputs (monitored) ----
  logic [DATA_WIDTH-1:0] rd_data;
  logic                  full;
  logic                  almost_full;
  logic                  empty;
  logic                  almost_empty;

  // ---- Write Domain Clocking Block ----
  // Input skew  : 1ns before posedge (setup)
  // Output skew : posedge + 1ns  (drive after clock)
  clocking wr_cb @(posedge wr_clk);
    default input #1ns output #1ns;
    output wr_en;
    output wr_data;
    output arst_n;
    input  full;
    input  almost_full;
  endclocking

  // ---- Read Domain Clocking Block ----
  clocking rd_cb @(posedge rd_clk);
    default input #1ns output #1ns;
    output rd_en;
    input  rd_data;
    input  empty;
    input  almost_empty;
  endclocking

  // ---- Write Driver Modport ----
  modport wr_mp (
    clocking wr_cb,
    input    wr_clk,
    input    rd_clk
  );

  // ---- Read Driver Modport ----
  modport rd_mp (
    clocking rd_cb,
    input    wr_clk,
    input    rd_clk
  );

  // ---- Passive Monitor Modport ----
  modport mon_mp (
    input wr_clk, rd_clk,
    input wr_en, wr_data, rd_en, arst_n,
    input rd_data, full, almost_full, empty, almost_empty
  );

endinterface : fifo_if
// ============================================================
// End of fifo_if.sv
// ============================================================
