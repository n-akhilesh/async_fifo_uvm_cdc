// ============================================================
// File        : fifo_agent_wr.sv
// Project     : async_fifo_uvm_cdc
// Description : Write-side UVM agent (ACTIVE mode).
//               Contains: fifo_wr_driver + fifo_wr_monitor
//                         + uvm_sequencer #(fifo_seq_item)
//               Active = drives DUT + monitors DUT.
//               Set is_active = UVM_PASSIVE to disable driver.
//
// Interview Key Points:
//   - Active vs Passive mode (is_active flag)
//   - agent contains driver + sequencer + monitor
//   - connect_phase: driver.seq_item_port → sequencer.seq_item_export
//   - analysis port forwarded from monitor to env
// ============================================================
`ifndef FIFO_AGENT_WR_SV
`define FIFO_AGENT_WR_SV

class fifo_agent_wr extends uvm_agent;

  `uvm_component_utils(fifo_agent_wr)

  // ---- Sub-Components ----
  fifo_wr_driver                    wr_drv;
  fifo_wr_monitor                   wr_mon;
  uvm_sequencer #(fifo_seq_item)    wr_seqr;

  // ---- Analysis Port (forwarded from monitor) ----
  uvm_analysis_port #(fifo_seq_item) ap;

  function new(string name = "fifo_agent_wr", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap      = new("ap", this);
    wr_mon  = fifo_wr_monitor::type_id::create("wr_mon", this);
    // Only build driver + sequencer if ACTIVE
    if (get_is_active() == UVM_ACTIVE) begin
      wr_drv  = fifo_wr_driver::type_id::create("wr_drv", this);
      wr_seqr = uvm_sequencer #(fifo_seq_item)::type_id::create("wr_seqr", this);
    end
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    // Forward monitor analysis port upward to env
    wr_mon.ap.connect(ap);
    // Connect driver TLM port to sequencer export
    if (get_is_active() == UVM_ACTIVE)
      wr_drv.seq_item_port.connect(wr_seqr.seq_item_export);
  endfunction : connect_phase

endclass : fifo_agent_wr

`endif // FIFO_AGENT_WR_SV
// ============================================================
// End of fifo_agent_wr.sv
// ============================================================
