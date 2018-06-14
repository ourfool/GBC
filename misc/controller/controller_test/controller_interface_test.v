`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:30:08 10/26/2014 
// Design Name: 
// Module Name:    controller_interface_test 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module controller_interface_test();

	reg clock = 0;
	reg reset;
	wire [7:0] buttons;
	wire latch;
	wire pulse;
	reg data;
	integer count;

   always
     #5 clock = ~clock;

	controller_interface controller(
		// outputs
		.O_BUTTONS(buttons),
		.O_LATCH(latch),
		.O_PULSE(pulse),
	
		// inputs
		.I_CLK_33MHZ(clock),
		.I_DATA(data),
	
		.I_RESET(reset)
	);
	
	initial begin
		clock = 0;
		reset = 0;
		count = 0;
		#3 reset = 1;
		#3 reset = 0;
		data = 1;
      
		while (count < 1316134912) begin
			count = count + 1;
			@(posedge clock);
		end
      
		@(posedge clock);
      
		#1 $finish;
	end

endmodule

/*
module cpu_mem_integration();
   wire         cpu_mem_we_l, cpu_mem_re_l, cpu_halt;
   tri [15:0]   addr_ext;
   tri [7:0]    data_ext;
   reg          clock, reset;
   
   assign cpu_halt = 0;
   
   wire [15:0]  cpu_addr;
   assign cpu_addr = addr_ext;
   
   
   tri [7:0]    iobus_data;
   wire [15:0]  iobus_addr;
   wire         iobus_we_l, iobus_re_l;
   
   tri [7:0]    wram_data;
   wire [15:0]  wram_addr;
   wire         wram_we_l, wram_re_l;
   
   
   tri [7:0]    cartridge_data, oam_data, lcdram_data;
   wire [15:0]  cartridge_addr, oam_addr, lcdram_addr;
   wire         cartridge_we_l, cartridge_re_l, 
		oam_we_l, oam_re_l, 
		lcdram_we_l, lcdram_re_l;
   
   
   wire [7:0]   ioreg1_data, ioreg2_data;
   
   wire         gb_mode ;
   assign       gb_mode = 0;
   integer      count;
   
   wire         clock_main, mem_clock;
   
   always
     #5 clock = ~clock;
   
   my_clock_divider #(.DIV_SIZE(4), .DIV_OVER_TWO(4))
   cdiv(.clock_out(clock_main),
        .clock_in(clock));
   my_clock_divider #(.DIV_SIZE(4), .DIV_OVER_TWO(2))
   cdiv(.clock_out(mem_clock),
        .clock_in(clock));
   
   initial begin
      clock = 0;
      reset = 0;
      count = 0;
      #3 reset = 1;
      #3 reset = 0;
      
      while (count < 10000000) begin
         count = count + 1;
         @(posedge clock_main);
      end
      
      @(posedge clock_main);
      
      #1 $finish;
   end
   
   wire cpu_mem_disable;
   assign cpu_mem_disable = 0;
   
   wire [15:0] rdma_addr, wdma_addr;
   wire [7:0]  rdma_data, wdma_data;
   wire        rdma_re_l, wdma_we_l;
   
   cpu gbc_cpu(
               .mem_we_l(cpu_mem_we_l), 
               .mem_re_l(cpu_mem_re_l), 
               .halt(cpu_halt), 
               .addr_ext(addr_ext), 
               .data_ext(data_ext),
               .cpu_mem_disable(cpu_mem_disable),
               .clock(clock_main), 
               .reset(reset)
               );
   
   dma_controller dma(
                      .I_CLK(clock_main),
                      .I_SYNC_RESET(clock_reset),
                      .I_IOREG_ADDR(iobus_addr),
                      .IO_IOREG_DATA(iobus_data),
                      .I_IOREG_WE_L(iobus_we_l),
                      .I_IOREG_RE_L(iobus_re_l),
                      .O_RDMA_ADDR(rdma_addr),
                      .I_RDMA_DATA(rdma_data),
                      .O_RDMA_RE_L(rdma_re_l),
                      .O_WDMA_ADDR(wdma_addr),
                      .O_WDMA_DATA(wdma_data),
                      .O_WDMA_WE_L(wdma_we_l),
                      .I_HBLANK(0),
                      .I_VBLANK(0)
                      );

   memory_router router(
                        .I_CLK(clock_main),
                        .I_RESET(reset),
                        .I_CPU_ADDR(cpu_addr),
                        .IO_CPU_DATA(data_ext),
                        .I_CPU_WE_L(cpu_mem_we_l),
                        .I_CPU_RE_L(cpu_mem_re_l),
                        .O_IOREG_ADDR(iobus_addr),
                        .IO_IOREG_DATA(iobus_data),
                        .O_IOREG_WE_L(iobus_we_l),
                        .O_IOREG_RE_L(iobus_re_l),
                        .I_PPU_ADDR(0),
                        .I_PPU_WE_L(1),
                        .I_PPU_RE_L(1),
                        .I_RDMA_ADDR(rdma_addr),
                        .O_RDMA_DATA(rdma_data),
                        .I_RDMA_RE_L(rdma_re_l),
                        .I_WDMA_ADDR(wdma_addr),
                        .I_WDMA_WE_L(wdma_we_l),
                        .I_WDMA_DATA(wdma_data),
                        .O_WRAM_ADDR(wram_addr),
                        .IO_WRAM_DATA(wram_data),
                        .O_WRAM_WE_L(wram_we_l),
                        .O_WRAM_RE_L(wram_re_l),
                        .O_CARTRIDGE_ADDR(cartridge_addr),
                        .IO_CARTRIDGE_DATA(cartridge_data),
                        .O_CARTRIDGE_WE_L(cartridge_we_l),
                        .O_CARTRIDGE_RE_L(cartridge_re_l)
			.O_OAM_ADDR(oam_addr),
			.IO_OAM_DATA(oam_data),
			.O_OAM_WE_L(oam_we_l),
			.O_OAM_RE_L(oam_re_l)
			.O_LCDRAM_ADDR(lcdram_addr),
			.IO_LCDRAM_DATA(lcdram_data),
			.O_LCDRAM_WE_L(lcdram_we_l),
			.O_LCDRAM_RE_L(lcdram_re_l)
                        );


   io_bus_parser_reg #(`SC, 0)ioreg1(
                                     .I_CLK(clock_main),
                                     .I_SYNC_RESET(reset),
                                     .IO_DATA_BUS(iobus_data),
                                     .I_ADDR_BUS(iobus_addr),
                                     .I_WE_BUS_L(iobus_we_l),
                                     .I_RE_BUS_L(iobus_re_l),
                                     .O_DATA_READ(ioreg1_data)
                                     );
   
   io_bus_parser_reg #(`SB,0) ioreg2(
                                     .I_CLK(clock_main),
                                     .I_SYNC_RESET(reset),
                                     .IO_DATA_BUS(iobus_data),
                                     .I_ADDR_BUS(iobus_addr),
                                     .I_WE_BUS_L(iobus_we_l),
                                     .I_RE_BUS_L(iobus_re_l),
                                     .O_DATA_READ(ioreg2_data)
                                     );
   
   
   working_memory_bank wram(
                            .I_CLK(clock_main),
			    .I_MEM_CLK(mem_clock),
                            .I_RESET(reset),
                            .I_IOREG_ADDR(iobus_addr),
                            .IO_IOREG_DATA(iobus_data),
                            .I_IOREG_WE_L(iobus_we_l),
                            .I_IOREG_RE_L(iobus_re_l),
                            .I_WRAM_ADDR(wram_addr),
                            .IO_WRAM_DATA(wram_data),
                            .I_WRAM_WE_L(wram_we_l),
                            .I_WRAM_RE_L(wram_re_l),
                            .I_IN_DMG_MODE(gb_mode)
                            );

   
   cartridge_sim cartsim(
                         .I_CLK(mem_clock),
                         .I_RESET(reset),
                         .I_CARTRIDGE_ADDR(cartridge_addr),
                         .IO_CARTRIDGE_DATA(cartridge_data),
                         .I_CARTRIDGE_WE_L(cartridge_we_l),
                         .I_CARTRIDGE_RE_L(cartridge_re_l)
                         );
   

   oamram_test oam(
		   .I_MEM_CLK(mem_clock),
		   .I_RESET(reset),
		   .I_OAM_ADDR(oam_addr),
		   .IO_OAM_DATA(oam_data),
		   .I_OAM_WE_L(oam_we_l),
		   .I_OAM_RE_L(oam_re_l)
		   );

   
   lcdram_test lcdram(
		      .I_MEM_CLK(mem_clock),
		      .I_RESET(reset),
		      .I_LCDRAM_ADDR(lcdram_addr),
		      .IO_LCDRAM_DATA(lcdram_data),
		      .I_LCDRAM_WE_L(lcdram_we_l),
		      .I_LCDRAM_RE_L(lcdram_re_l)
		      );
   
endmodule

module my_clock_divider(
                        // Outputs
                        clock_out,
                        // Inputs
                        clock_in
                        );
   
   parameter
     DIV_SIZE = 15,
       DIV_OVER_TWO = 24000;
   
   
   output reg clock_out = 0;
   
   input wire clock_in;
   
   reg [DIV_SIZE-1:0] counter=0;
   
   always @(posedge clock_in) begin
      if (counter == DIV_OVER_TWO-1) begin
         clock_out <= ~clock_out;
         counter <= 0;
      end
      else
        counter <= counter + 1;
   end
   
endmodule
*/
