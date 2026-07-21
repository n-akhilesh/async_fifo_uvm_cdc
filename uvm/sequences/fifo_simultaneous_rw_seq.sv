// ============================================================
// Sequence    : fifo_simultaneous_rw_seq
// Description : Simultaneous read+write — max CDC stress.
//               Uses coprime clocks (100/73 MHz) to exercise
//               worst-case metastability window.
//               Covers cg_simultaneous_rw.both_active bin.
// ============================================================
`ifndef FIFO_SIMULTANEOUS_RW_SEQ_SV
`define FIFO_SIMULTANEOUS_RW_SEQ_SV

class fifo_simultaneous_rw_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_simultaneous_rw_seq)

  int unsigned num_txn = 64;

  function new(string name = "fifo_simultaneous_rw_seq");
    super.new(name);
  endfunction : new

  task body();
    fifo_seq_item txn;
    // Pre-fill half the FIFO so reads are valid
    repeat(8) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      void'(txn.randomize() with { wr_en==1; rd_en==0; inj_delay==0; });
      finish_item(txn);
    end
    // Now drive simultaneous R+W for num_txn beats
    repeat(num_txn) begin
      txn = fifo_seq_item::type_id::create("txn");
      start_item(txn);
      void'(txn.randomize() with { wr_en==1; rd_en==1; inj_delay inside{[0:1]}; });
      finish_item(txn);
    end
    `uvm_info("SIM_RW_SEQ", "Simultaneous R+W CDC stress complete", UVM_MEDIUM)
  endtask : body

endclass : fifo_simultaneous_rw_seq

`endif // FIFO_SIMULTANEOUS_RW_SEQ_SV
