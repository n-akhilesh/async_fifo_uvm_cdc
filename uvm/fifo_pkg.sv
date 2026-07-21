// ============================================================
// File        : fifo_pkg.sv
// Project     : async_fifo_uvm_cdc
// Description : UVM package — imports all UVM files in
//               correct compilation order.
//               Include this ONE file in tb_top.sv.
//
// Compilation Order (must follow dependency chain):
//   1. uvm_pkg import
//   2. fifo_seq_item  (no UVM dependencies beyond uvm_pkg)
//   3. fifo_wr_driver / fifo_rd_driver
//   4. fifo_wr_monitor / fifo_rd_monitor
//   5. fifo_scoreboard
//   6. fifo_coverage
//   7. fifo_agent_wr / fifo_agent_rd
//   8. fifo_env
//   9. sequences/*
//  10. fifo_base_test + all test overrides
// ============================================================
`ifndef FIFO_PKG_SV
`define FIFO_PKG_SV

package fifo_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ---- Transaction ----
  `include "fifo_seq_item.sv"

  // ---- Drivers ----
  `include "fifo_wr_driver.sv"
  `include "fifo_rd_driver.sv"

  // ---- Monitors ----
  `include "fifo_wr_monitor.sv"
  `include "fifo_rd_monitor.sv"

  // ---- Scoreboard ----
  `include "fifo_scoreboard.sv"

  // ---- Coverage ----
  `include "fifo_coverage.sv"

  // ---- Agents ----
  `include "fifo_agent_wr.sv"
  `include "fifo_agent_rd.sv"

  // ---- Environment ----
  `include "fifo_env.sv"

  // ---- Sequences (12 test sequences) ----
  `include "sequences/fifo_wr_basic_seq.sv"
  `include "sequences/fifo_rd_basic_seq.sv"
  `include "sequences/fifo_fill_seq.sv"
  `include "sequences/fifo_drain_seq.sv"
  `include "sequences/fifo_overflow_seq.sv"
  `include "sequences/fifo_underflow_seq.sv"
  `include "sequences/fifo_almost_full_seq.sv"
  `include "sequences/fifo_almost_empty_seq.sv"
  `include "sequences/fifo_reset_seq.sv"
  `include "sequences/fifo_simultaneous_rw_seq.sv"
  `include "sequences/fifo_burst_wr_seq.sv"
  `include "sequences/fifo_burst_rd_seq.sv"

  // ---- Tests ----
  `include "fifo_base_test.sv"

endpackage : fifo_pkg

`endif // FIFO_PKG_SV
// ============================================================
// End of fifo_pkg.sv
// ============================================================
