// ============================================================
// Sequence    : fifo_almost_empty_seq
// Description : Fill FIFO then drain to AE_THRESH (4 left).
//               Verifies almost_empty assertion at threshold.
// ============================================================
`ifndef FIFO_ALMOST_EMPTY_SEQ_SV
`define FIFO_ALMOST_EMPTY_SEQ_SV

class fifo_almost_empty_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_almost_empty_seq)

  function new(string name = "fifo_almost_empty_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    // Fill completely
    repeat(16) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      void'(txn.randomize() with { wr_en==1; rd_en==0; inj_delay==0; });
      finish_item(txn);
    end
    // Drain until AE_THRESH (12 reads → 4 left)
    repeat(12) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      void'(txn.randomize() with { rd_en==1; wr_en==0; inj_delay==0; });
      finish_item(txn);
    end
    `uvm_info("AE_SEQ", "Drained to AE_THRESH — almost_empty should assert", UVM_MEDIUM)
  endtask : body

endclass : fifo_almost_empty_seq

`endif // FIFO_ALMOST_EMPTY_SEQ_SV
