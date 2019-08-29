module dbg_ctl (
  input clk,
  input rst,
  input  dbg::addr_t  dbg_addr,
  input  logic        dbg_wen,
  input  logic        dbg_ren,
  input  mcs4::byte_t dbg_wdata,
  output mcs4::byte_t dbg_rdata,

  output dbg::seg_addr_t rom_addr,
  output mcs4::byte_t    rom_wdata,
  input  mcs4::byte_t    rom_rdata,
  output logic           rom_wen,
  output logic           rom_ren,

  output logic cpu_rst,
  output logic rom_rst,
  output logic ram_rst,

  input logic [63:0] io_rom,
  input logic [63:0] io_ram,

  input  mcs4::addr_t              pc,
  input  mcs4::instr_t             instr,
  input  mcs4::char_t [mcs4::Num_regs-1:0] idx_reg
);

mcs4::byte_t    ctl_rdata;
mcs4::byte_t    io_rdata;
always_ff @(posedge clk) begin : proc_rst
  if(rst) begin
    cpu_rst <= 1'b1;
    rom_rst <= 1'b1;
    ram_rst <= 1'b1;
  end else if(dbg_addr.seg == dbg::CTL) begin
    if(dbg_wen) begin
      case (dbg_addr.addr)
        dbg::Ctl_sys_rst_addr: {ram_rst, rom_rst, cpu_rst} <= dbg_wdata[2:0];
        default : ;
      endcase
    end
    case (dbg_addr.addr)
      dbg::Ctl_sys_rst_addr:       ctl_rdata <= {5'd0, ram_rst, rom_rst, cpu_rst};
      dbg::Ctl_cpu_pc_lo_addr:     ctl_rdata <= pc[7:0];
      dbg::Ctl_cpu_pc_hi_addr:     ctl_rdata <= {4'h0, pc[11:8]};
      dbg::Ctl_cpu_instr_addr:     ctl_rdata <= instr;
      dbg::Ctl_cpu_idxreg_p0_addr: ctl_rdata <= {idx_reg[0], idx_reg[1]};
      dbg::Ctl_cpu_idxreg_p1_addr: ctl_rdata <= {idx_reg[2], idx_reg[3]};
      dbg::Ctl_cpu_idxreg_p2_addr: ctl_rdata <= {idx_reg[4], idx_reg[5]};
      dbg::Ctl_cpu_idxreg_p3_addr: ctl_rdata <= {idx_reg[6], idx_reg[7]};
      dbg::Ctl_cpu_idxreg_p4_addr: ctl_rdata <= {idx_reg[8], idx_reg[9]};
      dbg::Ctl_cpu_idxreg_p5_addr: ctl_rdata <= {idx_reg[10], idx_reg[11]};
      dbg::Ctl_cpu_idxreg_p6_addr: ctl_rdata <= {idx_reg[12], idx_reg[13]};
      dbg::Ctl_cpu_idxreg_p7_addr: ctl_rdata <= {idx_reg[14], idx_reg[15]};
      default :                    ctl_rdata <= 8'hAA;
    endcase
    // Buffer CTL data same cycles as ROM
    dbg_rdata <= ctl_rdata;
  end else if(dbg_addr.seg == dbg::ROM) begin
    dbg_rdata <= rom_rdata;
  end else if(dbg_addr.seg == dbg::IO) begin
    case (dbg::Io_addr_mask & dbg_addr.addr)
      dbg::Io_rom_base_addr: io_rdata <= io_rom[dbg_addr.addr[2:0]*8+:8];
      dbg::Io_ram_base_addr: io_rdata <= io_ram[dbg_addr.addr[2:0]*8+:8];
      default : io_rdata <= 8'hAC;
    endcase
    // Buffer IO data same cycles as ROM
    dbg_rdata <= io_rdata;
  end
end

assign rom_addr  = dbg_addr.addr;
assign rom_wdata = dbg_wdata;
assign rom_wen   = dbg_wen && dbg_addr.seg == dbg::ROM;
assign rom_ren   = dbg_ren && dbg_addr.seg == dbg::ROM;

// assign ram_addr  = dbg_addr.addr;
// assign ram_wdata = dbg_wdata;
// assign ram_wen   = dbg_addr.seg == dbg::RAM;

endmodule