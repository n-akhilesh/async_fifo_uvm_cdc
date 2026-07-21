// ============================================================
// File        : fifo_base_test.sv
// Project     : async_fifo_uvm_cdc
// Description : Base UVM test.
//               - Creates fifo_env in build_phase
//               - Sets fifo_vif via config_db
//               - Provides base run_phase (override in child tests)
//               - Demonstrates factory override mechanism
//
// Interview Key Points:
//   - Top of UVM hierarchy (uvm_test)
//   - build_phase  → instantiate env, set config
//   - run_phase    → raise/drop objection, start sequences
//   - Factory override: swap seq/driver without recompile
//   - +UVM_TESTNAME=fifo_base_test on command line
// ============================================================
`ifndef FIFO_BASE_TEST_SV
`define FIFO_BASE_TEST_SV

class fifo_base_test extends uvm_test;

  `uvm_component_utils(fifo_base_test)

  fifo_env env;

  function new(string name = "fifo_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  // ---- build_phase ----
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
  endfunction : build_phase

  // ---- end_of_elaboration_phase: print topology ----
  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction : end_of_elaboration_phase

  // ---- run_phase ----
  // Base test: runs fifo_wr_basic_seq on wr_seqr
  //            and fifo_rd_basic_seq on rd_seqr in parallel
  task run_phase(uvm_phase phase);
    fifo_wr_basic_seq wr_seq;
    fifo_rd_basic_seq rd_seq;

    phase.raise_objection(this, "fifo_base_test running");

    wr_seq = fifo_wr_basic_seq::type_id::create("wr_seq");
    rd_seq = fifo_rd_basic_seq::type_id::create("rd_seq");

    // Fork write and read sequences — parallel execution
    fork
      wr_seq.start(env.wr_agent.wr_seqr);
      rd_seq.start(env.rd_agent.rd_seqr);
    join

    // Small drain time — let FIFO flush
    #500ns;

    phase.drop_objection(this, "fifo_base_test done");
  endtask : run_phase

endclass : fifo_base_test

`endif // FIFO_BASE_TEST_SV
// ============================================================
// End of fifo_base_test.sv
// ============================================================
