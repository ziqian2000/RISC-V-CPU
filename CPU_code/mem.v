module mem(
	input wire				  	clk,
	input wire				  	rst,

	// read from ex
	input wire[`OpcodeBus]	  	opcode_i,
	input wire[`FunctBus3]	  	funct3_i,
	input wire[`RegAddrBus]		wd_i,
	input wire				  	wreg_i,
	input wire[`RegBus]		 	wdata_i,
	input wire[`InstAddrBus]	mem_addr_i,

	// load mem data
	input wire[`MemDataBus]	 	mem_data_i,
	// pass the result
	output reg[`RegAddrBus]	 	wd_o,
	output reg				  	wreg_o,
	output reg[`RegBus]		 	wdata_o,

	// mem ctrl
	output reg				  	mem_mem_req_o,
	output reg				  	mem_we_o,

	output reg[`InstAddrBus]	mem_addr_o,
	output reg[`MemDataBus]	 	mem_data_o
);

reg[3:0]			state;
reg					mem_done;
reg[`RegBus]		mem_data;
reg[`MemDataBus]	data_block1;
reg[`MemDataBus]	data_block2;
reg[`MemDataBus]	data_block3;

	// observer
	always @(*) begin
		if (rst) begin
			mem_mem_req_o			  = 0;
		end else begin
			if (mem_done) begin
				mem_mem_req_o		  = 0;
			end else if (!mem_done) begin
				case(opcode_i)
					7'b0000011, 7'b0100011:				// LOAD, STORE
						mem_mem_req_o = 1;
					default:							// OTHERS
						mem_mem_req_o = 0;
				endcase
			end
		end
	end

	always @ (posedge clk) begin
		if (rst) begin
			state			<= 4'b0000;
			mem_we_o		<= `WriteDisable;
			mem_data		<= 0;
			mem_addr_o		<= 0;
			data_block1		<= 8'h00;
			data_block2		<= 8'h00;
			data_block3		<= 8'h00;
			mem_data_o		<= 8'h00;
			mem_done		<= 0;
		end else if (mem_mem_req_o) begin
			case (state)
				4'b0000: begin
					mem_addr_o  <= mem_addr_i;
					mem_done	<= 0;
					case (opcode_i)
						`LOAD_OP: begin
							mem_we_o	<= 0;
							state		<= 4'b0001;
						end
						`STORE_OP: begin
							mem_we_o	<= 1'b1;
							mem_data_o  <= wdata_i[7:0];
							state		<= 4'b0001;
						end
						default: ;
					endcase
				end
				4'b0001: begin
					case (opcode_i)
						`LOAD_OP: begin
							case (funct3_i)
								`LB_FUNCT3, `LBU_FUNCT3: begin
									state		<= 4'b0010;
								end
								`LH_FUNCT3, `LHU_FUNCT3, `LW_FUNCT3: begin
									mem_addr_o  <= mem_addr_i + 1;
									state		<= 4'b0010;
								end
								default: ;
							endcase
						end
						`STORE_OP: begin
							case (funct3_i)
								`SB_FUNCT3: begin
									mem_we_o	<= 0;
									mem_done	<= 1'b1;
									mem_addr_o  <= 0;
									state		<= 4'b0000;
								end
								`SH_FUNCT3, `SW_FUNCT3: begin
									mem_data_o  <= wdata_i[15:8];
									mem_addr_o  <= mem_addr_i + 1;
									state		<= 4'b0010;
								end
								default: ;
							endcase
						end
						default: begin
							state	<= 4'b0010;
						end
					endcase
				end
				4'b0010: begin
					case (opcode_i)
						`LOAD_OP: begin
							case (funct3_i)
								`LB_FUNCT3: begin
									mem_data	<= {{24{mem_data_i[7]}}, mem_data_i};
									mem_done	<= 1'b1;
									mem_addr_o  <= 0;
									state		<= 4'b0000;
								end
								`LBU_FUNCT3: begin
									mem_data	<= {24'b0, mem_data_i};
									mem_done	<= 1'b1;
									mem_addr_o  <= 0;
									state		<= 4'b0000;
								end
								`LH_FUNCT3, `LHU_FUNCT3: begin
									data_block1	<= mem_data_i;
									state		<= 4'b0011;
								end
								`LW_FUNCT3: begin
									data_block1	<= mem_data_i;
									mem_addr_o  <= mem_addr_i + 2;
									state		<= 4'b0011;
								end
								default: ;
							endcase
						end
						`STORE_OP: begin
							case (funct3_i)
								`SH_FUNCT3: begin
									mem_we_o	<= 0;
									mem_done	<= 1'b1;
									state		<= 4'b0000;
									mem_addr_o  <= 0;
								end
								`SW_FUNCT3: begin
									mem_data_o  <= wdata_i[23:16];
									mem_addr_o  <= mem_addr_i + 2;
									state		<= 4'b0011;
								end
								default: ;
							endcase
						end
						default: ;
					endcase
				end
				4'b0011: begin
					case (opcode_i)
						`LOAD_OP: begin
							case (funct3_i)
								`LH_FUNCT3: begin
									mem_data	<= {{16{mem_data_i[7]}}, mem_data_i, data_block1};
									mem_done	<= 1'b1;
									state		<= 4'b0000;
									mem_addr_o  <= 0;
								end
								`LHU_FUNCT3: begin
									mem_data	<= {16'b0, mem_data_i, data_block1};
									mem_done	<= 1'b1;
									state		<= 4'b0000;
									mem_addr_o  <= 0;
								end
								`LW_FUNCT3: begin
									data_block2 <= mem_data_i;
									mem_addr_o  <= mem_addr_i + 3;
									state		<= 4'b0100;
								end
								default: ;
							endcase
						end
						`STORE_OP: begin
							if (funct3_i == `SW_FUNCT3) begin
								mem_data_o	 <= wdata_i[31:24];
								mem_addr_o	 <= mem_addr_i + 3;
								state		 <= 4'b0100;
							end
						end
						default: begin
							state			 <= 4'b0100;
						end
					endcase
				end
				4'b0100: begin
					case (opcode_i)
						`LOAD_OP: begin
							case (funct3_i)
								`LW_FUNCT3: begin
									data_block3 <= mem_data_i;
									state	<= 4'b0101;
								end
								default: ;
							endcase
						end
						`STORE_OP: begin
							if (funct3_i == `SW_FUNCT3) begin
								mem_we_o	<= 0;
								mem_done	<= 1'b1;
								mem_addr_o  <= 0;
								state		<= 4'b0000;
							end
						end
						default: begin
							state			<= 4'b0000;
						end
					endcase

				end
				4'b0101: begin
					mem_data				<= {mem_data_i, data_block3, data_block2, data_block1};
					mem_done				<= 1'b1;
					mem_addr_o			  	<= 0;
					state					<= 4'b0000;
				end
				default: begin
				end
			endcase
		end else begin
			mem_done	   					<= 0;
		end
	end

	
	always @ ( * ) begin
		if (rst) begin
			wdata_o			<= 0;
			wd_o			<= `NOPRegAddr;
			wreg_o			<= `WriteDisable;
		end else begin
			wreg_o			<= wreg_i;
			wd_o			<= wd_i;
			if (opcode_i == `LOAD_OP) begin
				wdata_o		<= mem_data;
			end else begin
				wdata_o		<= wdata_i;
			end
		end
	end

endmodule
