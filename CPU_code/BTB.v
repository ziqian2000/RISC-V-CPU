`include "defines.v"

module BTB(
	input	wire 					clk,
	input 	wire 					rst,
	input 	wire 					rdy,

	// read
	input 	wire[`InstAddrBus]		raddr_i,
	output 	reg 					hit_o,
	output 	wire[31:0] 				target_o,

	// write
	input 	wire 					we_i,
	input 	wire[`InstAddrBus] 		waddr_i,
	input 	wire[31:0] 				wtarget_i

);

wire[`BTBBlockNumLog2+1:2] 		raddr_idx;
wire[16:`BTBBlockNumLog2+2] 	raddr_tag;
wire[`BTBBlockNumLog2+1:2] 		waddr_idx;
wire[16:`BTBBlockNumLog2+2] 	waddr_tag;

reg 							BTB_valid[`BTBBlockNum-1:0];
reg[14-`BTBBlockNumLog2:0]		BTB_tag[`BTBBlockNum-1:0];
reg[31:0] 						BTB_data[`BTBBlockNum-1:0];

assign raddr_idx = raddr_i[`BTBBlockNumLog2+1:2];
assign raddr_tag = raddr_i[16:`BTBBlockNumLog2+2];
assign waddr_idx = waddr_i[`BTBBlockNumLog2+1:2];
assign waddr_tag = waddr_i[16:`BTBBlockNumLog2+2];

integer i;

// write
always @(posedge clk) begin
	if (rst || !rdy) begin
		for(i = 0; i < `BTBBlockNum; i = i + 1)
			BTB_valid[i] <= 0;
	end	else begin
		if(we_i) begin
			BTB_valid[waddr_idx] <= 1'b1;
			BTB_tag[waddr_idx] <= waddr_tag;
			BTB_data[waddr_idx] <= wtarget_i;
		end
	end
end

assign target_o = BTB_data[raddr_idx];

// read
always @(*) begin
	if(rst || !rdy)begin
		hit_o = 0;
	end else begin
		hit_o = BTB_tag[raddr_idx] == raddr_tag && BTB_valid[raddr_idx];
	end
end

endmodule