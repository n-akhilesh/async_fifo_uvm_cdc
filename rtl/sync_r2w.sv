module sync_r2w #(
  parameter int PTR_WIDTH   = 5, 
  parameter int SYNC_STAGES = 2  
)(
  input  logic                 wr_clk,         
  input  logic                 wr_rstn,        
  input  logic [PTR_WIDTH-1:0] rptr_gray,      
  output logic [PTR_WIDTH-1:0] rptr_gray_sync 
);


  (* ASYNC_REG = "TRUE" *) logic [PTR_WIDTH-1:0] sync_stage1;
  (* ASYNC_REG = "TRUE" *) logic [PTR_WIDTH-1:0] sync_stage2;

  always_ff @(posedge wr_clk) begin
    if (!wr_rstn) begin
      sync_stage1 <= '0;  
      sync_stage2 <= '0;
    end else begin
      sync_stage1 <= rptr_gray;   
      sync_stage2 <= sync_stage1; 
    end
  end

  // Output is always Stage 2 — never Stage 1
  assign rptr_gray_sync = sync_stage2;

endmodule