`timescale 1ns / 1ps

module sound_test_top(

		      /*forward the AC97 Interface*/
		      input              ac97_bitclk,
		      input              ac97_sdata_in,
		      input              pos1, pos2,
		      output wire        ac97_sdata_out,
		      output wire        ac97_sync,
		      output wire        ac97_reset_b,

		      input CLK_33MHZ_FPGA,
		      input GPIO_SW_E,

		      /*For Debugging*/
                      output GPIO_LED_0,
                      output GPIO_LED_1,
                      output GPIO_LED_2,
                      output GPIO_LED_3,
                      output GPIO_LED_4,
                      output GPIO_LED_5,
                      output GPIO_LED_6,
                      output GPIO_LED_7,

							 
							 input GPIO_DIP_SW1,
						    input GPIO_DIP_SW2,
							 input GPIO_DIP_SW3,
							 input GPIO_DIP_SW4,
							 input GPIO_DIP_SW5 ,
							 input GPIO_DIP_SW6,
							 input GPIO_DIP_SW7,
							 input GPIO_DIP_SW8
                      
		
    );
	 
	 reg [15:0] ioreg_addr;
	 wire [7:0] ioreg_data;
	 reg ioreg_we_l, ioreg_re_l;
	 reg ioreg_en;
	 reg [7:0] bus_data;
	 
	 wire I_CLK, I_CLK33MHZ, I_RESET;
	 assign I_CLK33MHZ = CLK_33MHZ_FPGA;
	 assign I_RESET = GPIO_SW_E;
	 
	 wire [7:0] O_DATA1;
	 wire [7:0] I_DATA;
	 
	 assign GPIO_LED_0 = O_DATA1[7];
    assign GPIO_LED_1 = O_DATA1[6];
    assign GPIO_LED_2 = O_DATA1[5];
    assign GPIO_LED_3 = O_DATA1[4];
    assign GPIO_LED_4 = O_DATA1[3];
    assign GPIO_LED_5 = O_DATA1[2];
    assign GPIO_LED_6 = O_DATA1[1];
    assign GPIO_LED_7 = O_DATA1[0];
	 
	 assign I_DATA[7] = GPIO_DIP_SW1;
	 assign I_DATA[6] = GPIO_DIP_SW2;
	 assign I_DATA[5] = GPIO_DIP_SW3;
	 assign I_DATA[4] = GPIO_DIP_SW4;
	 assign I_DATA[3] = GPIO_DIP_SW5;
	 assign I_DATA[2] = GPIO_DIP_SW6;
	 assign I_DATA[1] = GPIO_DIP_SW7;
	 assign I_DATA[0] = GPIO_DIP_SW8;
	 
	 wire [7:0] da,db,dc,dd,de;
	 reg [7:0]  restart_count;

	 assign O_DATA1 = restart_count;

	 
	 my_clock_divider #(.DIV_SIZE(4), .DIV_OVER_TWO(2))
    cdivdouble(.clock_out(I_CLK), .clock_in(I_CLK33MHZ));

	 tristate #(8) trist( .out(ioreg_data), .in(bus_data), .en(ioreg_en));

	 
	 reg [23:0] count;
     reg new_sound;
	 
	 
	 always @(posedge I_CLK) begin
	
	    count <= count + 1;
		ioreg_we_l <= 1;
		ioreg_re_l <= 1;
        new_sound <= 0;
	
		if (count == 0) begin
		   ioreg_addr <= 16'hFF10;
			bus_data <= 8'b0_111_0_111;
			ioreg_en <= 1;
			ioreg_we_l <= 0;
			restart_count <= restart_count + 1;
            new_sound <= 1;
		end
	   else if (count == 1) begin
		   ioreg_addr <= 16'hFF11;
			bus_data <= 8'b10_000000;
			ioreg_en <= 1;
			ioreg_we_l <= 0;
		end
      else if (count == 2) begin
		   ioreg_addr <= 16'hFF12;
			bus_data <= 8'b1111_1_111;
			ioreg_en <= 1;
			ioreg_we_l <= 0;
		end
		else if (count == 3) begin
		   ioreg_addr <= 16'hFF13;
			bus_data <= 8'b11010110; //A 440 HZ
			ioreg_en <= 1;
			ioreg_we_l <= 0;
		end
		else if (count == 4) begin
		   ioreg_addr <= 16'hFF14;
			bus_data <= 8'b1_0_000_110; //A 440 HZ
			ioreg_en <= 1;
			ioreg_we_l <= 0;
		end
        else if (count == 5) begin
            ioreg_addr <= 16'hFF19;
			bus_data <= 8'b1_0_000_110;
			ioreg_en <= 1;
			ioreg_we_l <= 0;
        end
        else if (count == 6) begin
            ioreg_addr <= 16'hFF23;
			bus_data <= 8'b1_0_000_110;
			ioreg_en <= 1;
			ioreg_we_l <= 0;
        end
        else if (count == 7) begin
           ioreg_en <= 0;
           ioreg_we_l <= 1;
        end
	 
		if (I_RESET) begin
			count <= 0;
			restart_count <= 0;
            ioreg_en <= 0;
	   end
			
			
	end
			
	 
	 
	 
	 AC97 sound(
		          .ac97_bitclk(ac97_bitclk),
		          .ac97_sdata_in(ac97_sdata_in),
	             .pos1(pos1), .pos2(pos2),
		          .ac97_sdata_out(ac97_sdata_out),
	             .ac97_sync(ac97_sync),
	             .ac97_reset_b(ac97_reset_b),
	
		          .I_CLK(I_CLK), 
					 .I_CLK33MHZ(I_CLK33MHZ),
	             .I_RESET(I_RESET),
	             .I_IOREG_ADDR(ioreg_addr),
	             .IO_IOREG_DATA(ioreg_data),
	             .I_IOREG_WE_L(ioreg_we_l),	
	             .I_IOREG_RE_L(ioreg_re_l),
                 .new_sound(new_sound),
					 
					 .O_D1(db), .O_D2(dc),
					 .O_D3(dd), .O_D4(de), .O_D0(da)
	             );
	 

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

module tristate(/*AUTOARG*/
		// Outputs
		out,
		// Inputs
		in, en
		);
   parameter
     width = 1;
   output wire [width-1:0] out;
   input [width-1:0] 	   in;
   input                   en;

   assign out = (en) ? in : {width{1'bz}};
   
endmodule // tristate
