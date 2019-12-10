module id(
	input wire				  rst,
	input wire				  rdy,

	// from regfile
	input wire [`RegBus]		reg1_data_i,
	input wire [`RegBus]		reg2_data_i,

	// to regfile
	output reg				  	reg1_read_o,
	output reg				  	reg2_read_o,
	output reg[`RegAddrBus]	 	reg1_addr_o,
	output reg[`RegAddrBus]	 	reg2_addr_o,

	// from IF/ID
	input wire[`InstAddrBus]	pc_i,
	input wire[`InstBus]		inst_i,

	// to ID/EX
	output reg[`OpcodeBus]	  	opcode_o,
	output reg[`FunctBus3]	  	funct3_o,
	output reg[`FunctBus7]	  	funct7_o,
	output reg[`RegBus]		 	reg1_o,
	output reg[`RegBus]		 	reg2_o,
	output reg[`RegBus]		 	ls_offset_o,
	output reg[`RegAddrBus]	 	wd_o,
	output reg				  	wreg_o, 

	// data hazard
	// (ex)
	input wire				  	ex_wreg_i,
	input wire[`RegAddrBus]	 	ex_wd_i,
	input wire[6:0]			 	ex_op_i,
	input wire[`RegBus]		 	ex_wdata_i,
	// (mem)
	input wire				  	mem_wreg_i,
	input wire[`RegAddrBus]	 	mem_wd_i,
	input wire[`RegBus]		 	mem_wdata_i,

	// to IF
	output reg				  	branch_enable_o,
	output reg[`InstAddrBus]	branch_addr_o,
	
	// from ctrl
	input wire[`StallBus]	   	stall_sign
);

wire [`OpcodeBus]   opcode = inst_i[6:0];
wire [`FunctBus3]   funct3 = inst_i[14:12];
wire [`FunctBus7]   funct7 = inst_i[31:25];

reg[`RegBus]		imm;
wire[`InstAddrBus]  pc_plus_4;
wire				reg1_eq_reg2;
wire				reg1_lt_reg2_u;
wire				reg1_gt_reg2_u;
wire[`RegBus]	   	reg1_opp;
wire[`RegBus]	   	reg2_opp;
wire				reg1_lt_reg2;
reg				 	id_stall_req1;
reg				 	id_stall_req2;

assign pc_plus_4 = pc_i + 32'h4;
assign reg1_eq_reg2 = (reg1_o == reg2_o);
assign reg1_lt_reg2_u = reg1_o < reg2_o;
assign reg1_gt_reg2_u = reg1_o > reg2_o;
assign reg1_opp = ~reg1_o + 32'h1;
assign reg2_opp = ~reg2_o + 32'h1;
assign reg1_lt_reg2 = ((reg1_o[31] & !reg2_o[31]) // - +
					|| (reg1_o[31] && reg2_o[31] && (reg1_opp > reg2_opp)) // - -
					|| (!reg1_o[31] && !reg2_o[31] && reg1_lt_reg2_u)); // + +

	always @ (*) begin
		if (rst) begin
			opcode_o		= `NON_OP;
			funct3_o		= `NON_FUNCT3;
			funct7_o		= `NON_FUNCT7;
			wd_o			= `NOPRegAddr;
			wreg_o		  	= `WriteDisable;
			reg1_read_o	 	= 0;
			reg2_read_o	 	= 0;
			reg1_addr_o	 	= `NOPRegAddr;
			reg2_addr_o	 	= `NOPRegAddr;
			imm			 	= 0;
			branch_enable_o = 0;
			branch_addr_o   = 0;
			ls_offset_o	 = 0;
		end else begin
			opcode_o		= `NON_OP;
			funct3_o		= `NON_FUNCT3;
			funct7_o		= `NON_FUNCT7;
			wd_o			= inst_i[11:7];
			wreg_o		  	= `WriteDisable;
			reg1_read_o	 	= 0;
			reg2_read_o	 	= 0;
			reg1_addr_o	 	= inst_i[19:15];
			reg2_addr_o	 	= inst_i[24:20];
			imm			 	= 0;
			branch_enable_o = 0;
			branch_addr_o   = 0;
			ls_offset_o	 	= 0;
			case (opcode)
				`OP_IMM_OP: begin
					wreg_o	  	= `WriteEnable;
					opcode_o	= `OP_IMM_OP;
					reg1_read_o = 1'b1;
					reg2_read_o = 0;
					funct7_o	= `NON_FUNCT7;
					case (funct3)
						`ADDI_FUNCT3: begin
							funct3_o	= `ADDI_FUNCT3;
							imm		 	= {{20{inst_i[31]}}, inst_i[31:20]};
						end
						`SLTI_FUNCT3: begin
							opcode_o	= `OP_OP; // to simplify the ex, SLTI == SLT in ex stage
							funct3_o	= `SLTI_FUNCT3;
							imm		 	= {{20{inst_i[31]}}, inst_i[31:20]};
						end
						`SLTIU_FUNCT3: begin
							opcode_o	= `OP_OP; // to simplify the ex
							funct3_o	= `SLTIU_FUNCT3;
							imm		 	= {{20{inst_i[31]}}, inst_i[31:20]};
						end
						`XORI_FUNCT3: begin
							funct3_o	= `XORI_FUNCT3;
							imm		 	= {{20{inst_i[31]}}, inst_i[31:20]};
						end
						`ORI_FUNCT3: begin
							funct3_o	= `ORI_FUNCT3;
							imm		 	= {{20{inst_i[31]}}, inst_i[31:20]};
						end
						`ANDI_FUNCT3: begin
							funct3_o	= `ANDI_FUNCT3;
							imm		 	= {{20{inst_i[31]}}, inst_i[31:20]};
						end
						`SLLI_FUNCT3: begin
							opcode_o	= `OP_OP; // to simplify ex
							funct3_o	= `SLLI_FUNCT3;
							imm		 	= {27'b0, inst_i[24:20]};
						end
						`SRLI_SRAI_FUNCT3: begin
							opcode_o	= `OP_OP;
							funct3_o	= `SRLI_SRAI_FUNCT3;
							imm		 	= {27'b0, inst_i[24:20]};
							funct7_o	= funct7;
						end
						default: begin
						end
					endcase
				end
				`OP_OP: begin
					wreg_o	  	= `WriteEnable;
					opcode_o	= `OP_OP;
					reg1_read_o = 1'b1;
					reg2_read_o = 1'b1;
					wd_o		= inst_i[11:7];
					funct3_o	= funct3;
					funct7_o	= funct7;
				end
				`JAL_OP: begin
					branch_enable_o = 1'b1;
					branch_addr_o   = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0} + pc_i;
					wreg_o		  	= `WriteEnable;
					opcode_o		= `JAL_OP;
					funct3_o		= `NON_FUNCT3;
					reg1_read_o	 	= 0;
					reg2_read_o	 	= 0;
					imm			 	= pc_plus_4;
					wd_o			= inst_i[11:7];
				end
				`JALR_OP: begin
					branch_enable_o = 1'b1;
					branch_addr_o   = {{20{inst_i[31]}}, inst_i[31:20]} + reg1_o;
					wreg_o		  	= `WriteEnable;
					opcode_o		= `JALR_OP;
					funct3_o		= `NON_FUNCT3;
					reg1_read_o	 	= 1'b1;
					reg2_read_o	 	= 0;
					imm			 	= pc_plus_4;
					wd_o			= inst_i[11:7];
				end
				`BRANCH_OP: begin
					wreg_o		  	= `WriteDisable;
					opcode_o		= `BRANCH_OP;
					funct3_o		= funct3;
					reg1_read_o	 	= 1'b1;
					reg2_read_o	 	= 1'b1;
					imm			 	= 0;
					wd_o			= 0;
					branch_enable_o = 1'b1;
					case (funct3)
						`BEQ_FUNCT3: begin
							if (reg1_o == reg2_o) begin
								branch_addr_o   = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
							end else begin
								branch_addr_o   = pc_plus_4;
							end
						end
						`BNE_FUNCT3: begin
							if (reg1_o != reg2_o) begin
								branch_addr_o   = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
							end else begin
								branch_addr_o   = pc_plus_4;
							end
						end
						`BLT_FUNCT3: begin
							if (reg1_lt_reg2) begin
								branch_addr_o   = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
							end else begin
								branch_addr_o   = pc_plus_4;
							end
						end
						`BLTU_FUNCT3: begin
							if (reg1_lt_reg2_u) begin
								branch_addr_o   = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
							end else begin
								branch_addr_o   = pc_plus_4;
							end
						end
						`BGE_FUNCT3: begin
							if (!reg1_lt_reg2) begin
								branch_addr_o   = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
							end else begin
								branch_addr_o   = pc_plus_4;
							end
						end
						`BGEU_FUNCT3: begin
							if (reg1_gt_reg2_u || reg1_eq_reg2) begin
								branch_addr_o   = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + pc_i;
							end else begin
								branch_addr_o   = pc_plus_4;
							end
						end
						default: begin
						end
					endcase
				end
				`LOAD_OP: begin
					wreg_o	  = `WriteEnable;
					opcode_o	= `LOAD_OP;
					funct3_o	= funct3;
					funct7_o	= `NON_FUNCT7;
					ls_offset_o = {{20{inst_i[31]}}, inst_i[31:20]};
					reg1_read_o = 1'b1;
					reg2_read_o = 0;
					wd_o		= inst_i[11:7];
				end
				`STORE_OP: begin
					wreg_o	  = `WriteDisable;
					opcode_o	= `STORE_OP;
					funct3_o	= funct3;
					funct7_o	= `NON_FUNCT7;
					ls_offset_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
					reg1_read_o = 1'b1;
					reg2_read_o = 1'b1;
					wd_o		= inst_i[11:7];
				end
				`LUI_OP: begin
					wreg_o		  = `WriteEnable;
					opcode_o		= `LUI_OP;
					funct3_o		= `NON_FUNCT3;
					reg1_read_o	 = 0;
					reg2_read_o	 = 0;
					imm			 = {inst_i[31:12], 12'b0};
					wd_o			= inst_i[11:7];
				end
				`AUIPC_OP: begin
					wreg_o		  = `WriteEnable;
					opcode_o		= `AUIPC_OP;
					funct3_o		= `NON_FUNCT3;
					reg1_read_o	 = 0;
					reg2_read_o	 = 0;
					imm			 = {inst_i[31:12], 12'b0} + pc_i;
					wd_o			= inst_i[11:7];
				end
				default: begin
				end
			endcase
		end
	end

	always @ ( * ) begin
		if (rst) begin
			reg1_o = 0;
		end else if (rdy) begin
			if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o) && (ex_wd_i != 0)) begin
				reg1_o  = ex_wdata_i;
			end else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o) && (mem_wd_i != 0)) begin
				reg1_o = mem_wdata_i;
			end else if (reg1_read_o == 1'b1) begin
				reg1_o = reg1_data_i;
			end else if (reg1_read_o == 0) begin
				reg1_o = imm;
			end else begin
				reg1_o = 0;
			end
		end
	end

	always @ ( * ) begin
		if (rst) begin
			reg2_o = 0;
		end else if (rdy) begin
			if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o) && (ex_wd_i != 0)) begin
				reg2_o  = ex_wdata_i;
			end else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o) && (mem_wd_i != 0)) begin
				reg2_o = mem_wdata_i;
			end else if (reg2_read_o == 1'b1) begin
				reg2_o = reg2_data_i;
			end else if (reg2_read_o == 0) begin
				reg2_o = imm;
			end else begin
				reg2_o = 0;
			end
		end
	end

endmodule