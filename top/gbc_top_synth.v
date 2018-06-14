`include "../../memory/memory_router/memdef.vh"

`default_nettype none

  module gameboycolor(
                      CLK_33MHZ_FPGA, //base clock
                      CLK_27MHZ_FPGA,
                      USER_CLK, // 100mhz clock for ppu

                      GPIO_SW_W, //reset
                      GPIO_SW_E, //switch

                      /*FPGA GPIO for Controller*/
                      HDR2_2_SM_8_N,
                      HDR2_4_SM_8_P,
                      HDR2_6_SM_7_N,

                      /*FPGA GPIO for Serial*/
                      HDR2_58_SM_4_N,
                      HDR2_60_SM_4_P,
                      HDR2_62_SM_9_N,
                      HDR2_64_SM_9_P,

                      /*FPGA 28F256P30 Flash Controls*/
                      flash_d,
                      flash_a,
                      flash_clk,
                      flash_adv_n,
                      flash_ce_n,
                      flash_oe_n,
                      flash_we_n,

                      /*DVI inputs*/
                      dvi_d,
                      dvi_vs,
                      dvi_hs,
                      dvi_xclk_p,
                      dvi_xclk_n,
                      dvi_de,
                      dvi_reset_b,
                      dvi_sda,
                      dvi_scl,

                      /*FPGA AC97 Sound Module*/
                      ac97_bitclk,
                      ac97_sdata_in,
                      pos1, pos2,
                      ac97_sdata_out,
                      ac97_sync,
                      ac97_reset_b,

                      /*To See multiple bytes of data*/
                      GPIO_DIP_SW1,
                      GPIO_DIP_SW2,
                      GPIO_DIP_SW3,
                      GPIO_DIP_SW4,
                      GPIO_DIP_SW5,
                      GPIO_DIP_SW6,
                      GPIO_DIP_SW7,
                      GPIO_DIP_SW8,

                      /*For Debugging*/
                      GPIO_LED_0,
                      GPIO_LED_1,
                      GPIO_LED_2,
                      GPIO_LED_3,
                      GPIO_LED_4,
                      GPIO_LED_5,
                      GPIO_LED_6,
                      GPIO_LED_7
                      );
                     
   parameter SYNTH = 1;

   // ========================================
   // ========== Board I/O Setup =============
   // ========================================
   // General I/O
   input   GPIO_SW_W, GPIO_SW_E,
           CLK_33MHZ_FPGA, CLK_27MHZ_FPGA, USER_CLK,
           GPIO_DIP_SW1, GPIO_DIP_SW2, GPIO_DIP_SW3,
           GPIO_DIP_SW4, GPIO_DIP_SW5, GPIO_DIP_SW6,
           GPIO_DIP_SW7, GPIO_DIP_SW8;
   output  GPIO_LED_0,GPIO_LED_1,GPIO_LED_2,
           GPIO_LED_3,GPIO_LED_4,GPIO_LED_5,
           GPIO_LED_6,GPIO_LED_7;

   // Controller I/O
   input   HDR2_6_SM_7_N;
   output  HDR2_2_SM_8_N, HDR2_4_SM_8_P;

   // Serial I/O
   input     HDR2_58_SM_4_N, HDR2_60_SM_4_P;
   output    HDR2_62_SM_9_N, HDR2_64_SM_9_P;

   // Sound I/O        
   input   ac97_bitclk;
   input   ac97_sdata_in;
   input   pos1, pos2;
   output  ac97_sdata_out;
   output  ac97_sync;
   output  ac97_reset_b;

   // Flash I/O
   input  [15:0]  flash_d;
   output [23:0]  flash_a;
   output         flash_clk, flash_adv_n,
                  flash_ce_n, flash_oe_n, flash_we_n;

   // DVI I/O
   output [11:0]  dvi_d;
   output         dvi_vs, dvi_hs, dvi_xclk_p,
                  dvi_xclk_n, dvi_de, dvi_reset_b;
   inout          dvi_sda, dvi_scl;

   wire           clock, reset, synch_reset, push_button;
   wire [7:0]     I_DATA;
   wire [7:0]     O_DATA;

   wire     serial_external_clock, serial_internal_clock;
   wire     serial_in_data, serial_out_data;

   assign clock = CLK_33MHZ_FPGA;
   assign reset = GPIO_SW_W;

   assign push_button = GPIO_SW_E;

   assign GPIO_LED_7 = O_DATA[0];
   assign GPIO_LED_6 = O_DATA[1];
   assign GPIO_LED_5 = O_DATA[2];
   assign GPIO_LED_4 = O_DATA[3];
   assign GPIO_LED_3 = O_DATA[4];
   assign GPIO_LED_2 = O_DATA[5];
   assign GPIO_LED_1 = O_DATA[6];
   assign GPIO_LED_0 = O_DATA[7];

   assign I_DATA = {GPIO_DIP_SW1, GPIO_DIP_SW2, GPIO_DIP_SW3, GPIO_DIP_SW4,
                    GPIO_DIP_SW5, GPIO_DIP_SW6, GPIO_DIP_SW7, GPIO_DIP_SW8};

   assign serial_external_clock = HDR2_58_SM_4_N;
   assign serial_in_data = HDR2_60_SM_4_P;
   assign HDR2_62_SM_9_N = serial_internal_clock;
   assign HDR2_64_SM_9_P = serial_out_data;
   
   parameter num_ioregister = 16'h100;
   wire [7:0] register_data [0:num_ioregister-1];

   // ========================================
   // ============= CPU Setup ================
   // ========================================

   // Outputs
   wire [7:0]         F_data, A_data, instruction;
   wire [4:0]         IF_data, IE_data;
   wire [79:0]        regs_data;
   wire               cpu_mem_we_l, cpu_mem_re_l;

   // Inouts
   wire [15:0]        addr_ext;
   wire [7:0]         data_ext;

   // Inputs
   wire [4:0]         IF_in, IE_in;
   wire               IF_load, IE_load;
   wire               dma_cpu_halt;
   wire [15:0]        bp_addr;
   wire               bp_step, bp_continue;

   // Assigns
   assign       bp_addr = 16'hffff;
   assign       bp_step = 1'b0;
   assign       bp_continue = 1'b0;

   // ========================================
   // ============= PPU Setup ================
   // ========================================

   wire [7:0]         do_video;
   wire [1:0]         mode_video;
   wire               vblank_interrupt, lcdstat_interrupt;
   wire               vblank_ack, lcdstat_ack;
   wire               mem_enable_video;

   /*for the DMA unit*/
   wire is_hblank;
   assign is_hblank = (mode_video == 0);

   // ========================================
   // =========== Memory Setup ===============
   // ========================================
   wire               gb_mode;
   wire [15:0]        cpu_addr;
   wire [7:0]         iobus_data;
   wire [15:0]        iobus_addr;
   wire               iobus_we_l, iobus_re_l;

   wire [7:0]         wram_data;
   wire [15:0]        wram_addr;
   wire               wram_we_l, wram_re_l;

   wire [15:0]        rdma_addr, wdma_addr;
   wire [7:0]         rdma_data, wdma_data;
   wire               rdma_re_l, wdma_we_l;

   wire [7:0]         cartridge_data, lcdram_data;
   wire [15:0]        cartridge_addr, lcdram_addr;
   wire               cartridge_we_l, cartridge_re_l,
                      lcdram_we_l, lcdram_re_l;

   wire [7:0]         ioreg1_data, ioreg2_data;

   // Assigns
   assign gb_mode = 0;
   assign cpu_addr = addr_ext;

   // ========================================
   // ============ Clock Setup ===============
   // ========================================

   wire               clock_main, clock_main_double;
   wire               mem_clock;
	 wire               is_in_doublespeed_mode, controller_disable;
	
	clock_module clk_mod(
					        .I_CLK33MHZ(clock), 
					        .I_SYNC_RESET(synch_reset),
                       .I_DOUBLE_SPEED(I_DATA[0]),
					        .O_CLOCKMAIN(clock_main),
                       .O_CLOCKMAIN_DOUBLE(clock_main_double),
					        .O_MEM_CLOCK(mem_clock),
					        .I_IOREG_ADDR(iobus_addr),
					        .IO_IOREG_DATA(iobus_data),
					        .I_IOREG_WE_L(iobus_we_l),
					        .I_IOREG_RE_L(iobus_re_l),
					        .O_IS_IN_DOUBLE_SPEEDMODE(is_in_doublespeed_mode), 
					        .O_DISABLE_CONTROLLER(controller_disable)
					
					        /*for debugging*/
					       // .O_RP_DATA(register_data[8'h56])
					        );
  
   // ========================================
   // =========== Connections ================
   // ========================================

   wire     timer_interrupt, controller_interrupt, serial_interrupt;

   assign mem_enable_video = ~lcdram_we_l || ~lcdram_re_l;

   // ========================================
   // ============ Debugging =================
   // ========================================

   // reg [7:0]                              count;
   // reg [20:0]                             count2;
   // (* KEEP = "TRUE" *) reg [63:0]         cycle_count;
   wire [2:0]   current_game_select;
   
   assign O_DATA = (push_button) ? {I_DATA[7:5], 4'b0000, I_DATA[0]} : {current_game_select, 4'b0000, is_in_doublespeed_mode};
   //assign register_data[255] = count;

   // always @(posedge clock_main) begin
   //    count2 <= count2 + 1;
      
   //    // calculate T cycles
   //    if (count2[1:0] == 0) begin
   //       cycle_count <= cycle_count + 1;
   //    end

   //    if (count2 == 0)
   //       count <= count + 1;
   //    if (synch_reset) begin
   //       count <= 0;
   //       count2 <= 0;
   //       cycle_count <= 0;
   //    end
   // end

   // ========================================
   // ======== Module Instantiation ==========
   // ========================================

   /*we have it this way in case we need to do a more elaborate system reset
    *other than just pushing a button*/
   reset_controller rc(
         .I_CLK(clock_main),
         .I_ASYNC_RESET(reset),
         .O_SYNC_RESET(synch_reset)
         );

   cpu gbc_cpu(
               .mem_we_l(cpu_mem_we_l),
               .mem_re_l(cpu_mem_re_l),
               .IF_data(IF_data),
               .IE_data(IE_data),
               .addr_ext(addr_ext),
               .data_ext(data_ext),
               .IF_in(IF_in[4:0]),
               .IE_in(IE_in[4:0]),
               .IF_load(IF_load),
               .IE_load(IE_load),
               .cpu_mem_disable(dma_cpu_halt),
               .ext_halt(dma_cpu_halt),
               .bp_addr(bp_addr),
               .bp_step(bp_step),
               .bp_continue(bp_continue),
               .clock(clock_main),
               .reset(synch_reset)
               );

   /*PPU renders the graphics specifications by the CPU
    *and outputs them to the DVA interface*/
   gpu_top ppu(
               //MMU Outputs
               .do_video(do_video),
               .mode_video(mode_video),
               // 0: Vblank 1: LCDC
               .int_req({lcdstat_interrupt,vblank_interrupt}),
               .dvi_d(dvi_d),
               .dvi_vs(dvi_vs),
               .dvi_hs(dvi_hs),
               .dvi_xclk_p(dvi_xclk_p),
               .dvi_xclk_n(dvi_xclk_n),
               .dvi_de(dvi_de),
               .dvi_reset_b(dvi_reset_b),
               //Inouts
               .dvi_sda(dvi_sda),
               .dvi_scl(dvi_scl),
               //Inputs
               .clk27(CLK_27MHZ_FPGA),
               .clk33(CLK_33MHZ_FPGA),
               .clk100(USER_CLK),
               .clk_cpu(clock_main),
               .top_rst_b(~synch_reset),
               //MMU Inputs
               .mem_enable_video(mem_enable_video),
               .rd_n_video(lcdram_re_l),
               .wr_n_video(lcdram_we_l),
               .A_video(lcdram_addr),
               .di_video(lcdram_data),
               .int_ack({lcdstat_ack,vblank_ack})
               );


   /*DMA controlls the data tranfers requested by
    *the cpu.  The DMA internals has 3 different
    *DMA types: OAM DMA, General DMA, and HBLANK
    *DMA */
   dma_controller dma(
                      .I_CLK(clock_main),
                      .I_DMA_CLK(clock_main_double),
                      .I_SYNC_RESET(synch_reset),
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
                      .I_HBLANK(is_hblank),
                      .O_HALT_CPU(dma_cpu_halt),
                      .O_DMA_DATA(register_data[16'h46]),
                      .O_HDMA1_DATA(register_data[16'h51]), 
                      .O_HDMA2_DATA(register_data[16'h52]), 
                      .O_HDMA3_DATA(register_data[16'h53]), 
                      .O_HDMA4_DATA(register_data[16'h54]), 
                      .O_HDMA5_DATA(register_data[16'h55])
                      );


   /*Memory Router is the central hub of all the information passing
    *through the system.  It is mostly controlled by the CPU master
    *interface in which the other slave interfaces will feed data to
    *the CPU.  Morover, it also provides access for routing DAM transfers*/
   memory_router router(
                        .I_CLK(clock_main),
                        .I_RESET(synch_reset),
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
                        .O_CARTRIDGE_RE_L(cartridge_re_l),
                        .O_LCDRAM_ADDR(lcdram_addr),
                        .I_LCDRAM_DATA(do_video),
                        .O_LCDRAM_DATA(lcdram_data),
                        .O_LCDRAM_WE_L(lcdram_we_l),
                        .O_LCDRAM_RE_L(lcdram_re_l)
                        );

   /*Working memory bank is just logic surrounding block RAM
    *that enables banking linearly offset banking*/
   working_memory_bank wram(
                            .I_CLK(clock_main),
                            .I_MEM_CLK(mem_clock),
                            .I_RESET(synch_reset),
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

   /*Cartsim contains the hardware specification according
    *to MBC3.  If ROM access then flash data is read,
    *else if RAM or timer access is used, BRAM or internal
    *FPGA logic is used.  The parameter set to 0 will
    *load from BRAM instead of flash to more easily.*/
   cartridge_sim #(SYNTH, 2'd2) cartsim(
                       .I_CLK(mem_clock),
                       .I_CLK_33MHZ(CLK_33MHZ_FPGA),
                       .I_RESET(synch_reset),
                       .I_GAME_SELECT(I_DATA[7:5]),
                       .O_GAME_SELECT(current_game_select),
                       .I_CARTRIDGE_ADDR(cartridge_addr),
                       .IO_CARTRIDGE_DATA(cartridge_data),
                       .I_CARTRIDGE_WE_L(cartridge_we_l),
                       .I_CARTRIDGE_RE_L(cartridge_re_l),
                       .I_FLASH_DATA(flash_d),
                       .O_FLASH_ADDR(flash_a),
                       .O_FLASH_CLK(flash_clk),
                       .O_ADDR_VALID_L(flash_adv_n),
                       .O_FLASH_CE_L(flash_ce_n),
                       .O_FLASH_OE_L(flash_oe_n),
                       .O_FLASH_WE_L(flash_we_n)
                       );

   interrupt Interrupt(
                       .I_CLOCK(clock_main),
                       .I_RESET(synch_reset),
                       .I_VBLANK_INTERRUPT(vblank_interrupt),
                       .I_LCDSTAT_INTERRUPT(lcdstat_interrupt),
                       .I_TIMER_INTERRUPT(timer_interrupt),
                       .I_SERIAL_INTERRUPT(serial_interrupt),
                       .I_JOYPAD_INTERRUPT(controller_interrupt),

                       .I_MEM_WE_L(iobus_we_l),
                       .I_MEM_RE_L(iobus_re_l),
                       .I_CPU_ADDR(iobus_addr),
                       .IO_CPU_DATA(iobus_data),

                       .I_IF_DATA(IF_data),
                       .I_IE_DATA(IE_data),
                       .O_IF(IF_in),
                       .O_IE(IE_in),
                       .O_IF_LOAD(IF_load),
                       .O_IE_LOAD(IE_load),
                       .O_VBLANK_ACK(vblank_ack),
                       .O_LCDSTAT_ACK(lcdstat_ack)
                       );

   timer_module Timer(
                      .O_TIMER_INTERRUPT(timer_interrupt),
                      .I_CLOCK(clock_main),
                      .I_RESET(synch_reset),
                      .I_ADDR(iobus_addr),
                      .I_RE_L(iobus_re_l),
                      .I_WE_L(iobus_we_l),
                      .IO_DATA(iobus_data),
                      .O_DIV_DATA(register_data[4]), 
                      .O_TIMA_DATA(register_data[5]), 
                      .O_TMA_DATA(register_data[6]), 
                      .O_TAC_DATA(register_data[7])
                      );


   /*Controller makes an interface with the CPU with the handheld,
    *SNES controller.  It converts the interface to one that the
    *CPU expects.  If the controller is not connected, then set
    * the parameter to 0 so it does not continuously reset the 
    * system.*/
   controller Controller(
                        .I_CLK(clock_main),
                        .I_CLK_33MHZ(CLK_33MHZ_FPGA),
                        .I_RESET(synch_reset),
                        .I_IOREG_ADDR(iobus_addr),
                        .IO_IOREG_DATA(iobus_data),
                        .I_IOREG_WE_L(iobus_we_l),
                        .I_IOREG_RE_L(iobus_re_l),
                        .O_CONTROLLER_LATCH(HDR2_2_SM_8_N),
                        .O_CONTROLLER_PULSE(HDR2_4_SM_8_P),
                        .I_CONTROLLER_DATA(HDR2_6_SM_7_N),
                        .O_CONTROLLER_INTERRUPT(controller_interrupt),
                        .O_P1_DATA(register_data[0])
                        );

   serial Serial(
      .I_CLK(clock_main),
      .I_RESET(synch_reset),
      .I_ADDR_BUS(iobus_addr),
      .IO_DATA_BUS(iobus_data),
      .I_WE_BUS_L(iobus_we_l),
      .I_RE_BUS_L(iobus_re_l),
      .O_SERIAL_INTERRUPT(serial_interrupt),

      .I_EXTERNAL_CLOCK(serial_external_clock),
      .O_SERIAL_CLOCK(serial_internal_clock),
      .I_SERIAL_DATA(serial_in_data),
      .O_SERIAL_DATA(serial_out_data)
      );

   /*The AC97 write to the sound output, and within this module is the
    *sound top level module that contains the four sound channels*/
   AC97 sound(
             .ac97_bitclk(ac97_bitclk),
             .ac97_sdata_in(ac97_sdata_in),
             .pos1(pos1), .pos2(pos2),
             .ac97_sdata_out(ac97_sdata_out),
             .ac97_sync(ac97_sync),
             .ac97_reset_b(ac97_reset_b),
             .I_CLK(clock_main),
             .I_CLK33MHZ(CLK_33MHZ_FPGA),
             .I_RESET(synch_reset),
             .I_IOREG_ADDR(iobus_addr),
             .IO_IOREG_DATA(iobus_data),
             .I_IOREG_WE_L(iobus_we_l),
             .I_IOREG_RE_L(iobus_re_l),
              
             // for debugging
             .O_NR10_DATA(register_data[8'h10]), 
             .O_NR11_DATA(register_data[8'h11]), 
             .O_NR12_DATA(register_data[8'h12]),
             .O_NR13_DATA(register_data[8'h13]), 
             .O_NR14_DATA(register_data[8'h14]),
             .O_NR21_DATA(register_data[8'h16]),
             .O_NR22_DATA(register_data[8'h17]),
             .O_NR23_DATA(register_data[8'h18]), 
             .O_NR24_DATA(register_data[8'h19]),
             .O_NR30_DATA(register_data[8'h1A]), 
             .O_NR31_DATA(register_data[8'h1B]), 
             .O_NR32_DATA(register_data[8'h1C]), 
             .O_NR33_DATA(register_data[8'h1D]), 
             .O_NR34_DATA(register_data[8'h1E]),
                     
             .O_WF0(register_data[8'h30]), 
             .O_WF1(register_data[8'h31]), 
             .O_WF2(register_data[8'h32]), 
             .O_WF3(register_data[8'h33]), 
             .O_WF4(register_data[8'h34]), 
             .O_WF5(register_data[8'h35]), 
             .O_WF6(register_data[8'h36]), 
             .O_WF7(register_data[8'h37]),
             .O_WF8(register_data[8'h38]), 
             .O_WF9(register_data[8'h39]), 
             .O_WF10(register_data[8'h3A]), 
             .O_WF11(register_data[8'h3B]), 
             .O_WF12(register_data[8'h3C]), 
             .O_WF13(register_data[8'h3D]), 
             .O_WF14(register_data[8'h3E]), 
             .O_WF15(register_data[8'h3F]),
                     
             .O_NR41_DATA(register_data[8'h20]), 
             .O_NR42_DATA(register_data[8'h21]), 
             .O_NR43_DATA(register_data[8'h22]), 
             .O_NR44_DATA(register_data[8'h23]),
             .O_NR50_DATA(register_data[8'h24]), 
             .O_NR51_DATA(register_data[8'h25]), 
             .O_NR52_DATA(register_data[8'h26])
             );

   /*Registers that are unused, but need to still be implemented, 
   *they can also be used for debugging when running custom
   *made programs*/

   io_bus_parser_reg #(`RP,8'hFD) ioregRP(
                                     .I_CLK(clock_main),
                                     .I_SYNC_RESET(synch_reset),
                                     .IO_DATA_BUS(iobus_data),
                                     .I_ADDR_BUS(iobus_addr),
                                     .I_WE_BUS_L(iobus_we_l),
                                     .I_RE_BUS_L(iobus_re_l),
                                     .O_DATA_READ(register_data[8'h56])
                                     );
              
              
   /*undocumented gameboy color registers*/    
   io_bus_parser_reg #(16'hFF6C,8'hFE,0,0,0) ioreg_unused_1(
                                  .I_CLK(clock_main),
                                  .I_SYNC_RESET(synch_reset),
                                  .IO_DATA_BUS(iobus_data),
                                  .I_ADDR_BUS(iobus_addr),
                                  .I_WE_BUS_L(iobus_we_l),
                                  .I_RE_BUS_L(iobus_re_l),
                                  .O_DATA_READ(register_data[8'h6C])
                                  );
                                  
   io_bus_parser_reg #(16'hFF72,8'h00,0,0,0) ioreg_unused_2(
                                  .I_CLK(clock_main),
                                  .I_SYNC_RESET(synch_reset),
                                  .IO_DATA_BUS(iobus_data),
                                  .I_ADDR_BUS(iobus_addr),
                                  .I_WE_BUS_L(iobus_we_l),
                                  .I_RE_BUS_L(iobus_re_l),
                                  .O_DATA_READ(register_data[8'h72])
                                  );
                                  
   io_bus_parser_reg #(16'hFF73,8'h00,0,0,0) ioreg_unused_3(
                                  .I_CLK(clock_main),
                                  .I_SYNC_RESET(synch_reset),
                                  .IO_DATA_BUS(iobus_data),
                                  .I_ADDR_BUS(iobus_addr),
                                  .I_WE_BUS_L(iobus_we_l),
                                  .I_RE_BUS_L(iobus_re_l),
                                  .O_DATA_READ(register_data[8'h73])
                                  );
                                  
   io_bus_parser_reg #(16'hFF74,8'h00,0,0,0) ioreg_unused_4(
                                  .I_CLK(clock_main),
                                  .I_SYNC_RESET(synch_reset),
                                  .IO_DATA_BUS(iobus_data),
                                  .I_ADDR_BUS(iobus_addr),
                                  .I_WE_BUS_L(iobus_we_l),
                                  .I_RE_BUS_L(iobus_re_l),
                                  .O_DATA_READ(register_data[8'h74])
                                  );
                                  
   io_bus_parser_reg #(16'hFF75,8'h8F,0,0,0) ioreg_unused_5(
                                  .I_CLK(clock_main),
                                  .I_SYNC_RESET(synch_reset),
                                  .IO_DATA_BUS(iobus_data),
                                  .I_ADDR_BUS(iobus_addr),
                                  .I_WE_BUS_L(iobus_we_l),
                                  .I_RE_BUS_L(iobus_re_l),
                                  .O_DATA_READ(register_data[8'h75])
                                  );
                                  
   io_bus_parser_reg #(16'hFF76,8'h00,0,0,'b10) ioreg_unused_6( //read only
                                  .I_CLK(clock_main),
                                  .I_SYNC_RESET(synch_reset),
                                  .IO_DATA_BUS(iobus_data),
                                  .I_ADDR_BUS(iobus_addr),
                                  .I_WE_BUS_L(iobus_we_l),
                                  .I_RE_BUS_L(iobus_re_l),
                                  .O_DATA_READ(register_data[8'h76])
                                  );
                                  
   io_bus_parser_reg #(16'hFF77,8'h00,0,0,'b10) ioreg_unused_7( //read only
                                  .I_CLK(clock_main),
                                  .I_SYNC_RESET(synch_reset),
                                  .IO_DATA_BUS(iobus_data),
                                  .I_ADDR_BUS(iobus_addr),
                                  .I_WE_BUS_L(iobus_we_l),
                                  .I_RE_BUS_L(iobus_re_l),
                                  .O_DATA_READ(register_data[8'h77])
                                  );

endmodule // gameboycolor


