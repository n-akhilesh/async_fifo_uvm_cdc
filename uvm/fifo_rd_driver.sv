// ============================================================
// File        : fifo_rd_driver.sv
// Project     : async_fifo_uvm_cdc
// Description : Read-domain UVM driver.
//               Drives rd_clk domain @ 73 MHz (coprime to wr).
//               Uses rd_cb clocking block (1ns skew).
//               Handles rd_en only — read is demand-driven.
//
// CDC NOTE: rd_clk and wr_clk are INDEPENDENT (coprime 100/73).
//           This driver NEVER touches wr_clk domain signals.
// ============================================================
`ifndef FIFO_RD_DRIVER_SV
`define FIFO_RD_DRIVER_SV

class fifo_rd_driver extends uvm_driver #(fifo_seq_item);

  `uvm_component_utils(fifo_rd_driver)

  virtual fifo_if #(.DATA_WIDTH(8)) vif;

  function new(string name = "fifo_rd_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual fifo_if #(.DATA_WIDTH(8)))::get(
          this, "", "fifo_vif", vif))
      `uvm_fatal("RD_DRV", "Cannot get fifo_vif from config_db")
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    fifo_seq_item txn;

    // Initialise read-domain signals
    vif.rd_cb.rd_en <= 1'b0;

    // Wait for reset deassert (wait until arst_n goes high)
    // Monitor arst_n asynchronously then re-sync to rd_clk
    @(posedge vif.arst_n);
    repeat(2) @(vif.rd_cb);  // 2-FF sync deassert margin

    forever begin
      seq_item_port.get_next_item(txn);

      if (txn.inj_delay > 0)
        repeat(txn.inj_delay) @(vif.rd_cb);

      vif.rd_cb.rd_en <= txn.rd_en;
      @(vif.rd_cb);
      vif.rd_cb.rd_en <= 1'b0;

      // Capture read-side observable outputs
      txn.rd_data    = vif.rd_cb.rd_data;
      txn.empty      = vif.rd_cb.empty;
      txn.almost_empty = vif.rd_cb.almost_empty;

      `uvm_info("RD_DRV",
        $sformatf("DROVE: rd_en=%0b rd_data=0x%02h empty=%0b ae=%0b",
          txn.rd_en, txn.rd_data, txn.empty, txn.almost_empty), UVM_HIGH)

      seq_item_port.item_done();
    end
  endtask : run_phase

endclass : fifo_rd_driver

`endif // FIFO_RD_DRIVER_SV
// ============================================================
// End of fifo_rd_driver.sv
// ============================================================
