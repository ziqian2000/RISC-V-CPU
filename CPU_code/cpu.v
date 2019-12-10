// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "defines.v"
module cpu(
	input  wire				 clk_in,			// system clock signal
	input  wire				 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low

	input  wire [7:0]		   mem_din,		// data input bus
	output wire [7:0]		   mem_dout,		// data output bus
	output wire [31:0]		  mem_a,			// address bus (only 17:0 is used)
	output wire				 mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// link pc_reg to if
wire[`InstAddrBus]	  inst_addr;

// assign  dbgreg_dout = inst_addr;

// link if to if_id
wire[`CntBus8]		  ifid_cnt;
wire[`CntBus8]		  idif_cnt;
wire[`InstAddrBus]	  if_pc_o;
wire[`InstBus]		  if_inst_o;


// link if_id to id
wire[`InstAddrBus]	  id_pc_i;
wire[`InstBus]		  id_inst_i;

// link id to id_ex
wire[`OpcodeBus]		id_opcode_o;
wire[`FunctBus3]		id_funct3_o;
wire[`FunctBus7]		id_funct7_o;
wire[`RegBus]		   id_reg1_o;
wire[`RegBus]		   id_reg2_o;
wire[`RegBus]		   id_ls_offset_o;
wire[`RegAddrBus]	   id_wd_o;
wire					id_wreg_o;

// link id_ex to ex
wire[`OpcodeBus]		ex_opcode_i;
wire[`FunctBus3]		ex_funct3_i;
wire[`FunctBus7]		ex_funct7_i;
wire[`RegBus]		   ex_reg1_i;
wire[`RegBus]		   ex_reg2_i;
wire[`RegBus]		   ex_ls_offset_i;
wire[`RegAddrBus]	   ex_wd_i;
wire					ex_wreg_i;

// link ex to ex_mem
wire[`RegAddrBus]	   ex_wd_o;
wire[`RegBus]		   ex_wdata_o;
wire					ex_wreg_o;
wire[`OpcodeBus]		ex_opcode_o;
wire[`FunctBus3]		ex_funct3_o;
wire[`InstAddrBus]	  ex_mem_addr_o;

// link ex_mem to mem
wire[`RegAddrBus]	   mem_wd_i;
wire[`RegBus]		   mem_wdata_i;
wire					mem_wreg_i;
wire[`OpcodeBus]		mem_opcode_i;
wire[`FunctBus3]		mem_funct3_i;
wire[`InstAddrBus]	  mem_mem_addr_i;

// link mem to mem_wb
wire[`RegAddrBus]	   mem_wd_o;
wire[`RegBus]		   mem_wdata_o;
wire					mem_wreg_o;
wire[`CntBus8]		  memwb_cnt;
wire[`CntBus8]		  wbmem_cnt;

// link mem_wb to reg
wire[`RegAddrBus]	   wb_wd_i;
wire[`RegBus]		   wb_wdata_i;
wire					wb_wreg_i;

// link id to regfile
wire					reg1_read;
wire					reg2_read;
wire[`RegAddrBus]	   reg1_addr;
wire[`RegAddrBus]	   reg2_addr;
wire[`RegBus]		   reg1_data;
wire[`RegBus]		   reg2_data;

// mcu
wire[`InstAddrBus]	  if_mem_addr;
wire[`InstAddrBus]	  mem_mem_addr;
wire[`MemDataBus]	   mem_mem_data_o;
wire					if_write_enable;
wire					mem_write_enable;
wire					mem_busy_sign;

// ctrl signal
wire[`StallBus]		 stall_signal;
wire					if_mem_req;
wire					if_stall_req;
wire					branch_stall_req;
wire					mem_mem_req;
wire					mem_stall_req;

// branch
wire					branch_enable;
wire[`InstAddrBus]	  branch_addr;

// Instruction cache
wire					cache_we;
wire[`InstAddrBus]	  cache_wpc;
wire[`InstBus]		  cache_winst;
wire[`InstAddrBus]	  cache_rpc;
wire					cache_hit;
wire[`InstBus]		  cache_inst;

regfile regfile0(
	.clk(clk_in),
	.rst(rst_in),
	.rdy(rdy_in),
	.we(wb_wreg_i),
	.waddr(wb_wd_i),
	.wdata(wb_wdata_i),
	.re1(reg1_read),
	.re2(reg2_read),
	.raddr1(reg1_addr),
	.rdata1(reg1_data),
	.raddr2(reg2_addr),
	.rdata2(reg2_data)
);

if_ if0(
	.clk(clk_in),
	.rst(rst_in),
	.stall_sign(stall_signal),
	.mem_data_i(mem_din),
	.cache_inst_i(cache_inst),
	.cache_hit_i(cache_hit),
	.if_addr(if_mem_addr),
	.mem_we_o(if_write_enable),
	.cache_waddr_o(cache_wpc),
	.cache_we_o(cache_we),
	.cache_winst_o(cache_winst),
	.cache_raddr_o(cache_rpc),
	.branch_enable_i(branch_enable),
	.branch_addr_i(branch_addr),
	.if_mem_req_o(if_mem_req),
	.branch_stall_req_o(branch_stall_req),
	.pc_o(if_pc_o),
	.if_inst(if_inst_o)
);

if_id if_id0(
	.clk(clk_in),
	.rst(rst_in),
	.if_pc(if_pc_o),
	.if_inst(if_inst_o),
	.id_pc(id_pc_i),
	.id_inst(id_inst_i),
	.stall_sign(stall_signal)
);

id id0(
	.rst(rst_in),
	.rdy(rdy_in),
	.pc_i(id_pc_i),
	.inst_i(id_inst_i),
	.reg1_data_i(reg1_data),
	.reg2_data_i(reg2_data),
	.ex_wreg_i(ex_wreg_o),
	.ex_wd_i(ex_wd_o),
	.ex_op_i(ex_opcode_o),
	.ex_wdata_i(ex_wdata_o),
	.mem_wreg_i(mem_wreg_o),
	.mem_wd_i(mem_wd_o),
	.mem_wdata_i(mem_wdata_o),
	.stall_sign(stall_signal),
	.reg1_read_o(reg1_read),
	.reg2_read_o(reg2_read),
	.reg1_addr_o(reg1_addr),
	.reg2_addr_o(reg2_addr),
	.opcode_o(id_opcode_o),
	.funct3_o(id_funct3_o),
	.funct7_o(id_funct7_o),
	.reg1_o(id_reg1_o),
	.reg2_o(id_reg2_o),
	.ls_offset_o(id_ls_offset_o),
	.wd_o(id_wd_o),
	.wreg_o(id_wreg_o),
	.branch_enable_o(branch_enable),
	.branch_addr_o(branch_addr)
);

id_ex id_ex0(
	.clk(clk_in),
	.rst(rst_in),
	.id_opcode(id_opcode_o),
	.id_funct3(id_funct3_o),
	.id_funct7(id_funct7_o),
	.id_reg1(id_reg1_o),
	.id_reg2(id_reg2_o),
	.id_ls_offset(id_ls_offset_o),
	.id_wd(id_wd_o),
	.id_wreg(id_wreg_o),
	.ex_opcode(ex_opcode_i),
	.ex_funct3(ex_funct3_i),
	.ex_funct7(ex_funct7_i),
	.ex_reg1(ex_reg1_i),
	.ex_reg2(ex_reg2_i),
	.ex_ls_offset(ex_ls_offset_i),
	.ex_wd(ex_wd_i),
	.ex_wreg(ex_wreg_i),
	.stall_sign(stall_signal)
);

ex ex0(
	.rst(rst_in),
	.rdy(rdy_in),
	.opcode_i(ex_opcode_i),
	.funct3_i(ex_funct3_i),
	.funct7_i(ex_funct7_i),
	.reg1_i(ex_reg1_i),
	.reg2_i(ex_reg2_i),
	.ls_offset_i(ex_ls_offset_i),
	.wd_i(ex_wd_i),
	.wreg_i(ex_wreg_i),
	.stall_sign(stall_signal),
	.opcode_o(ex_opcode_o),
	.funct3_o(ex_funct3_o),
	.mem_addr_o(ex_mem_addr_o),
	.wd_o(ex_wd_o),
	.wreg_o(ex_wreg_o),
	.wdata_o(ex_wdata_o)
);

ex_mem ex_mem0(
	.clk(clk_in),
	.rst(rst_in),
	.stall_sign(stall_signal),
	.ex_wd(ex_wd_o),
	.ex_wreg(ex_wreg_o),
	.ex_wdata(ex_wdata_o),
	.ex_opcode(ex_opcode_o),
	.ex_funct3(ex_funct3_o),
	.ex_mem_addr(ex_mem_addr_o),
	.mem_wd(mem_wd_i),
	.mem_wreg(mem_wreg_i),
	.mem_wdata(mem_wdata_i),
	.mem_opcode(mem_opcode_i),
	.mem_funct3(mem_funct3_i),
	.mem_mem_addr(mem_mem_addr_i)
);

mem mem0(
	.clk(clk_in),
	.rst(rst_in),
	.opcode_i(mem_opcode_i),
	.funct3_i(mem_funct3_i),
	.wd_i(mem_wd_i),
	.wreg_i(mem_wreg_i),
	.wdata_i(mem_wdata_i),
	.mem_addr_i(mem_mem_addr_i),
	.mem_data_i(mem_din),
	.wd_o(mem_wd_o),
	.wreg_o(mem_wreg_o),
	.wdata_o(mem_wdata_o),
	.mem_mem_req_o(mem_mem_req),
	.mem_we_o(mem_write_enable),
	.mem_addr_o(mem_mem_addr),
	.mem_data_o(mem_mem_data_o)
);

mem_wb mem_wb0(
	.clk(clk_in),
	.rst(rst_in),
	.mem_wd(mem_wd_o),
	.mem_wreg(mem_wreg_o),
	.mem_wdata(mem_wdata_o),
	.wb_wd(wb_wd_i),
	.wb_wreg(wb_wreg_i),
	.wb_wdata(wb_wdata_i),
	.stall_sign(stall_signal)
);

mcu mcu0(
	.rst(rst_in),
	.rdy(rdy_in),
	.if_request(if_mem_req),
	.mem_request(mem_mem_req),
	.mem_write_enable_i(mem_write_enable),
	.if_mem_addr_i(if_mem_addr),
	.mem_mem_addr_i(mem_mem_addr),
	.mem_data_i(mem_mem_data_o),
	.write_enable_o(mem_wr),
	.mem_addr_o(mem_a),
	.mem_data_o(mem_dout),
	.if_stall_req_o(if_stall_req),
	.mem_stall_req_o(mem_stall_req)
);

ctrl ctrl0(
	.rst(rst_in),
	.rdy(rdy_in),
	.if_stall_req_i(if_stall_req),
	.branch_stall_req_i(branch_stall_req),
	.mem_stall_req_i(mem_stall_req),
	.stall_sign(stall_signal)
);

icache icache0(
	.clk(clk_in),
	.rst(rst_in),
	.rdy(rdy_in),
	.raddr_i(cache_rpc),
	.hit_o(cache_hit),
	.inst_o(cache_inst),
	.we_i(cache_we),
	.waddr_i(cache_wpc),
	.winst_i(cache_winst)
);

endmodule
