// ============================================================
// Sequence    : fifo_overflow_seq
// Description : Write to FULL FIFO — attempt overflow.
//               DUT must block write (wr_en_gated=0 when full).
//               Verifies p_no_write_when_full SVA.
// ============================================================
`ifndef FIFO_OVERFLOW_SEQ_SV
`define FIFO_OVERFLOW_SEQ_SV

class fifo_overflow_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_overflow_seq)

  function new(string name = "fifo_overflow_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    // Fill the FIFO first
    repeat(16) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      void'(txn.randomize() with { wr_en==1; rd_en==0; inj_delay==0; });
      finish_item(txn);
    end
    // Now attempt 4 more writes — these MUST be blocked by DUT
    repeat(4) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      void'(txn.randomize() with { wr_en==1; rd_en==0; inj_delay==0; });
      finish_item(txn);
    end
    `uvm_info("OVERFLOW_SEQ", "Overflow attempts completed — check SVA", UVM_MEDIUM)
  endtask : body

endclass : fifo_overflow_seq

`endif // FIFO_OVERFLOW_SEQ_SV
