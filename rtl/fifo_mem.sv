module fifo_mem #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 16
) (
    //Write Port
    input logic wr_clk,
    input loigc wr_en,
    input logic [$clog2(DEPTH)-1:0] wr_addr,
    input logic [DATA_WIDTH-1:0] wr_data

    //Read Port
    input logic [$clog2(DEPTH)-1:0] rd_addr,
    output logic [DATA_WIDTH-1 :0] rd_data

);

logic [DATA_WIDTH-1:0] mem [0:DEPTH-1] ;


//write on synchrnous edge
always_ff @(posedge wr_clk ) begin 
    if(wr_en) begin
        mem[wr_addr] <= wr_data;
    end
  //Read Port Async

  assign rd_data = mem[rd_addr] ;
end

endmodule   







