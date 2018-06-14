`define READ_ONLY 2'b10
`define WRITE_ONLY 2'b01
`default_nettype none


/* IO BUS PARSER*/

module io_bus_parser_reg (
                         /*System Level Signals*/
                         I_CLK,
                         I_SYNC_RESET,

                         /*Interface with the memory router*/
                         IO_DATA_BUS,
                         I_ADDR_BUS,
                         I_WE_BUS_L,
                         I_RE_BUS_L,

                         /*Interface with external modules*/
                         I_DATA_WR, //to write to the io register
                         O_DATA_READ, //to read from the io register
                         I_REG_WR_EN,
                         O_DBUS_WRITE,//indicates a new value in the register
                         O_WAIT); //active high, write data to register

   parameter P_REGISTER_ADDR = 16'h0000;
   parameter P_DATA_RST_VAL = 8'h00;
   parameter P_FORWARD_DATA = 0;
   parameter P_RESET_ON_READ = 0;
   /*MODE:
    * 00 - read/write access
    * 01 - write only access
    * 10 - read only access
    */
   parameter P_MODE = 2'b00;


   /*Description of interface with the
    *io bus from the memory router*/
   input        I_CLK, I_SYNC_RESET;
   inout [7:0]  IO_DATA_BUS;
   input [15:0] I_ADDR_BUS;
   input        I_WE_BUS_L, I_RE_BUS_L;

   /*Description of the interface with the
    *external module accessing the io register*/
   input [7:0]  I_DATA_WR;
   output [7:0] O_DATA_READ;
   input        I_REG_WR_EN;
   output reg   O_DBUS_WRITE;
   output       O_WAIT;


   reg [7:0] io_register;
   wire      data_bus_en;
   wire [7:0] write_bus_data;

   /*tell external module to wait if the CPU memory mapped IO
     write transaction is taking place*/
   assign O_WAIT = ~I_WE_BUS_L & (I_ADDR_BUS == P_REGISTER_ADDR);

   /*always make reading the register available*/
   assign O_DATA_READ = io_register;

   /*write to the tristate data bus when indicated to do so*/
   assign IO_DATA_BUS = (data_bus_en) ? write_bus_data : 8'bzzzzzzzz;

   wire      address_match;
   assign address_match = (I_ADDR_BUS == P_REGISTER_ADDR);

   /*forwards the data being written, else return the register contents*/
   assign write_bus_data = (I_REG_WR_EN & P_FORWARD_DATA) ? I_DATA_WR : io_register;
   assign data_bus_en = (address_match & ~I_RE_BUS_L & (P_MODE != `WRITE_ONLY));

   always @(posedge I_CLK) begin

      io_register <= io_register;
      O_DBUS_WRITE <= 0;

      /*if the IO register identifies itself*/
      if (address_match) begin

         /*if any write transaction for the bus,
          *service it, ingoring all other interfaces*/
         if (~I_WE_BUS_L & (P_MODE != `READ_ONLY)) begin
            io_register <= IO_DATA_BUS;
            O_DBUS_WRITE <= 1;
         end
         /*if only writing from the external module,
           load the data in*/
         else if (I_REG_WR_EN) begin
            io_register <= I_DATA_WR;
         end

	 else begin
	    io_register <= io_register;
	 end

	 /*if a read triggers a register reset*/
	 if (P_RESET_ON_READ & ~I_RE_BUS_L)
	     io_register <= P_DATA_RST_VAL;

      end

      /* put reset at the end to supercede all
         other transactions */
      if (I_SYNC_RESET) begin
         io_register <= P_DATA_RST_VAL;
      end

   end // always @ (posedge I_CLK)


endmodule


