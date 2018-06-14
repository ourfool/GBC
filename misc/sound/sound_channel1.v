`include "../../memory/memory_router/memdef.vh"
`default_nettype none

/*Clocks for sweep time specs based on 33MHz clock*/
`define SWEEPCLOCKS1 257400
`define SWEEPCLOCKS2 514800
`define SWEEPCLOCKS3 772200
`define SWEEPCLOCKS4 1029600
`define SWEEPCLOCKS5 1287000
`define SWEEPCLOCKS6 1544400
`define SWEEPCLOCKS7 1801800
`define CLOCKS256    128906
`define CLOCKS64     515625

module sound_channel1(

                      /*System Level Inputs*/
                      I_CLK,
                      I_CLK33MHZ,
                      I_RESET,

                      /*Interface with sound module*/
                      I_BITCLK,
                      I_STROBE,

                      /*Interface with CPU*/
                      I_IOREG_ADDR,
                      IO_IOREG_DATA,
                      I_IOREG_WE_L,
                      I_IOREG_RE_L,


		              /*Sound Status*/
		              O_CH1_ON,
                      
                      new_sound, 

                      /*Output Samples*/
                      O_CH1_WAVEFORM,

                      /*for debugging*/
                      O_NR10_DATA, 
                      O_NR11_DATA, 
                      O_NR12_DATA, 
                      O_NR13_DATA, 
                      O_NR14_DATA
                      
                      );

   input         I_CLK, I_CLK33MHZ, I_BITCLK, I_RESET;
   input [15:0]  I_IOREG_ADDR;
   inout [7:0] 	 IO_IOREG_DATA;
   input         I_IOREG_WE_L, I_IOREG_RE_L, I_STROBE;
   output 	 O_CH1_ON;
   output [19:0] O_CH1_WAVEFORM;
   input new_sound;
   output [7:0] O_NR10_DATA, O_NR11_DATA, O_NR12_DATA, O_NR13_DATA, O_NR14_DATA;
   
   wire [7:0] 	 nr10_data, nr11_data,
                 nr12_data, nr13_data,
                 nr14_data;
   wire          new_nr10, new_nr11, new_nr12,
                 new_nr13, new_nr14;
   wire [7:0] 	 gnd8 = 0;
   
   assign O_NR10_DATA = nr10_data;
   assign O_NR11_DATA = nr11_data;
   assign O_NR12_DATA = nr12_data;
   assign O_NR13_DATA=  nr13_data;
   assign O_NR14_DATA = nr14_data;
   
   /*service data from the IOREG Bus into the registers*/
   io_bus_parser_reg #(`NR10,0,0,0,0) nr10(.I_CLK(I_CLK),
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr10_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr10)
                                           );
   //assign nr10_data = 'b0_111_0_111; 
   io_bus_parser_reg #(`NR11,0,0,0,0) nr11(.I_CLK(I_CLK),
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr11_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr11));
   //assign nr11_data = 'b10_000000;                                        
   io_bus_parser_reg #(`NR12,0,0,0,0) nr12(.I_CLK(I_CLK),
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr12_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr12));
   //assign nr12_data = 'b1111_1_111;
   io_bus_parser_reg #(`NR13,0,0,0,'b01) nr13(.I_CLK(I_CLK), //write only
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr13_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr13));
   //assign nr13_data = 8'b11010110;
   io_bus_parser_reg #(`NR14,0,0,0,0) nr14(.I_CLK(I_CLK),
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr14_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr14));
   //assign nr14_data = 8'b1_0_000_110;

   reg [10:0] 	 current_freq;
   reg [3:0] 	 current_volume;
   wire [2:0] 	 sweep_time;
   wire          sweep_decrease;
   wire [2:0] 	 num_sweep_shift;

   wire [1:0] 	 duty_cycle;
   wire [31:0] 	 sound_length;
   wire [31:0] 	 volume_step_time;
   wire [3:0] 	 initial_volume;
   wire [10:0] 	 base_frequency;
   wire          restart_sound;
   wire          stop_output;
   wire          volume_increase;

   /*extract the sound parameters*/
   assign sweep_time = nr10_data[6:4];
   assign sweep_decrease = nr10_data[3];
   assign num_sweep_shift = nr10_data[2:0];
   assign duty_cycle = nr11_data[7:6];
   assign sound_length = (64 - nr11_data[5:0]) * `CLOCKS256;
   assign base_frequency = {nr14_data[2:0], nr13_data};
   assign restart_sound = new_nr14 & nr14_data[7];
   assign stop_output = nr14_data[6];
   assign initial_volume = nr12_data[7:4];
   assign volume_step_time = nr12_data[2:0] * `CLOCKS64;
   assign volume_increase = nr12_data[3];
   
   /*calculate the number of clocks*/
   wire [31:0] 	 num_clocks_sweep_time;
   assign num_clocks_sweep_time = (sweep_time == 'b001) ? `SWEEPCLOCKS1 :
                                  (sweep_time == 'b010) ? `SWEEPCLOCKS2 :
                                  (sweep_time == 'b011) ? `SWEEPCLOCKS3 :
                                  (sweep_time == 'b100) ? `SWEEPCLOCKS4 :
                                  (sweep_time == 'b101) ? `SWEEPCLOCKS5 :
                                  (sweep_time == 'b110) ? `SWEEPCLOCKS6 :
                                  (sweep_time == 'b111) ? `SWEEPCLOCKS7 : 0;

   wire [10:0] 	 freq_delta, new_freq;
   reg [31:0] 	 sweep_env_count;
   reg [31:0] 	 sound_time_count;
   reg [31:0] 	 volume_time_count;   
   reg           sound_enable;
   wire          not_overflow;

   assign freq_delta = (sweep_time == 'b000) ? 0 : current_freq >> num_sweep_shift;
   assign new_freq = (sweep_decrease) ? current_freq - freq_delta : current_freq + freq_delta;
   assign not_overflow = (current_freq[10] == new_freq[10]);

   /*execute the sweep/sound generation*/
   always @(posedge I_CLK33MHZ) begin

      if (sound_enable) begin
         sweep_env_count <= sweep_env_count + 1;
         sound_time_count <= sound_time_count + 1;
         volume_time_count <= volume_time_count + 1;
      end

      /*sweep time expired, update the frequency*/
      if (sweep_env_count >= num_clocks_sweep_time) begin
         sweep_env_count <= 0;
         if (not_overflow)
           current_freq <= new_freq;
      end
      
      /*volume envelope time expired, update the volume*/
      if (volume_time_count >= volume_step_time && volume_step_time != 'd0) begin
         volume_time_count <= 0;
         if (volume_increase && current_volume != 'b1111)
           current_volume <= current_volume + 1;
         else if (~volume_increase && current_volume != 0000)
           current_volume <= current_volume - 1;
      end
      
      /*if time for sound to play expires, stop playing the sound*/
      if (sound_time_count >= sound_length & stop_output) begin
         sound_enable <= 0;
      end
      
      /*if a new sound specification*/
      if (restart_sound) begin
         sound_enable <= 1;
         sweep_env_count <= 0;
         current_freq<= base_frequency;
         sound_time_count <= 0;
         current_volume <= initial_volume;
	     volume_time_count <= 0;
      end
      
      if (I_RESET) begin
         sound_enable <= 0;
         sweep_env_count <= 0;
         current_freq <= base_frequency;
         sound_time_count <= 0;
	     volume_time_count <= 0;
         current_volume <= initial_volume;
      end

   end // always @ (posedge I_CLK33MHZ)

   assign O_CH1_ON = sound_enable;

   squarewave_generator waveGenCh1(
                                   .I_BITCLK(I_BITCLK),
                                   .I_RESET(I_RESET),
                                   .I_CLK_33MHZ(I_CLK33MHZ),
                                   .O_SAMPLE(O_CH1_WAVEFORM),
                                   .I_STROBE(I_STROBE),
                                   .I_FREQUENCY(current_freq),
                                   .I_DUTY_CYCLE(duty_cycle),
                                   .I_WAVEFORM_EN(sound_enable), 
                                   .I_VOLUME(current_volume));
endmodule
