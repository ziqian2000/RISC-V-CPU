//Defines of Instructions

// For control
`define RstEnable           1'b1
`define RstDisable          1'b0
`define PauseEnable         1'b0
`define PauseDisable        1'b1
`define ReadEnable          1'b1
`define ReadDisable         1'b0
`define WriteEnable         1'b1
`define WriteDisable        1'b0
`define InstValid           1'b1
`define InstInvalid         1'b0
`define ChipEnable          1'b1
`define ChipDisable         1'b0
`define True_v              1'b1
`define False_v             1'b0

// For InterFace
`define RegAddrBus          4:0
`define RegBus              31:0
`define InstAddrBus         31:0
`define InstBus             31:0
`define MemAddrBus          16:0
`define MemDataBus          7:0
`define OpcodeBus           6:0
`define FunctBus3           2:0
`define FunctBus7           6:0
`define StallBus            6:0
`define CntBus2             1:0
`define CntBus4             2:0
`define CntBus8             3:0

// For Inst opcode
`define NON_OP              7'b0000000 // Nothing
`define OP_IMM_OP           7'b0010011 // ADDI* SLTI* SLTIU* XORI* ORI* ANDI* SLLI SRLI SRAI
`define OP_OP               7'b0110011 // ADD* SUB* SLL/ SLT* SLTU* XOR/ SRL/ SRA/ OR* AND/
`define LUI_OP              7'b0110111 // LUI*
`define AUIPC_OP            7'b0010111 // AUIPC*
`define JAL_OP              7'b1101111 // JAL*
`define JALR_OP             7'b1100111 // JALR/
`define BRANCH_OP           7'b1100011 // BEQ/ BNE/ BLT/ BGE/ BLTU/ BGEU/
`define LOAD_OP             7'b0000011 // LB* LH* LW* LBU* LHU*
`define STORE_OP            7'b0100011 // SB* SH* SW*

// For Inst funct3
`define NON_FUNCT3          3'b000
`define ADDI_FUNCT3         3'b000
`define SLTI_FUNCT3         3'b010
`define SLTIU_FUNCT3        3'b011
`define XORI_FUNCT3         3'b100
`define ORI_FUNCT3          3'b110
`define ANDI_FUNCT3         3'b111
`define SLLI_FUNCT3         3'b001
`define SRLI_SRAI_FUNCT3    3'b101
`define ADD_SUB_FUNCT3      3'b000
`define SLL_FUNCT3          3'b001
`define SLT_FUNCT3          3'b010
`define SLTU_FUNCT3         3'b011
`define XOR_FUNCT3          3'b100
`define SRL_SRA_FUNCT3      3'b101
`define OR_FUNCT3           3'b110
`define AND_FUNCT3          3'b111
`define BEQ_FUNCT3          3'b000
`define BNE_FUNCT3          3'b001
`define BLT_FUNCT3          3'b100
`define BGE_FUNCT3          3'b101
`define BLTU_FUNCT3         3'b110
`define BGEU_FUNCT3         3'b111
`define LB_FUNCT3           3'b000
`define LH_FUNCT3           3'b001
`define LW_FUNCT3           3'b010
`define LBU_FUNCT3          3'b100
`define LHU_FUNCT3          3'b101
`define SB_FUNCT3           3'b000
`define SH_FUNCT3           3'b001
`define SW_FUNCT3           3'b010

// For Inst funct7
`define NON_FUNCT7          7'b0000000 // Nothing
`define ADD_FUNCT7          7'b0000000
`define SUB_FUNCT7          7'b0100000
`define SRL_FUNCT7          7'b0000000
`define SRA_FUNCT7          7'b0100000

// For General
`define RegNum              32
`define RegNumLog2          5
`define BlockNum            128
`define ZeroWord            32'h00000000
`define NOPRegAddr          5'b00000
