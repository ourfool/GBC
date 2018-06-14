`default_nettype none
 module controller_interface(
                             // outputs
                             O_BUTTONS,
                             O_LATCH,
                             O_PULSE,
			     
                             // inputs
                             I_CLK_33MHZ,
                             I_DATA,
			     
                             I_RESET
                             );
   output reg [7:0] O_BUTTONS = 8'b0;
   output reg       O_LATCH;
   output reg       O_PULSE;
   input wire       I_CLK_33MHZ;
   input wire       I_DATA;
   input wire       I_RESET;
   
   wire             ctrl_clk;
   
   controller_clock_divider cdiv(.clock_out(ctrl_clk), .clock_in(I_CLK_33MHZ));
   
   reg [12:0]       state = 0;
   
`define START 7
`define SELECT 6
`define B 5
`define A 4
`define DOWN 3
`define UP 2
`define LEFT 1
`define RIGHT 0

`define INIT = 0
`define LATCH_START 1
`define LATCH_PART2 (`LATCH_START + 1)
`define PULSE0_START (`LATCH_START + 3)
`define PULSE1_START (`LATCH_START + 5)
`define PULSE2_START (`LATCH_START + 7)
`define PULSE3_START (`LATCH_START + 9)
`define PULSE4_START (`LATCH_START + 11)
`define PULSE5_START (`LATCH_START + 13)
`define PULSE6_START (`LATCH_START + 15)
`define PULSE7_START (`LATCH_START + 17)
`define RESTART      (2778)
   
   
   always @(posedge ctrl_clk) begin
      //always @(posedge I_CLK_33MHZ) begin
      
      state <= state + 1;
      
      O_LATCH <= 1'b0;
      O_PULSE <= 1'b0;
      
      case (state)
        `LATCH_START: begin
           O_LATCH <= 1'b1;
        end
        
        `LATCH_PART2: begin
           O_LATCH <= 1'b1;
        end
        
        `PULSE0_START: begin
           O_PULSE <= 1'b1;
           O_BUTTONS[`A] <= ~I_DATA;
        end
        
        `PULSE1_START: begin
           O_PULSE <= 1'b1;
           O_BUTTONS[`B] <= ~I_DATA;
        end

        `PULSE2_START: begin
           O_PULSE <= 1'b1;
           O_BUTTONS[`SELECT] <= ~I_DATA;
        end

        `PULSE3_START: begin
           O_PULSE <= 1'b1;
           O_BUTTONS[`START] <= ~I_DATA;
        end

        `PULSE4_START: begin
           O_PULSE <= 1'b1;
           O_BUTTONS[`UP] <= ~I_DATA;
        end

        `PULSE5_START: begin
           O_PULSE <= 1'b1;
           O_BUTTONS[`DOWN] <= ~I_DATA;
        end

        `PULSE6_START: begin
           O_PULSE <= 1'b1;
           O_BUTTONS[`LEFT] <= ~I_DATA;
        end
        
        `PULSE7_START: begin
           O_PULSE <= 1'b1;
           O_BUTTONS[`RIGHT] <= ~I_DATA;
        end
        
        `RESTART: begin
           state <= 0;
        end
      endcase
      if (I_RESET) begin
         state <= 0;
         O_BUTTONS <= 8'b0;
      end
   end
   
endmodule

module controller_clock_divider(/*AUTOARG*/
                                // Outputs
                                clock_out,
                                // Inputs
                                clock_in
                                );
   
   parameter
     DIV_SIZE = 15,
       DIV_OVER_TWO = 198 / 2;

   output reg clock_out = 0;
   input wire clock_in;
   
   reg [DIV_SIZE-1:0] counter = 0;

   always @(posedge clock_in) begin
      if (counter == DIV_OVER_TWO - 1) begin
         clock_out <= ~clock_out;
         counter <= 0;
      end else begin
         counter <= counter + 1;
      end
   end

endmodule
