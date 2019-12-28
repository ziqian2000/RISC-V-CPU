module predictor(
	input	wire 					clk,
	input 	wire 					rst,
	input 	wire 					rdy,

	// read
	input 	wire[`InstAddrBus]		raddr_i,
	output 	wire 					pre_taken,

	// write
	input 	wire 					we_i,
	input 	wire[`InstAddrBus] 		waddr_i,
	input 	wire 					res_taken

);

wire[`PreBlockNumLog2-1:0] 		raddr_idx;
wire[`PreBlockNumLog2-1:0] 		waddr_idx;

reg[2:0]						branch_history[`PreBlockNum-1:0];

assign raddr_idx = raddr_i[`PreBlockNumLog2+1:2];
assign waddr_idx = waddr_i[`PreBlockNumLog2+1:2];

integer i;

// write
always @(posedge clk) begin
	if (rst || !rdy) begin
		for(i = 0; i < `PreBlockNum; i = i + 1)
			branch_history[i] <= 2'b01;
	end	else begin
		if(we_i) begin
			if(res_taken) 	branch_history[waddr_idx] <= branch_history[waddr_idx] == 2'b11 ? 2'b11 : branch_history[waddr_idx] + 2'b01;
			else 			branch_history[waddr_idx] <= branch_history[waddr_idx] == 2'b00 ? 2'b00 : branch_history[waddr_idx] - 2'b01;
		end
	end
end

// read
assign pre_taken = branch_history[raddr_idx][1];

endmodule