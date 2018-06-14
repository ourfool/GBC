`include "../../memory/memory_router/memdef.vh"
`default_nettype none

module sound_controller(

			/*System Level Inputs*/
			I_CLK,
			I_CLK_33MHZ,
			I_RESET,

			/*Interface with ac97*/
			I_BITCLK,
			I_STROBE,
			O_SO1,
			O_SO2,

			/*Interface with the CPU*/
			I_IOREG_ADDR,
			IO_IOREG_DATA,
			I_IOREG_RE_L,
			I_IOREG_WE_L, 
            
            /*for debugging*/
            O_NR10_DATA, O_NR11_DATA, O_NR12_DATA, O_NR13_DATA, O_NR14_DATA,
            O_NR21_DATA, O_NR22_DATA, O_NR23_DATA, O_NR24_DATA,
            O_NR30_DATA, O_NR31_DATA, O_NR32_DATA, O_NR33_DATA, O_NR34_DATA,
                     
            O_WF0, O_WF1, O_WF2, O_WF3, O_WF4, O_WF5, O_WF6, O_WF7,
            O_WF8, O_WF9, O_WF10, O_WF11, O_WF12, O_WF13, O_WF14, O_WF15,
                     
            O_NR41_DATA, O_NR42_DATA, O_NR43_DATA, O_NR44_DATA,
            O_NR50_DATA, O_NR51_DATA, O_NR52_DATA
           );

   input         I_CLK, I_CLK_33MHZ, I_RESET;
   input 	 I_BITCLK, I_STROBE;
   output [19:0] O_SO1, O_SO2;
   input [15:0]  I_IOREG_ADDR;
   inout [7:0] 	 IO_IOREG_DATA;
   input 	 I_IOREG_WE_L, I_IOREG_RE_L;
   
   output [7:0] O_NR10_DATA, O_NR11_DATA, O_NR12_DATA, O_NR13_DATA, O_NR14_DATA,
                     O_NR21_DATA, O_NR22_DATA, O_NR23_DATA, O_NR24_DATA,
                     O_NR30_DATA, O_NR31_DATA, O_NR32_DATA, O_NR33_DATA, O_NR34_DATA,
                     
                     O_WF0, O_WF1, O_WF2, O_WF3, O_WF4, O_WF5, O_WF6, O_WF7,
                     O_WF8, O_WF9, O_WF10, O_WF11, O_WF12, O_WF13, O_WF14, O_WF15,
                     
                     O_NR41_DATA, O_NR42_DATA, O_NR43_DATA, O_NR44_DATA,
                     O_NR50_DATA, O_NR51_DATA, O_NR52_DATA;

   wire [7:0] 	 gnd8 = 0;
   
   wire [7:0] 	 nr50_data, nr51_data, nr52_data;
   wire 	 new_nr50, new_nr51, new_nr52;
   wire [7:0]   	 nr52_write_data;
   
   assign O_NR50_DATA = nr50_data;
   assign O_NR51_DATA = nr51_data;
   assign O_NR52_DATA = {nr52_data[7], 3'b0, nr52_write_data[3:0]};
   
   /*Top Level Controll parameter Registers*/
   io_bus_parser_reg #(`NR50,0,0,0,0) nr50(.I_CLK(I_CLK),
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr50_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr50)
                                           );
   io_bus_parser_reg #(`NR51,0,0,0,0) nr51(.I_CLK(I_CLK),
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr51_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr51)
                                           );

   /*Reading and writing for nr52 does different things*/

   /*write only register*/
   io_bus_parser_reg #(`NR52,0,0,0,'b01) nr52_wr(.I_CLK(I_CLK),
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr52_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr52)
                                           );

   /*read only register*/
   io_bus_parser_reg #(`NR52,0,1,0,'b10) nr52_re(.I_CLK(I_CLK),
                                              .I_SYNC_RESET(I_RESET),
                                              .IO_DATA_BUS(IO_IOREG_DATA),
                                              .I_ADDR_BUS(I_IOREG_ADDR),
                                              .I_WE_BUS_L(I_IOREG_WE_L),
                                              .I_RE_BUS_L(I_IOREG_RE_L),
                                              .I_DATA_WR(nr52_write_data),
                                              .I_REG_WR_EN(1) //always forward
                                              );
   
   wire 	 output_so1, output_so2;
   wire [2:0] 	 so1_volume, so2_volume;
   assign output_so1 = nr50_data[3]; //won't be implemented
   assign so1_volume = nr50_data[2:0]; //won't be implemented
   assign output_so2 = nr50_data[7];   //won't be implemented
   assign so2_volume = nr50_data[6:4]; //won't be implemented

   wire 	 ch4_so2_out, ch3_so2_out, ch2_so2_out, ch1_so2_out;
   wire 	 ch4_so1_out, ch3_so1_out, ch2_so1_out, ch1_so1_out;
   assign ch4_so2_out = nr51_data[7];
   assign ch3_so2_out = nr51_data[6];
   assign ch2_so2_out = nr51_data[5];
   assign ch1_so2_out = nr51_data[4];
   assign ch4_so1_out = nr51_data[3];
   assign ch3_so1_out = nr51_data[2];
   assign ch2_so1_out = nr51_data[1];
   assign ch1_so1_out = nr51_data[0];
   
   wire 	 enable_all_sound;
   wire 	 sound1_on, sound2_on, sound3_on, sound4_on;
   assign enable_all_sound = nr52_data[7];
   assign nr52_write_data[3] = sound4_on;
   assign nr52_write_data[2] = sound3_on;
   assign nr52_write_data[1] = sound2_on;
   assign nr52_write_data[0] = sound1_on;
   assign nr52_write_data[7] = enable_all_sound;

   wire [19:0] 	 sc1_sample, sc2_sample, sc3_sample, sc4_sample;

   wire [19:0] 	 sc1_so2_sample, sc2_so2_sample, sc3_so2_sample, sc4_so2_sample;
   wire [19:0] 	 sc1_so1_sample, sc2_so1_sample, sc3_so1_sample, sc4_so1_sample;

   /*enable the different components of the output waveforms
    * divide each signal by 4 so total sum is max possible
    * loudness*/
   assign sc1_so1_sample = (ch1_so1_out) ? sc1_sample : 0;
   assign sc2_so1_sample = (ch2_so1_out) ? sc2_sample : 0;
   assign sc3_so1_sample = (ch3_so1_out) ? sc3_sample : 0;
   assign sc4_so1_sample = (ch4_so1_out) ? sc4_sample : 0;
   assign sc1_so2_sample = (ch1_so2_out) ? sc1_sample : 0;
   assign sc2_so2_sample = (ch2_so2_out) ? sc2_sample : 0;
   assign sc3_so2_sample = (ch3_so2_out) ? sc3_sample : 0;
   assign sc4_so2_sample = (ch4_so2_out) ? sc4_sample : 0;

   /* add all te channels together*/
   wire [19:0] 	 so1_total, so2_total;
   assign so1_total = sc1_so1_sample + sc2_so1_sample + sc3_so1_sample + sc4_so1_sample;
   assign so2_total = sc1_so2_sample + sc2_so2_sample + sc3_so2_sample + sc4_so2_sample;

   assign O_SO1 = (enable_all_sound) ? so1_total : 0;
   assign O_SO2 = (enable_all_sound) ? so2_total : 0;
   
   /* Implement the Sound Channels*/
   sound_channel1 sc1(
                      .I_CLK(I_CLK),
                      .I_CLK33MHZ(I_CLK_33MHZ),
                      .I_RESET(I_RESET),
                      .I_BITCLK(I_BITCLK),
                      .I_STROBE(I_STROBE),
                      .I_IOREG_ADDR(I_IOREG_ADDR),
                      .IO_IOREG_DATA(IO_IOREG_DATA),
                      .I_IOREG_WE_L(I_IOREG_WE_L),
                      .I_IOREG_RE_L(I_IOREG_RE_L),
		              .O_CH1_ON(sound1_on),
                      .O_CH1_WAVEFORM(sc1_sample), 
                      
                      /*for debugging*/
                      .O_NR10_DATA(O_NR10_DATA),
                      .O_NR11_DATA(O_NR11_DATA), 
                      .O_NR12_DATA(O_NR12_DATA), 
                      .O_NR13_DATA(O_NR13_DATA), 
                      .O_NR14_DATA(O_NR14_DATA)
                      );

   sound_channel2 sc2(
                      .I_CLK(I_CLK),
                      .I_CLK_33MHZ(I_CLK_33MHZ),
                      .I_RESET(I_RESET),
                      .I_BITCLK(I_BITCLK),
                      .I_STROBE(I_STROBE),
                      .I_IOREG_ADDR(I_IOREG_ADDR),
                      .IO_IOREG_DATA(IO_IOREG_DATA),
                      .I_IOREG_WE_L(I_IOREG_WE_L),
                      .I_IOREG_RE_L(I_IOREG_RE_L),
		              .O_CH2_ON(sound2_on),
                      .O_CH2_WAVEFORM(sc2_sample), 
                      
                      /*for debugging*/
                      .O_NR21_DATA(O_NR21_DATA), 
                      .O_NR22_DATA(O_NR22_DATA),
                      .O_NR23_DATA(O_NR23_DATA),
                      .O_NR24_DATA(O_NR24_DATA)
                      );
   
   sound_channel3 sc3(
                      .I_CLK(I_CLK),
                      .I_CLK_33MHZ(I_CLK_33MHZ),
                      .I_RESET(I_RESET),
                      .I_BITCLK(I_BITCLK),
                      .I_STROBE(I_STROBE),
                      .I_IOREG_ADDR(I_IOREG_ADDR),
                      .IO_IOREG_DATA(IO_IOREG_DATA),
                      .I_IOREG_WE_L(I_IOREG_WE_L),
                      .I_IOREG_RE_L(I_IOREG_RE_L),
		              .O_CH3_ON(sound3_on),
                      .O_CH3_WAVEFORM(sc3_sample),
                      
                      /*for debugging*/
                      .O_NR30_DATA(O_NR30_DATA),
                      .O_NR31_DATA(O_NR31_DATA), 
                      .O_NR32_DATA(O_NR32_DATA), 
                      .O_NR33_DATA(O_NR33_DATA), 
                      .O_NR34_DATA(O_NR34_DATA),
                     
                      .O_WF0(O_WF0), 
                      .O_WF1(O_WF1), 
                      .O_WF2(O_WF2), 
                      .O_WF3(O_WF3), 
                      .O_WF4(O_WF4), 
                      .O_WF5(O_WF5), 
                      .O_WF6(O_WF6), 
                      .O_WF7(O_WF7),
                      .O_WF8(O_WF8), 
                      .O_WF9(O_WF9), 
                      .O_WF10(O_WF10), 
                      .O_WF11(O_WF11), 
                      .O_WF12(O_WF12), 
                      .O_WF13(O_WF13), 
                      .O_WF14(O_WF14), 
                      .O_WF15(O_WF15)
                      );
   
   sound_channel4 sc4(
                      .I_CLK(I_CLK),
                      .I_CLK_33MHZ(I_CLK_33MHZ),
                      .I_RESET(I_RESET),
                      .I_BITCLK(I_BITCLK),
                      .I_STROBE(I_STROBE),
                      .I_IOREG_ADDR(I_IOREG_ADDR),
                      .IO_IOREG_DATA(IO_IOREG_DATA),
                      .I_IOREG_WE_L(I_IOREG_WE_L),
                      .I_IOREG_RE_L(I_IOREG_RE_L),
		              .O_CH4_ON(sound4_on),
                      .O_CH4_WAVEFORM(sc4_sample),
                      .O_NR41_DATA(O_NR41_DATA), 
                      .O_NR42_DATA(O_NR42_DATA), 
                      .O_NR43_DATA(O_NR43_DATA), 
                      .O_NR44_DATA(O_NR44_DATA)
                      
                      );
   
endmodule   
   
			