`include "memdef.vh"
`default_nettype none

module memory_router(

                     I_CLK,
                     I_RESET,

                     /*******************************************************/
                     /* Memory Master Interfaces                            */
                     /*******************************************************/

                     /*Interface with CPU*/
                     I_CPU_ADDR,
                     IO_CPU_DATA,
                     I_CPU_WE_L,
                     I_CPU_RE_L,

                     /*Interface with PPU*/
                     I_PPU_ADDR,
                     IO_PPU_DATA,
                     I_PPU_WE_L,
                     I_PPU_RE_L,

                     /*Interface with DMA Read Port*/
                     I_RDMA_ADDR,
                     O_RDMA_DATA,
                     I_RDMA_RE_L,

                     /*Interface with DMA Write Port*/
                     I_WDMA_ADDR,
                     I_WDMA_DATA,
                     I_WDMA_WE_L,

                     /********************************************************/
                     /* Memory Slave Interfaces                              */
                     /********************************************************/

                     /*IO Register Bus*/
                     O_IOREG_ADDR,
                     IO_IOREG_DATA,
                     O_IOREG_WE_L,
                     O_IOREG_RE_L,

                     /*Cartridge Interface*/
                     O_CARTRIDGE_ADDR,
                     IO_CARTRIDGE_DATA,
                     O_CARTRIDGE_WE_L,
                     O_CARTRIDGE_RE_L,

                     /*LCD RAM*/
                     O_LCDRAM_ADDR,
                     O_LCDRAM_DATA,
                     I_LCDRAM_DATA,
                     O_LCDRAM_WE_L,
                     O_LCDRAM_RE_L,

                     /*WORKING RAM*/
                     O_WRAM_ADDR,
                     IO_WRAM_DATA,
                     O_WRAM_WE_L,
                     O_WRAM_RE_L);

   /*Master Interface Ports*/
   input             I_CLK, I_RESET;
   input [15:0]      I_CPU_ADDR, I_PPU_ADDR, I_RDMA_ADDR, I_WDMA_ADDR;
   inout [7:0]       IO_CPU_DATA, IO_PPU_DATA;
   output [7:0]      O_RDMA_DATA;
   input [7:0]       I_WDMA_DATA;
   input             I_CPU_WE_L, I_CPU_RE_L, I_PPU_WE_L, I_PPU_RE_L, I_RDMA_RE_L,                     
		     I_WDMA_WE_L;

   /*Slave Interface Ports*/
   output [15:0]     O_IOREG_ADDR, O_CARTRIDGE_ADDR, O_LCDRAM_ADDR, O_WRAM_ADDR;
   inout [7:0]       IO_IOREG_DATA, IO_CARTRIDGE_DATA, IO_WRAM_DATA;
   input [7:0]       I_LCDRAM_DATA;
   output [7:0]      O_LCDRAM_DATA;
   output            O_IOREG_WE_L, O_IOREG_RE_L, O_CARTRIDGE_WE_L, O_CARTRIDGE_RE_L,
                     O_LCDRAM_WE_L, O_LCDRAM_RE_L, O_WRAM_WE_L, O_WRAM_RE_L;

   /*break up the io busses into two separate lines so they can
    *be routed to a new location */

   /* Master Interfaces*/
   wire [7:0]        cpu_data_in, ppu_data_in;
   assign cpu_data_in = IO_CPU_DATA;
   assign ppu_data_in = IO_PPU_DATA;
   wire [7:0]        cpu_data_out, ppu_data_out;
   wire              en_cpu_data,  en_ppu_data;

   assign IO_CPU_DATA = (en_cpu_data) ?  cpu_data_out : 'bzzzzzzzz;
   assign IO_PPU_DATA = (en_ppu_data) ? ppu_data_out : 'bzzzzzzzz;

   /* Slave Interfaces*/
   wire [7:0]        ioreg_data_in, cartridge_data_in, lcdram_data_in,
                     wram_data_in, oam_data_in, lwram_data_in;
   assign ioreg_data_in = IO_IOREG_DATA;
   assign cartridge_data_in = IO_CARTRIDGE_DATA;
   assign lcdram_data_in = I_LCDRAM_DATA;
   assign wram_data_in = IO_WRAM_DATA;
   wire [7:0]        ioreg_data_out, cartridge_data_out, lcdram_data_out,
                     wram_data_out;
   wire              en_ioreg_data;
   wire              en_lcdram_data;
   wire              en_wram_data;
   wire              en_cartridge_data;
   wire              cpu_accessing_cartridge;
   assign IO_IOREG_DATA = (en_ioreg_data) ? ioreg_data_out : 'bzzzzzzzz;
   assign IO_CARTRIDGE_DATA = (en_cartridge_data) ? cartridge_data_out : 'bzzzzzzzz;
   assign O_LCDRAM_DATA = lcdram_data_out;
   assign IO_WRAM_DATA = (en_wram_data) ? wram_data_out : 'bzzzzzzzz;

   /*Bits to indicate who is accessing what*/
   wire              cpu_accessing_ioreg, cpu_accessing_lcdram,
                     cpu_accessing_wram;
   wire              ppu_accessing_ioreg, ppu_accessing_cartridge, ppu_accessing_lcdram,
                     ppu_accessing_wram;
   wire              rdma_accessing_ioreg, rdma_accessing_cartridge, rdma_accessing_lcdram,
                     rdma_accessing_wram;
   wire              wdma_accessing_ioreg, wdma_accessing_cartridge, wdma_accessing_lcdram,
                     wdma_accessing_wram;

   /*Bits To Route Returning Read Data*/
   wire              ioreg_cpu_return, cartridge_cpu_return, lcdram_cpu_return,
                     wram_cpu_return;
   wire              ioreg_ppu_return, cartridge_ppu_return, lcdram_ppu_return,
                     wram_ppu_return;
   wire              ioreg_rdma_return, cartridge_rdma_return, lcdram_rdma_return,
                     wram_rdma_return;

   wire              cpu_en, ppu_en, rdma_en, wdma_en;

   assign cpu_en = ~I_CPU_WE_L | ~I_CPU_RE_L;
   assign ppu_en = ~I_PPU_WE_L | ~I_PPU_RE_L;
   assign rdma_en = ~I_RDMA_RE_L;
   assign wdma_en = ~I_WDMA_WE_L;


   assign cpu_accessing_cartridge = (cpu_en && I_CPU_ADDR >= `CARTRIDGE_LO && I_CPU_ADDR <= `CARTRIDGE_HI) || 
				    (cpu_en && I_CPU_ADDR >= `EXTERNAL_EXPANSION_LO && I_CPU_ADDR <= `EXTERNAL_EXPANSION_HI);
   assign cpu_accessing_ioreg = (cpu_en && I_CPU_ADDR >= `IOREG_LO && I_CPU_ADDR <= `IOREG_HI || I_CPU_ADDR == `IE_REGISTER);
   assign cpu_accessing_lcdram =  cpu_en && ((I_CPU_ADDR >= `LCDRAM_LO & I_CPU_ADDR <= `LCDRAM_HI) || 
					     (I_CPU_ADDR >= `OAM_LO & I_CPU_ADDR <= `OAM_HI) || 
					     (I_CPU_ADDR == `LCDC) || (I_CPU_ADDR == `STAT) ||
					     (I_CPU_ADDR == `SCX)  || (I_CPU_ADDR == `SCY)  ||
					     (I_CPU_ADDR == `LY )  || (I_CPU_ADDR == `LYC)  ||
					     (I_CPU_ADDR == `BGP)  || (I_CPU_ADDR == `OBP0) || 
					     (I_CPU_ADDR == `OBP1) || (I_CPU_ADDR == `WY)   ||
					     (I_CPU_ADDR == `WX)   || (I_CPU_ADDR == `BCPS) ||
					     (I_CPU_ADDR == `BCPD) || (I_CPU_ADDR == `OCPS) ||
					     (I_CPU_ADDR == `OCPD) || (I_CPU_ADDR == `VBK)  ||
                         (I_CPU_ADDR >= `OAM_LO && I_CPU_ADDR <= `OAM_HI));
   assign cpu_accessing_wram = (cpu_en && I_CPU_ADDR >= `WRAM_LO && I_CPU_ADDR <= `ECHO_HI);

   assign ppu_accessing_cartridge = (ppu_en && I_PPU_ADDR >= `CARTRIDGE_LO && I_PPU_ADDR <= `CARTRIDGE_HI) ||
				    (ppu_en && I_PPU_ADDR >= `EXTERNAL_EXPANSION_LO && I_PPU_ADDR <= `EXTERNAL_EXPANSION_HI);
   assign ppu_accessing_ioreg = (ppu_en && I_PPU_ADDR >= `IOREG_LO && I_PPU_ADDR <= `IOREG_HI || I_PPU_ADDR == `IE_REGISTER);
   assign ppu_accessing_lcdram =  ppu_en && ((I_PPU_ADDR >= `LCDRAM_LO & I_PPU_ADDR <= `LCDRAM_HI) || 
					     (I_PPU_ADDR >= `OAM_LO & I_PPU_ADDR <= `OAM_HI) || 
					     (I_PPU_ADDR == `LCDC) || (I_PPU_ADDR == `STAT) ||
					     (I_PPU_ADDR == `SCX)  || (I_PPU_ADDR == `SCY)  ||
					     (I_PPU_ADDR == `LY )  || (I_PPU_ADDR == `LYC)  ||
					     (I_PPU_ADDR == `BGP)  || (I_PPU_ADDR == `OBP0) || 
					     (I_PPU_ADDR == `OBP1) || (I_PPU_ADDR == `WY)   ||
					     (I_PPU_ADDR == `WX)   || (I_PPU_ADDR == `BCPS) ||
					     (I_PPU_ADDR == `BCPD) || (I_PPU_ADDR == `OCPS) ||
					     (I_PPU_ADDR == `OCPD) || (I_PPU_ADDR == `VBK) ||
                         (I_PPU_ADDR >= `OAM_LO && I_PPU_ADDR <= `OAM_HI));
   assign ppu_accessing_wram = (ppu_en && I_PPU_ADDR >= `WRAM_LO && I_PPU_ADDR <= `ECHO_HI);

   assign rdma_accessing_cartridge = (rdma_en && I_RDMA_ADDR >= `CARTRIDGE_LO && I_RDMA_ADDR <= `CARTRIDGE_HI) ||
				     (rdma_en && I_RDMA_ADDR >= `EXTERNAL_EXPANSION_LO && I_RDMA_ADDR <= `EXTERNAL_EXPANSION_HI);
   assign rdma_accessing_ioreg = (rdma_en && I_RDMA_ADDR >= `IOREG_LO && I_RDMA_ADDR <= `IOREG_HI || I_RDMA_ADDR == `IE_REGISTER);
   assign rdma_accessing_lcdram =  rdma_en && ((I_RDMA_ADDR >= `LCDRAM_LO & I_RDMA_ADDR <= `LCDRAM_HI) || 
					     (I_RDMA_ADDR >= `OAM_LO & I_RDMA_ADDR <= `OAM_HI) || 
					     (I_RDMA_ADDR == `LCDC) || (I_RDMA_ADDR == `STAT) ||
					     (I_RDMA_ADDR == `SCX)  || (I_RDMA_ADDR == `SCY)  ||
					     (I_RDMA_ADDR == `LY )  || (I_RDMA_ADDR == `LYC)  ||
					     (I_RDMA_ADDR == `BGP)  || (I_RDMA_ADDR == `OBP0) || 
					     (I_RDMA_ADDR == `OBP1) || (I_RDMA_ADDR == `WY)   ||
					     (I_RDMA_ADDR == `WX)   || (I_RDMA_ADDR == `BCPS) ||
					     (I_RDMA_ADDR == `BCPD) || (I_RDMA_ADDR == `OCPS) ||
					     (I_RDMA_ADDR == `OCPD) || (I_RDMA_ADDR == `VBK) ||
                         (I_RDMA_ADDR >= `OAM_LO && I_RDMA_ADDR <= `OAM_HI));
   assign rdma_accessing_wram = (rdma_en && I_RDMA_ADDR >= `WRAM_LO && I_RDMA_ADDR <= `ECHO_HI);

   assign wdma_accessing_cartridge = (wdma_en && I_WDMA_ADDR >= `CARTRIDGE_LO && I_WDMA_ADDR <= `CARTRIDGE_HI) ||
				     (wdma_en && I_WDMA_ADDR >= `EXTERNAL_EXPANSION_LO && I_WDMA_ADDR <= `EXTERNAL_EXPANSION_HI);
   assign wdma_accessing_ioreg = (wdma_en && I_WDMA_ADDR >= `IOREG_LO && I_WDMA_ADDR <= `IOREG_HI || I_WDMA_ADDR == `IE_REGISTER);
   assign wdma_accessing_lcdram =  wdma_en && ((I_WDMA_ADDR >= `LCDRAM_LO & I_WDMA_ADDR <= `LCDRAM_HI) || 
					     (I_WDMA_ADDR >= `OAM_LO & I_WDMA_ADDR <= `OAM_HI) || 
					     (I_WDMA_ADDR == `LCDC) || (I_WDMA_ADDR == `STAT) ||
					     (I_WDMA_ADDR == `SCX)  || (I_WDMA_ADDR == `SCY)  ||
					     (I_WDMA_ADDR == `LY )  || (I_WDMA_ADDR == `LYC)  ||
					     (I_WDMA_ADDR == `BGP)  || (I_WDMA_ADDR == `OBP0) || 
					     (I_WDMA_ADDR == `OBP1) || (I_WDMA_ADDR == `WY)   ||
					     (I_WDMA_ADDR == `WX)   || (I_WDMA_ADDR == `BCPS) ||
					     (I_WDMA_ADDR == `BCPD) || (I_WDMA_ADDR == `OCPS) ||
					     (I_WDMA_ADDR == `OCPD) || (I_WDMA_ADDR == `VBK) ||
                         (I_WDMA_ADDR >= `OAM_LO && I_WDMA_ADDR <= `OAM_HI));
   assign wdma_accessing_wram = (wdma_en && I_WDMA_ADDR >= `WRAM_LO && I_WDMA_ADDR <= `ECHO_HI);

   assign O_IOREG_WE_L = (cpu_accessing_ioreg) ? I_CPU_WE_L :
                         (ppu_accessing_ioreg) ? I_PPU_WE_L :
                         (wdma_accessing_ioreg) ? I_WDMA_WE_L : 1;
   assign O_IOREG_RE_L = (cpu_accessing_ioreg) ? I_CPU_RE_L :
                         (ppu_accessing_ioreg) ? I_PPU_RE_L :
                         (rdma_accessing_ioreg) ? I_RDMA_RE_L : 1;
   assign ioreg_data_out = (cpu_accessing_ioreg) ? cpu_data_in :
                           (ppu_accessing_ioreg) ? ppu_data_in :
                           (wdma_accessing_ioreg) ? I_WDMA_DATA : 'd0;
   assign O_IOREG_ADDR = (cpu_accessing_ioreg) ? I_CPU_ADDR :
                         (ppu_accessing_ioreg) ? I_PPU_ADDR :
                         (rdma_accessing_ioreg) ? I_RDMA_ADDR :
                         (wdma_accessing_ioreg) ? I_WDMA_ADDR : 'd0;
   assign en_ioreg_data = (cpu_accessing_ioreg) ? ~I_CPU_WE_L :
                          (ppu_accessing_ioreg) ? ~I_PPU_WE_L :
                          (wdma_accessing_ioreg) ? ~I_WDMA_WE_L : 0;



   assign O_CARTRIDGE_WE_L = (cpu_accessing_cartridge) ? I_CPU_WE_L :
                             (ppu_accessing_cartridge) ? I_PPU_WE_L :
                             (wdma_accessing_cartridge) ? I_WDMA_WE_L : 1;
   assign O_CARTRIDGE_RE_L = (cpu_accessing_cartridge) ? I_CPU_RE_L :
                             (ppu_accessing_cartridge) ? I_PPU_RE_L :
                             (rdma_accessing_cartridge) ? I_RDMA_RE_L : 1;
   assign cartridge_data_out = (cpu_accessing_cartridge) ? cpu_data_in :
                               (ppu_accessing_cartridge) ? ppu_data_in :
                               (wdma_accessing_cartridge) ? I_WDMA_DATA : 'd0;
   assign O_CARTRIDGE_ADDR = (cpu_accessing_cartridge) ? I_CPU_ADDR :
                             (ppu_accessing_cartridge) ? I_PPU_ADDR :
                             (rdma_accessing_cartridge) ? I_RDMA_ADDR :
                             (wdma_accessing_cartridge) ? I_WDMA_ADDR : 'd0;
   assign en_cartridge_data = (cpu_accessing_cartridge) ? ~I_CPU_WE_L :
                              (ppu_accessing_cartridge) ? ~I_PPU_WE_L :
                              (wdma_accessing_cartridge) ? ~I_WDMA_WE_L : 0;



   assign O_WRAM_WE_L = (cpu_accessing_wram) ? I_CPU_WE_L :
                        (ppu_accessing_wram) ? I_PPU_WE_L :
                        (wdma_accessing_wram) ? I_WDMA_WE_L : 1;
   assign O_WRAM_RE_L = (cpu_accessing_wram) ? I_CPU_RE_L :
                        (ppu_accessing_wram) ? I_PPU_RE_L :
                        (rdma_accessing_wram) ? I_RDMA_RE_L : 1;
   assign wram_data_out = (cpu_accessing_wram) ? cpu_data_in :
                          (ppu_accessing_wram) ? ppu_data_in :
                          (wdma_accessing_wram) ? I_WDMA_DATA : 'd0;
   assign O_WRAM_ADDR = (cpu_accessing_wram) ? I_CPU_ADDR :
                        (ppu_accessing_wram) ? I_PPU_ADDR :
                        (rdma_accessing_wram) ? I_RDMA_ADDR :
                        (wdma_accessing_wram) ? I_WDMA_ADDR : 'd0;
   assign en_wram_data = (cpu_accessing_wram) ? ~I_CPU_WE_L :
                         (ppu_accessing_wram) ? ~I_PPU_WE_L :
                         (wdma_accessing_wram) ? ~I_WDMA_WE_L : 0;


   assign O_LCDRAM_WE_L = (cpu_accessing_lcdram) ? I_CPU_WE_L :
                          (ppu_accessing_lcdram) ? I_PPU_WE_L :
                          (wdma_accessing_lcdram) ? I_WDMA_WE_L : 1;
   assign O_LCDRAM_RE_L = (cpu_accessing_lcdram) ? I_CPU_RE_L :
                          (ppu_accessing_lcdram) ? I_PPU_RE_L :
                          (rdma_accessing_lcdram) ? I_RDMA_RE_L : 1;
   assign lcdram_data_out = (cpu_accessing_lcdram) ? cpu_data_in :
                            (ppu_accessing_lcdram) ? ppu_data_in :
                            (wdma_accessing_lcdram) ? I_WDMA_DATA : 'd0;
   assign O_LCDRAM_ADDR = (cpu_accessing_lcdram) ? I_CPU_ADDR :
                          (ppu_accessing_lcdram) ? I_PPU_ADDR :
                          (rdma_accessing_lcdram) ? I_RDMA_ADDR :
                          (wdma_accessing_lcdram) ? I_WDMA_ADDR : 'd0;
   assign en_lcdram_data = (cpu_accessing_lcdram) ? ~I_CPU_WE_L :
                           (ppu_accessing_lcdram) ? ~I_PPU_WE_L :
                           (wdma_accessing_lcdram) ? ~I_WDMA_WE_L : 0;


   /*figure out who gives the data back to the cpu*/
   assign ioreg_cpu_return = cpu_accessing_ioreg & ~I_CPU_RE_L & ~lcdram_cpu_return;
   assign cartridge_cpu_return = cpu_accessing_cartridge & ~I_CPU_RE_L;
   assign lcdram_cpu_return = cpu_accessing_lcdram & ~I_CPU_RE_L;
   assign wram_cpu_return = cpu_accessing_wram & ~I_CPU_RE_L;

   /*figure out who gives data back to the ppu*/
   assign ioreg_ppu_return = ppu_accessing_ioreg & ~I_PPU_RE_L & ~lcdram_ppu_return;
   assign cartridge_ppu_return = ppu_accessing_cartridge & ~I_PPU_RE_L;
   assign lcdram_ppu_return = ppu_accessing_lcdram & ~I_PPU_RE_L;
   assign wram_ppu_return = ppu_accessing_wram & ~I_PPU_RE_L;

   /*figure out who gives data back to the rdma*/
   assign ioreg_rdma_return = rdma_accessing_ioreg & ~I_RDMA_RE_L & ~lcdram_rdma_return;
   assign cartridge_rdma_return = rdma_accessing_cartridge & ~I_RDMA_RE_L;
   assign lcdram_rdma_return = rdma_accessing_lcdram & ~I_RDMA_RE_L;
   assign wram_rdma_return = rdma_accessing_wram & ~I_RDMA_RE_L;

   /*Drive CPU Data Bus with Return Data*/
   assign cpu_data_out = (ioreg_cpu_return) ? ioreg_data_in :
                         (cartridge_cpu_return) ? cartridge_data_in :
                         (lcdram_cpu_return) ? lcdram_data_in :
                         (wram_cpu_return) ? wram_data_in : 0;
   assign en_cpu_data = ioreg_cpu_return | cartridge_cpu_return |
                        lcdram_cpu_return | wram_cpu_return;

   /*Drive PPU Data Bus with Return Data*/
   assign ppu_data_out = (ioreg_ppu_return) ? ioreg_data_in :
                         (cartridge_ppu_return) ? cartridge_data_in :
                         (lcdram_ppu_return) ? lcdram_data_in :
                         (wram_ppu_return) ? wram_data_in : 0;
   assign en_ppu_data = ioreg_ppu_return | cartridge_ppu_return |
                        lcdram_ppu_return | wram_ppu_return;

   /*Drive RDMA Data with Return Data*/
   assign O_RDMA_DATA = (ioreg_rdma_return) ? ioreg_data_in :
                        (cartridge_rdma_return) ? cartridge_data_in :
                        (lcdram_rdma_return) ? lcdram_data_in :
                        (wram_rdma_return) ? wram_data_in : 0;
endmodule