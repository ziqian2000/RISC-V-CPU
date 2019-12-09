module if_(
	input	wire					clk,
	input 	wire 					rst,

	// to & from mem_ctrl
	output	reg 					if_request, 	//	0 : no request 			
													//  1 : load instr for IF
	output 	reg[31:0]				if_addr,
	input	wire[7:0]				mem_ctrl_data,	// data from mem_ctrl
	input	wire[1:0]				if_or_mem_i,	// 01 : if 		10 : mem

	// to IF/ID
	output	wire[`InstAddrBus]		pc_o, 			// the true pc value by substract 4 from pc
	output	reg[`InstBus]			if_inst,

	// from ID
	input 	wire 					branch_enable_i,
	input 	wire[`InstAddrBus] 		branch_addr_i,

	// from ctrl
	input 	wire[`StallBus] 		stall_sign,

	// to & from icache
	// (read)
	output 	reg[`InstAddrBus] 		raddr_o,
	input 	wire 					hit_i,
	input 	wire[31:0]				inst_i,
	// (write)
	output 	reg 					we_o,
	output 	reg[`InstAddrBus] 		waddr_o,
	output 	reg[31:0] 				wdata_o


);

reg[4:0] 		state;
reg[31:0] 		inst;
reg[`InstBus] 	pc;
reg 			stalled; // has been stalled, so the address is lost

assign pc_o = pc - 32'h4;

reg[3:0] avoid_data_hazard;


always @(posedge clk) begin
		if (rst == `RstEnable) begin
			if_request 	<= 0;
			if_addr 	<= 0;
			pc  		<= 0;
			if_inst 	<= 0;
			inst 		<= 0;
			state 		<= 0;
			we_o 		<= 0;
			avoid_data_hazard <= 0;
		// end else if(stall_sign[0]) begin
			// STALL
		end else if(branch_enable_i) begin
			if(!stall_sign[0]) begin
				if_request 	<= 0;
				if_addr 	<= 0;
				pc 			<= branch_addr_i;
				if_inst 	<= 0;
				inst 		<= 0;
				state 		<= 5'b00000;
			end
		end	else begin 

			// $display("%x",pc);

			case(state)
				5'b00000: begin // send the 1st address
					if(!stall_sign[1])  begin
						if(avoid_data_hazard == 0) begin
							if_request <= 1'b1;
							if_addr <= pc;
							if_inst <= 0;

							if(stall_sign[0]) begin
								state <= 5'b10000;
							end else begin
								state <= 5'b00001;
							end

							avoid_data_hazard <= 4'h7; // !!!

							raddr_o <= pc;
							we_o <= 0;
						end else begin
							avoid_data_hazard <= avoid_data_hazard - 1;
							if_inst <= 0;
						end
					end
				end
				5'b00001: begin // the 1st byte is being prepared, send the 2nd request
					if(hit_i) begin
						state <= 5'b00000;
						if_inst <= inst_i;
						pc <= pc + 31'h4;
					end else if(stall_sign[0]) begin
						state <= 5'b10000;
					end else begin
						state <= 5'b00010;
						if_addr <= pc + 31'h1;
						if_inst <= 0;
					end
				end
				5'b00010: begin // the 2nd byte is being prepared, send the 3rd request
					inst[7:0] <= mem_ctrl_data;
					state <= 5'b00011;
					if_addr <= pc + 31'h2;
					if(stall_sign[0]) begin
						stalled <= 1;
					end
				end
				5'b00011: begin // the 3rd byte is being prepared, send the 4th request
					if(stall_sign[0] || stalled) begin
						stalled <= 0;
						state <= 5'b10011;
					end else begin
						inst[15:8] <= mem_ctrl_data;
						state <= 5'b00100;
						if_addr <= pc + 31'h3;
					end
				end
				5'b00100: begin // the 4th byte is being prepared
					if(stall_sign[0] || stalled) begin
						stalled <= 0;
						state <= 5'b10110;
					end else begin
						inst[23:16] <= mem_ctrl_data;
						state <= 5'b00101;
					end
				end
				5'b00101: begin // form the whole instr, send the next request
					if(stall_sign[0] || stalled) begin
						stalled <= 0;
						state <= 5'b11000;
					end else begin
						inst[31:24] <= mem_ctrl_data;
						if_inst <= {mem_ctrl_data, inst[23:0]};
						pc <= pc + 31'h4;
						if_addr <= pc + 31'h4;

						state <= 5'b00000;

						we_o <= 1;
						waddr_o <= pc;
						wdata_o <= {mem_ctrl_data, inst[23:0]};
					end

				end

				// for interuption from MEM

				5'b10000: begin
					if(hit_i) begin
						state <= 5'b00000;
						if_inst <= inst_i;
						pc <= pc + 31'h4;
					end else if(!stall_sign[0]) begin
						state <= 5'b10001;
						if_addr <= pc;
						if_inst <= 0;
					end
				end
				5'b10001: begin
					state <= 5'b10010;
					if_addr <= pc + 31'h1;
					if(stall_sign[0]) begin
						stalled <= 1;
					end
				end
				5'b10010: begin
					state <= 5'b00011;
					if_addr <= pc + 31'h2;
					inst[7:0] <= mem_ctrl_data;
					if(stall_sign[0]) begin
						stalled <= 1;
					end
				end
				///
				5'b10011: begin
					if(!stall_sign[0]) begin
						state <= 5'b10100;
						if_addr <= pc + 31'h1;
					end
				end
				5'b10100: begin
					state <= 5'b10101;
					if_addr <= pc + 31'h2;
					if(stall_sign[0]) begin
						stalled <= 1;
					end
				end
				5'b10101: begin
					state <= 5'b00100;
					if_addr <= pc + 31'h3;
					inst[15:8] <= mem_ctrl_data;
					if(stall_sign[0]) begin
						stalled <= 1;
					end
				end
				///
				5'b10110: begin
					if(!stall_sign[0]) begin
						state <= 5'b10111;
						if_addr <= pc + 31'h2;
					end
				end
				5'b10111: begin
					state <= 5'b11000;
					if_addr <= pc + 31'h3;
					if(stall_sign[0]) begin
						stalled <= 1;
					end
				end
				5'b11000: begin
					state <= 5'b00101;
					if_addr <= pc + 31'h4;
					inst[23:16] <= mem_ctrl_data;
					if(stall_sign[0]) begin
						stalled <= 1;
					end
				end
				///
				5'b11001: begin
					if(!stall_sign[0]) begin
						state <= 5'b11010;
						if_addr <= pc + 31'h3;
					end
				end
				5'b11010: begin
					state <= 5'b11011;
					if(stall_sign[0]) begin
						stalled <= 1;
					end
				end
				5'b11011: begin
					state <= 5'b00000;


					inst[31:24] <= mem_ctrl_data;
					if_inst <= {mem_ctrl_data, inst[23:0]};
					pc <= pc + 31'h4;

					we_o <= 1;
					waddr_o <= pc;
					wdata_o <= {mem_ctrl_data, inst[23:0]};


					if(stall_sign[0]) begin
						stalled <= 1;
					end
				end
				///


			endcase
		end
	end	

endmodule