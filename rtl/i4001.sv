module i4001 #(
  parameter ROM_ID = 4'b0000
) (
  input  clk,
  input  rst,
  /* verilator lint_off UNUSED */
  input  clken_1,
  input  clken_2,
  input  sync,
  input  cm_rom,
  /* verilator lint_off UNUSED */
  input  mcs4::char_t dbus_in,
  output mcs4::char_t dbus_out,
  input  mcs4::char_t io_in,
  input  mcs4::char_t io_out
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

mcs4::char_t [2:0] in_addr;
mcs4::char_t chip_select;
always_ff @(posedge clk) begin : proc_in_addr
  if(rst) begin
    in_addr <= 0;
  end else begin
    case (icyc)
      mcs4::A1 : in_addr[0] <= dbus_in;
      mcs4::A2 : in_addr[1] <= dbus_in;
      mcs4::A3 : in_addr[2] <= dbus_in;
      mcs4::X2 : chip_select <= dbus_in;
      default : /* nothing */;
    endcase
  end
end

mcs4::byte_t rom_array [mcs4::Bytes_per_rom-1:0];
mcs4::char_t [1:0] rdata;
logic char_sel, dbus_en;
assign char_sel = icyc == mcs4::M1;
assign dbus_en = (chip_select == ROM_ID) && (icyc == mcs4::M1 || icyc == mcs4::M2);
always_ff @(posedge clk) begin : proc_dbus_out
  rdata <= rom_array[in_addr[1:0]];
end
assign dbus_out = dbus_en ? rdata[char_sel] : '0;

initial begin
  $readmemh("../rom_00.hrom", rom_array);
end

endmodule