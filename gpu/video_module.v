`timescale 1ns / 1ps
`default_nettype none

module video_module(//Outputs
		    int_vblank_req, int_lcdc_req, 	//INT Outputs
		    hsync, vsync, line_count, 		//CONVERTER Outputs
		    pixel_count, pixel_data_count, //CONVERTER Outputs
		    pixel_data, pixel_we,				//CONVERTER Outputs
		    data_out, 								//MMU Outputs

		    //Inputs
		    reset, clock, //33MHz clock
            clock_cpu,
		    mem_enable, rd_n, wr_n, A, di,	//MMU Inputs
		    int_vblank_ack, int_lcdc_ack,	//INT Inputs

		    //TESTING
		    mode, state, debug_out, 			//TEST Outputs
		    sprite_y_pos, sprite_x_pos, 	//TEST Outputs
		    sprite_num, 							//TEST Outputs
		    sprite_data1, sprite_data2, 	//TEST Outputs
		    sprite_pixel, 						//TEST Outputs
		    bg_pixel, oam_addrA 				//TEST Outputs
		    );

   //Outputs
   output reg int_vblank_req, int_lcdc_req;		//INT Outputs
   output wire hsync, vsync; 							//CONVERTER Outputs
   output reg [7:0] line_count;						//CONVERTER Outputs
   output reg [8:0] pixel_count;						//CONVERTER Outputs
   output reg [7:0] pixel_data_count;				//CONVERTER Outputs
   output reg [15:0] pixel_data;						//CONVERTER Outputs
   output reg       pixel_we;									//CONVERTER Outputs
   output wire [7:0] data_out;						//MMU Outputs
   
   //Inputs
   input wire        reset, clock; //33MHz clock
   input wire        clock_cpu;
   input wire        mem_enable, rd_n, wr_n; 				//MMU Inputs
   input wire [15:0] A;									//MMU Inputs
   input wire [7:0]  di;									//MMU Inputs
   input wire        int_vblank_ack, int_lcdc_ack; 		//INT Inputs
   
   //TESTING
   output reg [1:0]  mode; 								//TEST Outputs
   output reg [5:0]  state; 								//TEST Outputs - FSM state
   output wire [31:0] debug_out; 						//TEST Outputs
   output reg [7:0]   sprite_y_pos, sprite_x_pos; 	//TEST Outputs
   output reg [6:0]   sprite_num;						//TEST Outputs
   output reg [7:0]   sprite_data1, sprite_data2; 	//TEST Outputs
   output reg [1:0]   sprite_pixel; 					//TEST Outputs
   output reg [1:0]   bg_pixel; 							//TEST Outputs
   output reg [7:0]   oam_addrA; 						//TEST Outputs

   ///////////////////////////////////
   //
   // Video Registers
   //
   // LCDC - LCD Control (FF40) R/W
   //
   //
   //	Bit 7 - LCD Control Operation
   //		0: Stop completeLY (no picture on screen)
   //		1: operation
   //	Bit 6 - Window Screen Display Data Select
   //		0: $9800-$9BFF
   //		1: $9C00-$9FFF
   //	Bit 5 - Window Display
   //		0: off
   //		1: on
   //	Bit 4 - BG Character Data Select
   //		0: $8800-$97FF
   //		1: $8000-$8FFF <- Same area as OBJ
   //	Bit 3 - BG Screen Display Data Select
   //		0: $9800-$9BFF
   //		1: $9C00-$9FFF
   //	Bit 2 - OBJ Construction
   //		0: 8*8
   //		1: 8*16
   //	Bit 1 - Window priority bit
   //		0: window overlaps all sprites
   //		1: window onLY overlaps sprites whose
   //		priority bit is set to 1
   //	Bit 0 - BG Display
   //		0: off
   //		1: on
   //
   // STAT - LCDC Status (FF41) R/W
   //
   //	Bits 6-3 - Interrupt Selection By LCDC Status
   //		Bit 6 - LYC=LY Coincidence
   //			(1=Select)
   //		Bit 5 - Mode 2: OAM-Search
   //			(1=Enabled)
   //		Bit 4 - Mode 1: V-Blank
   //			(1=Enabled)
   //		Bit 3 - Mode 0: H-Blank
   //			(1=Enabled)
   //		Bit 2 - Coincidence Flag
   //			0: LYC not equal to LCDC LY
   //			1: LYC = LCDC LY
   //	Bit 1-0 - Mode Flag (Current STATus of the LCD controller)
   //		0: During H-Blank. Entire Display Ram can be accessed.
   //		1: During V-Blank. Entire Display Ram can be accessed.
   //		2: During Searching OAM-RAM. OAM cannot be accessed.
   //		3: During Transfering Data to LCD Driver. CPU cannot
   //			access OAM and display RAM during this period.
   //
   //		The following are typical when the display is enabled:
   //
   //		Mode 0 000___000___000___000___000___000___000________________
   //		Mode 1 _______________________________________11111111111111__
   //		Mode 2 ___2_____2_____2_____2_____2_____2___________________2_
   //		Mode 3 ____33____33____33____33____33____33__________________3
   //
   //		The Mode Flag goes through the values 00, 02,
   //		and 03 at a cycle of about 109uS. 00 is present
   //		about 49uS, 02 about 20uS, and 03 about 40uS. This
   //		is interrupted every 16.6ms by the VBlank (01).
   //		The mode flag stays set at 01 for 1.1 ms.
   //
   //		Mode 0 is present between 201-207 clks, 2 about 77-83 clks,
   //		and 3 about 169-175 clks. A complete cycle through these
   //		states takes 456 clks. VBlank lasts 4560 clks. A complete
   //		screen refresh occurs every 70224 clks.)
   //
   // SCY - Scroll Y (FF42) R/W
   //		Vertical scroll of background
   //
   // SCX - Scroll X (FF43) R/W
   //		Horizontal scroll of background
   //
   // LY - LCDC Y-Coordinate (FF44) R
   //		The LY indicates the vertical line to which
   //		the present data is transferred to the LCD
   //		Driver. The LY can take on any value between
   //		0 through 153. The values between 144 and 153
   //		indicate the V-Blank period. Writing will
   //		reset the counter.
   //		This is just a RASTER register. The current
   //		line is thrown into here. But since there are
   //		no RASTERS on an LCD display it's called the
   //		LCDC Y-Coordinate.
   //
   // LYC - LY Compare (FF45) R/W
   //		The LYC compares itself with the LY. If the
   //		values are the same it causes the STAT to set
   //		the coincident flag.
   //
   // DMA (FF46)
   //		Implemented in the MMU
   //	H-Blank
   //	V-Blank
   //	OAM
   //	Transfer
   //	
   // BGP - BG Palette Data (FF47) W
   //
   //		Bit 7-6 - Data for Dot Data 11
   //		Bit 5-4 - Data for Dot Data 10
   //		Bit 3-2 - Data for Dot Data 01
   //		Bit 1-0 - Data for Dot Data 00
   //
   //		This selects the shade of gray you what for
   //		your BG pixel. Since each pixel uses 2 bits,
   //		the corresponding shade will be selected
   //		from here. The Background Color (00) lies at
   //		Bits 1-0, just put a value from 0-$3 to
   //		change the color.
   //
   // OBP0 - Object Palette 0 Data (FF48) W
   //		This selects the colors for sprite palette 0.
   //		It works exactLY as BGP ($FF47).
   //		See BGP for details.
   // OBP1 - Object Palette 1 Data (FF49) W
   //		This selects the colors for sprite palette 1.
   //		It works exactLY as BGP ($FF47).
   //		See BGP for details.
   //
   // WY - Window Y Position (FF4A) R/W
   //		0 <= WY <= 143
   //
   // WX - Window X Position + 7 (FF4B) R/W
   //		7 <= WX <= 166
   /////////////////////////////////////
   
   reg [7:0]          LCDC;
   wire [7:0]         STAT;
   reg [7:0]          SCY;
   reg [7:0]          SCX;
   reg [7:0]          LYC;
   reg [7:0]          BGP;
   reg [7:0]          OBP0;
   reg [7:0]          OBP1;
   reg [7:0]          WY;
   reg [7:0]          WX;
	reg [7:0]          VRAM_BANK_SEL; // VRAM Bank Select
	
   // temp registers for r/rw mixtures
   reg [4:0]          STAT_w;
   
   wire               vram_enable, oam_enable, reg_enable;
   reg [12:0]         vram_addrA;
   reg [12:0]         vram_addrB;
	reg [12:0]         vram2_addrA;
   reg [12:0]         vram2_addrB;
   wire [7:0]         vram_outA;
   wire [7:0]         vram_outB;
	wire [7:0]         vram2_outA;
   wire [7:0]         vram2_outB;
   
   //reg[7:0] oam_addrA;
   reg [7:0]          oam_addrB;
   wire [7:0]         oam_outA;
   wire [7:0]         oam_outB;
   
   reg [7:0]          reg_out;
   
   wire               vram_we_n, vram2_we_n, oam_we_n;

   reg [4:0]          scanline1_addrA, scanline1_addrB;
   reg [4:0]          scanline2_addrA, scanline2_addrB;
   reg [7:0]          scanline1_inA, scanline1_inB;
   reg [7:0]          scanline2_inA, scanline2_inB;
   wire [7:0]         scanline1_outA, scanline1_outB;
   wire [7:0]         scanline2_outA, scanline2_outB;
   reg                scanline_rst;
   
   reg                scanlineA_we, scanlineB_we;
   
   wire               clock_enable;
   
   divider #(8) clock_divider(reset, clock, clock_enable);
   
   OAM oam(	//Outputs
		.douta(oam_outA), 
		.doutb(oam_outB),
		//Inputs
		.clka(clock),
		.clkb(clock),
        .rsta(reset),
        .rstb(reset),
		.wea(~oam_we_n), 
		.web(),
		.addra(oam_addrA), 
		.addrb(oam_addrB),					
		.dina(di), 
		.dinb()
		);
   
   // Signals to prevent compiler from complaining
   (* KEEP = "TRUE" *) wire web = 1'b0;
   (* KEEP = "TRUE" *) wire [7:0] dinb = 8'b0;

   //vram_rom vram(vram_addr, vram_addrB, clock, clock, vram_outA, vram_outB);
   VRAM vram(	//Outputs
		.douta(vram_outA), 
		.doutb(vram_outB),
		//Inputs
		.clka(clock),
		.clkb(clock),
        .rsta(reset),
        .rstb(reset),
		.wea(~vram_we_n), 
		.web(web),
		.addra(vram_addrA), 
		.addrb(vram_addrB),					
		.dina(di), 
		.dinb(dinb)	
		);
		
	// Second VRAM bank
	VRAM2 vram2(
		//Outputs
		.douta(vram2_outA), 
		.doutb(vram2_outB),
		//Inputs
		.clka(clock),
		.clkb(clock),
        .rsta(reset),
        .rstb(reset),
		.wea(~vram2_we_n), 
		.web(web),
		.addra(vram2_addrA), 
		.addrb(vram2_addrB),					
		.dina(di), 
		.dinb(dinb)	
		);
   
   scanline_ram scanline1 (//Outputs
			   .rd_dataA(scanline1_outA), 
			   .rd_dataB(scanline1_outB),
			   //Inputs
			   .clk(clock),
               .rst(scanline_rst),
			   .wr_enA(scanlineA_we), 
			   .wr_enB(scanlineB_we),
			   .addrA(scanline1_addrA), 
			   .addrB(scanline1_addrB),					
			   .wr_dataA(scanline1_inA), 
			   .wr_dataB(scanline1_inB)
			   );
   
   scanline_ram scanline2 (//Outputs
			   .rd_dataA(scanline2_outA), 
			   .rd_dataB(scanline2_outB),
			   //Inputs
			   .clk(clock),
               .rst(scanline_rst),
			   .wr_enA(scanlineA_we), 
			   .wr_enB(scanlineB_we),
			   .addrA(scanline2_addrA), 
			   .addrB(scanline2_addrB),					
			   .wr_dataA(scanline2_inA), 
			   .wr_dataB(scanline2_inB)
			   );

   reg [4:0] bg_scanline_addrA, bg_scanline_addrB;
   reg [7:0] bg_scanline_inA, bg_scanline_inB;
   wire [7:0] bg_scanline_outA, bg_scanline_outB;
 
    scanline_ram bg_scanline(
        .rd_dataA(bg_scanline_outA), 
        .rd_dataB(bg_scanline_outB),
        //Inputs
        .clk(clock),
        .rst(scanline_rst),
        .wr_enA(scanlineA_we), 
        .wr_enB(scanlineB_we),
        .addrA(bg_scanline_addrA),
        .addrB(bg_scanline_addrB),					
        .wr_dataA(bg_scanline_inA), 
        .wr_dataB(bg_scanline_inB)
    );
    
   reg [4:0] idx_scanline1_addrA, idx_scanline2_addrA, idx_scanline3_addrA;
   reg [4:0] idx_scanline1_addrB, idx_scanline2_addrB, idx_scanline3_addrB;
   reg [7:0] idx_scanline1_inA, idx_scanline2_inA, idx_scanline3_inA;
   reg [7:0] idx_scanline1_inB, idx_scanline2_inB, idx_scanline3_inB;
   wire [7:0] idx_scanline1_outA, idx_scanline2_outA,idx_scanline3_outA;
   wire [7:0] idx_scanline1_outB, idx_scanline2_outB, idx_scanline3_outB;
 
    scanline_ram idx_scanline1(
        .rd_dataA(idx_scanline1_outA), 
        .rd_dataB(idx_scanline1_outB),
        //Inputs
        .clk(clock),
        .rst(scanline_rst),
        .wr_enA(scanlineA_we), 
        .wr_enB(scanlineB_we),
        .addrA(idx_scanline1_addrA),
        .addrB(idx_scanline1_addrB),					
        .wr_dataA(idx_scanline1_inA), 
        .wr_dataB(idx_scanline1_inB)
    );
    
    scanline_ram idx_scanline2(
        .rd_dataA(idx_scanline2_outA), 
        .rd_dataB(idx_scanline2_outB),
        //Inputs
        .clk(clock),
        .rst(scanline_rst),
        .wr_enA(scanlineA_we), 
        .wr_enB(scanlineB_we),
        .addrA(idx_scanline2_addrA),
        .addrB(idx_scanline2_addrB),					
        .wr_dataA(idx_scanline2_inA), 
        .wr_dataB(idx_scanline2_inB)
    );
    
    scanline_ram idx_scanline3(
        .rd_dataA(idx_scanline3_outA), 
        .rd_dataB(idx_scanline3_outB),
        //Inputs
        .clk(clock),
        .rst(scanline_rst),
        .wr_enA(scanlineA_we), 
        .wr_enB(scanlineB_we),
        .addrA(idx_scanline3_addrA),
        .addrB(idx_scanline3_addrB),					
        .wr_dataA(idx_scanline3_inA), 
        .wr_dataB(idx_scanline3_inB)
    );

	/*
	// Buffer for holding the color data
	wire [14:0] scanline_color_out;
	wire scanline_color_we;
	wire [7:0] scanline_color_addr;
	wire [14:0] scanline_color_in;
	scanline_color_ram scanline_colors(
		// Outputs
		.rd_data(scanline_color_out),

		//Inputs
		.clk(clock),
		.wr_en(scanline_color_we),
		.addr(scanline_color_addr),
		.wr_data(scanline_color_in),
	);
	*/

   reg [2:0] bg_pal_sel, spr_pal_sel;
   reg [1:0] bg_pal_idx, spr_pal_idx;
   wire [15:0] bg_pal_col, spr_pal_col;
   wire [7:0] color_file_out;
   wire color_file_enable;
	color_file cf(
                  /*System Inputs*/
                  .I_CLK(clock_cpu),
                  .I_RESET(reset),

                  /*Interface with CPU (via Router)*/
                  .I_MEMBUS_ADDR(A),
						.I_DATA(di),
						.O_DATA(color_file_out),
                  .I_MEMBUS_WE_L(wr_n),
						.O_IS_CF_ADDR(color_file_enable),

                  /*Interface with PPU (BG Color)*/
                  .I_BGPAL_SEL(bg_pal_sel), //pallete selection
                  .I_BGPAL_INDEX(bg_pal_idx), //color in pallet
                  .O_BGPAL_COLOR(bg_pal_col),

                  /*Interface with PPU (Sprite Color)*/
                  .I_SPRPAL_SEL(spr_pal_sel),
                  .I_SPRPAL_INDEX(spr_pal_idx),
                  .O_SPRPAL_COLOR(spr_pal_col)
                  );
   
   //reg[7:0] oam[159:0]; // oam is reg array to speed up memory accesses
     //reg[7:0] scanline1[19:0];
   //reg[7:0] scanline2[19:0];
   // timing params -- see STAT register
   parameter PIXELS = 456;
   parameter LINES = 154;
   parameter HACTIVE_VIDEO = 160;
   parameter HBLANK_PERIOD = 41;
   parameter OAM_ACTIVE = 80;
   parameter RAM_ACTIVE = 172;
   parameter VACTIVE_VIDEO = 144;
   parameter VBLANK_PERIOD = 10;
   
   //reg[1:0] mode;
   parameter HBLANK_MODE = 0;
   parameter VBLANK_MODE = 1;
   parameter OAM_LOCK_MODE = 2;
   parameter RAM_LOCK_MODE = 3;
   
   //reg[3:0] state;
   parameter IDLE_STATE = 0;
   parameter BG_ADDR_STATE = 1;
   parameter BG_ADDR_WAIT_STATE = 2;
   parameter BG_DATA_STATE = 3;
   parameter BG_DATA_WAIT_STATE = 4;
   parameter BG_PIXEL_COMPUTE_STATE = 8;
   parameter BG_PIXEL_READ_STATE = 9;
   parameter BG_PIXEL_WAIT_STATE = 10;
   parameter BG_PIXEL_WRITE_STATE = 11;
   parameter BG_PIXEL_HOLD_STATE = 12;
   
   parameter SPRITE_POS_STATE = 13;
   parameter SPRITE_POS_WAIT_STATE = 14;
   parameter SPRITE_ATTR_STATE = 15;
   parameter SPRITE_ATTR_WAIT_STATE = 16;
   parameter SPRITE_DATA_STATE = 17;
   parameter SPRITE_DATA_WAIT_STATE = 18;
   parameter SPRITE_PIXEL_COMPUTE_STATE = 19;
   parameter SPRITE_PIXEL_READ_STATE = 20;
   parameter SPRITE_PIXEL_WAIT_STATE = 21;
   parameter SPRITE_PIXEL_DRAW_STATE = 22;
   parameter SPRITE_PIXEL_DATA_STATE = 23;
   parameter SPRITE_WRITE_STATE = 24;
   parameter SPRITE_HOLD_STATE = 25;
   
   parameter PIXEL_WAIT_STATE = 26;
   parameter PIXEL_READ_STATE = 27;
   parameter PIXEL_READ_WAIT_STATE = 28;
   
    parameter PIXEL_INDEX_STATE = 29;
    parameter PIXEL_OUT_STATE = 30;
   parameter PIXEL_OUT_HOLD_STATE = 31;
   parameter PIXEL_INCREMENT_STATE = 32;
   
   wire [7:0]         next_line_count;
   wire [8:0]         next_pixel_count;
   
   reg [7:0]          tile_x_pos, tile_y_pos;
   reg [4:0]          tile_byte_pos1, tile_byte_pos2;
   reg [3:0]          tile_byte_offset1, tile_byte_offset2;
   reg [7:0]          tile_data1, tile_data2;
   reg                render_background;
	
	reg [7:0]          background_attributes;
   
   //reg[7:0] sprite_x_pos;
   //reg[7:0] sprite_y_pos;
   //reg[7:0] sprite_data1;
   //reg[7:0] sprite_data2;
   reg [7:0] sprite_bg_data1;
   reg [7:0] sprite_idx_data1, sprite_idx_data2, sprite_idx_data3;
   reg [7:0]          sprite_location;
   reg [7:0]          sprite_attributes;
   //reg[1:0] sprite_pixel;
   //reg[1:0] bg_pixel;
   reg [2:0] bg_idx;
   reg [2:0]          sprite_pixel_num;
   reg [7:0]          sprite_palette;
   reg [4:0]          sprite_y_size;
   reg [1:0]          pixel_index;
   reg is_spr_pix;
   
   reg [4:0]          tile_col_num; // increments from 0 -> 31
   //reg[6:0] sprite_num; // increments from 0 -> 39
	integer i;
   
   always @(posedge clock) begin
      scanline_rst <= 1'b0;
      if (reset) begin
	 // initialize registers
     /*
     // TODO: Pokemon testing
	 LCDC 	<= 8'hE3; // FF40 //91
	 SCY 	<= 8'h00; //FF42 // 4f
	 SCX 	<= 8'h00; // FF43
	 LYC 	<= 8'h00; // FF45
	 //BGP 	<= 8'hFC; //fc
	 BGP 	<= 8'hE4; // FF47 //fc
	 OBP0 	<= 8'hE4; // FF48
	 OBP1 	<= 8'hE4; // FF49
	 WY 	<= 8'h90; // FF4A
	 WX		<= 8'h07; // FF4B
	 VRAM_BANK_SEL <= 8'h00;
     */
     
     // Default values:
     LCDC 	<= 8'h91; // FF40
	 SCY 	<= 8'h00; //FF42
	 SCX 	<= 8'h00; // FF43
	 LYC 	<= 8'h00; // FF45
	 BGP 	<= 8'hFC; // FF47
	 OBP0 	<= 8'hFF; // FF48
	 OBP1 	<= 8'hFF; // FF49
	 WY 	<= 8'h00; // FF4A
	 WX		<= 8'h00; // FF4B
	 VRAM_BANK_SEL <= 8'h00; // FF4F
	 
	 // reset internal registers
	 int_vblank_req <= 0;
	 int_lcdc_req <= 0;
	 mode <= 0;
	 state <= 0;
	 STAT_w <= 0;
	 
	 pixel_count <= 0;
	 line_count <= 0;
	 
	 vram_addrA <= 0;
	 vram_addrB <= 0;
      end
      else begin
	 // memory r/w
	 if (mem_enable) begin
	    if (!rd_n) begin
	       case (A)
		 16'hFF40: reg_out <= LCDC;
		 16'hFF41: reg_out <= STAT;
		 16'hFF42: reg_out <= SCY;
		 16'hFF43: reg_out <= SCX;
		 16'hFF44: reg_out <= line_count;
		 16'hFF45: reg_out <= LYC;
		 16'hFF47: reg_out <= BGP;
		 16'hFF48: reg_out <= OBP0;
		 16'hFF49: reg_out <= OBP1;
		 16'hFF4A: reg_out <= WY;
		 16'hFF4B: reg_out <= WX;
		 16'hFF4F: reg_out <= VRAM_BANK_SEL;
	       endcase
	    end
	    else if (!wr_n) begin
	       case (A)
		 16'hFF40: LCDC <= di;
		 16'hFF41: STAT_w[4:0] <= di[7:3];
		 16'hFF42: SCY <= di;
		 16'hFF43: SCX <= di;
		 16'hFF44: line_count <= 0; // TODO: why was this commented out?
		 16'hFF45: LYC <= di;
		 16'hFF47: BGP <= di;
		 16'hFF48: OBP0 <= di;
		 16'hFF49: OBP1 <= di;
		 16'hFF4A: WY <= di;
		 16'hFF4B: WX <= di;
		 16'hFF4F: VRAM_BANK_SEL <= di;
	       endcase
	    end
	 end
	 
	 // clear interrupts
	 if (int_vblank_ack) int_vblank_req <= 0;
	 
	 if (int_lcdc_ack)	int_lcdc_req <= 0;

	 if (LCDC[7]) begin // grapics enabled
	    
	    //////////////////////////////
	    // STAT INTERRUPTS AND MODE //
	    //////////////////////////////
	    
	    // vblank -- mode 1
	    if (line_count >= VACTIVE_VIDEO) begin
	       if (mode != VBLANK_MODE) begin					
		  int_vblank_req <= 1;
		  if (STAT[4]) int_lcdc_req <= 1;
		  
	       end
	       mode <= VBLANK_MODE;
	    end
	    
	    // oam lock -- mode 2
	    else if (pixel_count < OAM_ACTIVE) begin
	       if (STAT[5] && mode != OAM_LOCK_MODE)
		 int_lcdc_req <= 1;
	       mode <= OAM_LOCK_MODE;
	    end
	    
	    // ram + oam lock -- mode 3
	    else if (pixel_count < OAM_ACTIVE + RAM_ACTIVE) //begin
	      mode <= RAM_LOCK_MODE;
	    // does not generate an interrupt
	    //end
	    
	    // hblank -- mode 0
	    else begin
	       if (STAT[3] && mode != HBLANK_MODE) 
		 int_lcdc_req <= 1;
	       mode <= HBLANK_MODE;
	    end
	    
	    // lyc interrupt
	    if (pixel_count == 0 && line_count == LYC) //begin
	      // stat bit set automatically
	      if (STAT[6]) int_lcdc_req <= 1;
	    //end			

	    /////////////////////
	    // RENDER GRAPHICS //
	    /////////////////////
	    case (state)
	      IDLE_STATE: begin
		 if (mode == RAM_LOCK_MODE) begin
		    tile_col_num <= 0;
		    sprite_num <= 0;
		    pixel_data_count <= 0;
		    state <= BG_ADDR_STATE;
            
            // Reset the scanlines
            scanline_rst <= 1'b1;
		 end
	      end
	      
	      ////////////////
	      // BACKGROUND //
	      ////////////////
	      BG_ADDR_STATE: begin
		 // disable writes
		 scanlineA_we <= 0;
		 scanlineB_we <= 0;

		 if (LCDC[5] && WY <= line_count) begin // enable window
		    tile_x_pos <= {tile_col_num, 3'b0} + (WX - 7);
		    tile_y_pos <= (line_count - WY);
		    
			 // Get sprite index from background map
		    vram_addrA <= {(line_count - WY) >> 3, 5'b0} + //(tile_y_pos[7:3] << 5)
				  ({tile_col_num, 3'b0} >> 3) + // (tile_x_pos[7:3])
				  ((LCDC[6]) ? 16'h1C00 : 16'h1800);
			 
			 // Get sprite attributes from background map
			 vram2_addrA <= {(line_count - WY) >> 3, 5'b0} + //(tile_y_pos[7:3] << 5)
				  ({tile_col_num, 3'b0} >> 3) + // (tile_x_pos[7:3])
				  ((LCDC[6]) ? 16'h1C00 : 16'h1800);
		    
		    render_background <= 1;
		    state <= BG_ADDR_WAIT_STATE;
		 end
		 else if (LCDC[0]) begin // enable background
		    tile_x_pos <= {tile_col_num, 3'b0} + (-SCX);
		    tile_y_pos <= (SCY + line_count);
		    
            // Get sprite index from background map
		    vram_addrA <= {(SCY + line_count) >> 3, 5'b0} +
				  ({tile_col_num, 3'b0} >> 3) +
				  ((LCDC[3]) ? 16'h1C00 : 16'h1800);
			 
			 // Get sprite attributes from background map
			 vram2_addrA <= {(SCY + line_count) >> 3, 5'b0} +
				  ({tile_col_num, 3'b0} >> 3) +
				  ((LCDC[3]) ? 16'h1C00 : 16'h1800);
		    
		    render_background <= 1;
		    state <= BG_ADDR_WAIT_STATE;
		 end
		 else begin
			 /*
			  * TODO: GBC changes:
			  * If in GBC mode:
			  *
			  * when cleared background and window lose priority,\
			  * sprites always on top of bg and window independent of OAM and BG attribues
			  *
			  * GBC in non GBC mode: 
			  */
		    tile_x_pos <= {tile_col_num, 3'b0};
		    tile_y_pos <= line_count;
		    render_background <= 0;
		    state <= BG_PIXEL_COMPUTE_STATE;
		 end
	      end
	      
	      BG_ADDR_WAIT_STATE: //begin
		state <= BG_DATA_STATE;
	      //end
	      
	      BG_DATA_STATE: begin
/*
  vram2_outA contains sprite attributes:
			
  Bit 0-2  Background Palette number  (BGP0-7)
  Bit 3    Tile VRAM Bank number      (0=Bank 0, 1=Bank 1)
  Bit 4    Not used
  Bit 5    Horizontal Flip            (0=Normal, 1=Mirror horizontally)
  Bit 6    Vertical Flip              (0=Normal, 1=Mirror vertically)
  Bit 7    BG-to-OAM Priority         (0=Use OAM priority bit, 1=BG Priority)
*/			

			background_attributes <= vram2_outA;
         		 
		 // TODO: handle vertical background flipping here
         if (LCDC[4]) begin
            vram_addrA <= 16'h0000 + { vram_outA, 4'b0 } + { tile_y_pos[2:0], 1'b0 };
            vram_addrB <= 16'h0000 + { vram_outA, 4'b0 } + { tile_y_pos[2:0], 1'b0 } + 1;
            vram2_addrA <= 16'h0000 + { vram_outA, 4'b0 } + { tile_y_pos[2:0], 1'b0 };
            vram2_addrB <= 16'h0000 + { vram_outA, 4'b0 } + { tile_y_pos[2:0], 1'b0 } + 1;
         end else begin
            vram_addrA <= 13'h1000 + { vram_outA[7], vram_outA, 4'b0 } + { tile_y_pos[2:0], 1'b0 };
            vram_addrB <= 13'h1000 + { vram_outA[7], vram_outA, 4'b0 } + { tile_y_pos[2:0], 1'b0 } + 1;
            vram2_addrA <= 13'h1000 + { vram_outA[7], vram_outA, 4'b0 } + { tile_y_pos[2:0], 1'b0 };
            vram2_addrB <= 13'h1000 + { vram_outA[7], vram_outA, 4'b0 } + { tile_y_pos[2:0], 1'b0 } + 1;
         end

		 
		 state <= BG_DATA_WAIT_STATE;
	      end
	      
	      BG_DATA_WAIT_STATE: //begin
		state <= BG_PIXEL_COMPUTE_STATE;
	      //end
	      
	      BG_PIXEL_COMPUTE_STATE: begin
		 // Handle horizontal flipping
		 for (i = 0; i < 8; i = i + 1) begin
		   if (background_attributes[3]) begin
			  // Select sprite from bank 2
			  tile_data1[i] <= background_attributes[5] ? vram2_outA[7 - i] : vram2_outA[i];
			  tile_data2[i] <= background_attributes[5] ? vram2_outB[7 - i] : vram2_outB[i];
			end else begin
			  // Select sprite from bank 1
			  tile_data1[i] <= background_attributes[5] ? vram_outA[7 - i] : vram_outA[i];
			  tile_data2[i] <= background_attributes[5] ? vram_outB[7 - i] : vram_outB[i];
			end
		 end

		 tile_byte_pos1 <= tile_x_pos >> 3;
		 tile_byte_pos2 <= ((tile_x_pos + 8) & 8'hFF) >> 3;
		 tile_byte_offset1 <= tile_x_pos[2:0];
		 tile_byte_offset2 <= 8 - tile_x_pos[2:0];
		 state <= BG_PIXEL_READ_STATE;
	      end
	      
	      BG_PIXEL_READ_STATE: begin
		 scanline1_addrA <= tile_byte_pos1;
		 scanline1_addrB <= tile_byte_pos2;
		 scanline2_addrA <= tile_byte_pos1;
		 scanline2_addrB <= tile_byte_pos2;
         bg_scanline_addrA <= tile_byte_pos1;
         bg_scanline_addrB <= tile_byte_pos2;

         idx_scanline1_addrA <= tile_byte_pos1;
         idx_scanline1_addrB <= tile_byte_pos2;
         idx_scanline2_addrA <= tile_byte_pos1;
         idx_scanline2_addrB <= tile_byte_pos2;
         idx_scanline3_addrA <= tile_byte_pos1;
         idx_scanline3_addrB <= tile_byte_pos2;
		 state <= BG_PIXEL_WAIT_STATE;
	      end
	      
	      BG_PIXEL_WAIT_STATE: //begin
		state <= BG_PIXEL_WRITE_STATE;
	      //end
	      
	      BG_PIXEL_WRITE_STATE: begin
		 // first byte
		 scanline1_inA <= (render_background) ?
				  (scanline1_outA & (8'hFF << tile_byte_offset2) |
				   (tile_data1 >> tile_byte_offset1)) : 0;

		 scanline2_inA <= (render_background) ? 
				  (scanline2_outA & (8'hFF << tile_byte_offset2) |
				   (tile_data2 >> tile_byte_offset1)) : 0;
		 
		 // second byte
		 scanline1_inB <= (render_background) ? (scanline1_outB &
							 ~(8'hFF << tile_byte_offset2) |
							 (tile_data1 << tile_byte_offset2)) : 0;

		 scanline2_inB <= (render_background) ? (scanline2_outB &
							 ~(8'hFF << tile_byte_offset2) |
							 (tile_data2 << tile_byte_offset2)) : 0;
         // Reset bg scanline to 0
         bg_scanline_inA <= 8'b0;
         bg_scanline_inB <= 8'b0;

         // background index
		 idx_scanline1_inA <= background_attributes[0] ?
				  ((tile_col_num == 0 ? 8'hFF : idx_scanline1_outA) & (8'hFF << tile_byte_offset2) |
				   (8'hFF >> tile_byte_offset1)) :
                  ((tile_col_num == 0 ? 8'hFF : idx_scanline1_outA) & (8'hFF << tile_byte_offset2));
                  
         idx_scanline2_inA <= background_attributes[1] ?
				  ((tile_col_num == 0 ? 8'hFF : idx_scanline2_outA) & (8'hFF << tile_byte_offset2) |
				   (8'hFF >> tile_byte_offset1)) :
                  ((tile_col_num == 0 ? 8'hFF : idx_scanline2_outA) & (8'hFF << tile_byte_offset2));
                  
		 idx_scanline3_inA <= background_attributes[2] ?
				  ((tile_col_num == 0 ? 8'hFF : idx_scanline3_outA) & (8'hFF << tile_byte_offset2) |
				   (8'hFF >> tile_byte_offset1)) :
                  ((tile_col_num == 0 ? 8'hFF : idx_scanline3_outA) & (8'hFF << tile_byte_offset2));

         idx_scanline1_inB <= background_attributes[0] ? ((tile_col_num == 0 ? 8'hFF : idx_scanline1_outB) &
							 ~(8'hFF << tile_byte_offset2) |
							 (8'hFF << tile_byte_offset2)) :
                             ((tile_col_num == 0 ? 8'hFF : idx_scanline1_outB) & ~(8'hFF << tile_byte_offset2));
                             
         idx_scanline2_inB <= background_attributes[1] ? ((tile_col_num == 0 ? 8'hFF : idx_scanline2_outB) &
							 ~(8'hFF << tile_byte_offset2) |
							 (8'hFF << tile_byte_offset2)) :
                             ((tile_col_num == 0 ? 8'hFF : idx_scanline2_outB) & ~(8'hFF << tile_byte_offset2));
                             
         idx_scanline3_inB <= background_attributes[2] ? ((tile_col_num == 0 ? 8'hFF : idx_scanline3_outB) &
							 ~(8'hFF << tile_byte_offset2) |
							 (8'hFF << tile_byte_offset2)) :
                             ((tile_col_num == 0 ? 8'hFF : idx_scanline3_outB) & ~(8'hFF << tile_byte_offset2));

		 
		 // enable writes
		 scanlineA_we <= (tile_byte_pos1 < 20) ? 1 : 0;
		 scanlineB_we <= (tile_byte_pos2 < 20) ? 1 : 0;
		 state <= BG_PIXEL_HOLD_STATE;
	      end
	      
	      BG_PIXEL_HOLD_STATE: begin
		 // increment col
		 if (tile_col_num == 31)
		   state <= SPRITE_POS_STATE;
		 else begin
		    tile_col_num <= tile_col_num + 1;
		    state <= BG_ADDR_STATE;
		 end
	      end // 9 cycles * 32
	      
	      /////////////
	      // SPRITES //
	      /////////////
	      SPRITE_POS_STATE: begin
		 // disable writes
		 scanlineA_we <= 0;
		 scanlineB_we <= 0;
		 sprite_y_size <= LCDC[2] ? 16 : 8;
		 oam_addrA <= { sprite_num, 2'b00 }; // y pos
		 oam_addrB <= { sprite_num, 2'b01 }; // x pos
		 state <= SPRITE_POS_WAIT_STATE;
	      end
	      
	      SPRITE_POS_WAIT_STATE: //begin
		state <= SPRITE_ATTR_STATE;
	      //end
	      
	      SPRITE_ATTR_STATE: begin
		 sprite_y_pos <= oam_outA - 16;
		 sprite_x_pos <= oam_outB - 8;
		 if (line_count >= (oam_outA - 16) && line_count <
		     (oam_outA - 16) + sprite_y_size) begin
		    oam_addrA <= { sprite_num, 2'b10 }; // tile addr
		    oam_addrB <= { sprite_num, 2'b11 }; // attributes
		    state <= SPRITE_ATTR_WAIT_STATE;
		 end
		 else state <= SPRITE_HOLD_STATE;//begin
		 //state <= SPRITE_HOLD_STATE;
		 //end
	      end
	      
	      SPRITE_ATTR_WAIT_STATE: //begin
		state <= SPRITE_DATA_STATE;
	      //end
	      
	      SPRITE_DATA_STATE: begin
		 sprite_attributes <= oam_outB;
		 vram_addrA <= { (oam_outB[6]) ? 
				 ((line_count - sprite_y_pos) - sprite_y_size) * -1 :
				 (line_count - sprite_y_pos), 1'b0 } +
			       { oam_outA, 4'b0 };

		 vram_addrB <= { (oam_outB[6]) ?
				 ((line_count - sprite_y_pos) - sprite_y_size) * -1 :
				 (line_count - sprite_y_pos), 1'b0 } +
			       { oam_outA, 4'b0 } + 1;
					 
		 					 
		 vram2_addrA <= { (oam_outB[6]) ? 
				 ((line_count - sprite_y_pos) - sprite_y_size) * -1 :
				 (line_count - sprite_y_pos), 1'b0 } +
			       { oam_outA, 4'b0 };

		 vram2_addrB <= { (oam_outB[6]) ?
				 ((line_count - sprite_y_pos) - sprite_y_size) * -1 :
				 (line_count - sprite_y_pos), 1'b0 } +
			       { oam_outA, 4'b0 } + 1;
		 
		 state <= SPRITE_DATA_WAIT_STATE;
	      end
	      
	      SPRITE_DATA_WAIT_STATE: //begin
		state <= SPRITE_PIXEL_COMPUTE_STATE;
	      //end
	      
	      SPRITE_PIXEL_COMPUTE_STATE: begin
		 // Handle horizontal flipping
		 for (i = 0; i < 8; i = i + 1) begin
		   if (oam_outB[3]) begin
			  // Select sprite from bank 2
			  tile_data1[i] <= sprite_attributes[5] ? vram2_outA[7 - i] : vram2_outA[i];
			  tile_data2[i] <= sprite_attributes[5] ? vram2_outB[7 - i] : vram2_outB[i];
			end else begin
			  // Select sprite from bank 1
			  tile_data1[i] <= sprite_attributes[5] ? vram_outA[7 - i] : vram_outA[i];
			  tile_data2[i] <= sprite_attributes[5] ? vram_outB[7 - i] : vram_outB[i];
			end
		 end

		 tile_byte_pos1 <= sprite_x_pos >> 3;
		 tile_byte_pos2 <= (sprite_x_pos >> 3) + 1;
		 tile_byte_offset1 <= sprite_x_pos[2:0];
		 tile_byte_offset2 <= 8 - sprite_x_pos[2:0];
		 state <= SPRITE_PIXEL_READ_STATE;
	      end
	      
	      SPRITE_PIXEL_READ_STATE: begin
		 scanline1_addrA <= tile_byte_pos1;
		 scanline1_addrB <= tile_byte_pos2;
		 scanline2_addrA <= tile_byte_pos1;
		 scanline2_addrB <= tile_byte_pos2;
         bg_scanline_addrA <= tile_byte_pos1;
		 bg_scanline_addrB <= tile_byte_pos2;
         idx_scanline1_addrA <= tile_byte_pos1;
		 idx_scanline1_addrB <= tile_byte_pos2;
         idx_scanline2_addrA <= tile_byte_pos1;
		 idx_scanline2_addrB <= tile_byte_pos2;
         idx_scanline3_addrA <= tile_byte_pos1;
		 idx_scanline3_addrB <= tile_byte_pos2;
		 state <= SPRITE_PIXEL_WAIT_STATE;
	      end
	      
	      SPRITE_PIXEL_WAIT_STATE: begin
		 sprite_pixel_num <= 0;
		 /*
		 TODO: Handle GBC sprites
		 
  oam_out_B:
  Bit4   Palette number  **Non CGB Mode Only** (0=OBP0, 1=OBP1)
  Bit2-0 Palette number  **CGB Mode Only**     (OBP0-7)
  */
  
		 sprite_palette <= (sprite_attributes[4]) ? OBP1 : OBP0;
		 state <= SPRITE_PIXEL_DRAW_STATE;
	      end
	      
	      SPRITE_PIXEL_DRAW_STATE: begin
			/*
		 sprite_pixel <= (sprite_palette >> 
				  { tile_data2[sprite_pixel_num], 
				    tile_data1[sprite_pixel_num], 
				    1'b0 } ) & 2'b11;
		*/
		 sprite_pixel <=
				  { tile_data2[sprite_pixel_num], 
				    tile_data1[sprite_pixel_num] };

/*
		 bg_pixel <= (BGP >> (sprite_pixel_num < tile_byte_offset2) ?
			      { scanline2_outA[sprite_pixel_num + tile_byte_offset1],
				scanline1_outA[sprite_pixel_num + tile_byte_offset1], 
				1'b0 } :
			      { scanline2_outB[sprite_pixel_num - tile_byte_offset1],
				scanline1_outB[sprite_pixel_num - tile_byte_offset1], 
				1'b0 } ) & 2'b11;
				*/
		 bg_pixel <= (sprite_pixel_num >= tile_byte_offset1) ?
			{ scanline2_outA[sprite_pixel_num - tile_byte_offset1],
				scanline1_outA[sprite_pixel_num - tile_byte_offset1] } :
			{ scanline2_outB[sprite_pixel_num + tile_byte_offset2],
				scanline1_outB[sprite_pixel_num + tile_byte_offset2] };
                
         bg_idx <= (sprite_pixel_num >= tile_byte_offset1) ?
			{ idx_scanline3_outA[sprite_pixel_num - tile_byte_offset1],
              idx_scanline2_outA[sprite_pixel_num - tile_byte_offset1],
		      idx_scanline1_outA[sprite_pixel_num - tile_byte_offset1] } :
			{ idx_scanline3_outB[sprite_pixel_num + tile_byte_offset2],
              idx_scanline2_outB[sprite_pixel_num + tile_byte_offset2],
			  idx_scanline1_outB[sprite_pixel_num + tile_byte_offset2] };
		 
		 state <= SPRITE_PIXEL_DATA_STATE;
	      end
	      
	      SPRITE_PIXEL_DATA_STATE: begin
		 if (!LCDC[1] || sprite_pixel == 2'b00 || (sprite_attributes[7] &&
					       bg_pixel != 2'b00)) begin
		    sprite_data1 <= (sprite_data1 & ~(8'h01 << sprite_pixel_num)) |
				    (bg_pixel[0] << sprite_pixel_num);
		    sprite_data2 <= (sprite_data2 & ~(8'h01 << sprite_pixel_num)) |
				    (bg_pixel[1] << sprite_pixel_num);
                    
            sprite_bg_data1 <= (sprite_bg_data1 & ~(8'h01 << sprite_pixel_num)) |
				    (1'b0 << sprite_pixel_num);

            sprite_idx_data1 <= (sprite_idx_data1 & ~(8'h01 << sprite_pixel_num)) |
				    (bg_idx[0] << sprite_pixel_num);
            sprite_idx_data2 <= (sprite_idx_data2 & ~(8'h01 << sprite_pixel_num)) |
				    (bg_idx[1] << sprite_pixel_num);
            sprite_idx_data3 <= (sprite_idx_data3 & ~(8'h01 << sprite_pixel_num)) |
				    (bg_idx[2] << sprite_pixel_num);

		 end
		 else begin
		    sprite_data1 <= (sprite_data1 & ~(8'h01 << sprite_pixel_num)) |
				    (sprite_pixel[0] << sprite_pixel_num);
		    sprite_data2 <= (sprite_data2 & ~(8'h01 << sprite_pixel_num)) |
				    (sprite_pixel[1] << sprite_pixel_num);
                    
            sprite_bg_data1 <= (sprite_bg_data1 & ~(8'h01 << sprite_pixel_num)) |
				    (1'b1 << sprite_pixel_num);
                    
            sprite_idx_data1 <= (sprite_idx_data1 & ~(8'h01 << sprite_pixel_num)) |
				    (sprite_attributes[0] << sprite_pixel_num);
            sprite_idx_data2 <= (sprite_idx_data2 & ~(8'h01 << sprite_pixel_num)) |
				    (sprite_attributes[1] << sprite_pixel_num);
            sprite_idx_data3 <= (sprite_idx_data3 & ~(8'h01 << sprite_pixel_num)) |
				    (sprite_attributes[2] << sprite_pixel_num);
		 end
		 if (sprite_pixel_num < 7) begin
		    sprite_pixel_num <= sprite_pixel_num + 1;
		    state <= SPRITE_PIXEL_DRAW_STATE;
		 end
		 else state <= SPRITE_WRITE_STATE; //begin
		 //state <= SPRITE_WRITE_STATE;
		 //end
	      end
	      
	      SPRITE_WRITE_STATE: begin
		 // first byte
		 scanline1_inA <= (scanline1_outA & (8'hFF << tile_byte_offset2) |
				   (sprite_data1 >> tile_byte_offset1));
		 scanline2_inA <= (scanline2_outA & (8'hFF << tile_byte_offset2) |
				   (sprite_data2 >> tile_byte_offset1));
                   
         bg_scanline_inA <= (bg_scanline_outA & (8'hFF << tile_byte_offset2) |
				   (sprite_bg_data1 >> tile_byte_offset1));
         
         idx_scanline1_inA <= (idx_scanline1_outA & (8'hFF << tile_byte_offset2) |
				   (sprite_idx_data1 >> tile_byte_offset1));
         idx_scanline2_inA <= (idx_scanline2_outA & (8'hFF << tile_byte_offset2) |
				   (sprite_idx_data2 >> tile_byte_offset1));
         idx_scanline3_inA <= (idx_scanline3_outA & (8'hFF << tile_byte_offset2) |
				   (sprite_idx_data3 >> tile_byte_offset1));
		 
		 // second byte
		 scanline1_inB <= (scanline1_outB & ~(8'hFF << tile_byte_offset2) |
				   (sprite_data1 << tile_byte_offset2));
		 scanline2_inB <= (scanline2_outB & ~(8'hFF << tile_byte_offset2) |
				   (sprite_data2 << tile_byte_offset2));
                   
		 bg_scanline_inB <= (bg_scanline_outB & ~(8'hFF << tile_byte_offset2) |
				   (sprite_bg_data1 << tile_byte_offset2));
                   
         idx_scanline1_inB <= (idx_scanline1_outB & ~(8'hFF << tile_byte_offset2) |
				   (sprite_idx_data1 << tile_byte_offset2));	
         idx_scanline2_inB <= (idx_scanline2_outB & ~(8'hFF << tile_byte_offset2) |
				   (sprite_idx_data2 << tile_byte_offset2));
         idx_scanline3_inB <= (idx_scanline3_outB & ~(8'hFF << tile_byte_offset2) |
				   (sprite_idx_data3 << tile_byte_offset2));
           

		 // enable writes
		 scanlineA_we <= (tile_byte_pos1 < 20) ? 1 : 0;
		 scanlineB_we <= (tile_byte_pos2 < 20 && 
				  tile_byte_pos2 > tile_byte_pos1) ?
				 1 : 0; // don't wrap
		 state <= SPRITE_HOLD_STATE;
	      end
	      
	      SPRITE_HOLD_STATE: begin
		 if (sprite_num == 39)
		   state <= PIXEL_WAIT_STATE;
		 else begin
		    sprite_num <= sprite_num + 1;
		    state <= SPRITE_POS_STATE;
		 end
	      end // 13 cycles * 40
	      
	      /////////////
	      // DISPLAY //
	      /////////////
	      PIXEL_WAIT_STATE: begin
		 // disable writes
		 scanlineA_we <= 0;
		 scanlineB_we <= 0;
		 if (mode == HBLANK_MODE)
		   state <= PIXEL_READ_STATE;
	      end
	      
	      
	      PIXEL_READ_STATE: begin
		 scanline1_addrA <= pixel_data_count >> 3;
		 scanline2_addrA <= pixel_data_count >> 3;
         bg_scanline_addrA <= pixel_data_count >> 3;
         idx_scanline1_addrA <= pixel_data_count >> 3;
         idx_scanline2_addrA <= pixel_data_count >> 3;
         idx_scanline3_addrA <= pixel_data_count >> 3;
		 state <= PIXEL_READ_WAIT_STATE;
	      end
	      
	      PIXEL_READ_WAIT_STATE: begin
		state <= PIXEL_INDEX_STATE;
         end
         

			PIXEL_INDEX_STATE: begin
			   pixel_index <= { scanline2_outA[7 - pixel_data_count[2:0]], 
			      scanline1_outA[7 - pixel_data_count[2:0]] };

				bg_pal_idx <= { scanline2_outA[7 - pixel_data_count[2:0]], 
			      scanline1_outA[7 - pixel_data_count[2:0]] };

			  
				spr_pal_idx <=  { scanline2_outA[7 - pixel_data_count[2:0]], 
			      scanline1_outA[7 - pixel_data_count[2:0]] };


                is_spr_pix <= bg_scanline_outA[7 - pixel_data_count[2:0]];

			  bg_pal_sel <= {
                idx_scanline3_outA[7 - pixel_data_count[2:0]],
                idx_scanline2_outA[7 - pixel_data_count[2:0]],
                idx_scanline1_outA[7 - pixel_data_count[2:0]]
              };
                
			  spr_pal_sel <= {
                idx_scanline3_outA[7 - pixel_data_count[2:0]],
                idx_scanline2_outA[7 - pixel_data_count[2:0]],
                idx_scanline1_outA[7 - pixel_data_count[2:0]]
              };
			  
			  state <= PIXEL_OUT_STATE;
			end

	      
	      
	      PIXEL_OUT_STATE: begin
          /*
			if(pixel_index == 0)
                pixel_data <= 16'h2bf6;
			else if (pixel_index == 1)
				pixel_data <= 16'h072c;
			else if (pixel_index == 2)
				pixel_data <= 16'h01cf;
			else
				pixel_data <= 16'h1ce7;
                */
			pixel_data <= is_spr_pix ? spr_pal_col : bg_pal_col;
            
            // Output raw index data
            /*
		 pixel_data <=
         { 14'h0, scanline2_outA[7 - pixel_data_count[2:0]], 
			  scanline1_outA[7 - pixel_data_count[2:0]] };
              */

			/*
		 pixel_data <= (BGP >> 
				{ scanline2_outA[7 - pixel_data_count[2:0]], 
				  scanline1_outA[7 - pixel_data_count[2:0]], 
				  1'b0} ) & 2'b11;
				  */
		 pixel_we <= 1;
		 state <= PIXEL_OUT_HOLD_STATE;
	      end
	      
	      PIXEL_OUT_HOLD_STATE: begin
		 pixel_we <= 0;
		 state <= PIXEL_INCREMENT_STATE;
	      end
	      
	      PIXEL_INCREMENT_STATE: begin
		 if (pixel_data_count < 160) begin
		    pixel_data_count <= pixel_data_count + 1;
		    
		    if (pixel_data_count[2:0] == 7)
		      state <= PIXEL_READ_STATE;
		    else state <= PIXEL_INDEX_STATE;
		 end
		 else
		   state <= IDLE_STATE;
	      end
	      
	    endcase
	 end
	 else mode <= HBLANK_MODE;//begin
	 //mode <= HBLANK_MODE;
         //			end
	 
	 
	 // failsafe -- if we somehow exceed the allotted cycles for rendering
	 if (mode != RAM_LOCK_MODE && state < PIXEL_WAIT_STATE && 
	     state > IDLE_STATE)
	   state <= PIXEL_WAIT_STATE;
	 
	 // If GPU not reading from RAM, get vram_addrA from MMU
	 if (mode < RAM_LOCK_MODE) begin
	   vram_addrA <= A - 16'h8000;
		vram2_addrA <= A - 16'h8000;
	 end
	 
	 // If GPU not reading from OAM, get oam_addrA from MMU
	 if (mode < OAM_LOCK_MODE)
	   oam_addrA <= A - 16'hFE00;
	 
	 if (clock_enable) begin
	    pixel_count <= next_pixel_count;
	    line_count <= next_line_count;
	 end	
      end
   end
   
   // If LCD display is enabled, next_pixel_count = pixel_count + 1, 
   // looping around max # of pixels. If not enabled, set pixel_count to 0.
   assign next_pixel_count = (LCDC[7]) ? 
			     ((pixel_count == PIXELS - 1) ? 0 :	pixel_count + 1) : 0;
   
   // If LCD display is enabled, next_line_count = line_count + 1, 
   // looping around max # of lines. If not enabled, set line_count to 0
   assign next_line_count = (LCDC[7]) ?
			    ((pixel_count == PIXELS - 1) ?((line_count == LINES - 1) ? 
				                           0 : line_count + 1) : line_count) : 0;
   
   // Set both horizontal and vertical sync				
   assign hsync = (pixel_count > OAM_ACTIVE + RAM_ACTIVE + HACTIVE_VIDEO) ? 1 : 0;
   assign vsync = (line_count > VACTIVE_VIDEO) ? 1 : 0;
   
   // vram_enable set when MMU enables mem and addr is 
   // between 0x8000 and 0xA000
   assign vram_enable = mem_enable && (A >= 16'h8000 && A < 16'hA000);
   
   // oam_enable set when MMU enables mem and addr is 
   // between 0xFE00 and 0xFEA0
   assign oam_enable = mem_enable && (A >= 16'hFE00 && A < 16'hFEA0);
   
   // reg_enable set when MMU enables mem and the addr 
   // isn't in VRAM or OAM
   assign reg_enable = mem_enable && !vram_enable && !oam_enable;
   
   // vram_we_n set when vram enabled, MMU is trying to write,
   // and the RAM is not locked
   assign vram_we_n = !(~VRAM_BANK_SEL[0] && vram_enable && !wr_n && mode != RAM_LOCK_MODE);
   assign vram2_we_n = !(VRAM_BANK_SEL[0] && vram_enable && !wr_n && mode != RAM_LOCK_MODE);
   
   // oam_we_n set when oam enabled, MMU is trying to write,
   // and neither the RAM nor OAM are locked
   assign oam_we_n = !(oam_enable && !wr_n && 
		       mode != RAM_LOCK_MODE && 
		       mode != OAM_LOCK_MODE);
   
   // programmer can only write to top 5 bits of STAT register						
   assign STAT[7:3] = STAT_w[4:0]; // r/w
   
   // set if line count is the same as LYC
   assign STAT[2] = (line_count == LYC) ? 1 : 0; // LYC Coincidence flag
   
   // set the mode of the Gameboy GPU
   assign STAT[1:0] = mode; // read only -- set internally
   
   assign debug_out = (vram_addrA << 16) | (line_count << 8) | (vram_outA);
   
   // 'do' is data out for MMU
   // If vram_enable, read VRAM
   // Else if oam_enable, read OAM
   // Else if reg_enable, read a memory-mapped register
   // Else give the MMU 0xFF
   assign data_out = (vram_enable) ? (VRAM_BANK_SEL[0] ? vram2_outA : vram_outA) :
	       (oam_enable) ? oam_outA :
			 (color_file_enable) ? color_file_out : 
	       (reg_enable) ? reg_out : 8'hFF;
   
endmodule
