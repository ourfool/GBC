`default_nettype none

module squarewave_generator(
                            /*System Level Inputs*/
                            I_BITCLK,
                            I_CLK_33MHZ,
                            I_RESET,

                            /*Sampling Strobe Input*/
                            I_STROBE,

                            /*Waveform Output Signal*/
                            O_SAMPLE,

                            /*User Freq & Duty Cycle Spec*/
                            I_FREQUENCY,
                            I_DUTY_CYCLE,
                            I_WAVEFORM_EN,
                            I_VOLUME);

   input             I_BITCLK, I_RESET, I_CLK_33MHZ;
   output reg [19:0] O_SAMPLE;
   input             I_WAVEFORM_EN, I_STROBE;
   input [10:0]      I_FREQUENCY; //will be calculated as 2^17/(2^11-I_FREQUENCY)
   input [3:0]       I_VOLUME;
   input [1:0]       I_DUTY_CYCLE; /* 00 - 12.5%
                                    * 01 - 25%
                                    * 10 - 50%
                                    * 11 - 75% */

   wire [31:0]       num_strobes_in_period;
   wire [31:0]       num_strobes_high;
   reg [10:0]        freq_reg, freq_reg_d1, freq_reg_d2;
   reg [1:0]         duty_cyc_reg, duty_cyc_reg_d1, duty_cyc_reg_d2;
   reg [3:0]         volume_reg, volume_reg_d1, volume_reg_d2;
   reg               waveform;
   reg [31:0]        count;

   reg [19:0]        volume_to_sample;
   wire [19:0]       volume_to_sample_low;

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

   /*figure out the duty cycle*/
   assign num_strobes_high = (duty_cyc_reg == 'b00) ? num_strobes_in_period >> 3 : //12.5%
                             (duty_cyc_reg == 'b01) ? num_strobes_in_period >> 2 : //25%
                             (duty_cyc_reg == 'b10) ? num_strobes_in_period >> 1 : //50%
                             (duty_cyc_reg == 'b11) ? (num_strobes_in_period + (num_strobes_in_period << 1)) >> 2
                             : 0;

   /* Cross information over clock domains by
    * registering the information a few times*/
   always @(posedge I_BITCLK) begin
      freq_reg_d1 <= I_FREQUENCY;
      duty_cyc_reg_d1 <= I_DUTY_CYCLE;
      volume_reg_d1 <= I_VOLUME;
      freq_reg_d2 <= freq_reg_d1;
      duty_cyc_reg_d2 <= duty_cyc_reg_d1;
      volume_reg_d2 <= volume_reg_d1;
      freq_reg <= freq_reg_d2;
      duty_cyc_reg <= duty_cyc_reg_d2;
      volume_reg <= volume_reg_d2;
   end
   
   reg high;

   /*generate the square waveform based on the specification*/
   always @(posedge I_BITCLK) begin

      if (I_STROBE) begin
         O_SAMPLE <= (high) ? volume_to_sample : volume_to_sample_low;
      end
      
      if (~I_WAVEFORM_EN)
        O_SAMPLE <= 0;
      
      if (I_RESET) begin
         O_SAMPLE <= 0;
      end
      
   end
   
   
   always @(posedge I_CLK_33MHZ) begin
      count <= count + 1;

      /*make the duty cycle*/
      if (count < num_strobes_high) begin
         high <= 1;
      end

      /*low end of duty cycle, finish period*/
      else if (count < num_strobes_in_period) begin
         high <= 0;   
      end
      
      else if (count >= num_strobes_in_period) begin
         count <= 0;
      end
      
      if (I_RESET) begin
         count <= 0;
         high <= 0;
      end

   end // always @ (posedge I_BITCLK)

   wire gnd = 0;


   /* Translate the frequency to the strobes in period
    * from the BRAM lookup table*/
   sound_bram period_lookup_table(.clka(I_BITCLK),
                                  .wea(gnd),
                                  .addra(freq_reg),
                                  .dina(0),
                                  .douta(num_strobes_in_period)
                                  );

endmodule
