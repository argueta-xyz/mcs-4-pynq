/* verilator lint_off UNUSED */
module i4004 (
  input         clk,
  input         rst,
  input         test,
  output logic  clken_1,
  output logic  clken_2,
  input  mcs4::char_t dbus_in,
  output mcs4::char_t dbus_out,
  output logic  sync,
  output        cm_rom,
  output mcs4::char_t cm_ram
);

// Timing generation
logic [3:0] clk_count;
mcs4::instr_cyc_t icyc;
always @(posedge clk) begin
  if(rst) begin
    clk_count <= 0;
    icyc <= mcs4::A1;
  end else begin
    clk_count <= clk_count + 4'h1;
    icyc <= mcs4::instr_cyc_t'(clk_count);
  end
  clken_1 <= clk_count % 2 == 0;
  clken_2 <= clk_count % 2 == 1;
  sync <= clk_count > 13;
end

// Index Register
mcs4::char_t [mcs4::Num_reg_pairs-1:0][1:0] idx_reg;
mcs4::char_t [1:0] idxr_wbuf;
mcs4::char_t [1:0] idxr_rbuf;
mcs4::raddr_t      idxr_addr;
logic pair_mode, idxr_wen;

// ==========================
// M1 CYCLE
// ==========================
// Instruction Register Decode & Control
mcs4::instr_t [1:0] instr;
logic         double_instr;
logic         is_instr2;

mcs4::raddr_t      ird_reg;
mcs4::rpaddr_t     ird_reg_pair;
mcs4::char_t [1:0] ird_data;
mcs4::char_t [2:0] ird_addr;
mcs4::char_t       ird_cond;

always_ff @(posedge clk) begin : proc_instr
  if(rst) begin
    instr[0] <= mcs4::NOP;
  end else begin
    if(icyc == mcs4::M1) begin
      instr[double_instr].opr <= bus;
    end else if(icyc == mcs4::M1) begin
      instr[double_instr].opa <= bus;
    end
  end
end

// ==========================
// M2 CYCLE
// ==========================
// Decode OPR
mcs4::opchar_type_t opa_type, opr_type;
logic instr_mod;
always @(posedge clk) begin : proc_decode_opr
  if(icyc == mcs4::M2) begin
    if(!is_instr2) begin
      case (instr[0].opr)
        mcs4::NOP : opa_type <= mcs4::NOP_OP;
        mcs4::JCN : opa_type <= mcs4::COND;
        mcs4::FIM : opa_type <= mcs4::REG_PR;
        // mcs4::SRC
        mcs4::FIN : opa_type <= mcs4::REG_PR;
        // mcs4::JIN
        mcs4::JUN : opa_type <= mcs4::ADDR_HI;
        mcs4::JMS : opa_type <= mcs4::ADDR_HI;
        mcs4::INC : opa_type <= mcs4::REG;
        mcs4::ISZ : opa_type <= mcs4::REG;
        mcs4::ADD : opa_type <= mcs4::REG;
        mcs4::SUB : opa_type <= mcs4::REG;
        mcs4::LD  : opa_type <= mcs4::REG;
        mcs4::XCH : opa_type <= mcs4::REG;
        mcs4::BBL : opa_type <= mcs4::DATA_LO;
        mcs4::LDM : opa_type <= mcs4::DATA_LO;
        mcs4::IORAM_OPR : opa_type <= mcs4::IORAM;
        mcs4::ACCUM_OPR : opa_type <= mcs4::ACCUM;
        default : opa_type <= mcs4::NOP_OP;
      endcase
    end else begin
      // Decode DWords based on original OPR
      case (instr[0].opr)
        mcs4::JCN : begin
          opr_type <= mcs4::ADDR_MD;
          opa_type <= mcs4::ADDR_LO;
        end
        mcs4::FIM : begin
          opr_type <= mcs4::DATA_HI;
          opa_type <= mcs4::DATA_LO;
        end
        mcs4::JUN : begin
          opr_type <= mcs4::ADDR_MD;
          opa_type <= mcs4::ADDR_LO;
        end
        mcs4::JMS : begin
          opr_type <= mcs4::ADDR_MD;
          opa_type <= mcs4::ADDR_LO;
        end
        mcs4::ISZ : begin
          opr_type <= mcs4::ADDR_MD;
          opa_type <= mcs4::ADDR_LO;
        end
        default : begin
          opr_type <= mcs4::NOP_OP;
          opa_type <= mcs4::NOP_OP;
        end
      endcase
    end
  end
end

// ==========================
// X1 CYCLE
// ==========================
always @(posedge clk) begin : proc_decode_opa
   if(icyc == mcs4::X1) begin
    case (opa_type)
      mcs4::REG     : ird_reg <= bus;
      mcs4::REG_PR  : {ird_reg_pair, instr_mod} <= bus;
      mcs4::DATA_LO : ird_data[0] <= bus;
      mcs4::ADDR_HI : ird_addr[2] <= bus;
      mcs4::ADDR_LO : ird_addr[0] <= bus;
      mcs4::COND    : ird_cond <= bus;
      mcs4::IORAM   : begin
        case (bus)
          default : begin
            /* TODO: Implement IO/RAM instructions */;
          end
        endcase
      end
      mcs4::ACCUM   : begin
        case (bus)
          default : begin
            /* TODO: Implement Accumulate instructions */;
          end
        endcase
      end
      default : begin
        /* default */;
      end
    endcase
    case (opr_type)
      mcs4::ADDR_MD : ird_addr[1] <= bus;
      mcs4::DATA_HI : ird_data[1] <= bus;
      default : ;
    endcase
   end
end

// Determine addr & control for Index Register R/W
assign pair_mode = opa_type == mcs4::REG_PR;
assign idxr_addr = pair_mode? {ird_reg_pair, 1'b0} : ird_reg;
assign idxr_wen  = (instr[0].opr == mcs4::FIN ||
                    instr[0].opr == mcs4::INC ||
                    instr[0].opr == mcs4::ISZ ||
                    instr[0].opr == mcs4::XCH);

// ==========================
// X2 CYCLE
// ==========================
// Address Register
// [ADDRESS REGISTER 4x12b DRAM]
mcs4::addr_t [3:0] stack;
logic        [1:0] stack_ptr;
mcs4::addr_t       pc, next_pc;
logic stack_push, stack_pop;
logic end_of_page;
// Stack logic
always @(posedge clk) begin
  if(rst) begin
    stack_ptr <= 0;
  end else if(icyc == mcs4::X2) begin
    if(instr[0].opr == mcs4::JMS) begin
      // Stack push
      stack_ptr <= stack_ptr + 1;
      stack[stack_ptr] <= next_pc;
    end else if(instr[0].opr == mcs4::BBL) begin
      // Stack pop
      stack_ptr <= stack_ptr - 1;
    end else begin
      stack[stack_ptr] <= next_pc;
    end
  end
  // stack_ptr <= 2'b11;
  // stack[stack_ptr] <= 12'hFED;//next_pc;

  end_of_page <= pc[1:0] == 8'hFF;
end
assign pc = rst? '0 : stack[stack_ptr];

// Address incrementer
mcs4::char_t [2:0] addr_buff;
mcs4::char_t [2:0] addr_incr;
logic        [2:0] addr_carry;
logic              addr_overflow;
always_ff @(posedge clk) begin
  if(rst) begin
    addr_buff <= 0;
    addr_incr[0] <= 0;
    addr_incr[1] <= 0;
    addr_incr[2] <= 0;
    addr_carry <= '0;
  end else begin
    addr_buff <= icyc == mcs4::X1? pc : addr_buff;
    // Spec calls for lookahead adder, whoops
    {addr_carry[0], addr_incr[0]} <= addr_buff[0] + 1;
    {addr_carry[1], addr_incr[1]} <= addr_buff[1] + addr_carry[0];
    {addr_carry[2], addr_incr[2]} <= addr_buff[2] + addr_carry[1];
  end
end
assign addr_overflow = addr_carry[2];

// Next address selection
// [DECODER DRIVER & MUX]
logic jump_condition;
always @(posedge clk) begin
  if(rst) begin
    next_pc <= 0;
    jump_condition <= 0;
  end else begin
    if(icyc == mcs4::X2) begin
      case (instr[0].opr)
        mcs4::JCN : next_pc <=  jump_condition?
                                  {(end_of_page? addr_incr[2] : pc[2]), ird_addr[1:0]} :
                                  addr_incr;
        mcs4::JUN : next_pc <= ird_addr;
        mcs4::JMS : next_pc <= ird_addr;
        // mcs4::ISZ : next_pc <= TODO;
        default : next_pc <= addr_incr;
      endcase
      if(ird_cond[0]) begin
        jump_condition <= ird_cond[1] && (accum != 0) ||
                          ird_cond[2] && (carry == 0) ||
                          ird_cond[3] && (test == 1);
      end else begin
        jump_condition <= ird_cond[1] && (accum == 0) ||
                          ird_cond[2] && (carry == 1) ||
                          ird_cond[3] && (test == 0);
      end
    end
  end
end

always_ff @(posedge clk) begin : proc_idxr_wbuf
  if(rst) begin
    idxr_wbuf <= 0;
  end else begin
    case (instr[0].opr)
      // mcs4::ISZ : idxr_wbuf <= TODO
      default :   ;
    endcase
  end
end

// ==========================
// X3 CYCLE
// ==========================
always @(posedge clk) begin : proc_idx_reg
  if(icyc == mcs4::X1) begin
    idxr_rbuf <= ird_reg[idxr_addr.pair];
  end else if(icyc == mcs4::X3) begin
    if(idxr_wen) begin
      if(pair_mode) begin
        // According to spec:
        //   ODD:  ADDR_LO or DATA_LO
        //   EVEN: ADDR_MD or DATA_HI
        {idx_reg[idxr_addr.pair][1], idx_reg[idxr_addr.pair][0]} <= idxr_wbuf;
      end else begin
        idx_reg[idxr_addr.pair][idxr_addr.single] <= idxr_wbuf[0];
      end
    end else begin
    end
  end
end

// Adder
mcs4::char_t adb_buf;
mcs4::char_t accum;
logic        carry;
logic [2:0]  cm_ctl;
logic [2:0]  accum_ctl;
always_ff @(posedge clk) begin : proc_accum
  if(rst) begin
    accum <= 0;
  end else begin
    if(icyc == mcs4::X2) begin
      case (instr[0].opr)
        // LDM:   accum <= instr[0].opa;
        // ACCUM: {carry, accum} <= accum + adb_buf + carry;
        // LROT:  accum <= accum << 1;
        // RROT:  accum <= accum >> 1;
        default : /**/  ;
      endcase
    end
  end
end

// Bus arbitrator
mcs4::char_t bus;
mcs4::char_t ram_ctl;
logic io_read;
always_comb begin : proc_bus
  case (icyc)
    mcs4::A1 : bus <= addr_buff[0];
    mcs4::A2 : bus <= addr_buff[1];
    mcs4::A3 : bus <= addr_buff[2];
    mcs4::M1 : bus <= dbus_in; //instr.opr;
    mcs4::M2 : bus <= dbus_in; //instr.opa;
    mcs4::X1 : bus <= '0;
    mcs4::X2 : bus <= io_read? ram_ctl : dbus_in;
    mcs4::X3 : bus <= ram_ctl;
    default  : bus <= addr_buff[0];
  endcase // icyc
end

// Save dbus_in values
always @(posedge clk) begin
  case (icyc)
    // mcs4::A1 : dbus_out <= addr_buff[0];
    // mcs4::A2 : dbus_out <= addr_buff[1];
    // mcs4::A3 : dbus_out <= addr_buff[2];
    mcs4::M1 : instr[is_instr2].opr <= dbus_in;
    mcs4::M2 : instr[is_instr2].opa <= dbus_in;
    // mcs4::X1 : bus <= '0;
    // mcs4::X2 : bus <= io_read? ram_ctl : dbus_in;
    // mcs4::X3 : bus <= ram_ctl;
    default : ;
  endcase // icyc

  // if(mcs4::A1) begin
  //   addr_buff[0] <= dbus_in;
  // end
  // if(mcs4::A2) begin
  //   addr_buff[1] <= dbus_in;
  // end
  // if(mcs4::A3) begin
  //   addr_buff[2] <= dbus_in;
  // end
  // if(icyc == mcs4::M1) begin
  //   instr[is_instr2].opr <= dbus_in;
  // end
  // if(icyc == mcs4::M2) begin
  //   instr[is_instr2].opa <= dbus_in;
  // end
end


// Lint unused
assign dbus_out = bus;
assign cm_ram = '0;
assign cm_rom = '0;
assign ram_ctl = '0;
assign io_read = '0;

// Index Register




endmodule
/* verilator lint_on UNUSED */
