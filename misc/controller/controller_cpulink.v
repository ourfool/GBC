`include "../../memory/memory_router/memdef.vh"
`default_nettype none

`define START 7
`define SELECT 6
`define B 5
`define A 4
`define DOWN 3
`define UP 2
`define LEFT 1
`define RIGHT 0

module controller(
		  /*System Level Inputs*/
		  I_CLK,
		  I_CLK_33MHZ,
		  I_RESET,

		  /*IO Register Bus*/
		  I_IOREG_ADDR,
		  IO_IOREG_DATA,
		  I_IOREG_WE_L,
		  I_IOREG_RE_L,

		  /*IF with Controller Hardware*/
		  O_CONTROLLER_LATCH,
		  O_CONTROLLER_PULSE,
		  I_CONTROLLER_DATA,

		  /*CPU Interrupt*/
		  O_CONTROLLER_INTERRUPT,

          O_P1_DATA
		  );
          
   parameter P_CONTROLLER_CONNECTED = 1;

   input        I_CLK, I_CLK_33MHZ, I_RESET;
   input [15:0] I_IOREG_ADDR;
   inout [7:0] 	IO_IOREG_DATA;
   input 	    I_IOREG_WE_L, I_IOREG_RE_L;
   output 	    O_CONTROLLER_LATCH;
   output 	    O_CONTROLLER_PULSE;
   input 	    I_CONTROLLER_DATA;
   output reg	O_CONTROLLER_INTERRUPT;
   output [7:0] O_P1_DATA;

   reg 	[1:0]	p1_reg;
   wire 	start, sel, a, b, up, down, left, right;
   wire 	return_UDLR_values, return_startselAB_values;
   wire [3:0] 	UDLR_values, startselAB_values;
   wire [7:0] 	buttons_pressed;
   wire [7:0] 	return_data;

   assign O_P1_DATA = {0,p1_reg,return_data[3:0]};

   /*determine selection lines for the array*/
   assign return_startselAB_values = p1_reg[1];
   assign return_UDLR_values = p1_reg[0];

   /*multiplex which row in the array to choose*/
   assign return_data[7:6] = 0;
   assign return_data[5:4] = p1_reg;
   assign return_data[3:0] = //(~P_CONTROLLER_CONNECTED) ? 4'b1111 :
                             (!return_startselAB_values) ? startselAB_values :
			                 (!return_UDLR_values) ? UDLR_values : 0;

   /*find the buttons, so they can easily be reordered*/
   assign start = ~buttons_pressed[`START];
   assign sel   = ~buttons_pressed[`SELECT];
   assign a     = ~buttons_pressed[`A];
   assign b     = ~buttons_pressed[`B];
   assign up    = ~buttons_pressed[`UP];
   assign down  = ~buttons_pressed[`DOWN];
   assign left  = ~buttons_pressed[`LEFT];
   assign right = ~buttons_pressed[`RIGHT];

   /*reorder the buttons to the specification*/
   assign UDLR_values = {down, up, left, right};
   assign startselAB_values = {start, sel, b, a};

   /*drive the memory bus*/
   wire 	membus_rd, membus_wr;
   assign membus_rd = (~I_IOREG_RE_L && I_IOREG_ADDR == `P1);
   assign membus_wr = (~I_IOREG_WE_L && I_IOREG_ADDR == `P1);
   assign IO_IOREG_DATA = (membus_rd) ? return_data : 'bzzzzzzzz;

   /*write to the p1 register*/
   always @(posedge I_CLK) begin

      if (membus_wr) begin
	 p1_reg <= IO_IOREG_DATA[5:4];
      end

      if (I_RESET) begin
	 p1_reg <= 0;
      end

   end

   /*trigger the interrupt*/
   wire 	interrupt_monitor;
   reg    interrupt_monitor_d1;
   assign interrupt_monitor = start | sel | a | b | up | down | left | right;
   always @(posedge I_CLK) begin
      /*find the rising edge of any button being pressed to
       *to trigger the interrupt*/
      interrupt_monitor_d1 <= interrupt_monitor;
      //O_CONTROLLER_INTERRUPT <= ~interrupt_monitor_d1 & interrupt_monitor;
      // TODO: this interrupt code isn't correct
      O_CONTROLLER_INTERRUPT <= 1'b0;
   end


   controller_interface cif(
                            .O_BUTTONS(buttons_pressed),
                            .O_LATCH(O_CONTROLLER_LATCH),
                            .O_PULSE(O_CONTROLLER_PULSE),
                            .I_CLK_33MHZ(I_CLK_33MHZ),
                            .I_DATA(I_CONTROLLER_DATA),
                            .I_RESET(I_RESET)
                            );

endmodule
