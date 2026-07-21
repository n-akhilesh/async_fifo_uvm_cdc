// ============================================================
// File        : fifo_scoreboard.sv
// Project     : async_fifo_uvm_cdc
// Description : Golden FIFO model — byte-level comparison.
//               Receives write transactions from wr_monitor and
//               read transactions from rd_monitor via separate
//               uvm_analysis_imp ports (TLM).
//
//               Golden model: standard queue (FIFO order).
//               On each write: push to golden_q.
//               On each read:  pop from golden_q, compare
//                              with rd_data from DUT.
//
// Interview Key Points:
//   - uvm_analysis_imp_decl macro for two-port scoreboard
//   - write_wr() + write_rd() — separate write() callbacks
//   - Golden reference model (queue-based FIFO)
//   - uvm_error for mismatch, uvm_info for pass
//   - check_phase: verify no leftover items
// ============================================================
`ifndef FIFO_SCOREBOARD_SV
`define FIFO_SCOREBOARD_SV

// Declare two named analysis imp suffixes
`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)

class fifo_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(fifo_scoreboard)

  // ---- Two Analysis Imp Ports ----
  uvm_analysis_imp_wr #(fifo_seq_item, fifo_scoreboard) wr_export;
  uvm_analysis_imp_rd #(fifo_seq_item, fifo_scoreboard) rd_export;

  // ---- Golden Reference Model ----
  logic [7:0] golden_q[$];   // FIFO queue — push on write, pop on read

  // ---- Counters ----
  int unsigned wr_count;
  int unsigned rd_count;
  int unsigned pass_count;
  int unsigned fail_count;

  function new(string name = "fifo_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    wr_count   = 0;
    rd_count   = 0;
    pass_count = 0;
    fail_count = 0;
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_export = new("wr_export", this);
    rd_export = new("rd_export", this);
  endfunction : build_phase

  // ---- write_wr: called by wr_monitor on every valid write ----
  function void write_wr(fifo_seq_item txn);
    golden_q.push_back(txn.wr_data);
    wr_count++;
    `uvm_info("SCB",
      $sformatf("[WR] Pushed 0x%02h → golden_q depth=%0d",
        txn.wr_data, golden_q.size()), UVM_HIGH)
  endfunction : write_wr

  // ---- write_rd: called by rd_monitor on every valid read ----
  function void write_rd(fifo_seq_item txn);
    logic [7:0] expected;
    rd_count++;

    if (golden_q.size() == 0) begin
      `uvm_error("SCB",
        $sformatf("[RD] Underflow! rd_data=0x%02h but golden_q is EMPTY",
          txn.rd_data))
      fail_count++;
      return;
    end

    expected = golden_q.pop_front();  // FIFO order

    if (txn.rd_data === expected) begin
      pass_count++;
      `uvm_info("SCB",
        $sformatf("[RD] PASS rd_data=0x%02h == expected=0x%02h | golden_q depth=%0d",
          txn.rd_data, expected, golden_q.size()), UVM_MEDIUM)
    end else begin
      fail_count++;
      `uvm_error("SCB",
        $sformatf("[RD] FAIL rd_data=0x%02h != expected=0x%02h | golden_q depth=%0d",
          txn.rd_data, expected, golden_q.size()))
    end
  endfunction : write_rd

  // ---- check_phase: report leftover items ----
  function void check_phase(uvm_phase phase);
    if (golden_q.size() != 0)
      `uvm_error("SCB",
        $sformatf("check_phase: %0d items left in golden_q — not all data was read!",
          golden_q.size()))
    else
      `uvm_info("SCB", "check_phase: golden_q is empty — all data consumed ✓", UVM_LOW)
  endfunction : check_phase

  // ---- report_phase: final summary ----
  function void report_phase(uvm_phase phase);
    `uvm_info("SCB", $sformatf(
      "\n=== SCOREBOARD SUMMARY ===\n  Writes   : %0d\n  Reads    : %0d\n  PASS     : %0d\n  FAIL     : %0d\n==========================",
      wr_count, rd_count, pass_count, fail_count), UVM_NONE)
  endfunction : report_phase

endclass : fifo_scoreboard

`endif // FIFO_SCOREBOARD_SV
// ============================================================
// End of fifo_scoreboard.sv
// ============================================================
