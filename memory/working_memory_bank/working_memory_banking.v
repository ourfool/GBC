`include "../memory_router/memdef.vh"
`default_nettype none

/*WORKING MEMORY BANK - reads the specified working bank from
 * the io bus register and determines whether the address to
 * send the bram block.  Since the bram is 36kB and the
 * total working memory is 32 kB, we can simply divide this up
 * into 4kB address spaces.  The start of the banks' address space
 * will be determined by the input bram address as follows:
 *
 * bank 0 -> 0b00000000000000
 * bank 1 -> 0b00100000000000
 * bank 2 -> 0b01000000000000
 * bank 3 -> 0b01100000000000
 *
 * and so on.
 *
 * Note that the way the GBC is set up, the access to bank zero
 * is independent of the SVBK register and it has its own address
 * space (0xC000 - 0xCFFF) where as the address space of (0xD000 -
 * 0XDFFF) is shared accross memory banks.  This is taken into acount
 * into the final logic that goes into the bram block*/
module working_memory_bank(
			   I_CLK,
			   I_MEM_CLK,
			   I_RESET,

			   /*Interface with IO Register Bus
			    *to get the current working bank*/
			   I_IOREG_ADDR,
			   IO_IOREG_DATA,
			   I_IOREG_WE_L,
			   I_IOREG_RE_L,

			   /* Interface with Router to handle
			    * working ram transactions*/
			   I_WRAM_ADDR,
			   IO_WRAM_DATA,
			   I_WRAM_WE_L,
			   I_WRAM_RE_L,

			   /*to make sure in DMG mode, only
			    *one bank can be used*/
			   I_IN_DMG_MODE);

   input        I_CLK, I_MEM_CLK, I_RESET;
   input [15:0] I_IOREG_ADDR, I_WRAM_ADDR;
   inout [7:0] 	IO_IOREG_DATA, IO_WRAM_DATA;
   input 	I_IOREG_WE_L, I_IOREG_RE_L,
		    I_WRAM_WE_L, I_WRAM_RE_L;
   input 	I_IN_DMG_MODE;

   wire [7:0]	svbk_data;
   wire 	write_ioreg_l;

   wire 	is_bank_zero;


   /*only write to the io register in gameboy color mode*/
   assign write_ioreg_l = ~((~I_IOREG_WE_L) & (~I_IN_DMG_MODE));

   /* Bank Specification Register*/
   io_bus_parser_reg #(`SVBK,0)  svbk_reg(
					  .I_CLK(I_CLK),
					  .I_SYNC_RESET(I_RESET),
					  .IO_DATA_BUS(IO_IOREG_DATA),
					  .I_ADDR_BUS(I_IOREG_ADDR),
					  .I_WE_BUS_L(write_ioreg_l),
					  .I_RE_BUS_L(I_IOREG_RE_L),
					  .O_DATA_READ(svbk_data));

   /*the use of bank 0 is indicated such that top top 4 bits of
    * the incoming address will be 0xC, or 0xE (echo memory) */
   assign is_bank_zero =  (I_WRAM_ADDR[15:12] == 4'hC || I_WRAM_ADDR[15:12] == 4'hE);

   wire 		bram_en;
   wire 		bram_we;
   wire [15:0] 		router_addr;
   wire [15:0] 		bram_banked_addr;
   wire [15:0] 		bram_addr;
   wire [7:0] 		bram_data_in, bram_data_out1;
   wire [2:0] 		bank_selection;

   /*from the register get the working bank information*/
   assign bank_selection = svbk_data[2:0];

   assign bram_banked_addr[15] = 0;
   /*specifiy bank by offsetting it into the address*/
   assign bram_banked_addr[14:12] = (svbk_data[2:0] == 3'd0) ? 3'b001 : bank_selection;
   /*keep the offset from the "base of bank" address location*/
   assign bram_banked_addr[11:0] = router_addr[11:0];

   /*if using bank zero keep the same address, else use the modified one
    *to get information from a different spot in the bram chunk*/
   assign bram_addr = (is_bank_zero) ?  router_addr[15:0] : bram_banked_addr[15:0];


   /*keep only 12 bits since we are working with
    *4 kbyte segments of memory*/
   bram_wrapper #(16'h0FFF) ifconverter(
				       .I_CLK(I_MEM_CLK),
				       .I_RESET(I_RESET),
				       .I_ADDR(I_WRAM_ADDR),
				       .IO_DATA(IO_WRAM_DATA),
				       .I_WE_L(I_WRAM_WE_L),
				       .I_RE_L(I_WRAM_RE_L),
				       .O_BRAM_WE(bram_we),
				       .O_BRAM_ADDR(router_addr),
				       .O_BRAM_DIN(bram_data_in),
				       .I_BRAM_DOUT(bram_data_out1)
				       );
   /* Actual Memory Location*/
   bram banked_memory(
		      .clka(I_MEM_CLK),
              .rsta(I_RESET),
		      .wea(bram_we),
		      .addra(bram_addr),
		      .dina(bram_data_in),
		      .douta(bram_data_out1)
		      );

endmodule // working_memory_bank
