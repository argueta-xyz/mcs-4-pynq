//  mcs4_pkg.sv
/* verilator lint_off DECLFILENAME */
package mcs4;
/* verilator lint_on DECLFILENAME */
  // Parameters ...........................................................//
  localparam Cycles_per_instruction = 8;

  localparam Char_width = 4;
  localparam Byte_width = 8;
  localparam Addr_width = 12;
  localparam Stack_depth = 3;

  // Register file
  localparam Num_regs            = 16;
  localparam Num_reg_pairs       = Num_regs / 2;
  localparam Reg_pair_addr_width = $clog2(Num_reg_pairs);

  // ROM
  localparam Bytes_per_page   = 256;
  localparam Bytes_per_rom    = 256;
  localparam Pages_per_rom    = Bytes_per_rom / Bytes_per_page;
  localparam Page_index_width = $clog2(Pages_per_rom);

  // RAM
  localparam Num_ram_banks      = 8;
  localparam Ram_chips_per_bank = 4;
  localparam Ram_regs_per_chip  = 4;
  localparam Ram_chars_per_reg  = 16;
  localparam Ram_status_per_reg = 4;

  // Data Types ...........................................................//
  typedef logic [Char_width-1:0] char_t;
  typedef logic [Byte_width-1:0] byte_t;
  typedef logic [Addr_width-1:0] addr_t;

  // Register File
  typedef logic [Reg_pair_addr_width-1:0] rpaddr_t;
  typedef struct packed {
    rpaddr_t pair;
    logic    single;
  } raddr_t;

  // RAM
  typedef logic [$clog2(Num_ram_banks)-1:0]      ram_bank_sel_t;
  typedef logic [$clog2(Ram_chips_per_bank)-1:0] ram_chip_sel_t;
  typedef logic [$clog2(Ram_regs_per_chip)-1:0]  ram_reg_sel_t;
  typedef logic [$clog2(Ram_chars_per_reg)-1:0]  ram_char_sel_t;
  typedef logic [$clog2(Ram_status_per_reg)-1:0] ram_schar_sel_t;

  typedef struct packed {
    ram_bank_sel_t bank;
    ram_chip_sel_t chip;
    ram_reg_sel_t  rreg;
    ram_char_sel_t rchar;
  } ram_addr_t;

  //*************************
  // CPU SPECIFIC
  //*************************
  // Opcodes
  typedef enum logic [3:0] {
    NOP_OP   = 4'd0,
    REG      = 4'd1,
    REG_PR   = 4'd2,
    DATA_HI  = 4'd3,
    DATA_LO  = 4'd4,
    ADDR_HI  = 4'd5,
    ADDR_MD  = 4'd6,
    ADDR_LO  = 4'd7,
    COND     = 4'd8,
    IORAM    = 4'd9,
    ACCUM    = 4'd10
  } opchar_type_t;

  // Machine (OPR's)
  typedef enum logic [3:0] {
    NOP       = 4'b0000,
    JCN       = 4'b0001,
    FIM_SRC   = 4'b0010,
    FIN_JIN   = 4'b0011,
    JUN       = 4'b0100,
    JMS       = 4'b0101,
    INC       = 4'b0110,
    ISZ       = 4'b0111,
    ADD       = 4'b1000,
    SUB       = 4'b1001,
    LD        = 4'b1010,
    XCH       = 4'b1011,
    BBL       = 4'b1100,
    LDM       = 4'b1101,
    IORAM_GRP = 4'b1110,
    ACCUM_GRP = 4'b1111
  } opr_code_t;

  // localparam NOP = 4'b0000; // OPR: 0000 - No Operation
  // localparam JCN = 4'b0001; // OPR: 0000 - Jump Conditional
  // localparam FIM = 4'b0010; // OPR: 0000 - Fetch Immediate
  // localparam SRC = 4'b0010; // OPR: 0001 - Send Register Control
  // localparam FIN = 4'b0011; // OPR: 0000 - Fetch Indirect
  // localparam JIN = 4'b0011; // OPR: 0001 - Jump Indirect
  // localparam JUN = 4'b0100; // OPR: 0000 - Jump Uncoditional
  // localparam JMS = 4'b0101; // OPR: 0000 - Jump to Subroutine
  // localparam INC = 4'b0110; // OPR: 0000 - Increment
  // localparam ISZ = 4'b0111; // OPR: 0000 - Increment and Skip
  // localparam ADD = 4'b1000; // OPR: 0000 - Add
  // localparam SUB = 4'b1001; // OPR: 0000 - Subtract
  // localparam LD  = 4'b1010; // OPR: 0000 - Load
  // localparam XCH = 4'b1011; // OPR: 0000 - Exchange
  // localparam BBL = 4'b1100; // OPR: 0000 - Branch Back and Load
  // localparam LDM = 4'b1101; // OPR: 0000 - Load Immediate
  // localparam IORAM_OPR = 4'b1110;
  // localparam ACCUM_OPR = 4'b1111;

  // I/O and RAM (OPA's)
  typedef enum logic [3:0] {
    WRM = 4'b0000, // Write Main Memory
    WMP = 4'b0001, // Write RAM Port
    WRR = 4'b0010, // Write ROM Port
    WR0 = 4'b0100, // Write Status Char 0
    WR1 = 4'b0101, // Write Status Char 1
    WR2 = 4'b0110, // Write Status Char 2
    WR3 = 4'b0111, // Write Status Char 3
    SBM = 4'b1000, // Subtract Main Memory
    RDM = 4'b1001, // Read Main Memory
    RDR = 4'b1010, // Read ROM Port
    ADM = 4'b1011, // Add Main Memory
    RD0 = 4'b1100, // Read Status Char 0
    RD1 = 4'b1101, // Read Status Char 1
    RD2 = 4'b1110, // Read Status Char 2
    RD3 = 4'b1111  // Read Status Char 3
  } ioram_opa_t;

  // localparam WRM = 4'b0000; // Write Main Memory
  // localparam WMP = 4'b0001; // Write RAM Port
  // localparam WRR = 4'b0010; // Write ROM Port
  // localparam WR0 = 4'b0100; // Write Status Char 0
  // localparam WR1 = 4'b0101; // Write Status Char 1
  // localparam WR2 = 4'b0110; // Write Status Char 2
  // localparam WR3 = 4'b0111; // Write Status Char 3
  // localparam SBM = 4'b1000; // Subtract Main Memory
  // localparam RDM = 4'b1001; // Read Main Memory
  // localparam RDR = 4'b1010; // Read ROM Port
  // localparam ADM = 4'b1011; // Add Main Memory
  // localparam RD0 = 4'b1100; // Read Status Char 0
  // localparam RD1 = 4'b1101; // Read Status Char 1
  // localparam RD2 = 4'b1110; // Read Status Char 2
  // localparam RD3 = 4'b1111; // Read Status Char 3

  // Accumulator (OPA's)
  typedef enum logic [3:0] {
    CLB = 4'b0000, // Clear Both
    CLC = 4'b0001, // Clear Carry
    IAC = 4'b0010, // Increment Accumulator
    CMC = 4'b0011, // Complement Carry
    CMA = 4'b0100, // Complement
    RAL = 4'b0101, // Rotate Left
    RAR = 4'b0110, // Rotate Right
    TCC = 4'b0111, // Transfer Carry and Clear
    DAC = 4'b1000, // Decrement Accumulator
    TCS = 4'b1001, // Transfer Carry Subtract
    STC = 4'b1010, // Set Carry
    DAA = 4'b1011, // Decimal Adjust Accumulator
    KBP = 4'b1100, // Keybord Process
    DCL = 4'b1101  // Designate Command Line
  } accum_opa_t;

  // localparam CLB = 4'b0000; // Clear Both
  // localparam CLC = 4'b0001; // Clear Carry
  // localparam IAC = 4'b0010; // Increment Accumulator
  // localparam CMC = 4'b0011; // Complement Carry
  // localparam CMA = 4'b0100; // Complement
  // localparam RAL = 4'b0101; // Rotate Left
  // localparam RAR = 4'b0110; // Rotate Right
  // localparam TCC = 4'b0111; // Transfer Carry and Clear
  // localparam DAC = 4'b1000; // Decrement Accumulator
  // localparam TCS = 4'b1001; // Transfer Carry Subtract
  // localparam STC = 4'b1010; // Set Carry
  // localparam DAA = 4'b1011; // Decimal Adjust Accumulator
  // localparam KBP = 4'b1100; // Keybord Process
  // localparam DCL = 4'b1101; // Designate Command Line

  typedef struct packed {
    opr_code_t opr;
    char_t opa;
  } instr_t;

  /* Opcode Masks for:
      NOP, WRM, WMP, WRR, WR0, WR1, WR2, WR3,
      SBM, RDM, RDR, ADM, RD0, RD1, RD2, RD3,
      CLB, CLC, IAC, CMC, CMA, RAL, RAR, TCC,
      DAC, TCS, STC, DAA, KBP, DCL */
  localparam Instr_opcode_mask_full = 8'b1111_1111;

  /* Opcode masks for:
      JCN, JUN, JMS, INC, ISZ, ADD, SUB, LD,
      XCH, BBL, LDM */
  localparam Instr_opcode_mask_high = 8'b1111_0000;

  /* Opcode masks for:
      FIM, SRC, FIN, JIN */
  localparam Instr_opcode_mask_low  = 8'b1111_0001;

  // Argument masks
  localparam Instr_arg_mask_condition = 8'b0000_1111;
  localparam Instr_arg_mask_addr_high = 8'b0000_1111;
  localparam Instr_arg_mask_register  = 8'b0000_1111;
  localparam Instr_arg_mask_reg_pair  = 8'b0000_1110;
  localparam Instr_arg_mask_data      = 8'b0000_1111;

  typedef enum logic [2:0] {
    A1 = 3'd0,
    A2 = 3'd1,
    A3 = 3'd2,
    M1 = 3'd3,
    M2 = 3'd4,
    X1 = 3'd5,
    X2 = 3'd6,
    X3 = 3'd7
  } instr_cyc_t;

endpackage : mcs4