module cartridge_sim_test();
       /*System Level Inputs*/
       reg   clock, clock33, reset, I_SAVE;

       /*Interface with CPU*/
       wire [15:0]  I_CARTRIDGE_ADDR;
       wire [7:0]   IO_CARTRIDGE_DATA;
       wire         I_CARTRIDGE_WE_L;
       wire         I_CARTRIDGE_RE_L;

       /*Interface with the flash module*/
       wire [15:0]  IO_FLASH_DATA;
       wire [23:0]  O_FLASH_ADDR;
       wire   O_FLASH_CLK;
       wire   O_ADDR_VALID_L;
       wire   O_FLASH_CE_L;
       wire   O_FLASH_OE_L;
       wire   O_FLASH_WE_L;

       integer count;

       always
       #1 clock = ~clock;

       initial begin
       clock = 0;
       clock33 = 0;
       reset = 0;
       I_SAVE = 0;
       count = 0;
       @(posedge clock);
       reset = 1;
       @(posedge clock);
       reset = 0;
       @(posedge clock);
       reset = 1;

       while (count < 10) begin
         count = count + 1;
         if(count % 3)
            clock33 = ~clock33;
         @(posedge clock);
       end

       count = 0;
       reset = 0;
       I_SAVE = 1;

       while (count < 10) begin
         count = count + 1;
         if(count % 3)
            clock33 = ~clock33;
         @(posedge clock);
       end

       I_SAVE = 0;

       while (1) begin
         count = count + 1;
         if(count % 3)
            clock33 = ~clock33;
         @(posedge clock);
       end

       @(posedge clock);

       #1 $finish;
       end

       cartridge_sim cart_sim(
              /*System Level Inputs*/
              .I_CLK(clock),
              .I_CLK_33MHZ(clock33),
              .I_RESET(reset),
              .I_SAVE(I_SAVE),

              /*Interface with CPU*/
              .I_CARTRIDGE_ADDR(I_CARTRIDGE_ADDR),
              .IO_CARTRIDGE_DATA(IO_CARTRIDGE_DATA),
              .I_CARTRIDGE_WE_L(I_CARTRIDGE_WE_L),
              .I_CARTRIDGE_RE_L(I_CARTRIDGE_RE_L),

              /*Interface with the flash module*/
              .IO_FLASH_DATA(IO_FLASH_DATA),
              .O_FLASH_ADDR(O_FLASH_ADDR),
              .O_FLASH_CLK(O_FLASH_CLK),
              .O_ADDR_VALID_L(O_ADDR_VALID_L),
              .O_FLASH_CE_L(O_FLASH_CE_L),
              .O_FLASH_OE_L(O_FLASH_OE_L),
              .O_FLASH_WE_L
              );

endmodule