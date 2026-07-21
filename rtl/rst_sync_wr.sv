// ============================================================
// Module      : rst_sync_wr
// Project     : async_fifo_uvm_cdc
// Description : Write-domain reset synchronizer.
//               Implements RDC standard pattern:
//                 ASYNC ASSERT  — reset propagates immediately
//                                 the moment arst_n goes low,
//                                 regardless of wr_clk edge.
//                 SYNC DEASSERT — reset releases only on the
//                                 next wr_clk rising edge after
//                                 arst_n goes high, after passing
//                                 through 2 FF stages.
// ============================================================

`timescale 1ns/1ps

module rst_sync_wr (
  input  logic wr_clk,    // Write domain clock
  input  logic arst_n,    
  output logic srst_n_wr  
);

  logic [1:0] sync_ff;

  always_ff @(posedge wr_clk or negedge arst_n) begin
    if (!arst_n) begin
      // ASYNC ASSERT PATH:
      // arst_n low → immediately force both stages to 0
      // srst_n_wr goes low RIGHT NOW regardless of wr_clk
      sync_ff <= 2'b00;
    end else begin

      sync_ff <= {sync_ff[0], 1'b1};
    end
  end

  assign srst_n_wr = sync_ff[1];

endmodule
