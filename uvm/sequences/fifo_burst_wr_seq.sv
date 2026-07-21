// ============================================================
// Sequence    : fifo_burst_wr_seq
// Description : Burst 16 back-to-back writes (no delay).
//               Tests maximum sustained write bandwidth.
//               Verifies full flag timing after 16th write.
// ============================================================
`ifndef FIFO_BURST_WR_SEQ_SV
`define FIFO_BURST_WR_SEQ_SV

class fifo_burst_wr_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_burst_wr_seq)

  function new(string name = "fifo_burst_wr_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    repeat(16) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      void'(txn.randomize() with { wr_en==1; rd_en==0; inj_delay==0; });
      finish_item(txn);
    end
    `uvm_info("BURST_WR_SEQ", "16-beat burst write complete", UVM_MEDIUM)
  endtask : body

endclass : fifo_burst_wr_seq

`endif // FIFO_BURST_WR_SEQ_SV
