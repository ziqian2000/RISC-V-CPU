module id(
	input	wire					rst,
	input  	wire 					rdy,
	input	wire[`InstAddrBus]		pc_i,
	input	wire[`InstBus]			inst_i,
	input 	wire 					taken_i,

	// from regfile
	input	wire[`RegBus] 			reg1_data_i,
	input	wire[`RegBus] 			reg2_data_i,

	// to regfile
	output	reg 					reg1_read_o,
	output	reg 					reg2_read_o,
	output	reg[`RegAddrBus]		reg1_addr_o,
	output	reg[`RegAddrBus]		reg2_addr_o,

	// to id_ex
	output	reg[`OpcodeBus]			opcode_o,
	output	reg[`RegBus]			reg1_o,
	output	reg[`RegBus]			reg2_o,
	output	reg[`RegAddrBus]		wd_o,
	output	reg 					wreg_o,
	output 	reg[31:0] 				imm,
	output 	reg[`InstAddrBus]		branch_addr_o_t,
	output 	reg[`InstAddrBus]		branch_addr_o_n,
	output 	reg 					taken_o,

	// data hazard
	// (0) id/ex
	input	wire 					id_ex_wreg_i,
	input	wire[`RegAddrBus]		id_ex_wd_i,
	input 	wire[`OpcodeBus]		id_ex_opcode_i,
	// (1) ex
	input	wire 					ex_wreg_i,
	input	wire[`RegBus]			ex_wdata_i,
	input	wire[`RegAddrBus]		ex_wd_i,
	input 	wire[`OpcodeBus]		ex_opcode_i,
	// (2) ex/mem
	input	wire 					ex_mem_wreg_i,
	input	wire[`RegBus]			ex_mem_wdata_i,
	input	wire[`RegAddrBus]		ex_mem_wd_i,
	input 	wire[`OpcodeBus]		ex_mem_opcode_i,
	// (3) mem
	input	wire 					mem_wreg_i,
	input	wire[`RegBus]			mem_wdata_i,
	input	wire[`RegAddrBus]		mem_wd_i,
	// (4) mem_wb
	input	wire 					wb_wreg_i,
	input	wire[`RegBus]			wb_wdata_i,
	input	wire[`RegAddrBus]		wb_wd_i,
	// (4) to mem_ctrl
	output 	reg 	 				id_stall_request,

	// from ctrl
	input 	wire[`StallBus] 		stall_sign,

	// to BTB
	output 	reg 					b_we_o,
	output 	reg[`InstAddrBus] 		b_waddr_o,
	output 	reg[31:0] 				b_wtarget_o
);

wire[`InstAddrBus] 	pc_plus_4;

assign pc_plus_4 = pc_i + 31'h4;

// decoding

always @(*) begin
	if(rst == `RstEnable || !rdy) begin
		opcode_o 	= 0;
		wd_o 		= `NOPRegAddr;
		wreg_o		= `WriteDisable;
		reg1_read_o = 1'b0;
		reg2_read_o = 1'b0;
		reg1_addr_o = `NOPRegAddr;
		reg2_addr_o = `NOPRegAddr;
		imm			= 32'h0;
		branch_addr_o_t = 0;
		branch_addr_o_n = 0;
		b_we_o 		= 0;
		b_waddr_o 	= 0;
		b_wtarget_o = 0;
		// id_stall_request = 0;
		
	end else begin

		reg1_read_o = 1'b0;
		reg2_read_o = 1'b0;
		wreg_o		= 1'b0;

		reg1_addr_o = inst_i[19:15];// rs1
		reg2_addr_o = inst_i[24:20];// rs2
		wd_o 		= inst_i[11:7];	// rd

		imm			= `ZeroWord;

		taken_o  	= taken_i;

		case (inst_i[6:0])
			7'b0110011: begin 		//ADD,SUB,SLL,SLT,SLTU,XOR,SRL,SRA,OR,AND
				opcode_o	= {inst_i[30], inst_i[14:12], inst_i[6:0]};
				reg1_read_o	= 1'b1;
				reg2_read_o	= 1'b1;
				wreg_o		= 1'b1;
				branch_addr_o_t = 0;
				branch_addr_o_n = 0;
				b_we_o 		= 0;
			end
			7'b0110111: begin 		//LUI
				opcode_o	= {inst_i[30], inst_i[14:12], inst_i[6:0]};
				reg1_read_o = 0;
				reg2_read_o = 0;
				wreg_o 		= 1'b1;
				imm = {inst_i[31:12], 12'b0};
				branch_addr_o_t = 0;
				branch_addr_o_n = 0;
				b_we_o 		= 0;
			end
			7'b0010111: begin 		//AUIPC
				opcode_o	= {inst_i[30], inst_i[14:12], inst_i[6:0]};
				reg1_read_o = 0;
				reg2_read_o = 0;
				wreg_o 		= 1'b1;
				imm = {inst_i[31:12], 12'b0} + pc_i;
				branch_addr_o_t = 0;
				branch_addr_o_n = 0;
				b_we_o 		= 0;
			end
			7'b0010011: begin 		//ADDI,SLTI,SLTIU,XORI,ORI,ANDI,SLLI,SRLI,SRAI
				opcode_o	= {inst_i[30], inst_i[14:12], inst_i[6:0]};
				reg1_read_o	= 1'b1;
				reg2_read_o	= 1'b0;
				wreg_o		= 1'b1;
				imm			= {{20{inst_i[31]}}, inst_i[31:20]};
				branch_addr_o_t = 0;
				branch_addr_o_n = 0;
				b_we_o 		= 0;
			end
			7'b1101111: begin 		//JAL
				opcode_o	= {inst_i[30], inst_i[14:12], inst_i[6:0]};
				reg1_read_o 	= 0;
				reg2_read_o 	= 0;
				wreg_o			= 1'b1;
				imm 			= pc_plus_4;
				branch_addr_o_t = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0} + pc_i;
				branch_addr_o_n = pc_plus_4;

				// write to BTB
				b_we_o 			= 1'b1;
				b_waddr_o 		= pc_i;
				b_wtarget_o 	= {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0} + pc_i;
			end
			7'b1100111: begin 		//JALR
				opcode_o	= {inst_i[30], inst_i[14:12], inst_i[6:0]};
				reg1_read_o 	= 1'b1;
				reg2_read_o 	= 0;
				wreg_o			= 1'b1;
				imm 			= pc_plus_4;
				branch_addr_o_t = {{20{inst_i[31]}}, inst_i[31:20]} + reg1_o;
				branch_addr_o_n = pc_plus_4;
				b_we_o 			= 0;
			end
			7'b1100011: begin	 	//BEQ,BNE,BLT,BGE,BLTU,BGEU	
				opcode_o	= {inst_i[30], inst_i[14:12], inst_i[6:0]};
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;
				wreg_o		= 0;
				imm   		= {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
				branch_addr_o_t = imm + pc_i;
				branch_addr_o_n = pc_plus_4;
				b_we_o 		= 0;
				// write to BTB
				b_we_o 			= 1'b1;
				b_waddr_o 		= pc_i;
				b_wtarget_o 	= imm + pc_i;
			
			end
			7'b0000011: begin  		//LOAD
				opcode_o		= {inst_i[30], inst_i[14:12], inst_i[6:0]};
				reg1_read_o 	= 1'b1;
				reg2_read_o 	= 0;
				wreg_o 			= 1'b1;
				imm 			= {{21{inst_i[31]}}, inst_i[30:20]};
				branch_addr_o_t = 0;
				branch_addr_o_n = 0;
				b_we_o 		= 0;
			end
			7'b0100011: begin  		//STORE
				opcode_o		= {inst_i[30], inst_i[14:12], inst_i[6:0]};
				reg1_read_o 	= 1'b1;
				reg2_read_o 	= 1'b1;
				wreg_o 			= 0;
				imm 			= {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
				branch_addr_o_t = 0;
				branch_addr_o_n = 0;
				b_we_o 		= 0;
			end
			default: begin 			// something strange
				opcode_o 			= 0;
				reg1_read_o 		= 0;
				reg2_read_o 		= 0;
				wreg_o 				= 0;
				wd_o 				= 0;
				branch_addr_o_t 	= 0;
				branch_addr_o_n 	= 0;
				b_we_o 				= 0;
			end

		endcase
	end
end

// data hazard

always @(*) begin
	if (rst) begin
		id_stall_request = 0;
	// end	else if ((id_ex_wreg_i == 1'b1) && (id_ex_wd_i == reg1_addr_o || id_ex_wd_i == reg2_addr_o)) begin // nearset in ID/EX
	// 	id_stall_request = 1;
	end	else if ((ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o || ex_wd_i == reg2_addr_o)) begin // nearset in EX
		if(ex_opcode_i[6:0] == 7'b0000011) begin
			id_stall_request = 1;
		end else begin
			id_stall_request = 0;
		end
	end else if((ex_mem_wreg_i == 1'b1) && (ex_mem_wd_i == reg1_addr_o || ex_mem_wd_i == reg2_addr_o)) begin // nearest in EX/MEM
		if(ex_mem_opcode_i[6:0] == 7'b0000011) begin
			id_stall_request = 1;
		end else begin
			id_stall_request = 0;
		end
	end else begin
		id_stall_request = 0;
	end
end

// operand 1

always @(*) begin
	if (rst == `RstEnable) begin
		reg1_o = `ZeroWord;
	end else if(rdy) begin
		if(reg1_read_o == 1'b1) begin
			if(reg1_addr_o == 0) begin
				reg1_o = 0;
			end else if((ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o)) begin
				reg1_o = ex_wdata_i;
			end else if((ex_mem_wreg_i == 1'b1) && (ex_mem_wd_i == reg1_addr_o)) begin
				reg1_o = ex_mem_wdata_i;
			end else if((mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o)) begin
				reg1_o = mem_wdata_i;
			end else if((wb_wreg_i == 1'b1) && (wb_wd_i == reg1_addr_o)) begin
				reg1_o = wb_wdata_i;
			end else begin
				reg1_o = reg1_data_i;
			end
		end else if(reg1_read_o == 1'b0) begin
			reg1_o = imm;
		end else begin
			reg1_o = `ZeroWord;
		end
	end
end

// operand 2

always @(*) begin
	if (rst == `RstEnable) begin
		reg2_o = `ZeroWord;
	end else if(rdy) begin
		if(reg2_read_o == 1'b1) begin
			if(reg2_addr_o == 0) begin
				reg2_o = 0;
			end else if((ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o)) begin
				reg2_o = ex_wdata_i;
			end else if((ex_mem_wreg_i == 1'b1) && (ex_mem_wd_i == reg2_addr_o)) begin
				reg2_o = ex_mem_wdata_i;
			end else if((mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o)) begin
				reg2_o = mem_wdata_i;
			end else if((wb_wreg_i == 1'b1) && (wb_wd_i == reg2_addr_o)) begin
				reg2_o = wb_wdata_i;
			end else begin
				reg2_o = reg2_data_i;
			end
		end else if(reg2_read_o == 1'b0) begin
			reg2_o = imm;
		end else begin
			reg2_o = `ZeroWord;
		end
	end
	
end

endmodule