// ============================================================
// File        : fifo_env.sv
// Project     : async_fifo_uvm_cdc
// Description : Top-level UVM environment.
//               Instantiates:
//                 - fifo_agent_wr  (write domain agent)
//                 - fifo_agent_rd  (read domain agent)
//                 - fifo_scoreboard
//                 - fifo_coverage  (subscriber)
//               Wires analysis ports in connect_phase.
// ============================================================
`ifndef FIFO_ENV_SV
`define FIFO_ENV_SV

class fifo_env extends uvm_env;

  `uvm_component_utils(fifo_env)

  // ---- Sub-Components ----
  fifo_agent_wr    wr_agent;
  fifo_agent_rd    rd_agent;
  fifo_scoreboard  scoreboard;
  fifo_coverage    coverage;

  function new(string name = "fifo_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_agent   = fifo_agent_wr::type_id::create("wr_agent",   this);
    rd_agent   = fifo_agent_rd::type_id::create("rd_agent",   this);
    scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
    coverage   = fifo_coverage::type_id::create("coverage",   this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    // wr_monitor → scoreboard write port
    wr_agent.ap.connect(scoreboard.wr_export);

    // rd_monitor → scoreboard read port
    rd_agent.ap.connect(scoreboard.rd_export);

    // wr_monitor → coverage subscriber
    wr_agent.ap.connect(coverage.analysis_export);
  endfunction : connect_phase

endclass : fifo_env

`endif // FIFO_ENV_SV
// ============================================================
// End of fifo_env.sv
// ============================================================
