// ============================================================
// Sequence    : fifo_wr_basic_seq
// Description : Basic write sequence — 32 random write beats.
//               Default workhorse for fifo_base_test.
// ============================================================
`ifndef FIFO_WR_BASIC_SEQ_SV
`define FIFO_WR_BASIC_SEQ_SV

class fifo_wr_basic_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_wr_basic_seq)

  int unsigned num_txn = 32;

  function new(string name = "fifo_wr_basic_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    repeat(num_txn) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      if (!txn.randomize() with { wr_en == 1'b1; inj_delay inside {[0:2]}; })
        `uvm_fatal("WR_BASIC_SEQ", "Randomization failed")
      finish_item(txn);
    end
  endtask : body

endclass : fifo_wr_basic_seq

`endif // FIFO_WR_BASIC_SEQ_SV
