// ============================================================
// File        : fifo_wr_monitor.sv
// Project     : async_fifo_uvm_cdc
// Description : Write-domain passive monitor.
//               Samples wr_clk domain signals and broadcasts
//               transactions via uvm_analysis_port to
//               scoreboard and coverage collector.
// ============================================================
`ifndef FIFO_WR_MONITOR_SV
`define FIFO_WR_MONITOR_SV

class fifo_wr_monitor extends uvm_monitor;

  `uvm_component_utils(fifo_wr_monitor)

  // ---- Analysis Port — broadcasts to scoreboard + coverage ----
  uvm_analysis_port #(fifo_seq_item) ap;

  virtual fifo_if #(.DATA_WIDTH(8)) vif;

  function new(string name = "fifo_wr_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db #(virtual fifo_if #(.DATA_WIDTH(8)))::get(
          this, "", "fifo_vif", vif))
      `uvm_fatal("WR_MON", "Cannot get fifo_vif from config_db")
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    fifo_seq_item txn;
    forever begin
      @(posedge vif.wr_clk);
      // Only capture valid write beats
      if (vif.wr_en && !vif.full) begin
        txn              = fifo_seq_item::type_id::create("wr_txn");
        txn.wr_en        = vif.wr_en;
        txn.wr_data      = vif.wr_data;
        txn.full         = vif.full;
        txn.almost_full  = vif.almost_full;
        `uvm_info("WR_MON",
          $sformatf("CAPTURED: wr_data=0x%02h full=%0b af=%0b",
            txn.wr_data, txn.full, txn.almost_full), UVM_HIGH)
        ap.write(txn);  // Broadcast to all subscribers
      end
    end
  endtask : run_phase

endclass : fifo_wr_monitor

`endif // FIFO_WR_MONITOR_SV
// ============================================================
// End of fifo_wr_monitor.sv
// ============================================================
