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


  i4004 cpu (
    .clk(clk),
    .rst(rst),
    .test(1'b0),
    .dbus_in(4'b0000)
  );


endmodule