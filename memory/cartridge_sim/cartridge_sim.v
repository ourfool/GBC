`default_nettype none

`define IDLE        0
`define WRITE1      1
`define WRITE2      2
`define LOAD1       3
`define LOAD2       4

`define CRYSTAL      0
`define MARIO_DELUXE 1
`define TETRIS1      2

`define BLUE         0
`define POKE_PINBALL 1
`define 1942         2
`define MEGAMAN      3
`define METROID      4
`define TETRIS2      5
`define TETRIS       6

// Game addresses 
`define CRYSTAL_BASE      24'h0000_0000
`define MARIO_DELUXE_BASE 24'h0020_0000
`define TETRIS1_BASE      24'h0030_0000

`define BLUE_BASE         24'h0000_0000
`define POKE_PINBALL_BASE 24'h0010_0000
`define 1942_BASE         24'h0020_0000
`define MEGAMAN_BASE      24'h0030_0000
`define METROID_BASE      24'h0038_0000
`define TETRIS2_BASE      24'h003C_0000
`define TETRIS_BASE       24'h003E_0000

module cartridge_sim(
                 /*System Level Inputs*/
                 I_CLK,
                 I_CLK_33MHZ,
                 I_RESET,
                 I_GAME_SELECT,
                 O_GAME_SELECT,

                 /*Interface with CPU*/
                 I_CARTRIDGE_ADDR,
                 IO_CARTRIDGE_DATA,
                 I_CARTRIDGE_WE_L,
                 I_CARTRIDGE_RE_L,

                 /*Interface with the flash module*/
                 I_FLASH_DATA,
                 O_FLASH_ADDR,
                 O_FLASH_CLK,
                 O_ADDR_VALID_L,
                 O_FLASH_CE_L,
                 O_FLASH_OE_L,
                 O_FLASH_WE_L
                 );
                     
   parameter P_USE_FLASH_PORT = 1;
   parameter COMBINE_ROM_VERSION = 2'd1;

   input        I_CLK, I_CLK_33MHZ, I_RESET;
   input [2:0]  I_GAME_SELECT;
   output [2:0] O_GAME_SELECT;

   input [15:0] I_CARTRIDGE_ADDR;
   inout [7:0]  IO_CARTRIDGE_DATA;

   input        I_CARTRIDGE_WE_L, I_CARTRIDGE_RE_L;

   input  [15:0] I_FLASH_DATA;
   output [23:0] O_FLASH_ADDR;
   output        O_FLASH_CLK, O_ADDR_VALID_L,
                 O_FLASH_CE_L, O_FLASH_OE_L, O_FLASH_WE_L;

   wire               bram_en, bram_we;

   wire [23:0]        flash_addr_offset, game_select_base_addr_v1, game_select_base_addr_v2 ,game_select_base_addr;
   wire [15:0]        router_addr, bram_banked_addr;
   wire [15:0]        exp_bram_addr;
   wire [7:0]         exp_bram_data_in;
   wire [7:0]         exp_bram_data_out [0:2];
   wire [7:0]         exp_bram_data_out_select, bram_cartridge_data;
   reg [2:0]          game_select_num;

   assign game_select_base_addr_v1 = (game_select_num == `CRYSTAL) ?       `CRYSTAL_BASE:
                                     (game_select_num == `MARIO_DELUXE) ?  `MARIO_DELUXE_BASE:
                                     (game_select_num == `TETRIS1) ?       `TETRIS1_BASE: 0;

   assign game_select_base_addr_v2 = (game_select_num == `BLUE) ?         `BLUE_BASE:
                                     (game_select_num == `POKE_PINBALL) ? `POKE_PINBALL_BASE:
                                     (game_select_num == `1942) ?         `1942_BASE:
                                     (game_select_num == `MEGAMAN) ?      `MEGAMAN_BASE: 
                                     (game_select_num == `METROID) ?      `METROID_BASE: 
                                     (game_select_num == `TETRIS2) ?      `TETRIS2_BASE: 
                                     (game_select_num == `TETRIS) ?       `TETRIS_BASE: 0;

   assign game_select_base_addr = (COMBINE_ROM_VERSION == 1) ? game_select_base_addr_v1 :
                                  (COMBINE_ROM_VERSION == 2) ? game_select_base_addr_v2 : 24'd0;                        
   
   assign O_GAME_SELECT = game_select_num;

   // Asynchronous read mode
   assign O_FLASH_CLK = 1'b1;
   // Chip enable
   assign O_FLASH_CE_L = 1'b0;
   // Output enable
   assign O_FLASH_OE_L = 1'b0;
   // Write enable
   assign O_FLASH_WE_L = 1'b1;
   // Address Valid
   assign O_ADDR_VALID_L = 1'b0;


   /*Figure out which space on the cartridge you are accessing*/
   wire   accessing_ROM_space, accessing_RAM_space;
   assign accessing_ROM_space = (I_CARTRIDGE_ADDR >=0 && I_CARTRIDGE_ADDR < 16'h8000);
   assign accessing_RAM_space = (I_CARTRIDGE_ADDR >= 16'hA000 && I_CARTRIDGE_ADDR < 16'hC000);

   reg                ram_timer_en;
   reg [6:0]          rom_bank_num;
   reg [3:0]          ram_bank_num;
   reg                latch_clock_data, zero_found;
   reg                is_in_rom_mode; //for bootloading

   /*write to the controll registers!!*/
   always @(posedge I_CLK) begin

      latch_clock_data <= 0;

      /*must indicate a write signal to the ROM space to access control
       *registers*/
      if (~I_CARTRIDGE_WE_L && accessing_ROM_space && is_in_rom_mode) begin

       case(I_CARTRIDGE_ADDR[15:12]) //upper bits of address

         /*enable the ram/timer when A is written to address space
          * 0x0XXX - 0x1XXX*/
         16'h0: begin
            if (IO_CARTRIDGE_DATA == 0)
            ram_timer_en <= 0;
            else if (IO_CARTRIDGE_DATA == 8'h0A)
            ram_timer_en <= 1;
         end
         16'h1: begin
            if (IO_CARTRIDGE_DATA == 0)
            ram_timer_en <= 0;
            else if (IO_CARTRIDGE_DATA == 8'h0A)
            ram_timer_en <= 1;
         end

         /*When in the address range of 0x2XXX-3XXX, write the ROM
          *bank specification.  Note that rom bank 0 is really
          *just rom bank 1 since bank zero is in its own
          *address space*/
         16'h2: rom_bank_num <= (IO_CARTRIDGE_DATA[6:0] == 0) ? 1 : IO_CARTRIDGE_DATA[6:0];
         16'h3: rom_bank_num <= (IO_CARTRIDGE_DATA[6:0] == 0) ? 1 : IO_CARTRIDGE_DATA[6:0];

         /*When in the address range of 0x4XXX-5XXX, write the RAM
          *bank specification or the time register selection*/
         16'h4: ram_bank_num <= IO_CARTRIDGE_DATA[3:0];
         16'h5: ram_bank_num <= IO_CARTRIDGE_DATA[3:0];

         /*If writing a 0 follow by a 1 to the address range of 0x6XXX-0x7FFF
          *then indicate that the clock should be latched into the
          *RTC registers*/
         16'h6: begin
            if (IO_CARTRIDGE_DATA == 0)
            zero_found <= 1;
            else if (zero_found && IO_CARTRIDGE_DATA == 'd1) begin
             latch_clock_data <= 1;
             zero_found <= 0;
            end
            else
            zero_found <= 0;
         end
         16'h7: begin
            if (IO_CARTRIDGE_DATA == 0)
            zero_found <= 1;
            else if (zero_found && IO_CARTRIDGE_DATA == 'd1) begin
             latch_clock_data <= 1;
             zero_found <= 0;
            end
            else
            zero_found <= 0;
         end

       endcase // case (I_CARTRIDGE_ADDR[15:12])
      end // if (~I_CARTRIDGE_WE_L && accessing_ROM_space && ~is_in_bootload_mode)

      /*disable the bootload sequence when the CPU is finished*/
      if (~is_in_rom_mode & ~I_CARTRIDGE_WE_L & I_CARTRIDGE_ADDR == 16'hFF50)
        is_in_rom_mode <= IO_CARTRIDGE_DATA[0];

      /*reset the the hardware to begin in bootload mode*/
      if (I_RESET) begin
         is_in_rom_mode <= 1; //ignore bootload process (for now)
         game_select_num <= I_GAME_SELECT;
         rom_bank_num <= 1;
         ram_bank_num <= 0;
      end

   end // always @ (posedge I_CLK)


   /*Keep track of the time in the timer registers*/
   reg [31:0]  second_count;
   reg [7:0]   seconds, rtc_seconds;
   reg [7:0]   minutes, rtc_minutes;
   reg [7:0]   hours, rtc_hours;
   reg [15:0]  days, rtc_days;
   always @(posedge I_CLK_33MHZ) begin

      if (~rtc_days[14]) //indicating to run the counter
      second_count <= second_count + 1;

      /*33 MHz clocks -> 1 second is 33 Million clocks*/
      if (second_count >= 'd33000000) begin
       second_count <= 0;
       seconds <= seconds + 1;
      end

      /*rollover the seconds into a minute*/
      if (seconds >= 59) begin
       seconds <= 0;
       minutes <= minutes + 1;
      end

      /*roll over a minute into an hour*/
      if (minutes >= 59) begin
       minutes <= 0;
       hours <= hours + 1;
      end

      /*roll over the hours into a day*/
      if (hours >= 23) begin
       hours <= 0;
       days <= days + 1;
      end

      /*write to the timer registers when CPU commands so
       *such that it can change the time of day*/
      if (~I_CARTRIDGE_WE_L && accessing_RAM_space) begin
       if (ram_bank_num == 8)
         rtc_seconds <= IO_CARTRIDGE_DATA;
       else if (ram_bank_num == 9)
         rtc_minutes <= IO_CARTRIDGE_DATA;
       else if (ram_bank_num == 10)
         rtc_hours <= IO_CARTRIDGE_DATA;
       else if (ram_bank_num == 11)
         rtc_days[7:0] <= IO_CARTRIDGE_DATA;
       else if (ram_bank_num == 12)
         rtc_days[15:0] <= IO_CARTRIDGE_DATA;
      end

      /*if a latch indication, update the registers with the current time*/
      if (latch_clock_data) begin
       rtc_seconds <= seconds;
       rtc_minutes <= minutes;
       rtc_hours <= hours;
       rtc_days[8:0] <= days[8:0];
      end

      if (I_RESET) begin
       second_count <= 0;
       seconds <= 0;
       minutes <= 0;
       hours <= 0;
       days <= 0;
      end
   end // always @ (posedge I_CLK_33MHZ)

   /*Figure out the data to return*/
   wire        is_bank_zero;
   wire [7:0]  return_data, ram_return_data, register_return_data;
   wire [15:0] cartridge_addr_offset;
   wire [15:0] bootload_bram_addr, bootload_data;

   /*the banks are laid out linearly in flash so offset the address
    *by the bank bits*/
   assign is_bank_zero = I_CARTRIDGE_ADDR < 16'h4000;
   assign flash_addr_offset[23:14] = (is_bank_zero) ? 10'd0 : {3'd0, rom_bank_num};
   assign flash_addr_offset[13:0]  = I_CARTRIDGE_ADDR[13:0];
   assign O_FLASH_ADDR = game_select_base_addr + flash_addr_offset;
   assign bootload_bram_addr = I_CARTRIDGE_ADDR;

   /*Offset ram address so it starts at 0, then use the bank to linearly
    *offset the address into bram*/
   assign cartridge_addr_offset = I_CARTRIDGE_ADDR - 16'hA000;
   assign exp_bram_addr = {1'b0, ram_bank_num[1:0], cartridge_addr_offset[12:0]};
   assign bram_we =  ram_timer_en && ~I_CARTRIDGE_WE_L && ram_bank_num <= 3 && accessing_RAM_space;

   /*determine the write data into the BRAM , if indicated to write to BRAM*/
   assign exp_bram_data_in = (bram_we) ? IO_CARTRIDGE_DATA : 0;

   /* if accessing ROM space on a read, return the flash data, else
    * return the data from the RAM or the timer*/
   assign return_data = (~is_in_rom_mode) ? bootload_data :
                        (P_USE_FLASH_PORT & accessing_ROM_space) ? I_FLASH_DATA[7:0] : //rom -> read from flash
                        (~P_USE_FLASH_PORT & accessing_ROM_space) ? bram_cartridge_data :
                        (accessing_RAM_space & ram_timer_en) ? ram_return_data : 0;

   assign exp_bram_data_out_select =  (COMBINE_ROM_VERSION == 2 && game_select_num == `BLUE) ? exp_bram_data_out[0] : 
                                      (COMBINE_ROM_VERSION == 1 && game_select_num == `CRYSTAL) ? exp_bram_data_out[1] : exp_bram_data_out[2];

                                     

   /*the data being returned from the RAM address space can come from either BRAM
    *or from the RTC registers.  This is specified by the RAM bank number*/
   assign ram_return_data = (ram_bank_num <= 3) ? exp_bram_data_out_select :
                            (ram_bank_num >= 8 && ram_bank_num < 13) ? register_return_data : 0;

   /*return the correct RTC register of the RAM bank number is in the RTC register range*/
   assign register_return_data = (ram_bank_num == 8)  ? rtc_seconds :
                         (ram_bank_num == 9)  ? rtc_minutes :
                         (ram_bank_num == 10) ? rtc_hours   :
                         (ram_bank_num == 11) ? rtc_days[7:0] :
                         (ram_bank_num == 12) ? rtc_days[15:8] : 0;

   /*Drive The Cartridge Data bus with the return data*/
   wire   en_data;
   assign en_data = ~I_CARTRIDGE_RE_L;
   assign IO_CARTRIDGE_DATA = (en_data) ? return_data : 'bzzzzzzzz;

   /* Actual Memory Location*/         
   bram_save_blue expansion_blue(
                  .clka(I_CLK),
                  .rsta(I_RESET),
                  .wea(bram_we && (COMBINE_ROM_VERSION == 2 && game_select_num == `BLUE)),
                  .addra(exp_bram_addr),
                  .dina(exp_bram_data_in),
                  .douta(exp_bram_data_out[0])
                  );

   bram_save_crystal expansion_crystal(
                  .clka(I_CLK),
                  .rsta(I_RESET),
                  .wea(bram_we && (COMBINE_ROM_VERSION == 1 && game_select_num == `CRYSTAL)),
                  .addra(exp_bram_addr),
                  .dina(exp_bram_data_in),
                  .douta(exp_bram_data_out[1])
                  );

   bram_save expansion_other(
                  .clka(I_CLK),
                  .rsta(I_RESET),
                  .wea(bram_we && (game_select_num != `CRYSTAL) && (game_select_num != `BLUE)),
                  .addra(exp_bram_addr),
                  .dina(exp_bram_data_in),
                  .douta(exp_bram_data_out[2])
                  ); 
                      
   /*give capability of reading from FLASH or BRAM based on parameter*/                   
   bram_cart cartridge(
                      .clka(I_CLK),
                      .rsta(I_RESET),
                      .wea(0),
                      .addra(I_CARTRIDGE_ADDR),
                      .dina(0),
                      .douta(bram_cartridge_data)
                      );

   /*boot_bram bootload_bram(
                       .clka(I_CLK),
                       .wea(0),
                       .addra(bootload_bram_addr),
                       .dina(0),
                       .douta(bootload_data)
                       );*/

endmodule