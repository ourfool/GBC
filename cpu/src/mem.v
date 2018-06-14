`default_nettype none

/**
 * Very simple bus-based memory module.
 *
 * Author: Joseph Carlos (jdcarlos1@gmail.com)
 */

module mem(
   // Inouts
   data_ext,
   // Inputs
   addr_ext, mem_we, mem_re, reset, clock
   );

   parameter size = 512; // in bytes

   inout [7:0]  data_ext;

   input [15:0] addr_ext;
   input        mem_we, mem_re;
   input        reset, clock;

   reg [7:0]    data[0:size-1];

   integer      i;

   always @(posedge clock or posedge reset) begin
      if (reset) begin
         for (i = 0; i < size; i = i + 1) begin
            data[i] <= 8'hee;
         end
      end else if(mem_we) begin
         data[addr_ext] <= data_ext;
      end
   end

   assign data_ext = (mem_re) ? data[addr_ext] : 8'bzzzzzzzz;

endmodule
