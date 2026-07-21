// ============================================================
// File        : fifo_coverage.sv
// Project     : async_fifo_uvm_cdc
// Description : UVM Subscriber — 7 covergroups targeting
//               boundary, flag, CDC, and data path coverage.
//               Connected to both wr_monitor and rd_monitor
//               analysis ports via fifo_env.
// ============================================================
`ifndef FIFO_COVERAGE_SV
`define FIFO_COVERAGE_SV

class fifo_coverage extends uvm_subscriber #(fifo_seq_item);

  `uvm_component_utils(fifo_coverage)

  fifo_seq_item txn_h;  // Handle for current transaction

  // ---- CG1: Write Enable Coverage ----
  covergroup cg_wr_en;
    cp_wr_en: coverpoint txn_h.wr_en {
      bins write_active = {1};
      bins write_idle   = {0};
    }
  endgroup : cg_wr_en

  // ---- CG2: Read Enable Coverage ----
  covergroup cg_rd_en;
    cp_rd_en: coverpoint txn_h.rd_en {
      bins read_active = {1};
      bins read_idle   = {0};
    }
  endgroup : cg_rd_en

  // ---- CG3: Full / Empty Flag Corners ----
  covergroup cg_flags;
    cp_full:         coverpoint txn_h.full         { bins asserted={1}; bins deasserted={0}; }
    cp_empty:        coverpoint txn_h.empty         { bins asserted={1}; bins deasserted={0}; }
    cp_almost_full:  coverpoint txn_h.almost_full   { bins asserted={1}; bins deasserted={0}; }
    cp_almost_empty: coverpoint txn_h.almost_empty  { bins asserted={1}; bins deasserted={0}; }
  endgroup : cg_flags

  // ---- CG4: Write-when-Full (overflow attempt) ----
  covergroup cg_overflow_attempt;
    cp_wr_full: coverpoint {txn_h.wr_en, txn_h.full} {
      bins overflow_attempt = {2'b11};  // wr_en=1 while full=1
      bins normal_write     = {2'b10};  // wr_en=1 while not full
    }
  endgroup : cg_overflow_attempt

  // ---- CG5: Read-when-Empty (underflow attempt) ----
  covergroup cg_underflow_attempt;
    cp_rd_empty: coverpoint {txn_h.rd_en, txn_h.empty} {
      bins underflow_attempt = {2'b11};  // rd_en=1 while empty=1
      bins normal_read       = {2'b10};  // rd_en=1 while not empty
    }
  endgroup : cg_underflow_attempt

  // ---- CG6: Write Data Value Bins ----
  covergroup cg_wr_data;
    cp_wr_data: coverpoint txn_h.wr_data {
      bins zero_val    = {8'h00};
      bins max_val     = {8'hFF};
      bins walking_1s  = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
      bins mid_range   = {[8'h40 : 8'hBF]};
    }
  endgroup : cg_wr_data

  // ---- CG7: Simultaneous Read+Write (CDC stress) ----
  covergroup cg_simultaneous_rw;
    cp_rw: coverpoint {txn_h.wr_en, txn_h.rd_en} {
      bins both_active  = {2'b11};  // Concurrent R+W — max CDC stress
      bins only_write   = {2'b10};
      bins only_read    = {2'b01};
      bins both_idle    = {2'b00};
    }
  endgroup : cg_simultaneous_rw

  function new(string name = "fifo_coverage", uvm_component parent = null);
    super.new(name, parent);
    txn_h = fifo_seq_item::type_id::create("txn_h");
    cg_wr_en             = new();
    cg_rd_en             = new();
    cg_flags             = new();
    cg_overflow_attempt  = new();
    cg_underflow_attempt = new();
    cg_wr_data           = new();
    cg_simultaneous_rw   = new();
  endfunction : new

  // ---- write(): called by analysis port on each transaction ----
  function void write(fifo_seq_item t);
    txn_h = t;
    cg_wr_en.sample();
    cg_rd_en.sample();
    cg_flags.sample();
    cg_overflow_attempt.sample();
    cg_underflow_attempt.sample();
    cg_wr_data.sample();
    cg_simultaneous_rw.sample();
  endfunction : write

  // ---- report_phase: print coverage ----
  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf(
      "\n=== COVERAGE REPORT ===\n  cg_wr_en             : %0.2f%%\n  cg_rd_en             : %0.2f%%\n  cg_flags             : %0.2f%%\n  cg_overflow_attempt  : %0.2f%%\n  cg_underflow_attempt : %0.2f%%\n  cg_wr_data           : %0.2f%%\n  cg_simultaneous_rw   : %0.2f%%",
      cg_wr_en.get_coverage(),
      cg_rd_en.get_coverage(),
      cg_flags.get_coverage(),
      cg_overflow_attempt.get_coverage(),
      cg_underflow_attempt.get_coverage(),
      cg_wr_data.get_coverage(),
      cg_simultaneous_rw.get_coverage()), UVM_NONE)
  endfunction : report_phase

endclass : fifo_coverage

`endif // FIFO_COVERAGE_SV
// ============================================================
// End of fifo_coverage.sv
// ============================================================
