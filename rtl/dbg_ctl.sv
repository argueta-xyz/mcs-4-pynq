module dbg_ctl (
  input clk,
  input rst,
  input  dbg::addr_t  dbg_addr,
  input  logic        dbg_wen,
  input  mcs4::byte_t dbg_wdata,
  output mcs4::byte_t dbg_rdata,

  output dbg::seg_addr_t rom_addr,
  output mcs4::byte_t    rom_wdata,
  output logic           rom_wen,

  output logic cpu_rst,
  output logic rom_rst,
  output logic ram_rst,

  input  mcs4::addr_t              pc,
  input  mcs4::instr_t             instr,
  input  mcs4::char_t [mcs4::Num_regs-1:0] idx_reg
);

always_ff @(posedge clk) begin : proc_rst
  if(rst) begin
    cpu_rst <= 1'b1;
    rom_rst <= 1'b1;
    ram_rst <= 1'b1;
  end else if(dbg_addr.seg == dbg::CTL) begin
    if(dbg_wen) begin
      case (dbg_addr.addr)
        dbg::Ctl_sys_rst_addr: {ram_rst, rom_rst, cpu_rst} <= {dbg_wdata[8], dbg_wdata[4], dbg_wdata[0]};
        default : ;
      endcase
    end
    case (dbg_addr.addr)
      dbg::Ctl_sys_rst_addr:       dbg_rdata <= {3'd0, ram_rst, 3'd0, rom_rst, 3'd0, cpu_rst};
      dbg::Ctl_cpu_pc_lo_addr:     dbg_rdata <= pc[7:0];
      dbg::Ctl_cpu_pc_hi_addr:     dbg_rdata <= {4'h0, pc[11:8]};
      dbg::Ctl_cpu_instr_addr:     dbg_rdata <= instr;
      dbg::Ctl_cpu_idxreg_p0_addr: dbg_rdata <= {idx_reg[0], idx_reg[1]};
      dbg::Ctl_cpu_idxreg_p1_addr: dbg_rdata <= {idx_reg[2], idx_reg[3]};
      dbg::Ctl_cpu_idxreg_p2_addr: dbg_rdata <= {idx_reg[4], idx_reg[5]};
      dbg::Ctl_cpu_idxreg_p3_addr: dbg_rdata <= {idx_reg[6], idx_reg[7]};
      dbg::Ctl_cpu_idxreg_p4_addr: dbg_rdata <= {idx_reg[8], idx_reg[9]};
      dbg::Ctl_cpu_idxreg_p5_addr: dbg_rdata <= {idx_reg[10], idx_reg[11]};
      dbg::Ctl_cpu_idxreg_p6_addr: dbg_rdata <= {idx_reg[12], idx_reg[13]};
      dbg::Ctl_cpu_idxreg_p7_addr: dbg_rdata <= {idx_reg[14], idx_reg[15]};
      default :                    dbg_rdata <= 8'hAA;
    endcase
  end
end

assign rom_addr  = dbg_addr.addr;
assign rom_wdata = dbg_wdata;
assign rom_wen   = dbg_addr.seg == dbg::ROM;

// assign ram_addr  = dbg_addr.addr;
// assign ram_wdata = dbg_wdata;
// assign ram_wen   = dbg_addr.seg == dbg::RAM;

endmodule