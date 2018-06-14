`include "../../memory/memory_router/memdef.vh"

module gameboycolorsim();
   reg      clock, clock33, clock27, clock12, reset;
   reg[7:0] LED;
   
   wire     latch, pulse, data;

   wire [15:0]  flash_d;
   wire [23:0]  flash_a;
   wire         flash_clk, flash_adv_n, flash_ce_n, flash_oe_n, flash_we_n;

   wire [11:0]  dvi_d;
   wire         dvi_vs, dvi_hs, dvi_xclk_p, dvi_xclk_n, dvi_de, dvi_reset_b, dvi_sda, dvi_scl;

   wire         ac97_sdata_in, pos1, pos2, ac97_sdata_out, ac97_sync, ac97_reset_b;

   assign latch = 0;
   assign pulse = 0;
   assign data = 0;

   assign ac97_sdata_in = 0;
   assign pos1 = 0;
   assign pos2 = 0;



   integer count;

   always
     #1 clock = ~clock;

   initial begin
      clock = 0;
      clock33 = 0;
      clock27 = 0;
      clock12 = 0;
      reset = 0;
      count = 0;
      @(posedge clock);
      reset = 1;
      @(posedge clock);
      reset = 0;
      @(posedge clock);
      reset = 1;

      while (count < 50) begin
         count = count + 1;
         if(count % 3)
            clock33 = ~clock33;
         if(count % 4)
            clock27 = ~clock27;
         if(count % 5)
           clock12 = ~clock12;
         @(posedge clock);
      end

      count = 0;
      reset = 0;

      while (1) begin
         count = count + 1;
         if(count % 3)
            clock33 = ~clock33;
         if(count % 4)
            clock27 = ~clock27;
         if(count % 5)
           clock12 = ~clock12;
         @(posedge clock);
      end

      @(posedge clock);

      #1 $finish;
   end
   gameboycolor #(0) gbc(
                      .CLK_33MHZ_FPGA(clock33), //base clock
                      .CLK_27MHZ_FPGA(clock27),
                      .USER_CLK(clock), // 100mhz clock for ppu

                      .GPIO_SW_W(reset), //reset
                      .GPIO_SW_E(0),

                      /*FPGA GPIO for Controller*/
                      .HDR2_2_SM_8_N(latch),
                      .HDR2_4_SM_8_P(pulse),
                      .HDR2_6_SM_7_N(data),

                      /*FPGA 28F256P30 Flash Controls*/
                      /*flash_d,
                      flash_a,
                      flash_clk,
                      flash_adv_n,
                      flash_ce_n,
                      flash_oe_n,
                      flash_we_n,*/

                      /*DVI inputs*/
                      .dvi_d(dvi_d),
                      .dvi_vs(dvi_vs),
                      .dvi_hs(dvi_hs),
                      .dvi_xclk_p(dvi_xclk_p),
                      .dvi_xclk_n(dvi_xclk_n),
                      .dvi_de(dvi_de),
                      .dvi_reset_b(dvi_reset_b),
                      .dvi_sda(dvi_sda),
                      .dvi_scl(dvi_scl),

                      /*FPGA AC97 Sound Module*/
                      .ac97_bitclk(clock12),
                      .ac97_sdata_in(ac97_sdata_in),
                      .pos1(pos1),
                      .pos2(pos2),
                      .ac97_sdata_out(ac97_sdata_out),
                      .ac97_sync(ac97_sync),
                      .ac97_reset_b(ac97_reset_b),
                      
                      /*To See multiple bytes of data*/
                      .GPIO_DIP_SW1(0),
                      .GPIO_DIP_SW2(0),
                      .GPIO_DIP_SW3(0),
                      .GPIO_DIP_SW4(0),
                      .GPIO_DIP_SW5(0),
                      .GPIO_DIP_SW6(0),
                      .GPIO_DIP_SW7(0),
                      .GPIO_DIP_SW8(0),

                      /*For Debugging*/
                      .GPIO_LED_0(LED[0]),
                      .GPIO_LED_1(LED[1]),
                      .GPIO_LED_2(LED[2]),
                      .GPIO_LED_3(LED[3]),
                      .GPIO_LED_4(LED[4]),
                      .GPIO_LED_5(LED[5]),
                      .GPIO_LED_6(LED[6]),
                      .GPIO_LED_7(LED[7])
                      );
endmodule
