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
	input 	wire 					res_taken,
	input 	wire 					com_taken

);

wire[`PreBlockNumLog2-1:0] 		raddr_idx;
wire[`PreBlockNumLog2-1:0] 		waddr_idx;

reg[1:0]						branch_counter[`PreBlockNum-1:0];
reg[1:0] 						global_counter[`GlobalBlockNum-1:0];

reg[`GlobalBlockNumLog2-1:0] 	global_history;

reg[1:0] 						selector;

assign raddr_idx = raddr_i[`PreBlockNumLog2+1:2];
assign waddr_idx = waddr_i[`PreBlockNumLog2+1:2];

integer i;
integer j;

// write
always @(posedge clk) begin
	if (rst) begin
		for(i = 0; i < `PreBlockNum; i = i + 1)
			branch_counter[i] <= 2'b01;
		for(j = 0; j < `GlobalBlockNum; j = j + 1)
			global_counter[j] <= 2'b01;
		global_history <= 0;
		selector <= 0;
	end	else if(rdy) begin
		if(we_i) begin

			if(res_taken) begin
				branch_counter[waddr_idx] 
						<= (branch_counter[waddr_idx] == 2'b11 ? 2'b11 : branch_counter[waddr_idx] + 2'b01);
				global_counter[global_history] 
						<= (global_counter[global_history] == 2'b11 ? 2'b11 : global_counter[global_history] + 2'b01);
				global_history <= {global_history[`GlobalBlockNumLog2-2:0], 1'b1};
			end else begin
		 		branch_counter[waddr_idx] 
		 				<= (branch_counter[waddr_idx] == 2'b00 ? 2'b00 : branch_counter[waddr_idx] - 2'b01);
		 		global_counter[global_history] 
		 				<= (global_counter[global_history] == 2'b00 ? 2'b00 : global_counter[global_history] - 2'b01);
				global_history <= {global_history[`GlobalBlockNumLog2-2:0], 1'b0};
			end

			if(com_taken == res_taken) begin
				if(selector) begin
					selector <= selector == 2'b11 ? 2'b11 : selector + 2'b01;
				end else begin
					selector <= selector == 2'b00 ? 2'b00 : selector - 2'b01;
				end
			end else begin
				if(selector) begin 
					selector <= selector == 2'b00 ? 2'b00 : selector - 2'b01;
				end else begin
					selector <= selector == 2'b11 ? 2'b11 : selector + 2'b01;
				end
			end

		end
	end
end

// read
assign pre_taken = selector[1] ? branch_counter[raddr_idx][1] : global_counter[global_history][1];
// assign pre_taken = branch_counter[raddr_idx][1];
// assign pre_taken = global_counter[global_history][1];

endmodule