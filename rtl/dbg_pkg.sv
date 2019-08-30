/* verilator lint_off DECLFILENAME */
package dbg;
/* verilator lint_on DECLFILENAME */

  localparam Debug_addr_width = 14;
  localparam Debug_segment_index_width = 2;
  localparam Debug_segment_addr_width = Debug_addr_width - Debug_segment_index_width;

  typedef enum logic [1:0] {
    CTL  = 2'd0,
    ROM  = 2'd1,
    RAM  = 2'd2,
    IO   = 2'd3
  } seg_t;

  typedef logic [Debug_segment_addr_width-1:0] seg_addr_t;

  typedef struct packed {
    seg_t      seg;
    seg_addr_t addr;
  } addr_t;

  localparam Ctl_sys_rst_addr       = 12'h0000;
  localparam Ctl_cpu_pc_lo_addr     = 12'h0004;
  localparam Ctl_cpu_pc_hi_addr     = 12'h0005;
  localparam Ctl_cpu_instr_addr     = 12'h0006;
  localparam Ctl_cpu_idxreg_p0_addr = 12'h0008;
  localparam Ctl_cpu_idxreg_p1_addr = 12'h0009;
  localparam Ctl_cpu_idxreg_p2_addr = 12'h000A;
  localparam Ctl_cpu_idxreg_p3_addr = 12'h000B;
  localparam Ctl_cpu_idxreg_p4_addr = 12'h000C;
  localparam Ctl_cpu_idxreg_p5_addr = 12'h000D;
  localparam Ctl_cpu_idxreg_p6_addr = 12'h000E;
  localparam Ctl_cpu_idxreg_p7_addr = 12'h000F;
  localparam Ctl_io_drive_addr      = 12'h0010;

  localparam Io_rom_in_base_addr  = 12'h000;
  localparam Io_rom_in_high_addr  = 12'h007;
  localparam Io_rom_out_base_addr = 12'h010;
  localparam Io_rom_out_high_addr = 12'h017;
  localparam Io_ram_out_base_addr = 12'h020;
  localparam Io_ram_out_high_addr = 12'h027;
  localparam Io_addr_mask         = 12'hFF8;

endpackage : dbg