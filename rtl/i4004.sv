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
    icyc <= mcs4::instr_cyc_t'(clk_count/2);
  end
  clken_1 <= clk_count % 2 == 0;
  clken_2 <= clk_count % 2 == 1;
  sync <= clk_count > 13;
end

// Address Register
mcs4::addr_t stack [3:0];
logic [1:0] pc_ptr;
// TODO: Addr incrementer
mcs4::byte_t addr_buff [2:0];
mcs4::instr_t inst;

// Bus arbitrator
mcs4::byte_t bus;
logic da_out;
mcs4::byte_t ram_ctl;
logic io_read;
always @(posedge clk) begin
  case (icyc)
    mcs4::A1 : bus <= addr_buff[0];
    mcs4::A2 : bus <= addr_buff[1];
    mcs4::A3 : bus <= addr_buff[2];
    mcs4::M1 : bus <= inst.opr;
    mcs4::M2 : bus <= inst.opa;
    mcs4::X1 : bus <= '0;
    mcs4::X2 : bus <= io_read? ram_ctl : dbus_in;
    mcs4::X3 : bus <= ram_ctl;
    default : bus <= addr_buff[0];
  endcase // icyc
end



// Index Register




endmodule