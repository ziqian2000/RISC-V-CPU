// **************************** common **************************** 

`define RstEnable 			1'b1
`define RstDisable			1'b0
`define ZeroWord			32'h00000000
`define WriteEnable			1'b1
`define WriteDisable		1'b0
`define ReadEnable			1'b1
`define ReadDisable			1'b0
`define InstValid			1'b0
`define InstInvalid			1'b1
`define True_v				1'b1
`define False_v				1'b0
`define ChipEnable			1'b1
`define ChipDisable			1'b0
`define OpcodeBus 			10:0

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