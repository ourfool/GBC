`include "../../memory/memory_router/memdef.vh"
`define CLOCKS256    128906
`define CLOCKS64     515625
`default_nettype none

module sound_channel2(
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

		              /*Sound Status*/
		              O_CH2_ON,

                      /*Output Waveform*/
                      O_CH2_WAVEFORM,
                      
                      /*for debugging*/
                      O_NR21_DATA,
                      O_NR22_DATA,
                      O_NR23_DATA, 
                      O_NR24_DATA
                      );

   input        I_CLK, I_CLK_33MHZ, I_RESET, I_STROBE, I_BITCLK;
   input [15:0] I_IOREG_ADDR;
   inout [7:0] 	IO_IOREG_DATA;
   input        I_IOREG_WE_L, I_IOREG_RE_L;
   output [19:0] O_CH2_WAVEFORM;
   output 	 O_CH2_ON;
   output [7:0] O_NR21_DATA, O_NR22_DATA, O_NR23_DATA, O_NR24_DATA;
   
   wire         gnd=0;
   wire [7:0]   nr21_data, nr22_data,
                nr23_data, nr24_data;
   wire         new_nr21, new_nr22, new_nr23, new_nr24;
   
   assign O_NR21_DATA = nr21_data;
   assign O_NR22_DATA = nr22_data;
   assign O_NR23_DATA = nr23_data;
   assign O_NR24_DATA=  nr24_data;

   /*service data from the io register bus*/
   io_bus_parser_reg #(`NR21,0,0,0,0) nr21(.I_CLK(I_CLK),
                                       .I_SYNC_RESET(I_RESET),
                                       .IO_DATA_BUS(IO_IOREG_DATA),
                                       .I_ADDR_BUS(I_IOREG_ADDR),
                                       .I_WE_BUS_L(I_IOREG_WE_L),
                                       .I_RE_BUS_L(I_IOREG_RE_L),
                                       .I_DATA_WR(0),
                                       .O_DATA_READ(nr21_data),
                                       .I_REG_WR_EN(0),
                                       .O_DBUS_WRITE(new_nr21));
   //assign nr21_data = 8'b10_000000;
   io_bus_parser_reg #(`NR22,0,0,0,0) nr22(.I_CLK(I_CLK),
                                       .I_SYNC_RESET(I_RESET),
                                       .IO_DATA_BUS(IO_IOREG_DATA),
                                       .I_ADDR_BUS(I_IOREG_ADDR),
                                       .I_WE_BUS_L(I_IOREG_WE_L),
                                       .I_RE_BUS_L(I_IOREG_RE_L),
                                       .I_DATA_WR(0),
                                       .O_DATA_READ(nr22_data),
                                       .I_REG_WR_EN(0),
                                       .O_DBUS_WRITE(new_nr22));
   //assign nr22_data = 8'b0100_1_000;
   io_bus_parser_reg #(`NR23,0,0,0,'b01) nr23(.I_CLK(I_CLK), //write only
                                       .I_SYNC_RESET(I_RESET),
                                       .IO_DATA_BUS(IO_IOREG_DATA),
                                       .I_ADDR_BUS(I_IOREG_ADDR),
                                       .I_WE_BUS_L(I_IOREG_WE_L),
                                       .I_RE_BUS_L(I_IOREG_RE_L),
                                       .I_DATA_WR(0),
                                       .O_DATA_READ(nr23_data),
                                       .I_REG_WR_EN(0),
                                       .O_DBUS_WRITE(new_nr23));
   //assign nr23_data = 8'b11010110;
   io_bus_parser_reg #(`NR24,0,0,0,0) nr24(.I_CLK(I_CLK),
                                       .I_SYNC_RESET(I_RESET),
                                       .IO_DATA_BUS(IO_IOREG_DATA),
                                       .I_ADDR_BUS(I_IOREG_ADDR),
                                       .I_WE_BUS_L(I_IOREG_WE_L),
                                       .I_RE_BUS_L(I_IOREG_RE_L),
                                       .I_DATA_WR(0),
                                       .O_DATA_READ(nr24_data),
                                       .I_REG_WR_EN(0),
                                       .O_DBUS_WRITE(new_nr24));
   //assign nr24_data = 8'b1_1_000_110;

   wire [1:0]   duty_cycle;
   wire [10:0]  frequency;
   wire         stop_sound;
   wire         restart_sound;
   wire [31:0]  sound_length;
   reg          enable_sound;
   reg [31:0]   count, volume_time_count;
   reg [3:0] 	current_volume;
   wire [3:0] 	initial_volume;
   wire 	volume_increase;
   wire [31:0] 	volume_step_time;

   /*Based off GBC Sound II specification*/
   assign duty_cycle = nr21_data[7:6];
   assign sound_length = (64-nr21_data[5:0]) * `CLOCKS256;
   assign stop_sound = nr24_data[6];
   assign restart_sound = nr24_data[7] & new_nr24;
   assign frequency = {nr24_data[2:0] , nr23_data};
   assign initial_volume = nr22_data[7:4];
   assign volume_increase = nr22_data[3];
   assign volume_step_time = nr22_data[2:0] * `CLOCKS64;

   always @(posedge I_CLK_33MHZ) begin

      if (enable_sound) begin
        count <= count + 1;
        volume_time_count <= volume_time_count + 1;
      end

      /*time to play the sound expired*/
      if (count >= sound_length & stop_sound) begin
         enable_sound <= 0;
         count <= 0;
         volume_time_count <= 0;
      end

      /*volume envelope time expired, update the volume*/
      if (volume_time_count >= volume_step_time && volume_step_time != 'd0) begin
         volume_time_count <= 0;
         if (volume_increase && current_volume != 'b1111)
           current_volume <= current_volume + 1;
         else if (~volume_increase && current_volume != 'b0000)
           current_volume <= current_volume - 1;
      end

      /*Specification initates a new sound*/
      if (restart_sound) begin
         enable_sound <= 1;
         count <= 0;
	     current_volume <= initial_volume;
        volume_time_count <= 0;
      end

      if (I_RESET) begin
         count <= 0;
         enable_sound <= 0;
         current_volume <= initial_volume;
         volume_time_count <= 0;
      end
   end

   assign O_CH2_ON = enable_sound;
   
   squarewave_generator waveGenCh2(.I_BITCLK(I_BITCLK),
                                   .I_RESET(I_RESET),
                                   .I_CLK_33MHZ(I_CLK_33MHZ),
                                   .O_SAMPLE(O_CH2_WAVEFORM),
                                   .I_STROBE(I_STROBE),
                                   .I_FREQUENCY(frequency),
                                   .I_DUTY_CYCLE(duty_cycle),
                                   .I_WAVEFORM_EN(enable_sound),
                                   .I_VOLUME(current_volume));

endmodule
