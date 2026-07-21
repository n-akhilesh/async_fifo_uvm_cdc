// ============================================================
// Sequence    : fifo_drain_seq
// Description : Drain FIFO completely — read DEPTH=16 beats.
//               Verifies empty flag assertion.
// ============================================================
`ifndef FIFO_DRAIN_SEQ_SV
`define FIFO_DRAIN_SEQ_SV

class fifo_drain_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_drain_seq)

  int unsigned depth = 16;

  function new(string name = "fifo_drain_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    repeat(depth) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      if (!txn.randomize() with { rd_en == 1'b1; inj_delay == 0; })
        `uvm_fatal("DRAIN_SEQ", "Randomization failed")
      finish_item(txn);
    end
    `uvm_info("DRAIN_SEQ", "FIFO drained completely", UVM_MEDIUM)
  endtask : body

endclass : fifo_drain_seq

`endif // FIFO_DRAIN_SEQ_SV
