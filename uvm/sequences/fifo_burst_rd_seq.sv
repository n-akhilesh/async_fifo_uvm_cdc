// ============================================================
// Sequence    : fifo_burst_rd_seq
// Description : Burst 16 back-to-back reads (no delay).
//               Tests maximum sustained read bandwidth.
//               Verifies empty flag timing after 16th read.
// ============================================================
`ifndef FIFO_BURST_RD_SEQ_SV
`define FIFO_BURST_RD_SEQ_SV

class fifo_burst_rd_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_burst_rd_seq)

  function new(string name = "fifo_burst_rd_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    repeat(16) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      void'(txn.randomize() with { rd_en==1; wr_en==0; inj_delay==0; });
      finish_item(txn);
    end
    `uvm_info("BURST_RD_SEQ", "16-beat burst read complete", UVM_MEDIUM)
  endtask : body

endclass : fifo_burst_rd_seq

`endif // FIFO_BURST_RD_SEQ_SV
