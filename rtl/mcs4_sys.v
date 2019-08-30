
`timescale 1 ns / 1 ps

  module mcs4_sys #
  (
    parameter integer NUM_ROMS     = 1,
    parameter integer NUM_RAM_ROWS = 1,
    parameter integer NUM_RAM_COLS = 1,
    parameter [63:0]  ROM_IO_MASK  = 64'hFFFFFFFFFFFFFFFF,


    // Parameters of Axi Slave Bus Interface S_AXI
    parameter integer C_S_AXI_ID_WIDTH     = 1,
    parameter integer C_S_AXI_DATA_WIDTH   = 32,
    parameter integer C_S_AXI_ADDR_WIDTH   = 14,
    parameter integer C_S_AXI_AWUSER_WIDTH = 0,
    parameter integer C_S_AXI_ARUSER_WIDTH = 0,
    parameter integer C_S_AXI_WUSER_WIDTH  = 0,
    parameter integer C_S_AXI_RUSER_WIDTH  = 0,
    parameter integer C_S_AXI_BUSER_WIDTH  = 0
  )
  (
    // Users to add ports here
    output wire [NUM_RAM_COLS*NUM_RAM_ROWS*4-1:0] ram_dout,
    output wire [NUM_ROMS*4-1:0]                  rom_dout,
    input  wire [NUM_ROMS*4-1:0]                  rom_din,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S_AXI
    input  wire                                s_axi_aclk,
    input  wire                                s_axi_aresetn,
    input  wire [C_S_AXI_ID_WIDTH-1 : 0]       s_axi_awid,
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     s_axi_awaddr,
    input  wire [7 : 0]                        s_axi_awlen,
    input  wire [2 : 0]                        s_axi_awsize,
    input  wire [1 : 0]                        s_axi_awburst,
    input  wire                                s_axi_awlock,
    input  wire [3 : 0]                        s_axi_awcache,
    input  wire [2 : 0]                        s_axi_awprot,
    input  wire [3 : 0]                        s_axi_awqos,
    input  wire [3 : 0]                        s_axi_awregion,
    input  wire [C_S_AXI_AWUSER_WIDTH-1 : 0]   s_axi_awuser,
    input  wire                                s_axi_awvalid,
    output wire                                s_axi_awready,
    input  wire [C_S_AXI_DATA_WIDTH-1 : 0]     s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
    input  wire                                s_axi_wlast,
    input  wire [C_S_AXI_WUSER_WIDTH-1 : 0]    s_axi_wuser,
    input  wire                                s_axi_wvalid,
    output wire                                s_axi_wready,
    output wire [C_S_AXI_ID_WIDTH-1 : 0]       s_axi_bid,
    output wire [1 : 0]                        s_axi_bresp,
    output wire [C_S_AXI_BUSER_WIDTH-1 : 0]    s_axi_buser,
    output wire                                s_axi_bvalid,
    input  wire                                s_axi_bready,
    input  wire [C_S_AXI_ID_WIDTH-1 : 0]       s_axi_arid,
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     s_axi_araddr,
    input  wire [7 : 0]                        s_axi_arlen,
    input  wire [2 : 0]                        s_axi_arsize,
    input  wire [1 : 0]                        s_axi_arburst,
    input  wire                                s_axi_arlock,
    input  wire [3 : 0]                        s_axi_arcache,
    input  wire [2 : 0]                        s_axi_arprot,
    input  wire [3 : 0]                        s_axi_arqos,
    input  wire [3 : 0]                        s_axi_arregion,
    input  wire [C_S_AXI_ARUSER_WIDTH-1 : 0]   s_axi_aruser,
    input  wire                                s_axi_arvalid,
    output wire                                s_axi_arready,
    output wire [C_S_AXI_ID_WIDTH-1 : 0]       s_axi_rid,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0]     s_axi_rdata,
    output wire [1 : 0]                        s_axi_rresp,
    output wire                                s_axi_rlast,
    output wire [C_S_AXI_RUSER_WIDTH-1 : 0]    s_axi_ruser,
    output wire                                s_axi_rvalid,
    input  wire                                s_axi_rready
  );

  localparam NUM_RAMS = NUM_RAM_ROWS * NUM_RAM_COLS;

  // ------------------------------------------
  // -- AXI Slave
  // ------------------------------------------
  wire [13:0] dbg_addr;
  wire [7:0]  dbg_wdata;
  wire [7:0]  dbg_rdata;
  wire        dbg_wen;
  wire        dbg_ren;
  mcs4_sys_s_axi # (
    .C_S_AXI_ID_WIDTH    (C_S_AXI_ID_WIDTH),
    .C_S_AXI_DATA_WIDTH  (C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH  (C_S_AXI_ADDR_WIDTH),
    .C_S_AXI_AWUSER_WIDTH(C_S_AXI_AWUSER_WIDTH),
    .C_S_AXI_ARUSER_WIDTH(C_S_AXI_ARUSER_WIDTH),
    .C_S_AXI_WUSER_WIDTH (C_S_AXI_WUSER_WIDTH),
    .C_S_AXI_RUSER_WIDTH (C_S_AXI_RUSER_WIDTH),
    .C_S_AXI_BUSER_WIDTH (C_S_AXI_BUSER_WIDTH)
  ) s_axi (
    .S_AXI_ACLK    (s_axi_aclk),
    .S_AXI_ARESETN (s_axi_aresetn),
    .S_AXI_AWID    (s_axi_awid),
    .S_AXI_AWADDR  (s_axi_awaddr),
    .S_AXI_AWLEN   (s_axi_awlen),
    .S_AXI_AWSIZE  (s_axi_awsize),
    .S_AXI_AWBURST (s_axi_awburst),
    .S_AXI_AWLOCK  (s_axi_awlock),
    .S_AXI_AWCACHE (s_axi_awcache),
    .S_AXI_AWPROT  (s_axi_awprot),
    .S_AXI_AWQOS   (s_axi_awqos),
    .S_AXI_AWREGION(s_axi_awregion),
    .S_AXI_AWUSER  (s_axi_awuser),
    .S_AXI_AWVALID (s_axi_awvalid),
    .S_AXI_AWREADY (s_axi_awready),
    .S_AXI_WDATA   (s_axi_wdata),
    .S_AXI_WSTRB   (s_axi_wstrb),
    .S_AXI_WLAST   (s_axi_wlast),
    .S_AXI_WUSER   (s_axi_wuser),
    .S_AXI_WVALID  (s_axi_wvalid),
    .S_AXI_WREADY  (s_axi_wready),
    .S_AXI_BID     (s_axi_bid),
    .S_AXI_BRESP   (s_axi_bresp),
    .S_AXI_BUSER   (s_axi_buser),
    .S_AXI_BVALID  (s_axi_bvalid),
    .S_AXI_BREADY  (s_axi_bready),
    .S_AXI_ARID    (s_axi_arid),
    .S_AXI_ARADDR  (s_axi_araddr),
    .S_AXI_ARLEN   (s_axi_arlen),
    .S_AXI_ARSIZE  (s_axi_arsize),
    .S_AXI_ARBURST (s_axi_arburst),
    .S_AXI_ARLOCK  (s_axi_arlock),
    .S_AXI_ARCACHE (s_axi_arcache),
    .S_AXI_ARPROT  (s_axi_arprot),
    .S_AXI_ARQOS   (s_axi_arqos),
    .S_AXI_ARREGION(s_axi_arregion),
    .S_AXI_ARUSER  (s_axi_aruser),
    .S_AXI_ARVALID (s_axi_arvalid),
    .S_AXI_ARREADY (s_axi_arready),
    .S_AXI_RID     (s_axi_rid),
    .S_AXI_RDATA   (s_axi_rdata),
    .S_AXI_RRESP   (s_axi_rresp),
    .S_AXI_RLAST   (s_axi_rlast),
    .S_AXI_RUSER   (s_axi_ruser),
    .S_AXI_RVALID  (s_axi_rvalid),
    .S_AXI_RREADY  (s_axi_rready),

    .dbg_addr      (dbg_addr),
    .dbg_wdata     (dbg_wdata),
    .dbg_wen       (dbg_wen),
    .dbg_ren       (dbg_ren),
    .dbg_rdata     (dbg_rdata)
  );

  // ------------------------------------------
  // -- Debug Controller
  // ------------------------------------------
  wire [11:0] dbg_rom_addr;
  wire [7:0]  dbg_rom_wdata;
  wire [7:0]  dbg_rom_rdata;
  wire        dbg_rom_wen;
  wire        dbg_rom_ren;

  wire [11:0] dbg_ram_addr;
  wire [7:0]  dbg_ram_wdata;
  wire [7:0]  dbg_ram_rdata;
  wire        dbg_ram_wen;
  wire        dbg_ram_ren;

  wire        dbg_rom_in_drive;
  wire [63:0] dbg_rom_in;
  wire [63:0] io_romchip_in;
  wire [63:0] io_ramchip_out;
  wire [63:0] io_romchip_out;

  wire cpu_rst;
  wire rom_rst;
  wire ram_rst;

  wire [11:0] pc;
  wire [7:0]  instr;
  wire [63:0] idx_reg;
  dbg_ctl dbg_ctl (
    .clk       (s_axi_aclk),
    .rst       (~s_axi_aresetn),

    // AXI slave connections
    .dbg_addr  (dbg_addr),
    .dbg_wen   (dbg_wen),
    .dbg_ren   (dbg_ren),
    .dbg_wdata (dbg_wdata),
    .dbg_rdata (dbg_rdata),

    // ROM access
    .rom_addr  (dbg_rom_addr),
    .rom_wdata (dbg_rom_wdata),
    .rom_rdata (dbg_rom_rdata),
    .rom_wen   (dbg_rom_wen),
    .rom_ren   (dbg_rom_ren),

    // RAM access
    .ram_addr  (dbg_ram_addr),
    .ram_wdata (dbg_ram_wdata),
    .ram_rdata (dbg_ram_rdata),
    .ram_wen   (dbg_ram_wen),
    .ram_ren   (dbg_ram_ren),

    // IO access
    .io_rom_in_drive(dbg_rom_in_drive),
    .io_rom_in      (dbg_rom_in),
    .io_rom_out     (io_romchip_out),
    .io_ram_out     (io_ramchip_out),

    // Reset Control
    .cpu_rst   (cpu_rst),
    .rom_rst   (rom_rst),
    .ram_rst   (ram_rst),

    // CPU Debug
    .pc        (pc),
    .instr     (instr),
    .idx_reg   (idx_reg)
  );

  // ------------------------------------------
  // -- 4001 ROM
  // ------------------------------------------
  wire       sync;
  wire [3:0] d_bus;
  wire       cl_rom;
  wire       cm_rom;

  wire [3:0]            d_rom;
  wire [NUM_ROMS*4-1:0] d_romchip;
  wire [NUM_ROMS*4-1:0] d_romchip_bus;
  wire [NUM_ROMS*8-1:0] dbg_romchip_rdata;
  wire [NUM_ROMS*8-1:0] dbg_romchip_rdata_bus;
  generate
    for (genvar i = 0; i < NUM_ROMS; i=i+1) begin : ROMS
      i4001 #(
        .ROM_ID(i),
        .IO_MASK(ROM_IO_MASK[i*4+:4]),
        .ROM_FILE("rom_00.hrom")
      ) rom (
        .clk     (s_axi_aclk),
        .rst     (rom_rst),
        .sync    (sync),
        .cl_rom  (cl_rom),
        .cm_rom  (cm_rom),
        .dbus_in (d_bus),
        .dbus_out(d_romchip[i*4+:4]),

        .io_in   (io_romchip_in[i*4+:4]),
        .io_out  (io_romchip_out[i*4+:4]),

        .dbg_addr (dbg_rom_addr),
        .dbg_wdata(dbg_rom_wdata),
        .dbg_rdata(dbg_romchip_rdata[i*8+:8]),
        .dbg_wen  (dbg_rom_wen),
        .dbg_ren  (dbg_rom_ren)
      );
    end
  endgenerate

  genvar i, j, k;
  generate
    for (i = 0; i < mcs4::Char_width; i=i+1) begin : ROM_BUS
      for (j = 0; j < NUM_ROMS; j=j+1) begin : BITWISE_OR
        assign d_romchip_bus[i*NUM_ROMS+j] = d_romchip[i+j*mcs4::Char_width];
      end
      assign d_rom[i] = |d_romchip_bus[i*NUM_ROMS+:NUM_ROMS];
    end
    for (i = 0; i < mcs4::Byte_width; i=i+1) begin : ROM_DBG_RDATA
      for (j = 0; j < NUM_ROMS; j=j+1) begin : BITWISE_OR
        assign dbg_romchip_rdata_bus[i*NUM_ROMS+j] = dbg_romchip_rdata[i+j*mcs4::Byte_width];
      end
      assign dbg_rom_rdata[i] = |dbg_romchip_rdata_bus[i*NUM_ROMS+:NUM_ROMS];
    end
  endgenerate

  assign cl_rom = 0;
  assign io_romchip_in[NUM_ROMS*4-1:0] = dbg_rom_in_drive ? dbg_rom_in[NUM_ROMS*4-1:0] : rom_din;
  assign rom_dout = io_romchip_out[NUM_ROMS*4-1:0];

  // ------------------------------------------
  // -- 4002 RAM
  // ------------------------------------------
  wire [3:0]  cm_ram;
  wire [3:0]  d_ram;
  wire [63:0] d_ramchip;
  wire [63:0] d_ramchip_bus;
  wire [NUM_RAMS*8-1:0] dbg_ramchip_rdata;
  wire [NUM_RAMS*8-1:0] dbg_ramchip_rdata_bus;
  generate
  for (i = 0; i < NUM_RAM_ROWS; i=i+1) begin : RAM_BANK
    for (j = 0; j < NUM_RAM_COLS; j=j+1) begin : RAM_CHIP
      i4002 #(
        .RAM_ID(j)
      ) ram (
        .clk      (s_axi_aclk),
        .rst      (ram_rst),
        .sync     (sync),
        .cm_ram   (cm_ram[i]),
        .dbus_in  (d_bus),
        .dbus_out (d_ramchip[i * NUM_RAM_COLS + j+:4]),

        .io_out   (io_ramchip_out[i * NUM_RAM_COLS + j+:4]),

        .dbg_addr (dbg_ram_addr),
        .dbg_wdata(dbg_ram_wdata),
        .dbg_rdata(dbg_ramchip_rdata[i*8+:8]),
        .dbg_wen  (dbg_ram_wen),
        .dbg_ren  (dbg_ram_ren)
      );
    end
  end
  endgenerate

  generate
    for (i = 0; i < mcs4::Char_width; i=i+1) begin : RAM_BUS
      for (j = 0; j < NUM_RAMS; j=j+1) begin : BITWISE_OR
        assign d_ramchip_bus[i*NUM_RAMS+j] = d_ramchip[i+j*mcs4::Char_width];
      end
      assign d_ram[i] = |d_ramchip_bus[i*NUM_RAMS+:NUM_RAMS];
    end
    for (i = 0; i < mcs4::Byte_width; i=i+1) begin : RAM_DBG_RDATA
      for (j = 0; j < NUM_RAMS; j=j+1) begin : BITWISE_OR
        assign dbg_ramchip_rdata_bus[i*NUM_RAMS+j] = dbg_ramchip_rdata[i+j*mcs4::Byte_width];
      end
      assign dbg_ram_rdata[i] = |dbg_ramchip_rdata_bus[i*NUM_RAMS+:NUM_RAMS];
    end
  endgenerate

  assign ram_dout = io_ramchip_out[NUM_RAMS*4-1:0];

  // ------------------------------------------
  // -- 4004 CPU
  // ------------------------------------------
  wire [3:0] d_cpu;
  i4004 cpu (
    .clk        (s_axi_aclk),
    .rst        (cpu_rst),
    .test       (1'b0),
    .dbus_in    (d_bus),
    .dbus_out   (d_cpu),
    .sync       (sync),
    .cm_rom     (cm_rom),
    .cm_ram     (cm_ram),

    .dbg_pc     (pc),
    .dbg_instr  (instr),
    .dbg_idx_reg(idx_reg)
  );

  assign d_bus = d_cpu | d_rom | d_ram;
  // User logic ends

  endmodule
