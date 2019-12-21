module predictor(
	input 	wire 		clk,
	input	wire 		rst,
	input 	wire 		rdy,

	// read
	input 	wire[`InstAddrBus]		raddr_i,
	output 	reg 					pre_o,

	// write
	input 	wire 					we_i,
	input 	wire[`InstAddrBus] 		waddr_i,
	input 	wire 	 				taken_i

);

reg[1:0] 	branch_history0[`PredBlockNum-1:0];
reg[1:0] 	branch_history1[`PredBlockNum-1:0];
reg[1:0] 	branch_history2[`PredBlockNum-1:0];
reg[1:0] 	branch_history3[`PredBlockNum-1:0];

reg[1:0]	global_history;

wire[4:0] 	raddr;

integer i;
integer j;

assign raddr = raddr_i[4:0];

// write
always @(posedge clk) begin
	if (rst) begin
		global_history <= 0;
		for(i = 0; i < `PredBlockNum; i = i + 1) begin
			branch_history0[i] = 2'b1;
			branch_history1[i] = 2'b1;
			branch_history2[i] = 2'b1;
			branch_history3[i] = 2'b1;
		end
	end	else begin
		if(we_i) begin
			if(taken_i) begin
				case(global_history) 
					2'b00: begin
						branch_history0[raddr]
							<= branch_history0[raddr] == 2'b11 
								? 2'b11 
								: branch_history0[raddr] + 1;
					end
					2'b01: begin
						branch_history1[raddr]
							<= branch_history1[raddr] == 2'b11 
								? 2'b11 
								: branch_history1[raddr] + 1;
					end
					2'b10: begin
						branch_history2[raddr]
							<= branch_history2[raddr] == 2'b11 
								? 2'b11 
								: branch_history2[raddr] + 1;
					end
					2'b11: begin
						branch_history3[raddr]
							<= branch_history3[raddr] == 2'b11 
								? 2'b11 
								: branch_history3[raddr] + 1;
					end
				endcase
				global_history <= global_history == 2'b11 ? 2'b11 : global_history + 1;
			end else begin
				case(global_history) 
					2'b00: begin
						branch_history0[raddr]
							<= branch_history0[raddr] == 0
								? 0
								: branch_history0[raddr] - 1;
					end
					2'b01: begin
						branch_history1[raddr]
							<= branch_history1[raddr] == 0
								? 0
								: branch_history1[raddr] - 1;
					end
					2'b10: begin
						branch_history2[raddr]
							<= branch_history2[raddr] == 0
								? 0
								: branch_history2[raddr] - 1;
					end
					2'b11: begin
						branch_history3[raddr]
							<= branch_history3[raddr] == 0
								? 0
								: branch_history3[raddr] - 1;
					end
				endcase
				global_history <= global_history == 0 ? 0 : global_history - 1;
			end
		end
	end
end

// read
always @(*) begin
	if(rst || !rdy)begin
		pre_o = 0;
	end else begin
		case(global_history) 
			2'b00: begin
				pre_o = branch_history0[raddr] > 1'b1 ? 1'b1 : 0;
			end
			2'b01: begin
				pre_o = branch_history1[raddr] > 1'b1 ? 1'b1 : 0;
			end
			2'b10: begin
				pre_o = branch_history2[raddr] > 1'b1 ? 1'b1 : 0;
			end
			2'b11: begin
				pre_o = branch_history3[raddr] > 1'b1 ? 1'b1 : 0;
			end
		endcase
	end
end

endmodule