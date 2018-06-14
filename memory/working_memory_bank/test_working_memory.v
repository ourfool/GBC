module my_working_memory_test();

   wire clock33, clock8, clock16,  reset;
   wire [7:0] iobus, membus;
   wire [7:0] iobus_data, membus_data;
   wire [15:0] iobus_addr, membus_addr;
   wire        we_iobus, re_iobus, we_iobus, re_iobus;
   wire        en_iobus, en_membus;
   reg         rd_data;

   assign membus = (en_membus) ? membus_data : 'bzzzzzzzz;
   assign iobus = (en_iobus) ? iobus_data : 'bzzzzzzzz;

   my_clock_divider #(15,2) cd1(.clock_out(clock8), .clock_in(clock33));
   my_clock_divider #(15,1) cd2(.clock_out(clock16), .clock_in(clock33));

   /*Clock Instantiation*/
   always
     #5 clk33 = ~clk33;

   /* Initial Values */
   initial begin
      clk33 = 0;
      reset = 0;
      we_iobus = 1;
      re_iobus = 1;
      we_membus = 1;
      re_membus = 1;
      en_iobus = 0;
      en_membus = 0;
   end

   working_memory_bank dut (
			                .I_CLK(clock8),
			                .I_MEM_CLK(clock16),
			                .I_RESET(reset),
			                .I_IOREG_ADDR(iobus_addr),
			                .IO_IOREG_DATA(iobus),
			                .I_IOREG_WE_L(iobus_we_l),
			                .I_IOREG_RE_L(iobus_re_l),
			                .I_WRAM_ADDR(membus_addr),
			                .IO_WRAM_DATA(membus_data),
			                .I_WRAM_WE_L(membus_we_l),
			                .I_WRAM_RE_L(membus_re_l),
			                .I_IN_DMG_MODE(0)
                            );

   task bus_write;
      input [15:0] address;
      input [7:0]  data;

      begin
         if (address == `SVBK) begin
            @(posedge clock8);
            en_iobus <= 1;
            iobus_we_l <= 0;
            iobus_addr <= address;
            iobus_data <= data;
            @(posedge clock8);
            en_iobus <= 0;
            iobus_we_l <= 1;
            @(posedge clock8);
         end
         else begin
            @(posedge clock8);
            en_membus <= 1;
            membus_we_l <= 0;
            membus_addr <= address;
            membus_data <= data;
            @(posedge clock8);
            en_membus <= 0;
            membus_we_l <= 1;
            @(posedge clock8);
         end // else: !if(address == `SVBK)
      end
   endtask // io_bus_write

   /*BUS_READ - task to read a data bus and returns
    *the data value to a register*/
   task bus_read;
      input [15:0] address;
      output [7:0] register;
      begin
         if (address == `SVBK) begin
            @(posedge clock8);
            iobus_re_l <= 0;
            iobus_addr <= address;
            @(posedge clock8);
            iobus_re_l <= 1;
            register <= io_bus;
            @(posedge clock8);
         end
         else begin
            @(posedge clock8);
            membus_re_l <= 0;
            membus_addr <= address;
            @(posedge clock8);
            membus_re_l <= 1;
            register <= io_bus;
            @(posedge clock8);
         end // else: !if(address == `SVBK)
      end
   endtask // io_bus_read

   integer bank_addr_offset;
   integer banknum;
   initial begin
      @(posedge clock8);
      reset <= 1;
      @(posedge clock8);
      @(posedge clock8);
      @(posedge clock8);
      @(posedge clock8);
      reset <= 0;
      @(posedge clock8);

      /*write to bank 0*/
      $display("Writing to Bank %d", 0);
      for (bank_addr_offset = 16'hC000; bank_addr_offset < 16'D000; bank_addr_offset = bank_addr_offset + 1)
        bus_write(bank_addr_offset, 8'b10101010);

      /*write the data to the memory*/
      for (banknum = 0; banknum < 0; banknum = banknum + 1) begin
         $display("Writing to Bank %d", banknum);
         bus_write(`SVBK, banknum);
         for (bank_addr_offset = 16'hD000; bank_addr_offset < 16'E000; bank_addr_offset = bank_addr_offset + 1)
            bus_write(bank_addr_offset, (bank_addr_offset & 8'hFF) << 2);
      end

      /*verify the data from memory*/
      for (banknum = 0; banknum < 0; banknum = banknum + 1) begin
         bus_write(`SVBK, banknum);
         $display("Reading from Bank %d", banknum);
         for (bank_addr_offset = 16'hD000; bank_addr_offset < 16'E000; bank_addr_offset = bank_addr_offset + 1) begin
            bus_read(bank_addr_offset, rd_data);
            assert(rd_data == (bank_addr_offset & 8'hFF) << 2);
         end
         $display("Reading from Bank 0", banknum);
         for (bank_addr_offset = 16'hC000; bank_addr_offset < 16'D000; bank_addr_offset = bank_addr_offset + 1) begin
            bus_write(bank_addr_offset, rd_data);
            assert(rd_data == 8'b10101010);
         end
      end
      $display(" Working Memory Test Complete");
      $finish;
   end

endmodule

module my_clock_divider(
                        // Outputs
                        clock_out,
                        // Inputs
                        clock_in
                        );

    parameter   DIV_SIZE = 15, DIV_OVER_TWO = 24000;

    output reg clock_out = 0;

    input wire clock_in;

    reg [DIV_SIZE-1:0] counter=0;

    always @(posedge clock_in) begin
      if (counter == DIV_OVER_TWO-1) begin
         clock_out <= ~clock_out;
         counter <= 0;
      end
      else
        counter <= counter + 1;
    end

endmodule // my_clock_divider

