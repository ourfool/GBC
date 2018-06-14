`include "../../memory/memory_router/memdef.vh"
`default_nettype none

module color_file(
                  /*System Inputs*/
                  I_CLK,
                  I_RESET,

                  /*Interface with CPU (via Router)*/
                  I_MEMBUS_ADDR,
						I_DATA,
						O_DATA,
                  I_MEMBUS_WE_L,
						O_IS_CF_ADDR,

                  /*Interface with PPU (BG Color)*/
                  I_BGPAL_SEL, //pallete selection
                  I_BGPAL_INDEX, //color in pallet
                  O_BGPAL_COLOR,

                  /*Interface with PPU (Sprite Color)*/
                  I_SPRPAL_SEL,
                  I_SPRPAL_INDEX,
                  O_SPRPAL_COLOR

                  );

   input          I_CLK, I_RESET;
   input [15:0]   I_MEMBUS_ADDR;
   input [7:0]    I_DATA;
	output [7:0]   O_DATA;
   input          I_MEMBUS_WE_L;
	output         O_IS_CF_ADDR;
   input [2:0]    I_BGPAL_SEL, I_SPRPAL_SEL;
   input [1:0]    I_BGPAL_INDEX, I_SPRPAL_INDEX;
   output [15:0]  O_BGPAL_COLOR, O_SPRPAL_COLOR;


   /*Vector to Store the Background Pallets*/
   /*-->8 pallets, 8 bytes each*/
   reg [7:0]     bg_pallete_arr [0:63];
   reg [7:0]     spr_pallete_arr [0:63];

   /*Determine the index into the color file
    *from the ppu*/
   wire [5:0]    ppu_bgpal_index, ppu_sprpal_index;
   assign ppu_bgpal_index[5:3] = I_BGPAL_SEL;
   assign ppu_bgpal_index[2:1] = I_BGPAL_INDEX;
   assign ppu_bgpal_index[0] = 0;
   assign ppu_sprpal_index[5:3] = I_SPRPAL_SEL;
   assign ppu_sprpal_index[2:1] = I_SPRPAL_INDEX;
   assign ppu_sprpal_index[0] = 0;

   /*Return the Data based on the specified indices*/
   /*--note index|'d1 is a more efficient way
    *  of adding 1 to the index*/
   assign O_BGPAL_COLOR[15:8] = bg_pallete_arr[ppu_bgpal_index | 1'b1];
   assign O_BGPAL_COLOR[7:0] = bg_pallete_arr[ppu_bgpal_index];
   assign O_SPRPAL_COLOR[15:8] = spr_pallete_arr[ppu_sprpal_index | 1'b1];
   assign O_SPRPAL_COLOR[7:0] = spr_pallete_arr[ppu_sprpal_index];

   /*IO registers visible to memory*/
   reg [7:0]     bcps_reg, ocps_reg;

   wire          bgpal_inc_after_write, sprpal_inc_after_write;
   wire [5:0]    bgpal_arr_index, sprpal_arr_index;
   assign bgpal_inc_after_write = bcps_reg[7];
   assign sprpal_inc_after_write = ocps_reg[7];
   assign bgpal_arr_index = bcps_reg[5:0];
   assign sprpal_arr_index = ocps_reg[5:0];

   /*consodidate what data will be returned on a read*/
   wire [7:0]    bgpal_return_data;
   wire [7:0]    sprpal_return_data;
   assign bgpal_return_data = bg_pallete_arr[bgpal_arr_index];
   assign sprpal_return_data = spr_pallete_arr[sprpal_arr_index];

   /*determine which registers are being read*/
   wire          bcps_rd, bcpd_rd, ocps_rd, ocpd_rd;
   assign bcps_rd = (I_MEMBUS_ADDR == `BCPS);
   assign bcpd_rd = (I_MEMBUS_ADDR == `BCPD);
   assign ocps_rd = (I_MEMBUS_ADDR == `OCPS);
   assign ocpd_rd = (I_MEMBUS_ADDR == `OCPD);
	
	assign O_IS_CF_ADDR = bcps_rd | bcpd_rd | ocps_rd | ocpd_rd;

   wire [7:0]    membus_return_data;

	assign O_DATA = membus_return_data;
   
   /*multiplex the return data based on the address and re signal*/
   assign membus_return_data = (bcps_rd) ? bcps_reg :
                               (bcpd_rd) ? bgpal_return_data :
                               (ocps_rd) ? ocps_reg :
                               (ocpd_rd) ? sprpal_return_data : 0;

   integer i;
   always @(posedge I_CLK) begin
		if (I_RESET) begin
        /*
			bg_pallete_arr[1] <= 8'h6f;
			bg_pallete_arr[0] <= 8'hfb;
			bg_pallete_arr[3] <= 8'h56;
			bg_pallete_arr[2] <= 8'hb5;
			bg_pallete_arr[5] <= 8'h35;
			bg_pallete_arr[4] <= 8'had;
			bg_pallete_arr[7] <= 8'h1c;
			bg_pallete_arr[6] <= 8'he7;
			
			// bg1
			bg_pallete_arr[9] <= 8'h6f;
			bg_pallete_arr[8] <= 8'hfb;
			bg_pallete_arr[11] <= 8'h62;
			bg_pallete_arr[10] <= 8'h7f;
			bg_pallete_arr[13] <= 8'h19;
			bg_pallete_arr[12] <= 8'h5e;
			bg_pallete_arr[15] <= 8'h1c;
			bg_pallete_arr[14] <= 8'he7;
			
			// bg2
			bg_pallete_arr[17] <= 8'h2b;
			bg_pallete_arr[16] <= 8'hf6;
			bg_pallete_arr[19] <= 8'h07;
			bg_pallete_arr[18] <= 8'h2c;
			bg_pallete_arr[21] <= 8'h01;
			bg_pallete_arr[20] <= 8'hc5;
			bg_pallete_arr[23] <= 8'h1c;
			bg_pallete_arr[22] <= 8'he7;
		
			// bg3
			bg_pallete_arr[25] <= 8'h7e;
			bg_pallete_arr[24] <= 8'hf7;
			bg_pallete_arr[27] <= 8'h7e;
			bg_pallete_arr[26] <= 8'h72;
			bg_pallete_arr[29] <= 8'h7d;
			bg_pallete_arr[28] <= 8'h8d;
			bg_pallete_arr[31] <= 8'h1c;
			bg_pallete_arr[30] <= 8'he7;
			
			// bg4
			bg_pallete_arr[33] <= 8'h6f;
			bg_pallete_arr[32] <= 8'hfb;
			bg_pallete_arr[35] <= 8'h1f;
			bg_pallete_arr[34] <= 8'hff;
			bg_pallete_arr[37] <= 8'h06;
			bg_pallete_arr[36] <= 8'h1f;
			bg_pallete_arr[39] <= 8'h1c;
			bg_pallete_arr[38] <= 8'he7;
			
			// bg5
			bg_pallete_arr[41] <= 8'h6f;
			bg_pallete_arr[40] <= 8'hfb;
			bg_pallete_arr[43] <= 8'h1e;
			bg_pallete_arr[42] <= 8'h58;
			bg_pallete_arr[45] <= 8'h0d;
			bg_pallete_arr[44] <= 8'hf4;
			bg_pallete_arr[47] <= 8'h1c;
			bg_pallete_arr[46] <= 8'he7;
			
			// bg6
			bg_pallete_arr[49] <= 8'h6f;
			bg_pallete_arr[48] <= 8'hfb;
			bg_pallete_arr[51] <= 8'h3b;
			bg_pallete_arr[50] <= 8'hf4;
			bg_pallete_arr[53] <= 8'h16;
			bg_pallete_arr[52] <= 8'heb;
			bg_pallete_arr[55] <= 8'h1c;
			bg_pallete_arr[54] <= 8'he7;
			
			// bg7
			bg_pallete_arr[57] <= 8'h7f;
			bg_pallete_arr[56] <= 8'hff;
			bg_pallete_arr[59] <= 8'h72;
			bg_pallete_arr[58] <= 8'h68;
			bg_pallete_arr[61] <= 8'h40;
			bg_pallete_arr[60] <= 8'ha5;
			bg_pallete_arr[63] <= 8'h00;
			bg_pallete_arr[62] <= 8'h00;
		

            // Object colors
			// obj 0
			spr_pallete_arr[1] <= 8'h6f;
			spr_pallete_arr[0] <= 8'hfb;
			spr_pallete_arr[3] <= 8'h2a;
			spr_pallete_arr[2] <= 8'h7f;
			spr_pallete_arr[5] <= 8'h04;
			spr_pallete_arr[4] <= 8'hff;
			spr_pallete_arr[7] <= 8'h00;
			spr_pallete_arr[6] <= 8'h00;
			
			// obj 1
			spr_pallete_arr[9] <= 8'h6f;
			spr_pallete_arr[8] <= 8'hfb;
			spr_pallete_arr[11] <= 8'h2a;
			spr_pallete_arr[10] <= 8'h7f;
			spr_pallete_arr[13] <= 8'h7d;
			spr_pallete_arr[12] <= 8'h2a;
			spr_pallete_arr[15] <= 8'h00;
			spr_pallete_arr[14] <= 8'h00;
			
			// obj 2
			spr_pallete_arr[17] <= 8'h6f;
			spr_pallete_arr[16] <= 8'hfb;
			spr_pallete_arr[19] <= 8'h2a;
			spr_pallete_arr[18] <= 8'h7f;
			spr_pallete_arr[21] <= 8'h0e;
			spr_pallete_arr[20] <= 8'he7;
			spr_pallete_arr[23] <= 8'h00;
			spr_pallete_arr[22] <= 8'h00;
			
			// obj 3
			spr_pallete_arr[25] <= 8'h6f;
			spr_pallete_arr[24] <= 8'hfb;
			spr_pallete_arr[27] <= 8'h2a;
			spr_pallete_arr[26] <= 8'h7f;
			spr_pallete_arr[29] <= 8'h0d;
			spr_pallete_arr[28] <= 8'h4f;
			spr_pallete_arr[31] <= 8'h00;
			spr_pallete_arr[30] <= 8'h00;
			
			// obj 4
			spr_pallete_arr[33] <= 8'h6f;
			spr_pallete_arr[32] <= 8'hfb;
			spr_pallete_arr[35] <= 8'h2a;
			spr_pallete_arr[34] <= 8'h7f;
			spr_pallete_arr[37] <= 8'h19;
			spr_pallete_arr[36] <= 8'h5e;
			spr_pallete_arr[39] <= 8'h00;
			spr_pallete_arr[38] <= 8'h00;
			
			// obj 5
			spr_pallete_arr[41] <= 8'h7f;
			spr_pallete_arr[40] <= 8'hff;
			spr_pallete_arr[43] <= 8'h7f;
			spr_pallete_arr[42] <= 8'hff;
			spr_pallete_arr[45] <= 8'h35;
			spr_pallete_arr[44] <= 8'had;
			spr_pallete_arr[47] <= 8'h00;
			spr_pallete_arr[46] <= 8'h00;
			
			// obj 6
			spr_pallete_arr[49] <= 8'h2b;
			spr_pallete_arr[48] <= 8'hf6;
			spr_pallete_arr[51] <= 8'h07;
			spr_pallete_arr[50] <= 8'h2c;
			spr_pallete_arr[53] <= 8'h01;
			spr_pallete_arr[52] <= 8'hc5;
			spr_pallete_arr[55] <= 8'h1c;
			spr_pallete_arr[54] <= 8'he7;
			
			// obj 7
			spr_pallete_arr[57] <= 8'h6f;
			spr_pallete_arr[56] <= 8'hfb;
			spr_pallete_arr[59] <= 8'h1e;
			spr_pallete_arr[58] <= 8'h58;
			spr_pallete_arr[61] <= 8'h0d;
			spr_pallete_arr[60] <= 8'hf4;
			spr_pallete_arr[63] <= 8'h1c;
			spr_pallete_arr[62] <= 8'he7;
            */
            for (i = 0; i < 64; i = i + 8) begin
               bg_pallete_arr[i + 0] <= 8'hff;
               bg_pallete_arr[i + 1] <= 8'hff;
               bg_pallete_arr[i + 2] <= 8'h14;
               bg_pallete_arr[i + 3] <= 8'hA5;
               bg_pallete_arr[i + 4] <= 8'h0c;
               bg_pallete_arr[i + 5] <= 8'h63;
               bg_pallete_arr[i + 6] <= 8'h00;
               bg_pallete_arr[i + 7] <= 8'h00;
            end
            
            for (i = 0; i < 64; i = i + 8) begin
               spr_pallete_arr[i + 0] <= 8'hff;
               spr_pallete_arr[i + 1] <= 8'hff;
               spr_pallete_arr[i + 2] <= 8'h14;
               spr_pallete_arr[i + 3] <= 8'hA5;
               spr_pallete_arr[i + 4] <= 8'h0c;
               spr_pallete_arr[i + 5] <= 8'h63;
               spr_pallete_arr[i + 6] <= 8'h00;
               spr_pallete_arr[i + 7] <= 8'h00;
            end
            
            bcps_reg <= 8'b0;
            ocps_reg <= 8'b0;

      /* On a write, update the value in the specification
       * registers or in the color arrays*/
      end if (~I_MEMBUS_WE_L) begin
         case(I_MEMBUS_ADDR)
           `BCPS: begin
              bcps_reg <= I_DATA;
           end
           `BCPD: begin
              bg_pallete_arr[bgpal_arr_index] <= I_DATA;

              /*indicating that the index should be incremented*/
              if (bgpal_inc_after_write)
                bcps_reg[5:0] <= bcps_reg[5:0] + 1;
           end
           `OCPS: begin
              ocps_reg <= I_DATA;
           end
           `OCPD: begin
              spr_pallete_arr[sprpal_arr_index] <= I_DATA;

              /*indication that the index should be incremented*/
              if (sprpal_inc_after_write)
                ocps_reg[5:0] <= ocps_reg[5:0] + 1;
           end
         endcase
      end // if (~I_MEMBUS_WE_L)

   end // always @ (posedge I_CLK)

endmodule // color_file
