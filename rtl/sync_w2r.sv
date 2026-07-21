module sync_w2r #(
  parameter int PTR_WIDTH   = 5, 
  parameter int SYNC_STAGES = 2   
)(
  input  logic                 rd_clk,         
  input  logic                 rd_rstn,        
  input  logic [PTR_WIDTH-1:0] wptr_gray,     
  output logic [PTR_WIDTH-1:0] wptr_gray_sync  

  (* ASYNC_REG = "TRUE" *) logic [PTR_WIDTH-1:0] sync_stage1;
  (* ASYNC_REG = "TRUE" *) logic [PTR_WIDTH-1:0] sync_stage2;

  always_ff @(posedge rd_clk) begin
    if (!rd_rstn) begin
      sync_stage1 <= '0;  
      sync_stage2 <= '0;
    end else begin
      sync_stage1 <= wptr_gray;   
      sync_stage2 <= sync_stage1; 
    end
  end


  assign wptr_gray_sync = sync_stage2;

endmodule