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
  output logic  cm_rom,
  output mcs4::char_t cm_ram
);

// Timing generation
logic [3:0] clk_count;
mcs4::instr_cyc_t icyc;
always_ff @(posedge clk) begin : proc_clk_count
  if(rst) begin
    clk_count <= 0;
    icyc <= mcs4::A1;
  end else begin
    clk_count <= clk_count + 4'h1;
    icyc <= mcs4::instr_cyc_t'(clk_count);
  end
  clken_1 <= clk_count % 2 == 0;
  clken_2 <= clk_count % 2 == 1;
end
assign sync = icyc == mcs4::X3;

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

mcs4::raddr_t      ird_reg_addr;
mcs4::rpaddr_t     ird_reg_pair_addr;
mcs4::char_t [1:0] ird_data;
mcs4::char_t [2:0] ird_addr;
mcs4::char_t       ird_cond;
mcs4::opr_code_t   opr_code;
logic is_jin_or_src;

assign is_jin_or_src = instr[0].opa[0];
always_ff @(posedge clk) begin : proc_instr
  if(rst) begin
    instr[0].opr <= mcs4::NOP;
    opr_code     <= mcs4::NOP;
  end else begin
    if(icyc == mcs4::M1) begin
      instr[double_instr].opr <= dbus_in;
      opr_code <= double_instr ? opr_code : dbus_in;
    end else if(icyc == mcs4::M2) begin
      instr[double_instr].opa <= dbus_in;
      ioram_opa_code <= double_instr ? ioram_opa_code : dbus_in;
      accum_opa_code <= double_instr ? accum_opa_code : dbus_in;
    end
  end
end

// ==========================
// M2 CYCLE
// ==========================
// Decode OPR
mcs4::opchar_type_t opa_type, opr_type;
mcs4::ioram_opa_t ioram_opa_code;
mcs4::accum_opa_t accum_opa_code;
logic instr_mod;
mcs4::char_t opa_buf;
always_ff @(posedge clk) begin : proc_decode_opr
  if(icyc == mcs4::M2) begin
    opa_buf <= dbus_in;
    if(!is_instr2) begin
      opr_type <= mcs4::NO_OPA;
      case (opr_code)
        mcs4::NOP       : opa_type <= mcs4::NO_OPA;
        mcs4::JCN       : opa_type <= mcs4::COND;
        mcs4::FIM_SRC   : opa_type <= mcs4::REG_PR;
        mcs4::FIN_JIN   : opa_type <= mcs4::REG_PR;
        mcs4::JUN       : opa_type <= mcs4::ADDR_HI;
        mcs4::JMS       : opa_type <= mcs4::ADDR_HI;
        mcs4::INC       : opa_type <= mcs4::REG;
        mcs4::ISZ       : opa_type <= mcs4::REG;
        mcs4::ADD       : opa_type <= mcs4::REG;
        mcs4::SUB       : opa_type <= mcs4::REG;
        mcs4::LD        : opa_type <= mcs4::REG;
        mcs4::XCH       : opa_type <= mcs4::REG;
        mcs4::BBL       : opa_type <= mcs4::DATA_LO;
        mcs4::LDM       : opa_type <= mcs4::DATA_LO;
        mcs4::IORAM_GRP : opa_type <= mcs4::IORAM;
        mcs4::ACCUM_GRP : opa_type <= mcs4::ACCUM;
        default         : opa_type <= mcs4::NO_OPA;
      endcase
    end else begin
      // Decode DWords based on original OPR
      case (opr_code)
        mcs4::JCN : begin
          opr_type <= mcs4::ADDR_MD;
          opa_type <= mcs4::ADDR_LO;
        end
        mcs4::FIM_SRC : begin
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
          opr_type <= mcs4::NO_OPA;
          opa_type <= mcs4::NO_OPA;
        end
      endcase
    end
  end
end

// ==========================
// X1 CYCLE
// ==========================
always_ff @(posedge clk) begin : proc_decode_opa
   if(icyc == mcs4::X1) begin
    case (opa_type)
      mcs4::REG     : ird_reg_addr <= opa_buf;
      mcs4::REG_PR  : {ird_reg_pair_addr, instr_mod} <= opa_buf;
      mcs4::DATA_LO : ird_data[0] <= opa_buf;
      mcs4::ADDR_HI : ird_addr[2] <= opa_buf;
      mcs4::ADDR_LO : ird_addr[0] <= opa_buf;
      mcs4::COND    : ird_cond <= opa_buf;
      default : ;
    endcase
    case (opr_type)
      mcs4::ADDR_MD : ird_addr[1] <= opa_buf;
      mcs4::DATA_HI : ird_data[1] <= opa_buf;
      default : ;
    endcase
   end
end

always_ff @(posedge clk) begin : proc_ram_ctl
  if(rst) begin
    ram_ctl <= 0;
  end else if(icyc == mcs4::X1) begin
    if(opr_code == mcs4::FIM_SRC && is_jin_or_src) begin
      ram_ctl <= idx_reg[idxr_addr.pair];
    end else begin
      case (ioram_opa_code)
        mcs4::WRM : ram_ctl[0] <= accum;
        mcs4::WMP : ram_ctl[0] <= accum;
        mcs4::WRR : ram_ctl[0] <= accum;
        mcs4::WR0 : ram_ctl[0] <= accum;
        mcs4::WR1 : ram_ctl[0] <= accum;
        mcs4::WR2 : ram_ctl[0] <= accum;
        mcs4::WR3 : ram_ctl[0] <= accum;
        default : ;
      endcase
    end
  end
end

// Determine addr & control for Index Register R/W
assign pair_mode = opa_type == mcs4::REG_PR;
assign idxr_addr = pair_mode? {opa_buf[3:1], 1'b0} : opa_buf;
assign idxr_wen  = (opr_code == mcs4::FIN_JIN ||
                    opr_code == mcs4::INC ||
                    opr_code == mcs4::ISZ ||
                    opr_code == mcs4::XCH);

always_ff @(posedge clk) begin : idx_reg_read
  if(icyc == mcs4::X1) begin
    idxr_rbuf <= idx_reg[idxr_addr.pair];
  end
end

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
always_ff @(posedge clk) begin : proc_stack_ptr
  if(rst) begin
    stack_ptr <= 0;
  end else if(icyc == mcs4::X2) begin
    if(opr_code == mcs4::JMS) begin
      // Stack push
      stack_ptr <= stack_ptr + 1;
      stack[stack_ptr] <= next_pc;
    end else if(opr_code == mcs4::BBL) begin
      // Stack pop
      stack_ptr <= stack_ptr - 1;
    end else begin
      stack[stack_ptr] <= next_pc;
    end
  end
  // stack_ptr <= 2'b11;
  // stack[stack_ptr] <= 12'hFED;//next_pc;

  end_of_page <= pc[mcs4::Addr_width-1-:8] == 8'hFF;
end
assign pc = rst? '0 : stack[stack_ptr];

// Address incrementer
mcs4::char_t [2:0] addr_buff;
mcs4::char_t [2:0] addr_incr;
logic        [2:0] addr_carry;
logic              addr_overflow;
always_ff @(posedge clk) begin : proc_addr_incr
  if(rst) begin
    addr_buff <= 0;
    addr_incr[0] <= 0;
    addr_incr[1] <= 0;
    addr_incr[2] <= 0;
    addr_carry <= '0;
  end else begin
    addr_buff <= icyc == mcs4::X3? next_pc : addr_buff;
    // Spec calls for lookahead adder, whoops
    {addr_carry[0], addr_incr[0]} <= addr_buff[0] + 1;
    {addr_carry[1], addr_incr[1]} <= addr_buff[1] + {3'b0, addr_carry[0]};
    {addr_carry[2], addr_incr[2]} <= addr_buff[2] + {3'b0, addr_carry[1]};
  end
end
assign addr_overflow = addr_carry[2];

// Next address selection
// [DECODER DRIVER & MUX]
logic jump_condition;
always_ff @(posedge clk) begin : proc_jump_condition
  if(rst) begin
    next_pc <= 0;
    jump_condition <= 0;
  end else begin
    if(icyc == mcs4::X2) begin
      if(ird_cond[0]) begin
        jump_condition <= ird_cond[1] && (accum != 0) ||
                          ird_cond[2] && (carry == 0) ||
                          ird_cond[3] && (test == 1);
      end else begin
        jump_condition <= ird_cond[1] && (accum == 0) ||
                          ird_cond[2] && (carry == 1) ||
                          ird_cond[3] && (test == 0);
      end
      case (opr_code)
        mcs4::JCN : next_pc <=  jump_condition? {(end_of_page?
                                                    addr_incr[2] :
                                                    pc[mcs4::Addr_width-1-:4]), ird_addr[1:0]} :
                                                addr_incr;
        mcs4::JUN : next_pc <= ird_addr;
        mcs4::JMS : next_pc <= ird_addr;
        // mcs4::ISZ : next_pc <= TODO;
        default : next_pc <= addr_incr;
      endcase
    end
  end
end

always_ff @(posedge clk) begin : proc_idxr_wbuf
  if(rst) begin
    idxr_wbuf <= 0;
  end else begin
    case (opr_code)
      mcs4::INC : idxr_wbuf <= idxr_rbuf + 1;
      mcs4::ISZ : idxr_wbuf <= idxr_wbuf + 1;
      mcs4::XCH : idxr_wbuf <= {accum, accum};
      default :   ;
    endcase
  end
end

// ==========================
// X3 CYCLE
// ==========================
always_ff @(posedge clk) begin : idx_reg_write
  if(icyc == mcs4::X3) begin
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

// Determine if next icyc series is part 2 of current instr.
always_ff @(posedge clk) begin : proc_double_instr
  if(rst) begin
    double_instr <= 0;
  end else if(icyc == mcs4::X1) begin
    double_instr <= ~double_instr &&
                    (opr_code == mcs4::JCN ||
                     (opr_code == mcs4::FIM_SRC && !is_jin_or_src) ||
                     opr_code == mcs4::JUN ||
                     opr_code == mcs4::JMS ||
                     opr_code == mcs4::ISZ);
  end
end

// Adder
mcs4::char_t adb_buf;
mcs4::char_t accum;
logic        carry;
logic [2:0]  cm_ctl;
logic [2:0]  accum_ctl;
mcs4::char_t cm_ram_buf;
always_ff @(posedge clk) begin : proc_accum
  if(rst) begin
    accum <= 0;
  end else begin
    if(icyc == mcs4::X2) begin
      case (opr_code)
        mcs4::ADD : {carry, accum} <= accum + idxr_rbuf[idxr_addr.single];
        mcs4::SUB : accum <= accum - idxr_rbuf[idxr_addr.single];
        mcs4::LD  : accum <= idxr_rbuf[idxr_addr.single];
        mcs4::XCH : accum <= idxr_rbuf[idxr_addr.single];
        mcs4::BBL : accum <= instr[0].opa;
        mcs4::LDM : accum <= instr[0].opa;
        mcs4::IORAM_GRP : begin
          case (ioram_opa_code)
            mcs4::RDM : accum <= dbus_in;
            mcs4::RD0 : accum <= dbus_in;
            mcs4::RD1 : accum <= dbus_in;
            mcs4::RD2 : accum <= dbus_in;
            mcs4::RD3 : accum <= dbus_in;
            mcs4::RDR : accum <= dbus_in;
            mcs4::ADM : {carry, accum} <= {carry, accum} + dbus_in;
            mcs4::SBM : {carry, accum} <= {carry, accum} - dbus_in;
            default :   ;
          endcase
        end
        mcs4::ACCUM_GRP : begin
          case (accum_opa_code)
            mcs4::CLB : {carry, accum} <= 0;
            mcs4::CLC : carry <= 0;
            mcs4::IAC : {carry, accum} <= accum + 1;
            mcs4::CMC : carry <= ~carry;
            mcs4::CMA : accum <= ~accum;
            mcs4::RAL : {carry, accum} <= {accum, carry};
            mcs4::RAR : {carry, accum} <= {accum[0], carry, accum[3:1]};
            mcs4::TCC : {carry, accum} <= {1'b0, 3'b000, carry};
            mcs4::DAC : {carry, accum} <= accum - 1;
            mcs4::STC : carry <= 1'b1;
            mcs4::DAA : {carry, accum} <= accum + (carry ? 5'd6 : 5'd0);
            mcs4::KBP : begin
              case (accum)
                4'b0000 : accum <= 4'b0000;
                4'b0001 : accum <= 4'b0001;
                4'b0010 : accum <= 4'b0010;
                4'b0100 : accum <= 4'b0011;
                4'b1000 : accum <= 4'b0100;
                default : accum <= 4'b1111;
              endcase
            end
            mcs4::DCL : cm_ram_buf <= {accum[2:0], ~|accum[2:0]};
            default : /* default */;
          endcase
        end
        default : /**/  ;
      endcase
    end
  end
end

// Bus arbitrator
mcs4::char_t bus;
mcs4::char_t [1:0] ram_ctl;
logic io_read;
mcs4::char_t io_read_data;
always_ff @(posedge clk) begin : proc_io_read
  if(rst) begin
    io_read <= 0;
  end else begin
    io_read <= (opr_code == mcs4::FIM_SRC && is_jin_or_src) ||
               (opr_code == mcs4::IORAM_GRP && (
                  ioram_opa_code == mcs4::WRM ||
                  ioram_opa_code == mcs4::WMP ||
                  ioram_opa_code == mcs4::WRR ||
                  ioram_opa_code == mcs4::WR0 ||
                  ioram_opa_code == mcs4::WR1 ||
                  ioram_opa_code == mcs4::WR2 ||
                  ioram_opa_code == mcs4::WR3 ));
  end
end
always_comb begin : bus_arbitration
  case (icyc)
    mcs4::A1 : bus = addr_buff[0];
    mcs4::A2 : bus = addr_buff[1];
    mcs4::A3 : bus = addr_buff[2];
    mcs4::M1 : bus = '0;
    mcs4::M2 : bus = '0;
    mcs4::X1 : bus = '0;
    mcs4::X2 : bus = io_read? ram_ctl[0] : '0;
    mcs4::X3 : bus = is_jin_or_src ? ram_ctl[1] : 0;
    default  : bus = addr_buff[0];
  endcase // icyc
end
assign dbus_out = bus;

// Save dbus_in values
always_ff @(posedge clk) begin : proc_dbus_in
  case (icyc)
    // mcs4::A1 : dbus_out <= addr_buff[0];
    // mcs4::A2 : dbus_out <= addr_buff[1];
    // mcs4::A3 : dbus_out <= addr_buff[2];
    mcs4::M1 : instr[is_instr2].opr <= dbus_in;
    mcs4::M2 : instr[is_instr2].opa <= dbus_in;
    // mcs4::X1 : bus <= '0;
    mcs4::X2 : io_read_data <= dbus_in;
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

always_ff @(posedge clk) begin : proc_cm_ram
  if(rst) begin
    cm_ram <= 0;
    cm_rom <= 0;
  end else begin
    if(icyc == mcs4::A2) begin
      cm_ram <= opr_code == mcs4::IORAM_GRP ? cm_ram_buf : 0;
      cm_rom <= 1;
    end else if(icyc == mcs4::M1 && dbus_in == mcs4::IORAM_GRP) begin
      // Assert for IO operation
      cm_ram <= cm_ram_buf;
      cm_rom <= 1;
    end else if(icyc == mcs4::X1 && opr_code == mcs4::FIM_SRC && is_jin_or_src) begin
      // Assert for SRC
      cm_ram <= cm_ram_buf;
      cm_rom <= 1;
    end else begin
      cm_ram <= 0;
      cm_rom <= 0;
    end
  end
end

// Lint unused
assign cm_rom = '0;
assign is_instr2 = '0; // TODO: IMPLEMENT WHEN DECODING INSTR1

// Index Register




endmodule
/* verilator lint_on UNUSED */
