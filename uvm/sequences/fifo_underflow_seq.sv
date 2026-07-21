// ============================================================
// Sequence    : fifo_underflow_seq
// Description : Read from EMPTY FIFO — attempt underflow.
//               DUT must block read (rptr must not increment).
//               Verifies p_no_read_when_empty SVA.
// ============================================================
`ifndef FIFO_UNDERFLOW_SEQ_SV
`define FIFO_UNDERFLOW_SEQ_SV

class fifo_underflow_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_underflow_seq)

  function new(string name = "fifo_underflow_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    // Attempt 4 reads on empty FIFO — must be no-ops
    repeat(4) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      void'(txn.randomize() with { rd_en==1; wr_en==0; inj_delay==0; });
      finish_item(txn);
    end
    `uvm_info("UNDERFLOW_SEQ", "Underflow attempts completed — check SVA", UVM_MEDIUM)
  endtask : body

endclass : fifo_underflow_seq

`endif // FIFO_UNDERFLOW_SEQ_SV
