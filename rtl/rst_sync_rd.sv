// ============================================================
// Module      : rst_sync_rd
// Project     : async_fifo_uvm_cdc
// Description : Read-domain reset synchronizer.
//               Exact mirror of rst_sync_wr.sv — operates on
//               rd_clk instead of wr_clk.
//
//               CRITICAL DESIGN NOTE:
//               rst_sync_rd and rst_sync_wr are INTENTIONALLY
//               INDEPENDENT. They share the same arst_n source
//               but deassert on different clock edges (wr_clk
//               vs rd_clk). This means the write and read
//               domains come out of reset at different absolute
//               times — this is correct and expected behavior.
// ============================================================

`timescale 1ns/1ps

module rst_sync_rd (
  input  logic rd_clk,    
  input  logic arst_n,    
  output logic srst_n_rd  //fed to  all FF in read domain
);

 logic [1:0] sync_ff;

  always_ff @(posedge rd_clk or negedge arst_n) begin
    if (!arst_n) begin
      // ASYNC ASSERT PATH:
      // arst_n low → immediately clear both stages
      // srst_n_rd goes low instantly — no rd_clk needed
      sync_ff <= 2'b00;
    end else begin
      sync_ff <= {sync_ff[0], 1'b1}; //2 bit synchronizer on rd side
    end
  end
  // srst_n_rd follows sync_ff[1]
  assign srst_n_rd = sync_ff[1];

endmodule
