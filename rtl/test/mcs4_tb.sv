`timescale 1 ns/1 ns  // time-unit = 1 ns, precision = 1 ns

module mcs4_tb #(
  parameter RAM_BANKS = 4,
  parameter BANK_CHIPS = 4
) (
  input                     clk,
  input                     rst,
  input  mcs4::char_t [1:0] io_in,
  output mcs4::char_t [1:0] io_rom_out,
  output mcs4::char_t       io_ram_out,

  input  dbg::addr_t        dbg_addr,
  input  mcs4::byte_t       dbg_wdata,
  input                     dbg_wen,
  output mcs4::byte_t       dbg_rdata
);

  logic cm_rom, cl_rom;
  mcs4::char_t cm_ram;
  logic sync;
  mcs4::char_t [RAM_BANKS*BANK_CHIPS-1:0] d_ramchip;
  mcs4::char_t [RAM_BANKS*BANK_CHIPS-1:0] d_ramchip_bus;
  mcs4::char_t [RAM_BANKS*BANK_CHIPS-1:0] io_ramchip_out;
  mcs4::char_t d_cpu, d_ram;
  mcs4::char_t [1:0] d_rom;

  mcs4::char_t d_bus;

  assign cl_rom = 0;
  assign d_ram = d_ramchip_bus[RAM_BANKS*BANK_CHIPS-1];
  assign d_bus = d_cpu | d_rom[0] | d_rom[1] | d_ram;
  assign io_ram_out = io_ramchip_out[0];

  wire cpu_rst, rom_rst, ram_rst;
  wire mcs4::addr_t rom_addr;
  wire mcs4::byte_t rom_wdata;
  wire              rom_wen;
  wire mcs4::addr_t pc;
  wire mcs4::instr_t instr;
  wire mcs4::char_t [mcs4::Num_regs-1:0] idx_reg;
  dbg_ctl dbg_ctl (
    .clk      (clk),
    .rst      (rst),

    // AXI slave connections
    .dbg_addr (dbg_addr),
    .dbg_wen  (dbg_wen),
    .dbg_wdata(dbg_wdata),
    .dbg_rdata(dbg_rdata),

    // ROM access
    .rom_addr (rom_addr),
    .rom_wdata(rom_wdata),
    .rom_wen  (rom_wen),

    // Reset Control
    .cpu_rst  (cpu_rst),
    .rom_rst  (rom_rst),
    .ram_rst  (ram_rst),

    // CPU Debug
    .pc       (pc),
    .instr    (instr),
    .idx_reg  (idx_reg)
  );

  i4001 #(
    .ROM_ID(4'b0000),
    .IO_MASK(4'b1111),
    .ROM_FILE("rom_00.hrom")
  ) rom_0 (
    .clk(clk),
    .rst(rom_rst),
    .sync(sync),
    .cl_rom(cl_rom),
    .cm_rom(cm_rom),
    .dbus_in(d_bus),
    .dbus_out(d_rom[0]),
    .io_in(io_in[0]),
    .io_out(io_rom_out[0]),

    .dbg_addr(rom_addr),
    .dbg_wdata(rom_wdata),
    .dbg_wen(rom_wen)
  );

  i4001 #(
    .ROM_ID(4'b0001),
    .IO_MASK(4'b1111),
    .ROM_FILE("rom_00.hrom")
  ) rom_1 (
    .clk(clk),
    .rst(rom_rst),
    .sync(sync),
    .cl_rom(cl_rom),
    .cm_rom(cm_rom),
    .dbus_in(d_bus),
    .dbus_out(d_rom[1]),
    .io_in(io_in[1]),
    .io_out(io_rom_out[1]),

    .dbg_addr(rom_addr),
    .dbg_wdata(rom_wdata),
    .dbg_wen(rom_wen)
  );

  generate
  for (genvar i = 0; i < RAM_BANKS; i++) begin : RAM_BANK
    for (genvar j = 0; j < BANK_CHIPS; j++) begin : RAM_CHIP
      int k = i * BANK_CHIPS + j;
      i4002 #(
        .RAM_ID(j)
      ) ram (
        .clk(clk),
        .rst(ram_rst),
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
    for (int i = 1; i < RAM_BANKS * BANK_CHIPS; i++) begin : RAM_BUS
      d_ramchip_bus[i] = d_ramchip[i] | d_ramchip_bus[i-1];
    end
  end

  i4004 cpu (
    .clk(clk),
    .rst(cpu_rst),
    .test(1'b0),
    .dbus_in(d_bus),
    .dbus_out(d_cpu),
    .sync(sync),
    .cm_rom(cm_rom),
    .cm_ram (cm_ram),

    .dbg_pc(pc),
    .dbg_instr(instr),
    .dbg_idx_reg(idx_reg)
  );

endmodule