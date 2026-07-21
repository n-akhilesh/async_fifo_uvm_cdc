// ============================================================
// Sequence    : fifo_rd_basic_seq
// Description : Basic read sequence — 32 random read beats.
// ============================================================
`ifndef FIFO_RD_BASIC_SEQ_SV
`define FIFO_RD_BASIC_SEQ_SV

class fifo_rd_basic_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_rd_basic_seq)

  int unsigned num_txn = 32;

  function new(string name = "fifo_rd_basic_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    repeat(num_txn) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      if (!txn.randomize() with { rd_en == 1'b1; inj_delay inside {[0:2]}; })
        `uvm_fatal("RD_BASIC_SEQ", "Randomization failed")
      finish_item(txn);
    end
  endtask : body

endclass : fifo_rd_basic_seq

`endif // FIFO_RD_BASIC_SEQ_SV
