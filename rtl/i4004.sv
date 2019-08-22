module i4004 (
  input         clk,
  input         rst,
  input         test,
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
mcs4::instr_t instr;
logic         double_instr;
logic         is_instr2;

mcs4::raddr_t      ird_reg_addr;
mcs4::char_t [1:0] ird_data;
mcs4::char_t [2:0] ird_addr;
mcs4::char_t       ird_cond;
mcs4::opr_code_t   opr_code;
mcs4::char_t       opr_buf;
logic is_jin_or_src;

assign is_jin_or_src = instr.opa[0];
always_ff @(posedge clk) begin : proc_instr
  if(rst) begin
    instr.opr <= mcs4::NOP;
    opr_code     <= mcs4::NOP;
    opr_buf      <= 0;
  end else begin
    if(icyc == mcs4::M1) begin
      instr.opr <= is_instr2 ? instr.opr : dbus_in;
      opr_code  <= is_instr2 ? opr_code  : dbus_in;
      opr_buf   <= dbus_in;
    end else if(icyc == mcs4::M2) begin
      instr.opa <= is_instr2 ? instr.opa : dbus_in;
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
mcs4::char_t opa_buf;
always_ff @(posedge clk) begin : proc_decode_opr
  if(icyc == mcs4::M2) begin
    opa_buf <= dbus_in;
    if(!is_instr2) begin
      opr_type <= mcs4::NO_OPA;
      ioram_opa_code <= dbus_in;
      accum_opa_code <= dbus_in;
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
        mcs4::FIN_JIN : begin
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
      mcs4::REG_PR  : ird_reg_addr <= opa_buf;
      mcs4::DATA_LO : ird_data[0] <= opa_buf;
      mcs4::ADDR_HI : ird_addr[2] <= opa_buf;
      mcs4::ADDR_LO : ird_addr[0] <= opa_buf;
      mcs4::COND    : ird_cond <= opa_buf;
      default : ;
    endcase
    case (opr_type)
      mcs4::ADDR_MD : ird_addr[1] <= opr_buf;
      mcs4::DATA_HI : ird_data[1] <= opr_buf;
      default : ;
    endcase
   end
end

mcs4::char_t [1:0] ram_ctl;
always_ff @(posedge clk) begin : proc_ram_ctl
  if(rst) begin
    ram_ctl <= 0;
  end else if(icyc == mcs4::X1) begin
    if(opr_code == mcs4::FIM_SRC && is_jin_or_src) begin
      ram_ctl <= idx_reg[idxr_addr.pair];
    end else begin
      case (ioram_opa_code)
        mcs4::WRM : ram_ctl <= {accum, 4'h0};
        mcs4::WMP : ram_ctl <= {accum, 4'h0};
        mcs4::WRR : ram_ctl <= {accum, 4'h0};
        mcs4::WR0 : ram_ctl <= {accum, 4'h0};
        mcs4::WR1 : ram_ctl <= {accum, 4'h0};
        mcs4::WR2 : ram_ctl <= {accum, 4'h0};
        mcs4::WR3 : ram_ctl <= {accum, 4'h0};
        default : ;
      endcase
    end
  end
end

// Determine addr & control for Index Register R/W
logic         prev_pair_mode;
always_ff @(posedge clk) begin : proc_reg_ctl
  if(rst) begin
    prev_pair_mode <= 0;
  end else if(icyc == mcs4::X1 && !is_instr2)begin
    prev_pair_mode <= opa_type == mcs4::REG_PR;
  end
end
assign pair_mode = is_instr2 ? prev_pair_mode : opa_type == mcs4::REG_PR;
assign idxr_addr = is_instr2 ? ird_reg_addr : opa_buf;
assign idxr_wen  = (opr_code == mcs4::FIM_SRC && !is_jin_or_src && is_instr2 ||
                    opr_code == mcs4::FIN_JIN && !is_jin_or_src && is_instr2 ||
                    opr_code == mcs4::INC ||
                    opr_code == mcs4::ISZ && !is_instr2 ||
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
assign stack_push = opr_code == mcs4::JMS && is_instr2;
assign stack_pop  = opr_code == mcs4::BBL;
always_ff @(posedge clk) begin : proc_stack_ptr
  if(rst) begin
    pc <= 0;
    stack_ptr <= 0;
  end else if(icyc == mcs4::X1) begin
    if(stack_push) begin
      stack_ptr <= stack_ptr + 1;
      stack[stack_ptr] <= addr_incr;
    end else if(stack_pop) begin
      stack_ptr <= stack_ptr - 1;
    end else begin
      stack[stack_ptr] <= next_pc;
    end
  end else if(icyc == mcs4::X3) begin
    pc <= next_pc;
  end
  // TODO: Test stack logic

  end_of_page <= pc[mcs4::Addr_width-1-:8] == 8'hFF;
end
// assign pc = rst? '0 : stack[stack_ptr];

// Address incrementer
mcs4::char_t [2:0] addr_buff;
mcs4::char_t [2:0] addr_incr;
logic        [1:0] addr_carry;
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
                    addr_incr[2]  <= addr_buff[2] + {3'b0, addr_carry[1]};
  end
end

// Next address selection
// [DECODER DRIVER & MUX]
logic jump_condition;
always_comb begin : proc_jump_cond
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
always_ff @(posedge clk) begin : proc_next_pc
  if(rst) begin
    next_pc <= 0;
  end else begin
    if(icyc == mcs4::X2) begin
      case (opr_code)
        mcs4::FIN_JIN : next_pc <= is_jin_or_src ? {ird_addr[2] + {3'h0, end_of_page}, idxr_rbuf} :
                                                   is_instr2 ? addr_incr : addr_buff;
        mcs4::JCN : next_pc <=  is_instr2 && jump_condition ?
                                  {(end_of_page ? addr_incr[2] : pc[mcs4::Addr_width-1-:4]),
                                   ird_addr[1:0]} :
                                  addr_incr;
        mcs4::JUN : next_pc <= is_instr2 ? ird_addr : addr_incr;
        mcs4::JMS : next_pc <= is_instr2 ? ird_addr : addr_incr;
        mcs4::BBL : next_pc <= stack[stack_ptr];
        mcs4::ISZ : next_pc <= is_instr2 ? idxr_rbuf[idxr_addr.single] == 0 ? addr_incr : ird_addr :
                                           addr_incr;
        default : next_pc <= addr_incr;
      endcase
    end
  end
end

mcs4::char_t inc_idxr;
assign inc_idxr = idxr_rbuf[idxr_addr.single] + 1;
always_ff @(posedge clk) begin : proc_idxr_wbuf
  if(rst) begin
    idxr_wbuf <= 0;
  end else begin
    case (opr_code)
      mcs4::FIM_SRC : idxr_wbuf <= ird_data;
      mcs4::FIN_JIN : idxr_wbuf <= ird_data;
      mcs4::INC : idxr_wbuf <= {inc_idxr, inc_idxr};
      mcs4::ISZ : idxr_wbuf <= {inc_idxr, inc_idxr};
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
        {idx_reg[idxr_addr.pair][0], idx_reg[idxr_addr.pair][1]} <= idxr_wbuf;
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
    is_instr2 <= 0;
    double_instr <= 0;
  end else if(icyc == mcs4::X1) begin
    double_instr <= ~double_instr &&
                    (opr_code == mcs4::JCN ||
                     (opr_code == mcs4::FIM_SRC && !is_jin_or_src) ||
                     (opr_code == mcs4::FIN_JIN && !is_jin_or_src) ||
                     opr_code == mcs4::JUN ||
                     opr_code == mcs4::JMS ||
                     opr_code == mcs4::ISZ);
  end else if(icyc == mcs4::A3) begin
    is_instr2 <= !is_instr2 & double_instr;
  end
end

// Adder
mcs4::char_t accum;
logic        carry;
mcs4::char_t cm_ram_buf;
always_ff @(posedge clk) begin : proc_accum
  if(rst) begin
    accum <= 0;
    cm_ram_buf <= 1;
  end else begin
    if(icyc == mcs4::X2) begin
      case (opr_code)
        mcs4::ADD : {carry, accum} <= accum + idxr_rbuf[idxr_addr.single];
        mcs4::SUB : {carry, accum} <= accum - idxr_rbuf[idxr_addr.single];
        mcs4::LD  : accum <= idxr_rbuf[idxr_addr.single];
        mcs4::XCH : accum <= idxr_rbuf[idxr_addr.single];
        mcs4::BBL : accum <= instr.opa;
        mcs4::LDM : accum <= instr.opa;
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
            mcs4::TCS : {carry, accum} <= {1'b0, 2'b10, carry, ~carry};
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
            mcs4::DCL : begin
              case (accum[1:0])
                2'b00   : cm_ram_buf <= 4'b0001;
                2'b01   : cm_ram_buf <= 4'b0010;
                2'b10   : cm_ram_buf <= 4'b0100;
                2'b11   : cm_ram_buf <= 4'b1000;
                default : cm_ram_buf <= 4'b0001;
              endcase
            end
            default : /* default */;
          endcase
        end
        default : /* default */  ;
      endcase
    end
  end
end

// Bus arbitrator
mcs4::char_t bus;
logic io_read;
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

// ==========================
// MULTI-CYCLE
// ==========================
logic is_fin;
assign is_fin = opr_code == mcs4::FIN_JIN && !is_jin_or_src && !is_instr2;
always_comb begin : bus_arbitration
  case (icyc)
    mcs4::A1 : bus = is_fin ? idxr_rbuf[0] : addr_buff[0];
    mcs4::A2 : bus = is_fin ? idxr_rbuf[1] : addr_buff[1];
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

endmodule
