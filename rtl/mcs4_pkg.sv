//  mcs4_pkg.sv

package mcs4;

  // Parameters ...........................................................//
  localparam Cycles_per_instruction = 8;

  localparam Char_width = 4;
  localparam Byte_width = 8;
  localparam Addr_width = 12;
  localparam Stack_depth = 3;

  // Register file
  localparam Num_regs            = 16;
  localparam Num_reg_pairs       = Num_regs / 2;
  localparam Reg_addr_width      = $clog2(Num_regs);
  localparam Reg_pair_addr_width = $clog2(Num_reg_pairs);

  // ROM
  localparam Bytes_per_page   = 256;
  localparam Bytes_per_rom    = 2048;
  localparam Pages_per_rom    = Bytes_per_rom / Bytes_per_page;
  localparam Page_index_width = $clog2(Pages_per_rom);

  // RAM
  localparam Num_ram_banks      = 8;
  localparam Ram_chips_per_bank = 4;
  localparam Ram_regs_per_chip  = 4;
  localparam Ram_chars_per_reg  = 16;
  localparam Ram_status_per_reg = 4;

  // Data Types ...........................................................//
  typedef logic [4-1:0] char_t;
  typedef logic [8-1:0] byte_t;
  typedef logic [12-1:0] addr_t;
  // Fuck iVerilog
  // typedef logic [Char_width-1:0] char_t;
  // typedef logic [Byte_width-1:0] byte_t;
  // typedef logic [Addr_width-1:0] addr_t;

  // Register File
  typedef logic [Reg_addr_width-1:0] raddr_t;
  typedef logic [Reg_pair_addr_width-1:0] rpaddr_t;

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

  // Opcodes
  typedef struct packed {
    char_t opr;
    char_t opa;
  } instr_t;

  typedef struct packed {
    char_t op_b;
    char_t op_c;
  } instr2_t;

  // Machine
  localparam NOP = 8'b0000_0000; // No Operation
  localparam JCN = 8'b0001_0000; // Jump Conditional
  localparam FIM = 8'b0010_0000; // Fetch Immediate
  localparam SRC = 8'b0010_0001; // Send Register Control
  localparam FIN = 8'b0011_0000; // Fetch Indirect
  localparam JIN = 8'b0011_0001; // Jump Indirect
  localparam JUN = 8'b0100_0000; // Jump Uncoditional
  localparam JMS = 8'b0101_0000; // Jump to Subroutine
  localparam INC = 8'b0110_0000; // Increment
  localparam ISZ = 8'b0111_0000; // Increment and Skip
  localparam ADD = 8'b1000_0000; // Add
  localparam SUB = 8'b1001_0000; // Subtract
  localparam LD  = 8'b1010_0000; // Load
  localparam XCH = 8'b1011_0000; // Exchange
  localparam BBL = 8'b1100_0000; // Branch Back and Load
  localparam LDM = 8'b1101_0000; // Load Immediate
  // I/O and RAM
  localparam WRM = 8'b1110_0000; // Write Main Memory
  localparam WMP = 8'b1110_0001; // Write RAM Port
  localparam WRR = 8'b1110_0010; // Write ROM Port
  localparam WR0 = 8'b1110_0100; // Write Status Char 0
  localparam WR1 = 8'b1110_0101; // Write Status Char 1
  localparam WR2 = 8'b1110_0110; // Write Status Char 2
  localparam WR3 = 8'b1110_0111; // Write Status Char 3
  localparam SBM = 8'b1110_1000; // Subtract Main Memory
  localparam RDM = 8'b1110_1001; // Read Main Memory
  localparam RDR = 8'b1110_1010; // Read ROM Port
  localparam ADM = 8'b1110_1011; // Add Main Memory
  localparam RD0 = 8'b1110_1100; // Read Status Char 0
  localparam RD1 = 8'b1110_1101; // Read Status Char 1
  localparam RD2 = 8'b1110_1110; // Read Status Char 2
  localparam RD3 = 8'b1110_1111; // Read Status Char 3
  // Accumulator
  localparam CLB = 8'b1111_0000; // Clear Both
  localparam CLC = 8'b1111_0001; // Clear Carry
  localparam IAC = 8'b1111_0010; // Increment Accumulator
  localparam CMC = 8'b1111_0011; // Complement Carry
  localparam CMA = 8'b1111_0100; // Complement
  localparam RAL = 8'b1111_0101; // Rotate Left
  localparam RAR = 8'b1111_0110; // Rotate Right
  localparam TCC = 8'b1111_0111; // Transfer Carry and Clear
  localparam DAC = 8'b1111_1000; // Decrement Accumulator
  localparam TCS = 8'b1111_1001; // Transfer Carry Subtract
  localparam STC = 8'b1111_1010; // Set Carry
  localparam DAA = 8'b1111_1011; // Decimal Adjust Accumulator
  localparam KBP = 8'b1111_1100; // Keybord Process
  localparam DCL = 8'b1111_1101; // Designate Command Line

  /* Opcode Masks for:
      NOP, WRM, WMP, WRR, WR0, WR1, WR2, WR3,
      SBM, RDM, RDR, ADM, RD0, RD1, RD2, RD3,
      CLB, CLC, IAC, CMC, CMA, RAL, RAR, TCC,
      DAC, TCS, STC, DAA, KBP, DCL */
  localparam Inst_opcode_mask_full = 8'b1111_1111;

  /* Opcode masks for:
      JCN, JUN, JMS, INC, ISZ, ADD, SUB, LD,
      XCH, BBL, LDM */
  localparam Inst_opcode_mask_high = 8'b1111_0000;

  /* Opcode masks for:
      FIM, SRC, FIN, JIN */
  localparam Inst_opcode_mask_low  = 8'b1111_0001;

  // Argument masks
  localparam Inst_arg_mask_condition = 8'b0000_1111;
  localparam Inst_arg_mask_addr_high = 8'b0000_1111;
  localparam Inst_arg_mask_register  = 8'b0000_1111;
  localparam Inst_arg_mask_reg_pair  = 8'b0000_1110;
  localparam Inst_arg_mask_data      = 8'b0000_1111;

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