`include "../../memory/memory_router/memdef.vh"
`define CLOCKS256    128906
`define CLOCKS64     515625
`default_nettype none

module sound_channel4(
                      /* System Level Inputs*/
                      I_CLK,
                      I_CLK_33MHZ,
                      I_RESET,

                      /*Interface with sound module*/
                      I_BITCLK,
                      I_STROBE,

                      /*IO Register Bus*/
                      I_IOREG_ADDR,
                      IO_IOREG_DATA,
                      I_IOREG_WE_L,
                      I_IOREG_RE_L,

		              /*Sound Status Signals*/
		              O_CH4_ON,

                      /*Output Waveform*/
                      O_CH4_WAVEFORM,
                      
                      /*for debugging*/
                      O_NR41_DATA, O_NR42_DATA, O_NR43_DATA, O_NR44_DATA
                      );
   
   input        I_CLK, I_CLK_33MHZ, I_RESET, I_STROBE, I_BITCLK;
   input [15:0] I_IOREG_ADDR;
   inout [7:0] 	IO_IOREG_DATA;
   input        I_IOREG_WE_L, I_IOREG_RE_L;
   output [19:0] O_CH4_WAVEFORM;
   output 	     O_CH4_ON;
   output [7:0] O_NR41_DATA, O_NR42_DATA, O_NR43_DATA, O_NR44_DATA;
   
   wire [7:0] 	 nr41_data, nr42_data,
                 nr43_data, nr44_data;
   wire 	 new_nr41, new_nr42, new_nr43,
                 new_nr44;
   wire [7:0] 	 gnd8 = 0;
   
   assign O_NR41_DATA = nr41_data;
   assign O_NR42_DATA = nr42_data;
   assign O_NR43_DATA = nr43_data;
   assign O_NR44_DATA=  nr44_data;

   
   /*service data from the IOREG Bus into the registers*/
   io_bus_parser_reg #(`NR41,0,0,0,0) nr41(.I_CLK(I_CLK),
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr41_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr41)
                                           );
   //assign nr41_data = 0;
   io_bus_parser_reg #(`NR42,0,0,0,0) nr42(.I_CLK(I_CLK),
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr42_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr42));
   //assign nr42_data = 8'b0100_1_111;
   io_bus_parser_reg #(`NR43,0,0,0,0) nr43(.I_CLK(I_CLK),
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr43_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr43));
   //assign nr43_data = 8'b0000_0_000;
   io_bus_parser_reg #(`NR44,0,0,0,0) nr44(.I_CLK(I_CLK),
                                           .I_SYNC_RESET(I_RESET),
                                           .IO_DATA_BUS(IO_IOREG_DATA),
                                           .I_ADDR_BUS(I_IOREG_ADDR),
                                           .I_WE_BUS_L(I_IOREG_WE_L),
                                           .I_RE_BUS_L(I_IOREG_RE_L),
                                           .I_DATA_WR(gnd8),
                                           .O_DATA_READ(nr44_data),
                                           .I_REG_WR_EN(0),
                                           .O_DBUS_WRITE(new_nr44));
   //assign nr44_data = 8'b1_1_000000;

   /*extract the parameters of the sound from the io register*/
   wire [31:0] 	 sound_length_clocks;
   assign sound_length_clocks = (64-nr41_data[5:0]) * `CLOCKS256;
   wire [3:0] 	 initial_volume;
   assign initial_volume = nr42_data[7:4];
   wire 	 increase_volume;
   assign increase_volume = nr42_data[3];
   wire [31:0] 	 volume_env_clocks;
   assign volume_env_clocks = nr42_data[2:0] * `CLOCKS64;
   wire [3:0] 	 s;
   assign s = nr43_data[7:4];
   wire 	 counter_step_width;
   assign counter_step_width = nr43_data[3];
   wire [2:0] 	 r;
   assign r = nr43_data[2:0];
   wire 	 restart_sound;
   assign restart_sound = nr44_data[7] & new_nr44;
   wire 	 stop_output;
   assign stop_output = nr44_data[6];

   reg [31:0] 	 shift_clock_intermed;   
   wire [31:0] 	 shift_clock_clocks;

   /*frequency f is defined as intermed/2^(s+1)
    *so f is proportional to 1/clocks in period
    *so compute as clocks*2^(s+1) */
   assign shift_clock_clocks = shift_clock_intermed << (s + 1);
   wire [31:0] 	 shift_clock_clocks_div_two;
   assign shift_clock_clocks_div_two = shift_clock_clocks >> 1;

   /*calculate from the formula f = 524288/r
    *and then clocks = 33Mhz/f*/
   always @(*) begin
      case(r)
	0: shift_clock_intermed = 31;
	1: shift_clock_intermed = 63;
	2: shift_clock_intermed = 126;
	3: shift_clock_intermed = 189;
	4: shift_clock_intermed = 252;
	5: shift_clock_intermed = 315;
	6: shift_clock_intermed = 378;
	7: shift_clock_intermed = 441;
      endcase // case (r)
   end // always @ (*)
   
   reg 		 shift_clock;
   reg 		 sound_enable;
   reg [3:0] 	 current_volume;
   reg [31:0] 	 sound_length_count;
   reg [31:0] 	 shift_clock_count;
   reg [31:0] 	 volume_env_count;
   always @(posedge I_CLK_33MHZ) begin

      /*update the counts*/
      shift_clock_count <= shift_clock_count + 1;
      if (sound_enable) begin
	 volume_env_count <= volume_env_count + 1;
	 sound_length_count <= sound_length_count + 1;
      end

      /*if time for sound to play expires*/
      if (sound_length_count >= sound_length_clocks & stop_output) begin
	 sound_enable <= 0;
      end

      /*if time on volume envelope expires*/
      if (volume_env_count >= volume_env_clocks & volume_env_clocks != 0) begin

	 volume_env_count <= 0;
	if (increase_volume & current_volume != 'b1111)
	  current_volume <= current_volume + 1;
	else if (~increase_volume & current_volume != 'b0000)
	  current_volume <= current_volume - 1;
	 
      end

      /*generate the shift clock for the random generator*/
      if (shift_clock_count <= shift_clock_clocks_div_two)
	shift_clock <= 1;
      else if (shift_clock_count <= shift_clock_clocks)
	shift_clock <= 0;
      else
	shift_clock_count <= 0;

      /*if a restart signal is initialized*/
      if (restart_sound) begin
	 sound_enable <= 1;
	 sound_length_count <= 0;
	 volume_env_count <= 0;
	 current_volume <= initial_volume;
      end
      
      if (I_RESET) begin
	 sound_enable <= 0;
	 sound_length_count <= 0;
	 shift_clock_count <= 0;
	 volume_env_count <= 0;
	 current_volume <= initial_volume;
      end
      
   end

   assign O_CH4_ON = sound_enable;
	 
   randwave_generator randwave(
			                   .I_SHIFT_CLOCK(shift_clock),
                               .I_BITCLK(I_BITCLK),
                               .I_RESET(I_RESET),
                               .I_STROBE(I_STROBE),
                               .O_SAMPLE(O_CH4_WAVEFORM),
			                   .I_BIT_WIDTH(counter_step_width),
                               .I_WAVEFORM_EN(sound_enable),
                               .I_VOLUME(current_volume)
			       );

   
endmodule
