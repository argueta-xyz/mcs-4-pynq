module i4001 #(
  parameter ROM_ID = 4'b0000,
  parameter IO_MASK = 4'b1111
) (
  input  clk,
  input  rst,
  /* verilator lint_off UNUSED */
  input  clken_1,
  input  clken_2,
  /* verilator lint_off UNUSED */
  input  sync,
  input  cl_rom,
  input  cm_rom,
  input  mcs4::char_t dbus_in,
  output mcs4::char_t dbus_out,
  input  mcs4::char_t io_in,
  output mcs4::char_t io_out
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

// DBus input
mcs4::char_t [2:0] in_addr;
mcs4::char_t chip_select;
mcs4::ioram_opa_t opa;
logic opa_received;
always_ff @(posedge clk) begin : proc_in_addr
  if(rst) begin
    in_addr      <= 0;
    opa_received <= 0;
    opa          <= mcs4::WRM;
    chip_select  <= 0;
  end else begin
    case (icyc)
      mcs4::A1 : in_addr[0] <= dbus_in;
      mcs4::A2 : in_addr[1] <= dbus_in;
      mcs4::A3 : in_addr[2] <= dbus_in;
      mcs4::M2 : begin
        opa_received <= cm_rom;
        opa <= dbus_in;
      end
      mcs4::X2 : chip_select <= cm_rom ? dbus_in : chip_select;
      default : /* nothing */;
    endcase
  end
end

// ROM memory
mcs4::byte_t rom_array [mcs4::Bytes_per_rom-1:0];
mcs4::char_t [1:0] rdata;
always_ff @(posedge clk) begin : proc_rdata
  rdata <= rom_array[in_addr[1:0]];
end

// DBus output
logic io_rden;
always_comb begin : proc_dbus_out
  io_rden = opa_received && opa == mcs4::RDR;
  case (icyc)
    mcs4::M1 : dbus_out = rdata[1];
    mcs4::M2 : dbus_out = rdata[0];
    mcs4::X2 : dbus_out = io_rden ? (IO_MASK & io_in) | (~IO_MASK & io_out) : '0;
    default : dbus_out = '0;
  endcase
end

// IO Output
always_ff @(posedge clk) begin : proc_io_out
  if(rst || cl_rom) begin
    io_out <= 0;
  end if(icyc == mcs4::X2 && opa_received && opa == mcs4::WRR) begin
    io_out <= ~IO_MASK & dbus_in;
  end
end

initial begin
  $readmemh("../rom_00.hrom", rom_array);
end

endmodule