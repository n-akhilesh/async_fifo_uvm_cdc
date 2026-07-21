// ============================================================
// Sequence    : fifo_almost_full_seq
// Description : Fill FIFO to AF_THRESH boundary (depth-4=12).
//               Verifies almost_full assertion at threshold.
// ============================================================
`ifndef FIFO_ALMOST_FULL_SEQ_SV
`define FIFO_ALMOST_FULL_SEQ_SV

class fifo_almost_full_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_almost_full_seq)

  int unsigned af_level = 12;  // DEPTH(16) - AF_THRESH(4)

  function new(string name = "fifo_almost_full_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    repeat(af_level) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      void'(txn.randomize() with { wr_en==1; rd_en==0; inj_delay==0; });
      finish_item(txn);
    end
    `uvm_info("AF_SEQ", $sformatf("Filled to %0d — almost_full should assert", af_level), UVM_MEDIUM)
  endtask : body

endclass : fifo_almost_full_seq

`endif // FIFO_ALMOST_FULL_SEQ_SV
