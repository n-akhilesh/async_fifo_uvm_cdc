// ============================================================
// File        : fifo_wr_driver.sv
// Project     : async_fifo_uvm_cdc
// Description : Write-domain UVM driver.
//               Drives wr_clk domain @ 100 MHz.
//               Uses wr_cb clocking block (1ns skew).
//               Handles arst_n, wr_en, wr_data.
//
// Interview Key Points:
//   - uvm_driver #(seq_item) parametrisation
//   - run_phase + forever loop
//   - seq_item_port.get_next_item() → drive → item_done()
//   - virtual interface + clocking block usage
// ============================================================
`ifndef FIFO_WR_DRIVER_SV
`define FIFO_WR_DRIVER_SV

class fifo_wr_driver extends uvm_driver #(fifo_seq_item);

  `uvm_component_utils(fifo_wr_driver)

  // ---- Virtual Interface Handle ----
  virtual fifo_if #(.DATA_WIDTH(8)) vif;

  // ---- Constructor ----
  function new(string name = "fifo_wr_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  // ---- build_phase: fetch vif from config_db ----
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual fifo_if #(.DATA_WIDTH(8)))::get(
          this, "", "fifo_vif", vif))
      `uvm_fatal("WR_DRV", "Cannot get fifo_vif from config_db")
  endfunction : build_phase

  // ---- run_phase: main driving loop ----
  task run_phase(uvm_phase phase);
    fifo_seq_item txn;

    // Initialise write-domain signals
    vif.wr_cb.wr_en   <= 1'b0;
    vif.wr_cb.wr_data <= 8'h00;
    vif.wr_cb.arst_n  <= 1'b0;   // Assert reset

    // Hold reset for 4 wr_clk cycles
    repeat(4) @(vif.wr_cb);
    vif.wr_cb.arst_n <= 1'b1;    // Deassert reset
    @(vif.wr_cb);

    forever begin
      // 1. Request next transaction from sequencer
      seq_item_port.get_next_item(txn);

      // 2. Optional inter-beat injection delay
      if (txn.inj_delay > 0)
        repeat(txn.inj_delay) @(vif.wr_cb);

      // 3. Drive the clocking block outputs
      vif.wr_cb.wr_en   <= txn.wr_en;
      vif.wr_cb.wr_data <= txn.wr_data;
      @(vif.wr_cb);

      // 4. De-assert wr_en after one cycle (single-beat)
      vif.wr_cb.wr_en   <= 1'b0;
      vif.wr_cb.wr_data <= 8'h00;

      // 5. Capture observable outputs into transaction
      txn.full         = vif.wr_cb.full;
      txn.almost_full  = vif.wr_cb.almost_full;

      `uvm_info("WR_DRV",
        $sformatf("DROVE: wr_en=%0b wr_data=0x%02h full=%0b af=%0b",
          txn.wr_en, txn.wr_data, txn.full, txn.almost_full), UVM_HIGH)

      // 6. Signal to sequencer that item is consumed
      seq_item_port.item_done();
    end
  endtask : run_phase

endclass : fifo_wr_driver

`endif // FIFO_WR_DRIVER_SV
// ============================================================
// End of fifo_wr_driver.sv
// ============================================================
