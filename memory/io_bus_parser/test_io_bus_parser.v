`include "io_bus_parser.v"

/*IO BUS PARSER UNIT TEST*/

module test_io_bus_parser();

   reg clk, reset;
   tri [7:0] io_bus;
   reg [7:0] write_data;
   reg       read_data;
   reg       en_dbus;
   reg [15:0] addr_bus;
   reg we_bus;
   reg re_bus;
   reg [7:0] data_wr1, data_wr2;
   wire [7:0] data_rd1, data_rd2;
   wire       data_wait1, data_wait2;
   reg 	      write_reg1, write_reg2;

   /*Clock Instantiation*/
   always
     #5 clk = ~clk;

   /* Initial Values */
   initial begin
      clk = 0;
      reset = 0;
      we_bus = 1;
      re_bus = 1;
      en_dbus = 0;
      data_wr1 = 0;
      data_wr2 = 0;
      write_reg1 = 0;
      write_reg2 = 0;
   end

   /*Test Instantiation - use an address of
    * 0x00A0 and a reset value of 5*/
   io_bus_parser_reg #(16'h00A0, 5)  dut1 (.I_CLK(clk),
                                         .I_SYNC_RESET(reset),
                                         .IO_DATA_BUS(io_bus),
                                         .I_ADDR_BUS(addr_bus),
                                         .I_WE_BUS_L(we_bus),
                                         .I_RE_BUS_L(re_bus),
                                         .I_DATA_WR(data_wr1),
                                         .O_DATA_READ(data_rd1),
                                         .I_REG_WR_EN(write_reg1),
                                         .O_WAIT(data_wait1)
                                         );

   io_bus_parser_reg #(16'h00B0, 6)  dut2 (.I_CLK(clk),
                                         .I_SYNC_RESET(reset),
                                         .IO_DATA_BUS(io_bus),
                                         .I_ADDR_BUS(addr_bus),
                                         .I_WE_BUS_L(we_bus),
                                         .I_RE_BUS_L(re_bus),
                                         .I_DATA_WR(data_wr2),
                                         .O_DATA_READ(data_rd2),
                                         .I_REG_WR_EN(write_reg2),
                                         .O_WAIT(data_wait2)
                                         );

   always @(posedge clk)
     $display("addr_bus: %h io_bus: %h bus_we: %b bus_re: %b | data_wr1: %h we1: %b wait1: %b | data_wr2: %h we2: %b wait2: %b | data1: %h data2: %h", 
	      addr_bus, io_bus, we_bus, re_bus, data_wr1, write_reg1, data_wait1, data_wr2, write_reg2, data_wait2, data_rd1, data_rd2);

   assign io_bus = (en_dbus) ? write_data : 'bzzzzzzzz;

   /*BUS_WRITE- task to write a value to the register
    *given the data value*/
   task bus_write;
      input [15:0] address;
      input [7:0]  data;
      begin

         @(posedge clk );
         en_dbus <= 1;
         we_bus <= 0;
         addr_bus <= address;
         write_data <= data;
         @(posedge clk);
         en_dbus <= 0;
         we_bus <= 1;
         @(posedge clk);
      end
   endtask // io_bus_write

   /*BUS_READ - task to read a data bus and returns
    *the data value to a register*/
   task bus_read;
      input [15:0] address;
      output [7:0] register;
      begin
         @(posedge clk);
         re_bus <= 0;
         addr_bus <= address;
         @(posedge clk);
         re_bus <= 1;
         register <= io_bus;
         @(posedge clk);
      end
   endtask // io_bus_read

   task user_write;
      input [15:0] data;
      begin
	 @(posedge clk);
	 data_wr1 <= data;
	 write_reg1 <= 1;
	 @(posedge clk);
	 while (data_wait1) begin
	    @(posedge clk);
	 end
	 write_reg1 <= 0;
	 @ (posedge clk);
      end
   endtask // user_write
   
   integer i;
   integer randomNum;
   /*Bus Reader and Writer*/
   initial begin
      @(posedge clk);
      reset <= 1;
      @(posedge clk);
      reset <= 0;
      @(posedge clk);
      for( i = 0; i < 200; i=i+1) begin
	 randomNum = $random % 4;
	 if (randomNum == 0)
	   bus_read(16'h00A0, read_data);
	 else if (randomNum == 1) 
	   bus_write(16'h00A0, $random % 256);
	 else if (randomNum == 2)
	   bus_read(16'h00B0, read_data);
	 else
	   bus_write(16'h00B0, $random % 256);
      end // for ( i = 0; i < 200; i=i+1)
      #100 $finish;
   end // initial begin

   integer j;
   initial begin
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      for (j = 0; j < 100; j=j+1) begin
	 user_write($random % 256);
      end
   end
   
	 

endmodule // test_io_bus_parser















