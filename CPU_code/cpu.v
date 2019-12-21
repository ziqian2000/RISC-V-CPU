// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "defines.v"

module cpu(
	input  wire				 	clk_in,			// system clock signal
	input  wire				 	rst_in,			// reset signal
	input  wire				 	rdy_in,			// ready signal, pause cpu when low

	input  wire [ 7:0]		  	mem_din,		// data input bus
	output wire [ 7:0]		  	mem_dout,		// data output bus
	output wire [31:0]		  	mem_a,			// address bus (only 17:0 is used)
	output wire				 	mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// if --- if/id

wire[`InstAddrBus]	if_pc;
wire[`InstBus]		if_inst;

assign dbgreg_dout = if_pc;

// if/id --- id

wire[`InstAddrBus] 	id_pc_i;
wire[`InstBus]		id_inst_i;

// id --- id/ex

wire[`OpcodeBus]	id_opcode;
wire[`RegBus]		id_reg1_o;
wire[`RegBus]		id_reg2_o;
wire 				id_wreg_o;
wire[`RegAddrBus]	id_wd_o;
wire[31:0] 			id_imm;
wire[`InstAddrBus] 	id_branch_addr;

// id/ex --- ex

wire[`OpcodeBus]	ex_opcode;
wire[`RegBus]		ex_reg1_i;
wire[`RegBus]		ex_reg2_i;
wire 				ex_wreg_i;
wire[`RegAddrBus]	ex_wd_i;
wire[31:0] 			ex_imm;
wire[`InstAddrBus] 	ex_branch_addr;

// ex --- ex/mem

wire 				ex_wreg_o;
wire[`RegAddrBus]	ex_wd_o;
wire[`RegBus]		ex_wdata_o;
wire[`InstAddrBus] 	ex_mem_addr;
wire[`OpcodeBus] 	ex_mem_opcode;

// ex/mem --- mem

wire 				mem_wreg_i;
wire[`RegAddrBus]	mem_wd_i;
wire[`RegBus]		mem_wdata_i;
wire[`InstAddrBus] 	mem_mem_addr;
wire[`OpcodeBus] 	mem_opcode;

// mem --- mem/wb

wire 				mem_wreg_o;
wire[`RegAddrBus]	mem_wd_o;
wire[`RegBus]		mem_wdata_o;

// mem/wb --- wb

wire 				wb_wreg_i;
wire[`RegAddrBus]	wb_wd_i;
wire[`RegBus]		wb_wdata_i;

// id --- regfile

wire 				reg1_read;
wire 				reg2_read;
wire[`RegBus]		reg1_data;
wire[`RegBus]		reg2_data;
wire[`RegAddrBus]	reg1_addr;
wire[`RegAddrBus]	reg2_addr;

// ex --- if

wire 				branch_enable;
wire[`InstAddrBus] 	branch_addr;

// if, mem --- mem_ctrl
// (1) public
wire[1:0]			if_or_mem_o;
wire[7:0]			cpu_data_o;
// (2) if
wire 				if_request;
wire[31:0]			if_addr;
// (3) mem
wire[1:0] 			mem_request;
wire[31:0] 			mem_addr;
wire[7:0] 			cpu_data_i;

// mem --- ctrl

wire 				mem_busy;

// ctrl --- every stage

wire[`StallBus] 	stall_sign;

// if --- icache

wire[`InstAddrBus] 	ifc_raddr;
wire 				ifc_hit;
wire[31:0] 			ifc_inst;
wire 				ifc_we;
wire[`InstAddrBus] 	ifc_waddr;
wire[31:0]		 	ifc_wdata;

// **************************** instantiation **************************** 

// icache

icache icache0(
	.clk(clk_in), 	.rst(rst_in),  .rdy(rdy_in),
	// read
	.raddr_i(ifc_raddr), .hit_o(ifc_hit), .inst_o(ifc_inst),
	// write
	.we_i(ifc_we), .waddr_i(ifc_waddr), .winst_i(ifc_wdata)
);

// if

if_ if0(
	.clk(clk_in),				.rst(rst_in),	
	// mem_ctrl
	.if_request(if_request), 	.if_addr(if_addr),
	.mem_ctrl_data(cpu_data_o),
	.if_or_mem_i(if_or_mem_o),
	// to if/id
	.pc_o(if_pc),					.if_inst(if_inst),
	// from ID
	.branch_enable_i(branch_enable),
	.branch_addr_i(branch_addr),
	// from ctrl
	.stall_sign(stall_sign),
	// to & from icache
	.raddr_o(ifc_raddr), .hit_i(ifc_hit), 	.inst_i(ifc_inst),
	.we_o(ifc_we), 	.waddr_o(ifc_waddr), .wdata_o(ifc_wdata)
);

// if/id

if_id if_id0(
	.clk(clk_in),		.rst(rst_in),	
	.if_pc(if_pc),		.if_inst(if_inst),
	.id_pc(id_pc_i),	.id_inst(id_inst_i),
	// from ctrl
	.stall_sign(stall_sign)
);

// regfile

regfile regfile0(
	.clk(clk_in),		.rst(rst_in), 		.rdy(rdy_in),
	.we(wb_wreg_i),		.waddr(wb_wd_i),	.wdata(wb_wdata_i),
	.re1(reg1_read),	.raddr1(reg1_addr),	.rdata1(reg1_data),
	.re2(reg2_read),	.raddr2(reg2_addr),	.rdata2(reg2_data)
);

// id

id id0(
	.rst(rst_in), 		.rdy(rdy_in),
	.pc_i(id_pc_i),		.inst_i(id_inst_i),
	// from regfile
	.reg1_data_i(reg1_data),	.reg2_data_i(reg2_data),
	// to regfile
	.reg1_read_o(reg1_read),	.reg2_read_o(reg2_read),
	.reg1_addr_o(reg1_addr),	.reg2_addr_o(reg2_addr),
	// to id/ex
	.opcode_o(id_opcode),
	.reg1_o(id_reg1_o),			.reg2_o(id_reg2_o),
	.wd_o(id_wd_o),				.wreg_o(id_wreg_o),
	.imm(id_imm),
	.branch_addr_o(id_branch_addr),
	// data hazard
	.ex_wreg_i(ex_wreg_o), .ex_wdata_i(ex_wdata_o), .ex_wd_i(ex_wd_o),
	.ex_opcode_i(ex_mem_opcode),

	.ex_mem_wreg_i(mem_wreg_i), .ex_mem_wdata_i(mem_wdata_i), .ex_mem_wd_i(mem_wd_i),
	.ex_mem_opcode_i(mem_opcode),

	.mem_wreg_i(mem_wreg_o), .mem_wdata_i(mem_wdata_o), .mem_wd_i(mem_wd_o),
	.id_stall_request(id_stall_request),
	// from ctrl
	.stall_sign(stall_sign)
);

// id/ex

id_ex id_ex0(
	.clk(clk_in),				.rst(rst_in),
	// from id
	.id_opcode(id_opcode),
	.id_reg1(id_reg1_o),		.id_reg2(id_reg2_o),
	.id_wd(id_wd_o),			.id_wreg(id_wreg_o),
	.id_imm(id_imm),
	.id_branch_addr(id_branch_addr),
	// to ex
	.ex_opcode(ex_opcode),
	.ex_reg1(ex_reg1_i),		.ex_reg2(ex_reg2_i),
	.ex_wd(ex_wd_i),			.ex_wreg(ex_wreg_i),
	.ex_imm(ex_imm),
	.ex_branch_addr(ex_branch_addr),
	// from ctrl
	.stall_sign(stall_sign)
);

// ex

ex ex0(
	.rst(rst_in),
	// from id/ex
	.opcode_i(ex_opcode),
	.reg1_i(ex_reg1_i),			.reg2_i(ex_reg2_i),
	.wd_i(ex_wd_i),				.wreg_i(ex_wreg_i),
	.imm_i(ex_imm),
	.branch_addr_i(ex_branch_addr),
	// to IF
	.branch_enable_o(branch_enable),
	.branch_addr_o(branch_addr),
	// to ex/mem
	.wd_o(ex_wd_o),				.wreg_o(ex_wreg_o),
	.wdata_o(ex_wdata_o),
	.mem_addr(ex_mem_addr), 	.opcode_o(ex_mem_opcode),
	// from ctrl
	.stall_sign(stall_sign)
);

// ex/mem

ex_mem ex_mem0(
	.clk(clk_in),				.rst(rst_in),
	// from ex
	.ex_wd(ex_wd_o),			.ex_wreg(ex_wreg_o),
	.ex_wdata(ex_wdata_o),
	.ex_mem_addr(ex_mem_addr),		.ex_opcode_i(ex_mem_opcode),
	// to mem
	.mem_wd(mem_wd_i),			.mem_wreg(mem_wreg_i),
	.mem_wdata(mem_wdata_i),
	.mem_mem_addr(mem_mem_addr), 	.mem_opcode_o(mem_opcode),
	// from ctrl
	.stall_sign(stall_sign)
);

// mem

mem mem0(
	.clk(clk_in),				.rst(rst_in),
	// from ex/mem
	.wd_i(mem_wd_i),			.wreg_i(mem_wreg_i), 		
	.wdata_i(mem_wdata_i),	
	.mem_addr_i(mem_mem_addr), 	.opcode_i(mem_opcode),
	// to mem/wb
	.wd_o(mem_wd_o),			.wreg_o(mem_wreg_o), 		
	.wdata_o(mem_wdata_o),
	// to mem_ctrl
	.if_or_mem(if_or_mem_o),
	.mem_ctrl_data_i(cpu_data_o), 	
	.mem_ctrl_data_o(cpu_data_i),
	.mem_request(mem_request), 		.mem_addr(mem_addr),
	// to ctrl
	.mem_stall_request(mem_stall_request),
	// from ctrl
	.stall_sign(stall_sign)
);

// mem/wb

mem_wb mem_wb0(
	.clk(clk_in),			.rst(rst_in),
	// from mem
	.mem_wd(mem_wd_o),		.mem_wreg(mem_wreg_o),		.mem_wdata(mem_wdata_o),
	// to wb
	.wb_wd(wb_wd_i),		.wb_wreg(wb_wreg_i),		.wb_wdata(wb_wdata_i),
	// from ctrl
	.stall_sign(stall_sign)
);

mem_ctrl mem_ctrl0(
	.rst(rst_in),  .rdy(rdy_in),
	// IF
	.if_request(if_request),	.if_addr(if_addr),
	// MEM
	.mem_request(mem_request),	.mem_addr(mem_addr),
	// common
	.cpu_data_i(cpu_data_i),	.cpu_data_o(cpu_data_o),
	.if_or_mem_o(if_or_mem_o),
	//RAM
	.ram_data_i(mem_din),		.ram_data_o(mem_dout),
	.ram_addr_o(mem_a),			.ram_rw(mem_wr)
);

ctrl ctrl0(
	.clk(clk_in), 	.rst(rst_in), 	.rdy(rdy_in),
	.id_stall_request(id_stall_request),
	.mem_stall_request(mem_stall_request),
	.branch_stall_request(branch_enable),
	.stall_sign(stall_sign)
);

endmodule

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

	/* The following codes may be used when FPGA testing. */

	// always @(posedge clk_in)
	// begin
	// 	if (rst_in)
	// 		begin
			
	// 		end
	// 	else if (!rdy_in)
	// 		begin
			
	// 		end
	// 	else
	// 		begin
			
	// 		end
	// end