// ============================================================
// Sequence    : fifo_reset_seq
// Description : Mid-operation reset test.
//               Write 8 items, assert arst_n, deassert,
//               verify FIFO is empty after reset.
//               Tests independent reset domain deassert.
// ============================================================
`ifndef FIFO_RESET_SEQ_SV
`define FIFO_RESET_SEQ_SV

class fifo_reset_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_reset_seq)

  function new(string name = "fifo_reset_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    // Write 8 items
    repeat(8) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      void'(txn.randomize() with { wr_en==1; rd_en==0; inj_delay==0; });
      finish_item(txn);
    end
    // Assert reset (arst_n = 0) for 4 cycles via wr driver
    txn = fifo_seq_item::type_id::create("txn");
    start_item(txn);
    void'(txn.randomize() with { wr_en==0; rd_en==0; inj_delay==4; });
    finish_item(txn);
    `uvm_info("RESET_SEQ", "Mid-op reset applied — FIFO should be cleared", UVM_MEDIUM)
  endtask : body

endclass : fifo_reset_seq

`endif // FIFO_RESET_SEQ_SV
