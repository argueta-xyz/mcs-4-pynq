module mcs4_sys_tb (
  input clk,
  input rst,
  input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     s_axi_awaddr,
  input  wire [7 : 0]                        s_axi_awlen,
  input  wire                                s_axi_awvalid,
  output wire                                s_axi_awready,
  input  wire [2 : 0]                        s_axi_awsize,
  input  wire [1 : 0]                        s_axi_awburst,
  input  wire                                s_axi_awlock,
  input  wire [3 : 0]                        s_axi_awcache,
  input  wire [2 : 0]                        s_axi_awprot,
  input  wire [3 : 0]                        s_axi_awqos,
  input  wire [C_S_AXI_DATA_WIDTH-1 : 0]     s_axi_wdata,
  input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
  input  wire                                s_axi_wlast,
  input  wire                                s_axi_wvalid,
  output wire                                s_axi_wready,
  output wire [C_S_AXI_ID_WIDTH-1 : 0]       s_axi_bid,
  output wire [1 : 0]                        s_axi_bresp,
  output wire [C_S_AXI_BUSER_WIDTH-1 : 0]    s_axi_buser,
  output wire                                s_axi_bvalid,
  input  wire                                s_axi_bready,
  input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     s_axi_araddr,
  input  wire [7 : 0]                        s_axi_arlen,
  input  wire                                s_axi_arvalid,
  output wire                                s_axi_arready,
  output wire [C_S_AXI_DATA_WIDTH-1 : 0]     s_axi_rdata,
  output wire [1 : 0]                        s_axi_rresp,
  output wire                                s_axi_rlast,
  output wire                                s_axi_rvalid,
  input  wire                                s_axi_rready
);

localparam integer NUM_ROMS     = 16;
localparam integer NUM_RAM_ROWS = 4;
localparam integer NUM_RAM_COLS = 4;
localparam [63:0]  ROM_IO_MASK  = 64'hFFFFFFFFFFFFFFFF;

localparam integer C_S_AXI_ID_WIDTH     = 1;
localparam integer C_S_AXI_DATA_WIDTH   = 32;
localparam integer C_S_AXI_ADDR_WIDTH   = 14;
localparam integer C_S_AXI_AWUSER_WIDTH = 0;
localparam integer C_S_AXI_ARUSER_WIDTH = 0;
localparam integer C_S_AXI_WUSER_WIDTH  = 0;
localparam integer C_S_AXI_RUSER_WIDTH  = 0;
localparam integer C_S_AXI_BUSER_WIDTH  = 0;

/* verilator lint_save */
/* verilator lint_off LITENDIAN */
/* verilator lint_off UNUSED */
logic [NUM_RAM_COLS*NUM_RAM_ROWS*4-1:0] ram_dout;
logic [NUM_ROMS*4-1:0]                  rom_dout;
logic [NUM_ROMS*4-1:0]                  rom_din;

logic                                   s_axi_aclk;
logic                                   s_axi_aresetn;
logic [C_S_AXI_ID_WIDTH-1 : 0]          s_axi_awid;
logic [C_S_AXI_ADDR_WIDTH-1 : 0]        s_axi_awaddr;
logic [7 : 0]                           s_axi_awlen;
logic [2 : 0]                           s_axi_awsize;
logic [1 : 0]                           s_axi_awburst;
logic                                   s_axi_awlock;
logic [3 : 0]                           s_axi_awcache;
logic [2 : 0]                           s_axi_awprot;
logic [3 : 0]                           s_axi_awqos;
logic [3 : 0]                           s_axi_awregion;
logic [C_S_AXI_AWUSER_WIDTH-1 : 0]      s_axi_awuser;
logic                                   s_axi_awvalid;
logic                                   s_axi_awready;
logic [C_S_AXI_DATA_WIDTH-1 : 0]        s_axi_wdata;
logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0]    s_axi_wstrb;
logic                                   s_axi_wlast;
logic [C_S_AXI_WUSER_WIDTH-1 : 0]       s_axi_wuser;
logic                                   s_axi_wvalid;
logic                                   s_axi_wready;
logic [C_S_AXI_ID_WIDTH-1 : 0]          s_axi_bid;
logic [1 : 0]                           s_axi_bresp;
logic [C_S_AXI_BUSER_WIDTH-1 : 0]       s_axi_buser;
logic                                   s_axi_bvalid;
logic                                   s_axi_bready;
logic [C_S_AXI_ID_WIDTH-1 : 0]          s_axi_arid;
logic [C_S_AXI_ADDR_WIDTH-1 : 0]        s_axi_araddr;
logic [7 : 0]                           s_axi_arlen;
logic [2 : 0]                           s_axi_arsize;
logic [1 : 0]                           s_axi_arburst;
logic                                   s_axi_arlock;
logic [3 : 0]                           s_axi_arcache;
logic [2 : 0]                           s_axi_arprot;
logic [3 : 0]                           s_axi_arqos;
logic [3 : 0]                           s_axi_arregion;
logic [C_S_AXI_ARUSER_WIDTH-1 : 0]      s_axi_aruser;
logic                                   s_axi_arvalid;
logic                                   s_axi_arready;
logic [C_S_AXI_ID_WIDTH-1 : 0]          s_axi_rid;
logic [C_S_AXI_DATA_WIDTH-1 : 0]        s_axi_rdata;
logic [1 : 0]                           s_axi_rresp;
logic                                   s_axi_rlast;
logic [C_S_AXI_RUSER_WIDTH-1 : 0]       s_axi_ruser;
logic                                   s_axi_rvalid;
logic                                   s_axi_rready;
/* verilator lint_restore */

assign s_axi_aclk = clk;
assign s_axi_aresetn = ~rst;

mcs4_sys #(
  .NUM_ROMS     (NUM_ROMS),
  .NUM_RAM_ROWS (NUM_RAM_ROWS),
  .NUM_RAM_COLS (NUM_RAM_COLS),
  .ROM_IO_MASK  (ROM_IO_MASK)
) sys (
  .ram_dout       (ram_dout),
  .rom_dout       (rom_dout),
  .rom_din        (rom_din),

  .s_axi_aclk     (s_axi_aclk),
  .s_axi_aresetn  (s_axi_aresetn),
  .s_axi_awid     (s_axi_awid),
  .s_axi_awaddr   (s_axi_awaddr),
  .s_axi_awlen    (s_axi_awlen),
  .s_axi_awsize   (s_axi_awsize),
  .s_axi_awburst  (s_axi_awburst),
  .s_axi_awlock   (s_axi_awlock),
  .s_axi_awcache  (s_axi_awcache),
  .s_axi_awprot   (s_axi_awprot),
  .s_axi_awqos    (s_axi_awqos),
  .s_axi_awregion (s_axi_awregion),
  .s_axi_awuser   (s_axi_awuser),
  .s_axi_awvalid  (s_axi_awvalid),
  .s_axi_awready  (s_axi_awready),
  .s_axi_wdata    (s_axi_wdata),
  .s_axi_wstrb    (s_axi_wstrb),
  .s_axi_wlast    (s_axi_wlast),
  .s_axi_wuser    (s_axi_wuser),
  .s_axi_wvalid   (s_axi_wvalid),
  .s_axi_wready   (s_axi_wready),
  .s_axi_bid      (s_axi_bid),
  .s_axi_bresp    (s_axi_bresp),
  .s_axi_buser    (s_axi_buser),
  .s_axi_bvalid   (s_axi_bvalid),
  .s_axi_bready   (s_axi_bready),
  .s_axi_arid     (s_axi_arid),
  .s_axi_araddr   (s_axi_araddr),
  .s_axi_arlen    (s_axi_arlen),
  .s_axi_arsize   (s_axi_arsize),
  .s_axi_arburst  (s_axi_arburst),
  .s_axi_arlock   (s_axi_arlock),
  .s_axi_arcache  (s_axi_arcache),
  .s_axi_arprot   (s_axi_arprot),
  .s_axi_arqos    (s_axi_arqos),
  .s_axi_arregion (s_axi_arregion),
  .s_axi_aruser   (s_axi_aruser),
  .s_axi_arvalid  (s_axi_arvalid),
  .s_axi_arready  (s_axi_arready),
  .s_axi_rid      (s_axi_rid),
  .s_axi_rdata    (s_axi_rdata),
  .s_axi_rresp    (s_axi_rresp),
  .s_axi_rlast    (s_axi_rlast),
  .s_axi_ruser    (s_axi_ruser),
  .s_axi_rvalid   (s_axi_rvalid),
  .s_axi_rready   (s_axi_rready)
);

// Drive unused
assign s_axi_awregion = 0;
assign s_axi_awuser   = 0;
assign s_axi_wuser    = 0;
assign s_axi_buser    = 0;
assign s_axi_arid     = 0;
assign s_axi_arsize   = 0;
assign s_axi_arburst  = 0;
assign s_axi_arlock   = 0;
assign s_axi_arcache  = 0;
assign s_axi_arprot   = 0;
assign s_axi_arqos    = 0;
assign s_axi_arregion = 0;
assign s_axi_aruser   = 0;

assign rom_din = {NUM_ROMS{4'hA}};


endmodule