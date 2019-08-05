module i4002 #(
  parameter RAM_ID = 2'b00
) (
  input  clk,
  /* verilator lint_off UNUSED */
  input  clken_1,
  input  clken_2,
  /* verilator lint_off UNUSED */
  input  rst,
  input  sync,
  input  cm_ram,
  input  mcs4::char_t dbus_in,
  output mcs4::char_t dbus_out,
  /* verilator lint_off UNUSED */
  output mcs4::char_t io_out
  /* verilator lint_off UNUSED */
);

// Timing regeneration
logic [3:0] clk_count;
mcs4::instr_cyc_t icyc;
always_ff @(posedge clk) begin : proc_clk_count
  if(sync) begin
    clk_count <= 0;
  end else begin
    clk_count <= clk_count + 4'h1;
  end
end
assign icyc = mcs4::instr_cyc_t'(clk_count);

// Address and command latching
mcs4::char_t [1:0] in_addr;
logic [1:0] chip_index, reg_index;
mcs4::char_t char_index;
mcs4::ioram_opa_t opa;
logic src_received, opa_received;
always_ff @(posedge clk) begin : proc_in_addr
  if(rst) begin
    in_addr <= 0;
    opa_received <= 0;
    src_received <= 0;
  end else begin
    case (icyc)
      mcs4::M2 : begin
        opa_received <= cm_ram;
        opa <= dbus_in;
      end
      mcs4::X2 : begin
        opa_received <= 0;
        src_received <= cm_ram;
        in_addr[0] <= cm_ram ? dbus_in : in_addr[0];
      end
      mcs4::X3 : begin
        src_received <= 0;
        in_addr[1] <= src_received ? dbus_in : in_addr[1];
      end
      default : /* nothing */;
    endcase
  end
end
assign {char_index, chip_index, reg_index} = in_addr;

mcs4::char_t [mcs4::Ram_regs_per_chip-1:0]
             [mcs4::Ram_chars_per_reg-1:0] mem;
mcs4::char_t [mcs4::Ram_regs_per_chip-1:0]
             [mcs4::Ram_status_per_reg-1:0] status;
mcs4::char_t rdata;

logic dbus_en;
assign dbus_en = (chip_index == RAM_ID) && (icyc == mcs4::X2);
always_ff @(posedge clk) begin : proc_mem
  if(icyc == mcs4::X2 && opa_received) begin
    case (opa)
      mcs4::WRM : mem[reg_index][char_index] <= dbus_in;
      mcs4::WMP : io_out <= dbus_in;
      mcs4::WR0 : status[reg_index][0] <= dbus_in;
      mcs4::WR1 : status[reg_index][1] <= dbus_in;
      mcs4::WR2 : status[reg_index][2] <= dbus_in;
      mcs4::WR3 : status[reg_index][3] <= dbus_in;
      mcs4::SBM : rdata <= mem[reg_index][char_index];
      mcs4::RDM : rdata <= mem[reg_index][char_index];
      mcs4::ADM : rdata <= mem[reg_index][char_index];
      mcs4::RD0 : rdata <= status[reg_index][0];
      mcs4::RD1 : rdata <= status[reg_index][1];
      mcs4::RD2 : rdata <= status[reg_index][2];
      mcs4::RD3 : rdata <= status[reg_index][3];
      default : /* default */;
    endcase
  end
end
assign dbus_out = dbus_en ? rdata : '0;

endmodule