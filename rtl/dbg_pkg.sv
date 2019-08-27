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
    RSVD = 2'd3
  } seg_t;

  typedef logic [Debug_segment_addr_width-1:0] seg_addr_t;

  typedef struct packed {
    seg_t      seg;
    seg_addr_t addr;
  } addr_t;

  localparam Ctl_sys_rst_addr = 12'h0000;
  localparam Ctl_cpu_pc_lo_addr  = 12'h0004;
  localparam Ctl_cpu_pc_hi_addr  = 12'h0005;
  localparam Ctl_cpu_instr_addr  = 12'h0006;
  localparam Ctl_cpu_idxreg_p0_addr  = 12'h0008;
  localparam Ctl_cpu_idxreg_p1_addr  = 12'h0009;
  localparam Ctl_cpu_idxreg_p2_addr  = 12'h000A;
  localparam Ctl_cpu_idxreg_p3_addr  = 12'h000B;
  localparam Ctl_cpu_idxreg_p4_addr  = 12'h000C;
  localparam Ctl_cpu_idxreg_p5_addr  = 12'h000D;
  localparam Ctl_cpu_idxreg_p6_addr  = 12'h000E;
  localparam Ctl_cpu_idxreg_p7_addr  = 12'h000F;

endpackage : dbg