`default_nettype none

module bram_wrapper(
    I_CLK,
    I_RESET,

    I_ADDR,
    IO_DATA,
    I_WE_L,
    I_RE_L,

    O_BRAM_EN,
    O_BRAM_WE,
    O_BRAM_ADDR,
    O_BRAM_DIN,
    I_BRAM_DOUT
    );

   /*since all bram starts at 0x0000, and in our memory system, 
    *the address that is associated with the particular 
    *BRAM component may not start at zero, a mask is needed to 
    *make sure the BRAM address starts at 0x0000 (where the upper
    *bits are determined by the memory router*/ 
   parameter P_OFFSET_MASK = 16'h00FF;
   
   input           I_CLK, I_RESET;
   input [15:0]    I_ADDR;
   inout [7:0] 	 IO_DATA;
   input 	       I_WE_L, I_RE_L;
   
   output          O_BRAM_EN;
   output 	       O_BRAM_WE;
   output [15:0]   O_BRAM_ADDR;
   output [7:0]    O_BRAM_DIN;
   input [7:0] 	 I_BRAM_DOUT;

   // Internal variables   
   wire [7:0] 	   data_out;
   reg            bus_en;
   
   assign O_BRAM_ADDR = I_ADDR & P_OFFSET_MASK;
   assign O_BRAM_WE = ~I_WE_L;
   assign O_BRAM_EN = (~I_WE_L) | (~I_RE_L);
   assign IO_DATA = (bus_en) ? I_BRAM_DOUT: 8'bzzzzzzzz;
   assign O_BRAM_DIN = IO_DATA;
   
   always @(posedge I_CLK) begin
        bus_en <= ~I_RE_L;
   end
   
endmodule // bram_router

