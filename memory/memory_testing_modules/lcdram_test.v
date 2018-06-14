/*lcd ram without banking controll*/

`default_nettype none

module lcdram_test(
		   I_MEM_CLK,
		   I_RESET,
		   I_LCDRAM_ADDR,
		   IO_LCDRAM_DATA,
		   I_LCDRAM_WE_L,
		   I_LCDRAM_RE_L
		   );

   input I_MEM_CLK, I_RESET;
   input [15:0] I_LCDRAM_ADDR;
   inout [7:0] 	IO_LCDRAM_DATA;
   input 	I_LCDRAM_WE_L, I_LCDRAM_RE_L;
   
   wire 	bram_en;
   wire 	bram_we;
   wire [15:0] 	router_addr;
   wire [15:0] 	bram_banked_addr;
   wire [15:0] 	bram_addr;
   wire [7:0] 	bram_data_in2, bram_data_out2;
   
   assign bram_addr = router_addr[14:0];
   

   bram_wrapper #(16'h0FFF) ifconverter(
				       .I_CLK(I_MEM_CLK),
				       .I_RESET(I_RESET),
				       .I_ADDR(I_LCDRAM_ADDR),
				       .IO_DATA(IO_LCDRAM_DATA),
				       .I_WE_L(I_LCDRAM_WE_L),
				       .I_RE_L(I_LCDRAM_RE_L),
				       .O_BRAM_EN(bram_en),
				       .O_BRAM_WE(bram_we),
				       .O_BRAM_ADDR(router_addr),
				       .O_BRAM_DIN(bram_data_in2),
				       .I_BRAM_DOUT(bram_data_out2)
				       );


      /* Actual Memory Location*/
   bram lcdbram(
		.clka(I_MEM_CLK),
        .rsta(I_RESET),
		.wea(bram_we),
		.addra(bram_addr),
		.dina(bram_data_in2),
		.douta(bram_data_out2)
		);
endmodule // lcdram_test

   