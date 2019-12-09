module mem(
	input 	wire 					clk,
	input 	wire 					rst,

	// from ex_mem
	input	wire[`RegAddrBus]		wd_i,
	input	wire					wreg_i,
	input	wire[`RegBus]			wdata_i,
	input 	wire[`InstAddrBus] 		mem_addr_i,
	input 	wire[`OpcodeBus] 		opcode_i,

	// to mem_wb
	output	reg[`RegAddrBus]		wd_o,
	output 	reg 					wreg_o,
	output 	reg[`RegBus]			wdata_o,

	// to mem_ctrl
	input	wire[1:0]				if_or_mem,	// 01 : if 		10 : mem
	input 	wire[7:0] 				mem_ctrl_data_i,
	output 	reg[7:0] 				mem_ctrl_data_o,
	output 	reg[1:0] 				mem_request,// 	00 : no request 01 : LOAD	10 : STORE
	output 	reg[`InstAddrBus] 		mem_addr,	

	// to ctrl
	output 	reg 					mem_stall_request,

	// from ctrl
	input 	wire[`StallBus] 		stall_sign
);

reg[3:0] 	state;
reg 		mem_done;

// when applying combinational logic 
// use "=" instead of "<=" to avoid a endless loop caused by the change of state


// stall observer
always @(*) begin
	if (rst == `RstEnable) begin
		mem_stall_request = 0;
	end else begin
		if(mem_done) begin
			mem_stall_request = 0;
		end else begin
			case(opcode_i[6:0])
				7'b0000011, 7'b0100011: 				// LOAD, STORE
					mem_stall_request = 1;
				default: 								// OTHER
					mem_stall_request = 0;
			endcase
		end
	end
end

always @(posedge clk) begin
	if (rst == `RstEnable) begin
		wd_o <= `NOPRegAddr;
		wreg_o <= `WriteDisable;
		wdata_o <= `ZeroWord;
		state 	<= 0;
		mem_ctrl_data_o <= 0;
		mem_request <= 0;
		mem_addr <= 0;
		mem_done <= 0;

	// end else if(stall_sign[6]) begin
		// STALL
	end else begin
	
		wd_o <= wd_i;
		wreg_o <= wreg_i;

		if(mem_done) begin
			mem_done <= 0;
		end else begin
				
			if(opcode_i[6:0] == 7'b0000011 || opcode_i[6:0] == 7'b0100011) begin // LOAD or STORE
				
				begin
					
					case(state)
						4'b0000: begin // send the 1st address
							state <= 4'b0001;
							
							if(opcode_i[6:0] == 7'b0000011) begin 			// LOAD
								mem_addr <= mem_addr_i;
								mem_request <= 2'b01;
							end else begin 			
								mem_addr <= mem_addr_i;						// STORE
								mem_request <= 2'b10;
								mem_ctrl_data_o <= wdata_i[7:0];
							end
						end
						4'b0001: begin // the 1st byte is being loaded/stored, send the 2nd request
							if(opcode_i[6:0] == 7'b0000011) begin 			// LOAD
								case(opcode_i[9:7])
									`LB, `LBU: begin
										state <= 4'b0010;
									end
									`LH, `LHU, `LW: begin
										mem_addr <= mem_addr_i + 1;
										state <= 4'b0010;
									end
								endcase
							end else begin 									// STORE
								case(opcode_i[9:7])
									`SB: begin
										state <= 4'b0000;
										mem_done <= 1;
										mem_request <= 0;
										
									end
									`SH, `SW: begin
										mem_addr <= mem_addr_i + 1;
										mem_ctrl_data_o <= wdata_i[15:8];
										state <= 4'b0010;
									end
								endcase
							end
						end
						4'b0010: begin // the 2nd byte is being loaded/stored, send the 3rd request
							if(opcode_i[6:0] == 7'b0000011) begin 			// LOAD
								case(opcode_i[9:7])
									`LB: begin
										wdata_o <= {{24{mem_ctrl_data_i[7]}}, mem_ctrl_data_i};
										state <= 4'b0000;
										mem_request <= 0;
										
										mem_done <= 1;
									end
									`LBU: begin
										wdata_o <= {24'b0, mem_ctrl_data_i};
										state <= 4'b0000;
										mem_request <= 0;
										
										mem_done <= 1;
									end
									`LH, `LHU: begin
										wdata_o[7:0] <= mem_ctrl_data_i;
										state <= 4'b0100;
									end
									`LW: begin
										wdata_o[7:0] <= mem_ctrl_data_i;
										mem_addr <= mem_addr_i + 2;
										state <= 4'b0100;
									end
								endcase
							end else begin 									// STORE
								case(opcode_i[9:7])
									`SH: begin
										state <= 4'b0000;
										mem_request <= 0;
										
										mem_done <= 1;
									end
									`SW: begin
										mem_addr <= mem_addr_i + 2;
										mem_ctrl_data_o <= wdata_i[23:16];
										state <= 4'b0100;
									end
								endcase
							end
						end
						4'b0100: begin // the 3rd byte is being loaded/stored, send the 4th request
							state <= 4'b1000;
							if(opcode_i[6:0] == 7'b0000011) begin 			// LOAD
								case(opcode_i[9:7])
									`LH: begin
										wdata_o[31:8] <= {{16{mem_ctrl_data_i[7]}}, mem_ctrl_data_i};
										state <= 4'b0000;
										mem_request <= 0;
										
										mem_done <= 1;
									end
									`LHU: begin
										wdata_o[31:8] <= {16'b0, mem_ctrl_data_i};
										state <= 4'b0000;
										mem_request <= 0;
										
										mem_done <= 1;
									end
									`LW: begin
										wdata_o[15:8] <= mem_ctrl_data_i;
										mem_addr <= mem_addr_i + 3;
										state <= 4'b1000;
									end
								endcase
							end else begin 								// STORE
								case(opcode_i[9:7])
									`SW: begin
										mem_addr <= mem_addr_i + 3;
										mem_ctrl_data_o <= wdata_i[31:24];
										state <= 4'b1000;
									end
								endcase								// STORE
							end
						end
						4'b1000: begin // the 4th byte is being loaded/stored
							if(opcode_i[6:0] == 7'b0000011) begin 			// LOAD
								case(opcode_i[9:7])
									`LW: begin
										wdata_o[23:16] <= mem_ctrl_data_i;
										state <= 4'b1111;
									end
								endcase
							end else begin 									// STORE							// STORE
								case(opcode_i[9:7])
									`SW: begin
										state <= 4'b0000;
										mem_request <= 0;
										
										mem_done <= 1;
									end
								endcase
							end
						end
						4'b1111: begin // final state
							if(opcode_i[6:0] == 7'b0000011) begin 			// LOAD
								case(opcode_i[9:7])
									`LW: begin
										wdata_o[31:24] <= mem_ctrl_data_i;
										state <= 4'b0000;
										mem_request <= 0;
										
										mem_done <= 1;
									end
								endcase
							end else begin 									// STORE
							end
						end
						// default: begin
						// 	$display("FUCK, unknown opcode occured in stage MEM.");
						//end
					endcase
				end
			end else begin
			
				wdata_o <= wdata_i;
				mem_request <= 0;
			end
		end
	end
end

endmodule
