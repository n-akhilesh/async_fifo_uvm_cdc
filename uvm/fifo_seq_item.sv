// ============================================================
// File        : fifo_seq_item.sv
// Project     : async_fifo_uvm_cdc
// Description : UVM sequence item (transaction) for the
//               async FIFO. Represents one bus-level operation.
//               Fields cover both write and read domains.
//
// Interview Key Points:
//   - uvm_object_utils_begin/end  → factory registration
//   - rand/randc                  → randomisation fields
//   - constraint blocks           → legal value generation
//   - do_copy/do_compare/do_print → deep field automation
// ============================================================
`ifndef FIFO_SEQ_ITEM_SV
`define FIFO_SEQ_ITEM_SV

class fifo_seq_item extends uvm_sequence_item;

  // ---- Factory Registration ----
  `uvm_object_utils_begin(fifo_seq_item)
    `uvm_field_int(wr_data,   UVM_ALL_ON)
    `uvm_field_int(wr_en,     UVM_ALL_ON)
    `uvm_field_int(rd_en,     UVM_ALL_ON)
    `uvm_field_int(inj_delay, UVM_ALL_ON)
  `uvm_object_utils_end

  // ---- Randomisable Fields ----
  rand logic [7:0]  wr_data;    // 8-bit write data  (DATA_WIDTH=8)
  rand logic        wr_en;      // Write enable
  rand logic        rd_en;      // Read enable
  rand int unsigned inj_delay;  // Inter-transaction delay (cycles)

  // ---- Observed / Sampled Fields (not randomised) ----
  logic [7:0]  rd_data;         // Captured read data (monitor fills)
  logic        full;
  logic        almost_full;
  logic        empty;
  logic        almost_empty;

  // ---- Constraints ----

  // Default: bias writes and reads to be active 70% of the time
  constraint c_wr_en_dist {
    wr_en dist { 1 := 70, 0 := 30 };
  }

  constraint c_rd_en_dist {
    rd_en dist { 1 := 70, 0 := 30 };
  }

  // Inject small random inter-beat gaps: 0-5 cycles
  constraint c_inj_delay {
    inj_delay inside {[0:5]};
  }

  // ---- Constructor ----
  function new(string name = "fifo_seq_item");
    super.new(name);
  endfunction : new

  // ---- do_copy — deep copy ----
  function void do_copy(uvm_object rhs);
    fifo_seq_item rhs_;
    super.do_copy(rhs);
    if (!$cast(rhs_, rhs))
      `uvm_fatal("SEQ_ITEM", "do_copy: cast failed")
    this.wr_data    = rhs_.wr_data;
    this.wr_en      = rhs_.wr_en;
    this.rd_en      = rhs_.rd_en;
    this.inj_delay  = rhs_.inj_delay;
    this.rd_data    = rhs_.rd_data;
    this.full        = rhs_.full;
    this.almost_full = rhs_.almost_full;
    this.empty       = rhs_.empty;
    this.almost_empty= rhs_.almost_empty;
  endfunction : do_copy

  // ---- do_compare — field-level equality ----
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    fifo_seq_item rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (super.do_compare(rhs, comparer) &&
            (this.wr_data   == rhs_.wr_data)  &&
            (this.wr_en     == rhs_.wr_en)    &&
            (this.rd_en     == rhs_.rd_en));
  endfunction : do_compare

  // ---- convert2string — one-line summary ----
  function string convert2string();
    return $sformatf(
      "wr_en=%0b wr_data=0x%02h rd_en=%0b rd_data=0x%02h full=%0b empty=%0b af=%0b ae=%0b dly=%0d",
       wr_en, wr_data, rd_en, rd_data, full, empty, almost_full, almost_empty, inj_delay);
  endfunction : convert2string

endclass : fifo_seq_item

`endif // FIFO_SEQ_ITEM_SV
// ============================================================
// End of fifo_seq_item.sv
// ============================================================
