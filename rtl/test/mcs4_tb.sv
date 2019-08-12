`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 1 ns

module mcs4_tb(
  input         clk,
  input         rst
);
`ifdef IVERILOG
  initial begin
    $dumpfile("mcs4.lxt");
    $dumpvars;
  end

  logic clk = 0;
  logic rst = 1;

  initial begin
    #20 rst = 1'b0;
    $display("Done.");
    #200 $finish;
  end

  always #5 clk = ~clk;
`endif // IVERILOG

  logic clken_1, clken_2;
  logic cm_rom;
  mcs4::char_t cm_ram;
  logic sync;
  mcs4::char_t d_cpu, d_rom, d_ram;
  mcs4::char_t d_bus;
  /* verilator lint_off UNUSED */
  mcs4::char_t io_in, io_rom_out, io_ram_out;
  /* verilator lint_on UNUSED */

  assign d_bus = d_cpu | d_rom | d_ram;
  i4001 rom (
    .clk(clk),
    .rst(rst),
    .clken_1(clken_1),
    .clken_2(clken_2),
    .sync(sync),
    .cm_rom(cm_rom),
    .dbus_in(d_bus),
    .dbus_out(d_rom),
    .io_in(io_in),
    .io_out(io_rom_out)
  );

  i4002 #(.RAM_ID(2'b00)) ram (
    .clk(clk),
    .rst(rst),
    .clken_1(clken_1),
    .clken_2(clken_2),
    .sync(sync),
    .cm_ram(cm_ram[0]),
    .dbus_in(d_bus),
    .dbus_out(d_ram),
    .io_out(io_ram_out)
  );

  i4004 cpu (
    .clk(clk),
    .rst(rst),
    .clken_1(clken_1),
    .clken_2(clken_2),
    .test(1'b0),
    .dbus_in(d_bus),
    .dbus_out(d_cpu),
    .sync(sync),
    .cm_rom(cm_rom),
    .cm_ram (cm_ram)
  );

  assign io_in = 0;


endmodule