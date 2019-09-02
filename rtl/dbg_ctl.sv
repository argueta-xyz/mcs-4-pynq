module dbg_ctl (
  input clk,
  input rst,
  (* mark_debug = "true" *) input  dbg::addr_t  dbg_addr,
  (* mark_debug = "true" *) input  logic        dbg_wen,
  (* mark_debug = "true" *) input  logic        dbg_ren,
  (* mark_debug = "true" *) input  mcs4::byte_t dbg_wdata,
  (* mark_debug = "true" *) output mcs4::byte_t dbg_rdata,
  (* mark_debug = "true" *) output logic        dbg_rdata_vld,

  (* mark_debug = "true" *) output dbg::seg_addr_t rom_addr,
  (* mark_debug = "true" *) output mcs4::byte_t    rom_wdata,
  (* mark_debug = "true" *) input  mcs4::byte_t    rom_rdata,
  (* mark_debug = "true" *) input                  rom_rdata_vld,
  (* mark_debug = "true" *) output logic           rom_wen,
  (* mark_debug = "true" *) output logic           rom_ren,

  (* mark_debug = "true" *) output dbg::seg_addr_t ram_addr,
  (* mark_debug = "true" *) output mcs4::byte_t    ram_wdata,
  (* mark_debug = "true" *) input  mcs4::byte_t    ram_rdata,
  (* mark_debug = "true" *) input                  ram_rdata_vld,
  (* mark_debug = "true" *) output logic           ram_wen,
  (* mark_debug = "true" *) output logic           ram_ren,

  output logic cpu_rst,
  output logic rom_rst,
  output logic ram_rst,

  output logic        io_rom_in_drive,
  output logic [63:0] io_rom_in,
  input  logic [63:0] io_rom_out,
  input  logic [63:0] io_ram_out,

  input  mcs4::addr_t              pc,
  input  mcs4::instr_t             instr,
  input  mcs4::char_t [mcs4::Num_regs-1:0] idx_reg
);

mcs4::byte_t ctl_rdata;
logic        ctl_rdata_vld;
mcs4::byte_t io_rdata;
logic        io_rdata_vld;
always_ff @(posedge clk) begin : proc_rst
  if(rst) begin
    cpu_rst <= 1'b1;
    rom_rst <= 1'b1;
    ram_rst <= 1'b1;
    io_rom_in_drive <= 1'b0;
    io_rom_in <= '0;
  end else if(dbg_addr.seg == dbg::CTL) begin
    if(dbg_wen) begin
      case (dbg_addr.addr)
        dbg::Ctl_sys_rst_addr  : {ram_rst, rom_rst, cpu_rst} <= dbg_wdata[2:0];
        dbg::Ctl_io_drive_addr : io_rom_in_drive  <= dbg_wdata[0];
        default : ;
      endcase
    end
    case (dbg_addr.addr)
      dbg::Ctl_sys_rst_addr       : ctl_rdata <= {5'd0, ram_rst, rom_rst, cpu_rst};
      dbg::Ctl_cpu_pc_lo_addr     : ctl_rdata <= pc[7:0];
      dbg::Ctl_cpu_pc_hi_addr     : ctl_rdata <= {4'h0, pc[11:8]};
      dbg::Ctl_cpu_instr_addr     : ctl_rdata <= instr;
      dbg::Ctl_cpu_idxreg_p0_addr : ctl_rdata <= {idx_reg[0],  idx_reg[1]};
      dbg::Ctl_cpu_idxreg_p1_addr : ctl_rdata <= {idx_reg[2],  idx_reg[3]};
      dbg::Ctl_cpu_idxreg_p2_addr : ctl_rdata <= {idx_reg[4],  idx_reg[5]};
      dbg::Ctl_cpu_idxreg_p3_addr : ctl_rdata <= {idx_reg[6],  idx_reg[7]};
      dbg::Ctl_cpu_idxreg_p4_addr : ctl_rdata <= {idx_reg[8],  idx_reg[9]};
      dbg::Ctl_cpu_idxreg_p5_addr : ctl_rdata <= {idx_reg[10], idx_reg[11]};
      dbg::Ctl_cpu_idxreg_p6_addr : ctl_rdata <= {idx_reg[12], idx_reg[13]};
      dbg::Ctl_cpu_idxreg_p7_addr : ctl_rdata <= {idx_reg[14], idx_reg[15]};
      dbg::Ctl_io_drive_addr      : ctl_rdata <= {7'd0, io_rom_in_drive};
      default : ctl_rdata <= 8'hAA;
    endcase
    ctl_rdata_vld <= dbg_ren;
    // Buffer CTL data same cycles as ROM
    dbg_rdata <= ctl_rdata;
    dbg_rdata_vld <= ctl_rdata_vld;
  end else if(dbg_addr.seg == dbg::ROM) begin
    dbg_rdata <= rom_rdata;
    dbg_rdata_vld <= rom_rdata_vld;
  end else if(dbg_addr.seg == dbg::RAM) begin
    dbg_rdata <= ram_rdata;
    dbg_rdata_vld <= ram_rdata_vld;
  end else if(dbg_addr.seg == dbg::IO) begin
    if(dbg_wen) begin
      case (dbg::Io_addr_mask & dbg_addr.addr)
        dbg::Io_rom_in_base_addr : io_rom_in[dbg_addr.addr[2:0]*8+:8] <= dbg_wdata;
        default : ;
      endcase
    end
    case (dbg::Io_addr_mask & dbg_addr.addr)
      dbg::Io_rom_out_base_addr : io_rdata <= io_rom_out[dbg_addr.addr[2:0]*8+:8];
      dbg::Io_rom_in_base_addr  : io_rdata <= io_rom_in[dbg_addr.addr[2:0]*8+:8];
      dbg::Io_ram_out_base_addr : io_rdata <= io_ram_out[dbg_addr.addr[2:0]*8+:8];
      default : io_rdata <= 8'hAC;
    endcase
    io_rdata_vld <= dbg_ren;
    // Buffer IO data same cycles as ROM
    dbg_rdata <= io_rdata;
    dbg_rdata_vld <= io_rdata_vld;
  end
end

always_ff @(posedge clk) begin : proc_rom_rw_ctl
  rom_addr  <= dbg_addr.addr;
  rom_wdata <= dbg_wdata;
  rom_wen   <= dbg_wen && dbg_addr.seg == dbg::ROM;
  rom_ren   <= dbg_ren && dbg_addr.seg == dbg::ROM;
end

always_ff @(posedge clk) begin : proc_ram_rw_ctl
  ram_addr  <= dbg_addr.addr;
  ram_wdata <= dbg_wdata;
  ram_wen   <= dbg_wen && dbg_addr.seg == dbg::RAM;
  ram_ren   <= dbg_ren && dbg_addr.seg == dbg::RAM;
end

endmodule