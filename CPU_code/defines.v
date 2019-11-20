// **************************** common **************************** 

`define RstEnable 			1'b1
`define RstDisable			1'b0
`define ZeroWord			32'h00000000
`define WriteEnable			1'b1
`define WriteDisable		1'b0
`define ReadEnable			1'b1
`define ReadDisable			1'b0
`define AluOpBus			7:0
`define AluSelBus			2:0
`define InstValid			1'b0
`define InstInvalid			1'b1
`define True_v				1'b1
`define False_v				1'b0
`define ChipEnable			1'b1
`define ChipDisable			1'b0
`define OpcodeBus 			10:0

// **************************** instruction **************************** 

`define EXE_NOP				6'b000000
// AluOp
`define EXE_OR_OP			8'b00100101
`define EXE_NOP_OP			8'b00000000
// AluSel
`define EXE_RES_LOGIC		3'b001
`define EXE_RES_NOP 		3'b000

// **************************** RAM **************************** 

`define InstAddrBus			31:0 
`define InstBus 			31:0
`define MemNum				131071 // 128 KiB
`define MemNumLog2			17

// **************************** regfile **************************** 

`define RegAddrBus 			4:0
`define RegBus 				31:0
`define RegWidth			32
`define RegNum				32
`define RegNumLog2 			5
`define NOPRegAddr			5'b00000