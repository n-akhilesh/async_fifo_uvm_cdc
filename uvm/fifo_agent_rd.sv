// ============================================================
// File        : fifo_agent_rd.sv
// Project     : async_fifo_uvm_cdc
// Description : Read-side UVM agent (ACTIVE mode).
//               Contains: fifo_rd_driver + fifo_rd_monitor
//                         + uvm_sequencer #(fifo_seq_item)
//               Operates fully in rd_clk domain (73 MHz).
//               Independent of wr-agent — no shared state.
// ============================================================
`ifndef FIFO_AGENT_RD_SV
`define FIFO_AGENT_RD_SV

class fifo_agent_rd extends uvm_agent;

  `uvm_component_utils(fifo_agent_rd)

  fifo_rd_driver                    rd_drv;
  fifo_rd_monitor                   rd_mon;
  uvm_sequencer #(fifo_seq_item)    rd_seqr;

  uvm_analysis_port #(fifo_seq_item) ap;

  function new(string name = "fifo_agent_rd", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap     = new("ap", this);
    rd_mon = fifo_rd_monitor::type_id::create("rd_mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      rd_drv  = fifo_rd_driver::type_id::create("rd_drv", this);
      rd_seqr = uvm_sequencer #(fifo_seq_item)::type_id::create("rd_seqr", this);
    end
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    rd_mon.ap.connect(ap);
    if (get_is_active() == UVM_ACTIVE)
      rd_drv.seq_item_port.connect(rd_seqr.seq_item_export);
  endfunction : connect_phase

endclass : fifo_agent_rd

`endif // FIFO_AGENT_RD_SV
// ============================================================
// End of fifo_agent_rd.sv
// ============================================================
