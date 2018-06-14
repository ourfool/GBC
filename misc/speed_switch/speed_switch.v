`include "../../memory/memory_router/memdef.vh"
`default_nettype none

module clock_module(

					/*base clocks and reset*/
					I_CLK33MHZ, 
					I_SYNC_RESET,
          I_DOUBLE_SPEED,

					/*output system clocks*/
					O_CLOCKMAIN,
					O_MEM_CLOCK,
          O_CLOCKMAIN_DOUBLE,

					/*interface with CPU*/
					I_IOREG_ADDR,
					IO_IOREG_DATA,
					I_IOREG_WE_L,
					I_IOREG_RE_L,

					/*system status signals*/
					O_IS_IN_DOUBLE_SPEEDMODE, 
					O_DISABLE_CONTROLLER, 

					/*for debugging*/
					O_RP_DATA);

	parameter P_COUNTDOWN_CLOCKS = 'd255;



	input I_CLK33MHZ, I_SYNC_RESET, I_DOUBLE_SPEED; 
	output O_CLOCKMAIN, O_MEM_CLOCK, O_CLOCKMAIN_DOUBLE;

	input [15:0] I_IOREG_ADDR;
	inout [7:0] IO_IOREG_DATA;
	input I_IOREG_WE_L;
	input I_IOREG_RE_L;

	output O_IS_IN_DOUBLE_SPEEDMODE;
	output reg O_DISABLE_CONTROLLER;
	output [7:0] O_RP_DATA;


	wire [7:0] key1_data;
	wire new_key1_data;
	wire prepare_speed_switch;
	reg in_double_speedmode;
	wire clock_8Mhz, clock_4Mhz, clock_16Mhz;

	assign O_IS_IN_DOUBLE_SPEEDMODE = in_double_speedmode;
   assign prepare_speed_switch = key1_data[0] & new_key1_data;
   
   assign O_MEM_CLOCK = I_CLK33MHZ;

   	/*generate the different clocks for the system*/
    my_clock_divider #(.DIV_SIZE(8), .DIV_OVER_TWO(4))
      cdiv4(.clock_out(clock_4Mhz), .clock_in(I_CLK33MHZ));

  	my_clock_divider #(.DIV_SIZE(4), .DIV_OVER_TWO(2))
      cdiv8(.clock_out(clock_8Mhz), .clock_in(I_CLK33MHZ));

    my_clock_divider #(.DIV_SIZE(2), .DIV_OVER_TWO(2))
      cdiv16(.clock_out(clock_16Mhz), .clock_in(I_CLK33MHZ));

  //	my_clock_divider #(.DIV_SIZE(4), .DIV_OVER_TWO(1))
  //	cdiv16(.clock_out(O_MEM_CLOCK), .clock_in(O_CLOCK_MAIN));


  	/*multiplex which clock is being used*/
	assign O_CLOCKMAIN = (in_double_speedmode) ? clock_8Mhz : clock_4Mhz; 
  assign O_CLOCKMAIN_DOUBLE = (in_double_speedmode) ? clock_16Mhz : clock_8Mhz;

	/*write only register (01) */
   io_bus_parser_reg #(`KEY1,0,0,0,'b01) rp_wr_reg(
                                                  .I_CLK(O_CLOCKMAIN),
                                                  .I_SYNC_RESET(I_SYNC_RESET),
                                                  .IO_DATA_BUS(IO_IOREG_DATA),
                                                  .I_ADDR_BUS(I_IOREG_ADDR),
                                                  .I_WE_BUS_L(I_IOREG_WE_L),
                                                  .I_RE_BUS_L(I_IOREG_RE_L),
                                                  .I_DATA_WR(0),
                                                  .O_DATA_READ(key1_data),
                                                  .O_DBUS_WRITE(new_key1_data),
                                                  .I_REG_WR_EN(0));

   /*read only register (10) - forward the status data*/
   io_bus_parser_reg #(`KEY1,0,1,0,'b10) rp_re_reg(
                                                    .I_CLK(O_CLOCKMAIN),
                                                    .I_SYNC_RESET(I_SYNC_RESET),
                                                    .IO_DATA_BUS(IO_IOREG_DATA),
                                                    .I_ADDR_BUS(I_IOREG_ADDR),
                                                    .I_WE_BUS_L(I_IOREG_WE_L),
                                                    .I_RE_BUS_L(I_IOREG_RE_L),
                                                    .I_DATA_WR({in_double_speedmode, 7'b0}),
                                                    .I_REG_WR_EN(1)); //enables status to always be forwarded

   reg [1:0] state;
   parameter FIND_NEW_SPEED_SWITCH = 'b00;
   parameter NEW_SPEED_SWITCH_FOUND = 'b01;
   parameter COUNT_DOWN = 'b10;
   reg [15:0] count;

   /*when given a prepare speed switch signal from CPU, 
    *count down a certain number of cycles to let the CPU
    *into a known state before the speed switch*/
   always @(posedge I_CLK33MHZ) begin
   	
   		case(state)

   			FIND_NEW_SPEED_SWITCH: begin

   				/*prepare_speed_switch goes high*/
   				if (prepare_speed_switch) begin
   					state <= NEW_SPEED_SWITCH_FOUND;
   				end
   				else begin
   					state <= FIND_NEW_SPEED_SWITCH;
   				end

   			end

   			NEW_SPEED_SWITCH_FOUND: begin
   				
   				/*falling edge of prepare speed switch*/
   				if (~prepare_speed_switch) begin
   					state <= COUNT_DOWN;
   				end
   				else begin
   					state <= NEW_SPEED_SWITCH_FOUND;
   					count <= P_COUNTDOWN_CLOCKS;
   					O_DISABLE_CONTROLLER <= 1;
   				end

   			end

   			COUNT_DOWN: begin
   				count <= count - 1;
   				if (count == 0) begin
   					O_DISABLE_CONTROLLER <= 0;
   					state <= FIND_NEW_SPEED_SWITCH;
   					in_double_speedmode <= ~in_double_speedmode;
   				end
   			end

   		endcase

   		if (I_SYNC_RESET) begin
   			count <= P_COUNTDOWN_CLOCKS;
   			in_double_speedmode <= I_DOUBLE_SPEED;
   			O_DISABLE_CONTROLLER <= 0;
   			state <= FIND_NEW_SPEED_SWITCH;
   		end

   end

endmodule



module my_clock_divider(
                        // Outputs
                        clock_out,
                        // Inputs
                        clock_in
                        );

   parameter   DIV_SIZE = 15, DIV_OVER_TWO = 24000;

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

endmodule // my_clock_divider