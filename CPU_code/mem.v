module stage_mem(
	input wire				  clk,
	input wire				  rst,

	// read from ex
	input wire[`OpcodeBus]	  opcode_i,
	input wire[`FunctBus3]	  funct3_i,
	input wire[`RegAddrBus]	 wd_i,
	input wire				  wreg_i,
	input wire[`RegBus]		 wdata_i,
	input wire[`InstAddrBus]	mem_addr_i,

	// load mem data
	input wire[`MemDataBus]	 mem_data_i,
	// pass the result
	output reg[`RegAddrBus]	 wd_o,
	output reg				  wreg_o,
	output reg[`RegBus]		 wdata_o,

	// mem ctrl
	output reg				  mem_mem_req_o,
	output reg				  mem_we_o,

	output reg[`InstAddrBus]	mem_addr_o,
	output reg[`MemDataBus]	 mem_data_o
);

reg				 mem_done;
reg[3:0]			state;
reg[`MemDataBus]	data_block1;
reg[`MemDataBus]	data_block2;
reg[`MemDataBus]	data_block3;
reg[`RegBus]		mem_data;

	// for mem stall reg
	always @ ( * ) begin
		if (rst) begin
			mem_mem_req_o		   <= `False_v;
		end else begin
			if (mem_done) begin
				mem_mem_req_o	   <= `False_v;
			end else if (!mem_done) begin
				mem_mem_req_o	   <= ((opcode_i == `LOAD_OP) || (opcode_i == `STORE_OP));
			end
		end
	end

	always @ (posedge clk) begin
		if (rst) begin
			state				 <= 4'b0000;
			mem_we_o			<= `WriteDisable;
			mem_data			<= `ZeroWord;
			mem_addr_o		  <= `ZeroWord;
			data_block1		 <= 8'h00;
			data_block2		 <= 8'h00;
			data_block3		 <= 8'h00;
			mem_data_o		  <= 8'h00;
			mem_done			<= `False_v;
		end else if (mem_mem_req_o) begin
			case (state)
				4'b0000: begin
					mem_addr_o  <= mem_addr_i;
					mem_done	<= `False_v;
					case (opcode_i)
						`LOAD_OP: begin
							mem_we_o	<= `False_v;
							state		 <= 4'b0001;
						end
						`STORE_OP: begin
							mem_we_o	<= `True_v;
							mem_data_o  <= wdata_i[7:0];
							state		 <= 4'b0001;
						end
						default: ;
					endcase
				end
				4'b0001: begin
					case (opcode_i)
						`LOAD_OP: begin
							case (funct3_i)
								`LB_FUNCT3, `LBU_FUNCT3: begin
									state		 <= 4'b0010;
								end
								`LH_FUNCT3, `LHU_FUNCT3, `LW_FUNCT3: begin
									mem_addr_o  <= mem_addr_i + 1;
									state		 <= 4'b0010;
								end
								default: ;
							endcase
						end
						`STORE_OP: begin
							case (funct3_i)
								`SB_FUNCT3: begin
									mem_we_o	<= `False_v;
									mem_done	<= `True_v;
									mem_addr_o  <= `ZeroWord;
									state		 <= 4'b0000;
								end
								`SH_FUNCT3, `SW_FUNCT3: begin
									mem_data_o  <= wdata_i[15:8];
									mem_addr_o  <= mem_addr_i + 1;
									state		 <= 4'b0010;
								end
								default: ;
							endcase
						end
						default: begin
							state				 <= 4'b0010;
						end
					endcase
				end
				4'b0010: begin
					case (opcode_i)
						`LOAD_OP: begin
							case (funct3_i)
								`LB_FUNCT3: begin
									mem_data	<= {{24{mem_data_i[7]}}, mem_data_i};
									mem_done	<= `True_v;
									mem_addr_o  <= `ZeroWord;
									state		 <= 4'b0000;
								end
								`LBU_FUNCT3: begin
									mem_data	<= {24'b0, mem_data_i};
									mem_done	<= `True_v;
									mem_addr_o  <= `ZeroWord;
									state		 <= 4'b0000;
								end
								`LH_FUNCT3, `LHU_FUNCT3: begin
									data_block1 <= mem_data_i;
									state		 <= 4'b0011;
								end
								`LW_FUNCT3: begin
									data_block1 <= mem_data_i;
									mem_addr_o  <= mem_addr_i + 2;
									state		 <= 4'b0011;
								end
								default: ;
							endcase
						end
						`STORE_OP: begin
							case (funct3_i)
								`SH_FUNCT3: begin
									mem_we_o	<= `False_v;
									mem_done	<= `True_v;
									state		 <= 4'b0000;
									mem_addr_o  <= `ZeroWord;
								end
								`SW_FUNCT3: begin
									mem_data_o  <= wdata_i[23:16];
									mem_addr_o  <= mem_addr_i + 2;
									state		 <= 4'b0011;
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
									mem_done	<= `True_v;
									state		 <= 4'b0000;
									mem_addr_o  <= `ZeroWord;
								end
								`LHU_FUNCT3: begin
									mem_data	<= {16'b0, mem_data_i, data_block1};
									mem_done	<= `True_v;
									state		 <= 4'b0000;
									mem_addr_o  <= `ZeroWord;
								end
								`LW_FUNCT3: begin
									data_block2 <= mem_data_i;
									mem_addr_o  <= mem_addr_i + 3;
									state		 <= 4'b0100;
								end
								default: ;
							endcase
						end
						`STORE_OP: begin
							if (funct3_i == `SW_FUNCT3) begin
								mem_data_o		  <= wdata_i[31:24];
								mem_addr_o		  <= mem_addr_i + 3;
								state				 <= 4'b0100;
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
									state		 <= 4'b0101;
								end
								default: ;
							endcase
						end
						`STORE_OP: begin
							if (funct3_i == `SW_FUNCT3) begin
								mem_we_o	<= `False_v;
								mem_done	<= `True_v;
								mem_addr_o  <= `ZeroWord; //
								state		 <= 4'b0000;
							end
						end
						default: begin
							state			 <= 4'b0000;
						end
					endcase

				end
				4'b0101: begin
					mem_data				<= {mem_data_i, data_block3, data_block2, data_block1};
					mem_done				<= `True_v;
					mem_addr_o			  <= `ZeroWord; //
					state					 <= 4'b0000;
				end
				default: begin
				end
			endcase
		end else begin
			mem_done	   <= `False_v;
		end
	end

	// for data flow
	always @ ( * ) begin
		if (rst) begin
			wdata_o			 <= `ZeroWord;
			wd_o				<= `NOPRegAddr;
			wreg_o			  <= `WriteDisable;
		end else begin
			wreg_o			  <= wreg_i;
			wd_o				<= wd_i;
			if (opcode_i == `LOAD_OP) begin
				wdata_o		 <= mem_data;
			end else begin
				wdata_o		 <= wdata_i;
			end
		end
	end

endmodule
