module sound_bram(
	              clka,
	              rsta,
	              wea,
	              addra,
	              dina,
	              douta,
	              web,
	              addrb,
	              dinb,
	              doutb
	              );

   parameter
     size = 2048; // in bytes

   input clka;
   input [0 : 0] wea;
   input [10 : 0] addra;
   input [31 : 0]  dina;
   output reg [31 : 0] douta;

   reg [31:0]         i_mem[0:size-1];

   initial begin
      $readmemh("lookup_table.dat", i_mem);
   end
   
   always @(posedge clka or posedge rsta) begin
         if(wea)
           i_mem[addra] <= dina;
         if(web)
           i_mem[addrb] <= dinb;
   end

   always @(posedge clka) begin
      douta <=  i_mem[addra];
      doutb <=  i_mem[addrb];
   end


endmodule