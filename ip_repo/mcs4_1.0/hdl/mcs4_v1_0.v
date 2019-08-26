
`timescale 1 ns / 1 ps

  module mcs4_v1_0 #
  (
    // Users to add parameters here
    parameter integer NUM_ROMS = 1,
    parameter integer NUM_RAM_ROWS = 1,
    parameter integer NUM_RAM_COLS = 1,
    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S_AXI
    parameter integer C_S_AXI_ID_WIDTH  = 1,
    parameter integer C_S_AXI_DATA_WIDTH  = 32,
    parameter integer C_S_AXI_ADDR_WIDTH  = 10,
    parameter integer C_S_AXI_AWUSER_WIDTH  = 0,
    parameter integer C_S_AXI_ARUSER_WIDTH  = 0,
    parameter integer C_S_AXI_WUSER_WIDTH = 0,
    parameter integer C_S_AXI_RUSER_WIDTH = 0,
    parameter integer C_S_AXI_BUSER_WIDTH = 0
  )
  (
    // Users to add ports here
    output wire [NUM_RAM_COLS*NUM_RAM_ROWS*4-1:0] ram_dout,
    output wire [NUM_ROMS*4-1:0] rom_dout,
    input  wire [NUM_ROMS*4-1:0] rom_din,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S_AXI
    input wire  s_axi_aclk,
    input wire  s_axi_aresetn,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_awid,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
    input wire [7 : 0] s_axi_awlen,
    input wire [2 : 0] s_axi_awsize,
    input wire [1 : 0] s_axi_awburst,
    input wire  s_axi_awlock,
    input wire [3 : 0] s_axi_awcache,
    input wire [2 : 0] s_axi_awprot,
    input wire [3 : 0] s_axi_awqos,
    input wire [3 : 0] s_axi_awregion,
    input wire [C_S_AXI_AWUSER_WIDTH-1 : 0] s_axi_awuser,
    input wire  s_axi_awvalid,
    output wire  s_axi_awready,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
    input wire  s_axi_wlast,
    input wire [C_S_AXI_WUSER_WIDTH-1 : 0] s_axi_wuser,
    input wire  s_axi_wvalid,
    output wire  s_axi_wready,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_bid,
    output wire [1 : 0] s_axi_bresp,
    output wire [C_S_AXI_BUSER_WIDTH-1 : 0] s_axi_buser,
    output wire  s_axi_bvalid,
    input wire  s_axi_bready,
    input wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_arid,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
    input wire [7 : 0] s_axi_arlen,
    input wire [2 : 0] s_axi_arsize,
    input wire [1 : 0] s_axi_arburst,
    input wire  s_axi_arlock,
    input wire [3 : 0] s_axi_arcache,
    input wire [2 : 0] s_axi_arprot,
    input wire [3 : 0] s_axi_arqos,
    input wire [3 : 0] s_axi_arregion,
    input wire [C_S_AXI_ARUSER_WIDTH-1 : 0] s_axi_aruser,
    input wire  s_axi_arvalid,
    output wire  s_axi_arready,
    output wire [C_S_AXI_ID_WIDTH-1 : 0] s_axi_rid,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
    output wire [1 : 0] s_axi_rresp,
    output wire  s_axi_rlast,
    output wire [C_S_AXI_RUSER_WIDTH-1 : 0] s_axi_ruser,
    output wire  s_axi_rvalid,
    input wire  s_axi_rready
  );
// Instantiation of Axi Bus Interface S_AXI
  wire [11:0] dbg_addr;
  wire [3:0]  dbg_wdata;
  wire        dbg_wen;
  mcs4_v1_0_S_AXI # (
    .C_S_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
    .C_S_AXI_AWUSER_WIDTH(C_S_AXI_AWUSER_WIDTH),
    .C_S_AXI_ARUSER_WIDTH(C_S_AXI_ARUSER_WIDTH),
    .C_S_AXI_WUSER_WIDTH(C_S_AXI_WUSER_WIDTH),
    .C_S_AXI_RUSER_WIDTH(C_S_AXI_RUSER_WIDTH),
    .C_S_AXI_BUSER_WIDTH(C_S_AXI_BUSER_WIDTH)
  ) mcs4_v1_0_S_AXI_inst (
    .S_AXI_ACLK(s_axi_aclk),
    .S_AXI_ARESETN(s_axi_aresetn),
    .S_AXI_AWID(s_axi_awid),
    .S_AXI_AWADDR(s_axi_awaddr),
    .S_AXI_AWLEN(s_axi_awlen),
    .S_AXI_AWSIZE(s_axi_awsize),
    .S_AXI_AWBURST(s_axi_awburst),
    .S_AXI_AWLOCK(s_axi_awlock),
    .S_AXI_AWCACHE(s_axi_awcache),
    .S_AXI_AWPROT(s_axi_awprot),
    .S_AXI_AWQOS(s_axi_awqos),
    .S_AXI_AWREGION(s_axi_awregion),
    .S_AXI_AWUSER(s_axi_awuser),
    .S_AXI_AWVALID(s_axi_awvalid),
    .S_AXI_AWREADY(s_axi_awready),
    .S_AXI_WDATA(s_axi_wdata),
    .S_AXI_WSTRB(s_axi_wstrb),
    .S_AXI_WLAST(s_axi_wlast),
    .S_AXI_WUSER(s_axi_wuser),
    .S_AXI_WVALID(s_axi_wvalid),
    .S_AXI_WREADY(s_axi_wready),
    .S_AXI_BID(s_axi_bid),
    .S_AXI_BRESP(s_axi_bresp),
    .S_AXI_BUSER(s_axi_buser),
    .S_AXI_BVALID(s_axi_bvalid),
    .S_AXI_BREADY(s_axi_bready),
    .S_AXI_ARID(s_axi_arid),
    .S_AXI_ARADDR(s_axi_araddr),
    .S_AXI_ARLEN(s_axi_arlen),
    .S_AXI_ARSIZE(s_axi_arsize),
    .S_AXI_ARBURST(s_axi_arburst),
    .S_AXI_ARLOCK(s_axi_arlock),
    .S_AXI_ARCACHE(s_axi_arcache),
    .S_AXI_ARPROT(s_axi_arprot),
    .S_AXI_ARQOS(s_axi_arqos),
    .S_AXI_ARREGION(s_axi_arregion),
    .S_AXI_ARUSER(s_axi_aruser),
    .S_AXI_ARVALID(s_axi_arvalid),
    .S_AXI_ARREADY(s_axi_arready),
    .S_AXI_RID(s_axi_rid),
    .S_AXI_RDATA(s_axi_rdata),
    .S_AXI_RRESP(s_axi_rresp),
    .S_AXI_RLAST(s_axi_rlast),
    .S_AXI_RUSER(s_axi_ruser),
    .S_AXI_RVALID(s_axi_rvalid),
    .S_AXI_RREADY(s_axi_rready),

    .dbg_addr      (dbg_addr),
    .dbg_wdata     (dbg_wdata),
    .dbg_wen       (dbg_wen)
  );

  // Add user logic here
  logic cm_rom, cl_rom;
  mcs4::char_t cm_ram;
  logic sync;
  mcs4::char_t [NUM_RAM_COLS*NUM_RAM_ROWS-1:0] d_ramchip;
  mcs4::char_t [NUM_RAM_COLS*NUM_RAM_ROWS-1:0] d_ramchip_bus;
  mcs4::char_t [NUM_RAM_COLS*NUM_RAM_ROWS-1:0] io_ramchip_out;
  mcs4::char_t [NUM_ROMS-1:0] d_romchip;
  mcs4::char_t [NUM_ROMS-1:0] d_romchip_bus;
  mcs4::char_t d_cpu, d_ram, d_rom;

  mcs4::char_t d_bus;

  assign cl_rom = 0;
  assign d_ram = d_ramchip_bus[NUM_RAM_COLS * NUM_RAM_ROWS-1];
  assign d_bus = d_cpu | d_rom | d_ram;
  assign ram_dout = io_ramchip_out;
  generate
    for (genvar i = 0; i < NUM_ROMS; i++) begin : ROMS
      i4001 #(
        .ROM_ID(i),
        .IO_MASK(4'b1111),
        .ROM_FILE("rom_00.hrom")
      ) rom_0 (
        .clk(clk),
        .rst(rst),
        .sync(sync),
        .cl_rom(cl_rom),
        .cm_rom(cm_rom),
        .dbus_in(d_bus),
        .dbus_out(d_rom[i]),
        .io_in(rom_din[i]),
        .io_out(rom_dout[i]),

        .dbg_addr(dbg_addr),
        .dbg_wdata(dbg_wdata),
        .dbg_wen(dbg_wen)
      );
    end
  endgenerate

  always_comb begin : proc_drom_or
    d_romchip_bus[0] = d_romchip;
    for (int i = 1; i < NUM_ROMS; i++) begin : ROM_BUS
      d_romchip_bus[i] = d_romchip[i] | d_romchip_bus[i-1];
    end
  end

  generate
  for (genvar i = 0; i < NUM_RAM_ROWS; i++) begin : RAM_BANK
    for (genvar j = 0; j < NUM_RAM_COLS; j++) begin : RAM_CHIP
      int k = i * NUM_RAM_COLS + j;
      i4002 #(
        .RAM_ID(j)
      ) ram (
        .clk(clk),
        .rst(rst),
        .sync(sync),
        .cm_ram(cm_ram[i]),
        .dbus_in(d_bus),
        .dbus_out(d_ramchip[k]),
        .io_out(io_ramchip_out[k])
      );
    end
  end
  endgenerate

  always_comb begin : proc_dram_or
    d_ramchip_bus[0] = d_ramchip[0];
    for (int i = 1; i < NUM_RAM_COLS * NUM_RAM_ROWS; i++) begin : RAM_BUS
      d_ramchip_bus[i] = d_ramchip[i] | d_ramchip_bus[i-1];
    end
  end

  i4004 cpu (
    .clk(clk),
    .rst(rst),
    .test(1'b0),
    .dbus_in(d_bus),
    .dbus_out(d_cpu),
    .sync(sync),
    .cm_rom(cm_rom),
    .cm_ram (cm_ram)
  );
  // User logic ends

  endmodule
