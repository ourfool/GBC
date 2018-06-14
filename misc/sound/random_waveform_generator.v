`default_nettype none

module randwave_generator(
                          /*System Level Inputs*/
			  I_SHIFT_CLOCK,
                          I_BITCLK,
                          I_RESET,
			  
                          /*Sampling Strobe Input*/
                          I_STROBE,
			  
                          /*Waveform Output Signal*/
                          O_SAMPLE,
			  
                          /*User Freq & Duty Cycle Spec*/
			  I_BIT_WIDTH,
                          I_WAVEFORM_EN,
                          I_VOLUME
			  );
   
   input I_SHIFT_CLOCK, I_BITCLK, I_RESET;
   input I_STROBE;
   output reg [19:0] O_SAMPLE;
   input 	 I_WAVEFORM_EN;
   input [3:0] 	 I_VOLUME;
   input 	 I_BIT_WIDTH;//0 - 15 LFSR, 0 - 15 LFSR
   
   reg [14:0] 	 LFSR15;
   reg [6:0] 	 LFSR7;
   
   always @(posedge I_SHIFT_CLOCK) begin

      /*implement 7 bit wide LFSR*/
      LFSR7[6] <= LFSR7[1] ^ LFSR7[0];
      LFSR7[5] <= LFSR7[6];
      LFSR7[4] <= LFSR7[5];
      LFSR7[3] <= LFSR7[4];
      LFSR7[2] <= LFSR7[3];
      LFSR7[1] <= LFSR7[2];
      LFSR7[0] <= LFSR7[1];

      /*implement 15 bit wide LFSR*/
      LFSR15[14] <= LFSR15[1] ^ LFSR15[0];
      LFSR15[13] <= LFSR15[14];
      LFSR15[12] <= LFSR15[13];
      LFSR15[11] <= LFSR15[12];
      LFSR15[10] <= LFSR15[11];
      LFSR15[9] <= LFSR15[10];
      LFSR15[8] <= LFSR15[9];
      LFSR15[7] <= LFSR15[8];
      LFSR15[6] <= LFSR15[7];
      LFSR15[5] <= LFSR15[6];
      LFSR15[4] <= LFSR15[5];
      LFSR15[3] <= LFSR15[4];
      LFSR15[2] <= LFSR15[3];
      LFSR15[1] <= LFSR15[2];
      LFSR15[0] <= LFSR15[1];

      if (I_RESET) begin
	 LFSR15 <= 15'h7FFF;
	 LFSR7 <= 7'h7F;
      end
      
   end // always @ (posedge I_SHIFT_CLOCK)
   
   wire output_high_value;
   assign output_high_value = (I_BIT_WIDTH) ? LFSR7[0] : LFSR15[0];
   
   reg [19:0] volume_to_sample;
   wire [19:0] volume_to_sample_low;
   
   /*go from a 4 bit value to a 20 bit value*/
   always @(*) begin
      case(I_VOLUME)
        0:  volume_to_sample = 0;
        1:  volume_to_sample = 20'h08888 >> 3; //7FFFF*(1/15)
        2:  volume_to_sample = 20'h11110 >> 3; //7FFFF*(2/15)
        3:  volume_to_sample = 20'h19999 >> 3; //etc ..
        4:  volume_to_sample = 20'h22221 >> 3;
        5:  volume_to_sample = 20'h2AAAA >> 3;
        6:  volume_to_sample = 20'h33332 >> 3;
        7:  volume_to_sample = 20'h3BBBB >> 3;
        8:  volume_to_sample = 20'h44443 >> 3;
        9:  volume_to_sample = 20'h4CCCC >> 3;
        10: volume_to_sample = 20'h55554 >> 3;
        11: volume_to_sample = 20'h5DDDD >> 3;
        12: volume_to_sample = 20'h66665 >> 3;
        13: volume_to_sample = 20'h6EEEE >> 3;
        14: volume_to_sample = 20'h77776 >> 3;
        15: volume_to_sample = 20'h7FFFF >> 3;
      endcase
   end

   
   /*the low part of the waveform amplitude is simply
    *the negated magnitude of the positive amplitude*/
   assign volume_to_sample_low = ~volume_to_sample + 1;
   
   reg [3:0]         volume_reg, volume_reg_d1, volume_reg_d2;   
   
   /* Cross information over clock domains by
    * registering the information a few times*/
   always @(posedge I_BITCLK) begin
      volume_reg_d1 <= I_VOLUME;
      volume_reg_d2 <= volume_reg_d1;
      volume_reg <= volume_reg_d2;
   end


   /*generate the waveform based off bit 0 in the 
    *in one of the LFSR*/
   always @(posedge I_BITCLK) begin
      
      if (I_STROBE) begin
	 
	 if (output_high_value)
	   O_SAMPLE <= volume_to_sample;
	 else
	   O_SAMPLE <= volume_to_sample_low;
	 
      end
      
      if (~I_WAVEFORM_EN)
	O_SAMPLE <= 0;
      
      if (I_RESET)
	O_SAMPLE <= 0;

   end // always @ (posedge I_BITBLK)

endmodule // randwave_generator

   