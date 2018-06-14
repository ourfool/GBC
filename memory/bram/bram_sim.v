// Fake memory for simulation testing
// Initializes from memfile

// Fake memory for simulation testing
// Initializes from memfile

module bram_cart(
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
     size = 65536; // in bytes

   input clka;
   input rsta;
   input [0 : 0] wea;
   input [14 : 0] addra;
   input [7 : 0]  dina;
   output reg [7 : 0] douta;
   input [0 : 0]      web;
   input [14 : 0]     addrb;
   input [7 : 0]      dinb;
   output reg [7 : 0] doutb;

   reg [7:0] 	      i_mem[0:size-1];

   always @(posedge clka or posedge rsta) begin
      if(rsta) begin
         $readmemh("cart.dat", i_mem);
      end else begin
         if(wea)
             i_mem[addra] <= dina;
         if(web)
             i_mem[addrb] <= dinb;
      end
   end

   always @(posedge clka) begin
      douta <=  i_mem[addra];
      doutb <=  i_mem[addrb];
   end

endmodule

module bram(
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
     size = 65536; // in bytes

   input clka;
   input rsta;
   input [0 : 0] wea;
   input [14 : 0] addra;
   input [7 : 0]  dina;
   output reg [7 : 0] douta;
   input [0 : 0]      web;
   input [14 : 0]     addrb;
   input [7 : 0]      dinb;
   output reg [7 : 0] doutb;

   reg [7:0] 	      i_mem[0:size-1];
   
   integer i;

   always @(posedge clka or posedge rsta) begin
      if(rsta) begin
         for (i = 0; i < size; i = i + 1) begin
            i_mem[i] <= 8'hee;
         end
      end else begin
         if(wea)
           i_mem[addra] <= dina;
         if(web)
           i_mem[addrb] <= dinb;
      end
   end

   always @(posedge clka) begin
      douta <=  i_mem[addra];
      doutb <=  i_mem[addrb];
   end

endmodule

module OAM(
	    clka,
        clkb,
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
     size = 65536; // in bytes

   input clka, clkb;
   input rsta;
   input [0 : 0] wea;
   input [14 : 0] addra;
   input [7 : 0]  dina;
   output reg [7 : 0] douta;
   input [0 : 0]      web;
   input [14 : 0]     addrb;
   input [7 : 0]      dinb;
   output reg [7 : 0] doutb;

   reg [7:0] 	      i_mem[0:size-1];
   
   integer i;

   always @(posedge clka or posedge clkb or posedge rsta) begin
      if(rsta) begin
         for (i = 0; i < size; i = i + 1) begin
            i_mem[i] <= 8'hee;
         end
      end else begin
         if(wea)
           i_mem[addra] <= dina;
         if(web)
           i_mem[addrb] <= dinb;
      end
   end

   always @(posedge clka) begin
      douta <=  i_mem[addra];
      doutb <=  i_mem[addrb];
   end

endmodule

module VRAM(
	    clka,
        clkb,
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
     size = 65536; // in bytes

   input clka, clkb;
   input rsta;
   input [0 : 0] wea;
   input [14 : 0] addra;
   input [7 : 0]  dina;
   output reg [7 : 0] douta;
   input [0 : 0]      web;
   input [14 : 0]     addrb;
   input [7 : 0]      dinb;
   output reg [7 : 0] doutb;

   reg [7:0] 	      i_mem[0:size-1];
   
   integer i;

   always @(posedge clka or posedge clkb or posedge rsta) begin
      if(rsta) begin
         for (i = 0; i < size; i = i + 1) begin
            i_mem[i] <= 8'hee;
         end
      end else begin
         if(wea)
           i_mem[addra] <= dina;
         if(web)
           i_mem[addrb] <= dinb;
      end
   end

   always @(posedge clka) begin
      douta <=  i_mem[addra];
      doutb <=  i_mem[addrb];
   end

endmodule

module VRAM2(
	    clka,
        clkb,
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
     size = 65536; // in bytes

   input clka, clkb;
   input rsta;
   input [0 : 0] wea;
   input [14 : 0] addra;
   input [7 : 0]  dina;
   output reg [7 : 0] douta;
   input [0 : 0]      web;
   input [14 : 0]     addrb;
   input [7 : 0]      dinb;
   output reg [7 : 0] doutb;

   reg [7:0] 	      i_mem[0:size-1];
   
   integer i;

   always @(posedge clka or posedge rsta) begin
      if(rsta) begin
         for (i = 0; i < size; i = i + 1) begin
            i_mem[i] <= 8'hee;
         end
      end else begin
         if(wea)
           i_mem[addra] <= dina;
         if(web)
           i_mem[addrb] <= dinb;
      end
   end

   always @(posedge clka) begin
      douta <=  i_mem[addra];
      doutb <=  i_mem[addrb];
   end

endmodule

module framebuffer1(
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
     size = 65536; // in bytes

   input clka;
   input rsta;
   input [0 : 0] wea;
   input [14 : 0] addra;
   input [7 : 0]  dina;
   output reg [7 : 0] douta;
   input [0 : 0]      web;
   input [14 : 0]     addrb;
   input [7 : 0]      dinb;
   output reg [7 : 0] doutb;

   reg [7:0] 	      i_mem[0:size-1];
   
   integer i;

   always @(posedge clka or posedge rsta) begin
      if(rsta) begin
         for (i = 0; i < size; i = i + 1) begin
            i_mem[i] <= 8'hee;
         end
      end else begin
         if(wea)
           i_mem[addra] <= dina;
         if(web)
           i_mem[addrb] <= dinb;
      end
   end

   always @(posedge clka) begin
      douta <=  i_mem[addra];
      doutb <=  i_mem[addrb];
   end

endmodule

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
     size = 65536; // in bytes

   input clka;
   input rsta;
   input [0 : 0] wea;
   input [14 : 0] addra;
   input [7 : 0]  dina;
   output reg [7 : 0] douta;
   input [0 : 0]      web;
   input [14 : 0]     addrb;
   input [7 : 0]      dinb;
   output reg [7 : 0] doutb;

   reg [7:0] 	      i_mem[0:size-1];
   
   integer i;

   always @(posedge clka or posedge rsta) begin
      if(rsta) begin
         for (i = 0; i < size; i = i + 1) begin
            i_mem[i] <= 8'hee;
         end
      end else begin
         if(wea)
           i_mem[addra] <= dina;
         if(web)
           i_mem[addrb] <= dinb;
      end
   end

   always @(posedge clka) begin
      douta <=  i_mem[addra];
      doutb <=  i_mem[addrb];
   end

endmodule

module sound_bram2(
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
     size = 65536; // in bytes

   input clka;
   input rsta;
   input [0 : 0] wea;
   input [14 : 0] addra;
   input [7 : 0]  dina;
   output reg [7 : 0] douta;
   input [0 : 0]      web;
   input [14 : 0]     addrb;
   input [7 : 0]      dinb;
   output reg [7 : 0] doutb;

   reg [7:0] 	      i_mem[0:size-1];
   
   integer i;

   always @(posedge clka or posedge rsta) begin
      if(rsta) begin
         for (i = 0; i < size; i = i + 1) begin
            i_mem[i] <= 8'hee;
         end
      end else begin
         if(wea)
           i_mem[addra] <= dina;
         if(web)
           i_mem[addrb] <= dinb;
      end
   end

   always @(posedge clka) begin
      douta <=  i_mem[addra];
      doutb <=  i_mem[addrb];
   end

endmodule

module bram_save(
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
     size = 65536; // in bytes

   input clka;
   input rsta;
   input [0 : 0] wea;
   input [14 : 0] addra;
   input [7 : 0]  dina;
   output reg [7 : 0] douta;
   input [0 : 0]      web;
   input [14 : 0]     addrb;
   input [7 : 0]      dinb;
   output reg [7 : 0] doutb;

   reg [7:0]        i_mem[0:size-1];
   
   integer i;

   always @(posedge clka or posedge rsta) begin
      if(rsta) begin
         for (i = 0; i < size; i = i + 1) begin
            i_mem[i] <= 8'hde;
         end
      end else begin
         if(wea)
           i_mem[addra] <= dina;
         if(web)
           i_mem[addrb] <= dinb;
      end
   end

   always @(posedge clka) begin
      douta <=  i_mem[addra];
      doutb <=  i_mem[addrb];
   end

endmodule
