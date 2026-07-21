// ============================================================
// Sequence    : fifo_fill_seq
// Description : Fill FIFO to capacity — write DEPTH=16 beats
//               with no reads. Verifies full flag assertion.
// ============================================================
`ifndef FIFO_FILL_SEQ_SV
`define FIFO_FILL_SEQ_SV

class fifo_fill_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_fill_seq)

  int unsigned depth = 16;

  function new(string name = "fifo_fill_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    repeat(depth) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      if (!txn.randomize() with { wr_en == 1'b1; rd_en == 1'b0; inj_delay == 0; })
        `uvm_fatal("FILL_SEQ", "Randomization failed")
      finish_item(txn);
    end
    `uvm_info("FILL_SEQ", "FIFO filled to capacity", UVM_MEDIUM)
  endtask : body

endclass : fifo_fill_seq

`endif // FIFO_FILL_SEQ_SV
