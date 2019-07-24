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
  logic cm_rom, cm_ram;
  logic sync;
  mcs4::char_t d_cpu, d_rom;
  i4001 rom (
    .clk(clk),
    .rst(rst),
    .clken_1(clken_1),
    .clken_2(clken_2),
    .sync(sync),
    .cm_rom(cm_rom),
    .dbus_in(d_cpu),
    .dbus_out(d_rom),
    .io_in('0),
    .io_out()
  );

  i4004 cpu (
    .clk(clk),
    .rst(rst),
    .clken_1(clken_1),
    .clken_2(clken_2),
    .test(1'b0),
    .dbus_in(d_rom),
    .dbus_out(d_cpu),
    .sync(sync),
    .cm_rom(cm_rom)
  );

  // TODO: Create ROM with this program:
  // 0000: START:
  // 0000:        LDM $05         D5
  // 0001:        XCH R2          B2
  // 0002: FINISH
  // 0002:        NOP             00
  // Should just load 5 into Reg 2


endmodule