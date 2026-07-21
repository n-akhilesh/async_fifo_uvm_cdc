// ============================================================
// File        : fifo_rd_monitor.sv
// Project     : async_fifo_uvm_cdc
// Description : Read-domain passive monitor.
//               Samples rd_clk domain signals and broadcasts
//               transactions via uvm_analysis_port.
// ============================================================
`ifndef FIFO_RD_MONITOR_SV
`define FIFO_RD_MONITOR_SV

class fifo_rd_monitor extends uvm_monitor;

  `uvm_component_utils(fifo_rd_monitor)

  uvm_analysis_port #(fifo_seq_item) ap;

  virtual fifo_if #(.DATA_WIDTH(8)) vif;

  function new(string name = "fifo_rd_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db #(virtual fifo_if #(.DATA_WIDTH(8)))::get(
          this, "", "fifo_vif", vif))
      `uvm_fatal("RD_MON", "Cannot get fifo_vif from config_db")
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    fifo_seq_item txn;
    // 1-cycle read latency: data valid one cycle after rd_en
    forever begin
      @(posedge vif.rd_clk);
      if (vif.rd_en && !vif.empty) begin
        @(posedge vif.rd_clk);  // Wait one cycle for rd_data to settle
        txn               = fifo_seq_item::type_id::create("rd_txn");
        txn.rd_en         = 1'b1;
        txn.rd_data       = vif.rd_data;
        txn.empty         = vif.empty;
        txn.almost_empty  = vif.almost_empty;
        `uvm_info("RD_MON",
          $sformatf("CAPTURED: rd_data=0x%02h empty=%0b ae=%0b",
            txn.rd_data, txn.empty, txn.almost_empty), UVM_HIGH)
        ap.write(txn);
      end
    end
  endtask : run_phase

endclass : fifo_rd_monitor

`endif // FIFO_RD_MONITOR_SV
// ============================================================
// End of fifo_rd_monitor.sv
// ============================================================
