`include "../../memory/memory_router/memdef.vh"
`define CLOCKS256    128906
`define CLOCKS64     515625

`default_nettype none

module sound_channel3(
                      /* System Level Inputs*/
                      I_CLK,
                      I_CLK_33MHZ,
                      I_RESET,

		              /*Interface with ac97*/
		              I_BITCLK,
		              I_STROBE,
		      
                      /*IO Register Bus*/
                      I_IOREG_ADDR,
                      IO_IOREG_DATA,
                      I_IOREG_WE_L,
                      I_IOREG_RE_L,

		             /*Sound Status Signal*/
		              O_CH3_ON,

                      /*Output Waveform*/
                      O_CH3_WAVEFORM,
                      
                      /*for debugging*/
                      O_NR30_DATA, O_NR31_DATA, O_NR32_DATA, O_NR33_DATA, O_NR34_DATA,
                     
                      O_WF0, O_WF1, O_WF2, O_WF3, O_WF4, O_WF5, O_WF6, O_WF7,
                      O_WF8, O_WF9, O_WF10, O_WF11, O_WF12, O_WF13, O_WF14, O_WF15
                      );

   input        I_CLK, I_CLK_33MHZ, I_RESET;
   input 	I_BITCLK, I_STROBE;
   input [15:0] I_IOREG_ADDR;
   inout [7:0]  IO_IOREG_DATA;
   input        I_IOREG_WE_L, I_IOREG_RE_L;
   output reg [19:0] O_CH3_WAVEFORM;
   output 	 O_CH3_ON;
   output [7:0] O_NR30_DATA, O_NR31_DATA, O_NR32_DATA, O_NR33_DATA, O_NR34_DATA,
                     O_WF0, O_WF1, O_WF2, O_WF3, O_WF4, O_WF5, O_WF6, O_WF7,
                     O_WF8, O_WF9, O_WF10, O_WF11, O_WF12, O_WF13, O_WF14, O_WF15;

   wire [7:0]   nr30_data, nr31_data, nr32_data, nr33_data, nr34_data;
   wire         new_nr30, new_nr31, new_nr32, new_nr33, new_nr34;
   
   assign O_NR30_DATA = nr30_data;
   assign O_NR31_DATA = nr31_data;
   assign O_NR32_DATA = nr32_data;
   assign O_NR33_DATA=  nr33_data;
   assign O_NR34_DATA = nr34_data;

   /*Sound Module 3 Control Registers*/
   io_bus_parser_reg #(`NR30,0,0,0,0) nr30(.I_CLK(I_CLK),
                                       .I_SYNC_RESET(I_RESET),
                                       .IO_DATA_BUS(IO_IOREG_DATA),
                                       .I_ADDR_BUS(I_IOREG_ADDR),
                                       .I_WE_BUS_L(I_IOREG_WE_L),
                                       .I_RE_BUS_L(I_IOREG_RE_L),
                                       .I_DATA_WR(0),
                                       .O_DATA_READ(nr30_data),
                                       .I_REG_WR_EN(0),
                                       .O_DBUS_WRITE(new_nr30));
   io_bus_parser_reg #(`NR31,0,0,0,0) nr31(.I_CLK(I_CLK),
                                       .I_SYNC_RESET(I_RESET),
                                       .IO_DATA_BUS(IO_IOREG_DATA),
                                       .I_ADDR_BUS(I_IOREG_ADDR),
                                       .I_WE_BUS_L(I_IOREG_WE_L),
                                       .I_RE_BUS_L(I_IOREG_RE_L),
                                       .I_DATA_WR(0),
                                       .O_DATA_READ(nr31_data),
                                       .I_REG_WR_EN(0),
                                       .O_DBUS_WRITE(new_nr31));
   io_bus_parser_reg #(`NR32,0,0,0,0) nr32(.I_CLK(I_CLK),
                                       .I_SYNC_RESET(I_RESET),
                                       .IO_DATA_BUS(IO_IOREG_DATA),
                                       .I_ADDR_BUS(I_IOREG_ADDR),
                                       .I_WE_BUS_L(I_IOREG_WE_L),
                                       .I_RE_BUS_L(I_IOREG_RE_L),
                                       .I_DATA_WR(0),
                                       .O_DATA_READ(nr32_data),
                                       .I_REG_WR_EN(0),
                                       .O_DBUS_WRITE(new_nr32));
   io_bus_parser_reg #(`NR33,0,0,0,'b01) nr33(.I_CLK(I_CLK), //write only
                                       .I_SYNC_RESET(I_RESET),
                                       .IO_DATA_BUS(IO_IOREG_DATA),
                                       .I_ADDR_BUS(I_IOREG_ADDR),
                                       .I_WE_BUS_L(I_IOREG_WE_L),
                                       .I_RE_BUS_L(I_IOREG_RE_L),
                                       .I_DATA_WR(0),
                                       .O_DATA_READ(nr33_data),
                                       .I_REG_WR_EN(0),
                                       .O_DBUS_WRITE(new_nr33));
   io_bus_parser_reg #(`NR34,0,0,0,0) nr44(.I_CLK(I_CLK),
                                       .I_SYNC_RESET(I_RESET),
                                       .IO_DATA_BUS(IO_IOREG_DATA),
                                       .I_ADDR_BUS(I_IOREG_ADDR),
                                       .I_WE_BUS_L(I_IOREG_WE_L),
                                       .I_RE_BUS_L(I_IOREG_RE_L),
                                       .I_DATA_WR(0),
                                       .O_DATA_READ(nr34_data),
                                       .I_REG_WR_EN(0),
                                       .O_DBUS_WRITE(new_nr34));

   /*extract data according to module specification*/
   wire         enable_sound;
   assign enable_sound = nr30_data[7];
   wire [31:0]  sound_length_clocks;
   assign sound_length_clocks = (256 - nr31_data) * `CLOCKS256;
   wire [1:0]   output_level_select;
   assign output_level_select = nr32_data[6:5];
   wire [10:0]  frequency;
   assign frequency = {nr34_data[2:0], nr33_data};
   wire         stop_output;
   assign stop_output = nr34_data[6];
   wire         restart_sound;
   assign restart_sound = nr34_data[7] & new_nr34;

   /*Implement Waveform RAM CPU interface*/
   reg [7:0]    waveform_ram[0:15];
   wire         enable_ioreg_data;
   wire         waveform_ram_access;
   
   assign O_WF0 = waveform_ram[0];
   assign O_WF1 = waveform_ram[1];
   assign O_WF2 = waveform_ram[2];
   assign O_WF3 = waveform_ram[3];
   assign O_WF4 = waveform_ram[4];
   assign O_WF5 = waveform_ram[5];
   assign O_WF6 = waveform_ram[6];
   assign O_WF7 = waveform_ram[7];
   assign O_WF8 = waveform_ram[8];
   assign O_WF9 = waveform_ram[9];
   assign O_WF10 = waveform_ram[10];
   assign O_WF11 = waveform_ram[11];
   assign O_WF12 = waveform_ram[12];
   assign O_WF13 = waveform_ram[13];
   assign O_WF14 = waveform_ram[14];
   assign O_WF15 = waveform_ram[15];

   /*Reading from the RAM*/
   assign waveform_ram_access = (I_IOREG_ADDR >= 16'hFF30 && I_IOREG_ADDR <= 16'hFF3F);
   assign enable_ioreg_data = waveform_ram_access & ~I_IOREG_RE_L;
   assign IO_IOREG_DATA = (enable_ioreg_data) ? waveform_ram[I_IOREG_ADDR[3:0]] : 8'bzzzzzzzz;

   /*Writing to the RAM*/
   integer      i;
   always @(posedge I_CLK) begin

      if (~I_IOREG_WE_L & waveform_ram_access)
        waveform_ram[I_IOREG_ADDR[3:0]] <= IO_IOREG_DATA;

      if (I_RESET) begin
         for (i=0; i<16; i=i+1) begin
            waveform_ram[i] <= 0;
         end
      end

   end

   reg [4:0]  current_sample_ptr;

   wire [7:0] sample_data;
   assign sample_data = waveform_ram[current_sample_ptr >> 1];
   wire [3:0] current_sample;
   assign current_sample = (current_sample_ptr[0]) ? sample_data[3:0] : sample_data[7:4];
   wire [3:0] vol_sample;
   assign vol_sample = (output_level_select == 0) ? 0 :
                       (output_level_select == 1) ? current_sample :
                       (output_level_select == 2) ? current_sample >> 1 :
                       current_sample >> 2;

   reg [19:0] volume_to_sample;
   
   /*go from a 4 bit value to a 20 bit value, 
    * GBC volumes are all positive, so we must convert them to
    * signed integers.  Dividing by 4 allows for the 
    * mixing with the other 3 sound channels to not overflow.
    * we convert the positive magnitue to negative by adding
    * the minumum integer divided by 4 : (0x80000 -> 0xE0000)*/
   always @(*) begin
      /*case(vol_sample)
        0:  volume_to_sample = 0;
        1:  volume_to_sample = 20'h11111 >> 1 + 20'hE0000; //7FFFF*(1/15)
        2:  volume_to_sample = 20'h22222 >> 1 + 20'hE0000; //7FFFF*(2/15)
        3:  volume_to_sample = 20'h33333 >> 1 + 20'hE0000; //etc ..
        4:  volume_to_sample = 20'h44444 >> 1 + 20'hE0000;
        5:  volume_to_sample = 20'h55555 >> 1 + 20'hE0000;
        6:  volume_to_sample = 20'h66666 >> 1 + 20'hE0000;
        7:  volume_to_sample = 20'h77777 >> 1 + 20'hE0000;
        8:  volume_to_sample = 20'h88888 >> 1 + 20'hE0000;
        9:  volume_to_sample = 20'h99999 >> 1 + 20'hE0000;
        10: volume_to_sample = 20'hAAAAA >> 1 + 20'hE0000;
        11: volume_to_sample = 20'hBBBBB >> 1 + 20'hE0000;
        12: volume_to_sample = 20'hDDDDD >> 1 + 20'hE0000;
        13: volume_to_sample = 20'hCCCCC >> 1 + 20'hE0000;
        14: volume_to_sample = 20'hEEEEE >> 1 + 20'hE0000;
        15: volume_to_sample = 20'hFFFFF >> 1 + 20'hE0000;
      endcase*/
      case(vol_sample)
        0:  volume_to_sample = 0;
        1:  volume_to_sample = 20'h08888 >> 2; //7FFFF*(1/15)
        2:  volume_to_sample = 20'h11110 >> 2;//7FFFF*(2/15)
        3:  volume_to_sample = 20'h19999 >> 2; //etc ..
        4:  volume_to_sample = 20'h22221 >> 2;
        5:  volume_to_sample = 20'h2AAAA >> 2;
        6:  volume_to_sample = 20'h33332 >> 2;
        7:  volume_to_sample = 20'h3BBBB >> 2;
        8:  volume_to_sample = 20'h44443 >> 2;
        9:  volume_to_sample = 20'h4444C >> 2;
        10: volume_to_sample = 20'h55554 >> 2;
        11: volume_to_sample = 20'h5DDDD >> 2;
        12: volume_to_sample = 20'h66665 >> 2;
        13: volume_to_sample = 20'h6EEEE >> 2;
        14: volume_to_sample = 20'h77776 >> 2;
        15: volume_to_sample = 20'h7FFFF >> 2;
      endcase
   end

   /*wire the output based off the pointer to the waveform ram*/
   reg play_sound;

   wire [31:0] num_strobes_in_period;
   wire [31:0] strobes_in_sample;
   assign strobes_in_sample = num_strobes_in_period >> 5; //32 samples in period

   reg [31:0]  count_sample;
   always @(posedge I_CLK_33MHZ) begin
      count_sample <= count_sample + 1;
      if (count_sample >= strobes_in_sample) begin
         count_sample <= 0;
         current_sample_ptr <= current_sample_ptr + 1;
      end
      if (I_RESET) begin
         current_sample_ptr <= 0;
         count_sample <= 0;
      end
   end
   
   /*generate the square waveform based on the specification*/
   always @(posedge I_BITCLK) begin

      if (I_STROBE) begin
         O_CH3_WAVEFORM <= (enable_sound & play_sound) ? volume_to_sample : 0;
      end
      
      if (~play_sound)
         O_CH3_WAVEFORM <= 0;
      
      if (I_RESET || restart_sound) begin
         O_CH3_WAVEFORM <= 0;
      end
      
   end

   /*keep track of how long to play the sound*/
   reg [31:0] sound_time_count;
   always @(posedge I_CLK_33MHZ) begin

      if (play_sound)
        sound_time_count <= sound_time_count + 1;

      if (stop_output && sound_time_count >= sound_length_clocks)
        play_sound <= 0;

      if (restart_sound) begin
         play_sound <= 1;
         sound_time_count <= 0;
      end

      if (I_RESET) begin
         play_sound <= 0;
         sound_time_count <= 0;
      end

   end // always @ (posedge I_CLK_33MHZ)

   assign O_CH3_ON = enable_sound & play_sound;
   
   /*Find the amount of clocks in the period based off the frequency spec*/
   wire gnd = 0;
   sound_bram2 period_lookup_table(.clka(I_BITCLK),
                                   .wea(gnd),
                                   .addra(frequency),
                                   .dina(0),
                                   .douta(num_strobes_in_period)
                                   );

endmodule