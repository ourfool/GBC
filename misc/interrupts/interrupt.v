// IE loading is taken care of CPU-internally

// Bit 0: V-Blank  Interrupt Enable  (INT 40h)  (1=Enable)
// Bit 1: LCD STAT Interrupt Enable  (INT 48h)  (1=Enable)
// Bit 2: Timer    Interrupt Enable  (INT 50h)  (1=Enable)
// Bit 3: Serial   Interrupt Enable  (INT 58h)  (1=Enable)
// Bit 4: Joypad   Interrupt Enable  (INT 60h)  (1=Enable)
`include "../../memory/memory_router/memdef.vh"
`define VBLANK  0
`define LCDSTAT 1
`define TIMER   2
`define SERIAL  3
`define JOYPAD  4

`default_nettype none

module interrupt(
        I_CLOCK, I_RESET,
        I_VBLANK_INTERRUPT,
        I_LCDSTAT_INTERRUPT,
        I_TIMER_INTERRUPT,
        I_SERIAL_INTERRUPT,
        I_JOYPAD_INTERRUPT,
        I_MEM_WE_L,
        I_MEM_RE_L,

        I_CPU_ADDR,
        IO_CPU_DATA,

        I_IF_DATA,
        I_IE_DATA,

        O_IF,
        O_IE,

        O_IF_LOAD,
        O_IE_LOAD,

        O_VBLANK_ACK,
        O_LCDSTAT_ACK
    );

    input           I_CLOCK, I_RESET;
    input           I_VBLANK_INTERRUPT, I_LCDSTAT_INTERRUPT, I_TIMER_INTERRUPT, I_SERIAL_INTERRUPT, I_JOYPAD_INTERRUPT;
    input           I_MEM_WE_L, I_MEM_RE_L;

    input [15:0]    I_CPU_ADDR;
    inout [7:0]     IO_CPU_DATA;

    input [4:0]     I_IF_DATA, I_IE_DATA;

    output [4:0]    O_IF, O_IE;
    output          O_IF_LOAD, O_IE_LOAD;
    output          O_VBLANK_ACK, O_LCDSTAT_ACK;

    wire [4:0]      IF_TEMP;
    wire            IF_CPU_WE, IE_CPU_WE;
    
    wire IE_re = ~I_MEM_RE_L && I_CPU_ADDR == `IE;
    wire IF_re = ~I_MEM_RE_L && I_CPU_ADDR == `IF;
    
    
    tristate #(8) IE_tri(
        .out(IO_CPU_DATA),
        .in(I_IE_DATA),
        .en(IE_re)
    );
    
    tristate #(8) IF_tri(
        .out(IO_CPU_DATA),
        .in(I_IF_DATA),
        .en(IF_re)
    );

    assign IF_CPU_WE = I_CPU_ADDR == `IF;
    assign IE_CPU_WE = I_CPU_ADDR == `IE;

    assign O_IF_LOAD = I_VBLANK_INTERRUPT | I_LCDSTAT_INTERRUPT | I_TIMER_INTERRUPT | I_SERIAL_INTERRUPT | I_JOYPAD_INTERRUPT | (IF_CPU_WE & ~I_MEM_WE_L);
    assign O_IE_LOAD = 1'b0; // IE loading handled by CPU

    assign IF_TEMP[`VBLANK]    = I_VBLANK_INTERRUPT  | (I_IF_DATA[`VBLANK] & O_IF_LOAD);
    assign IF_TEMP[`LCDSTAT]   = I_LCDSTAT_INTERRUPT | (I_IF_DATA[`LCDSTAT] & O_IF_LOAD);
    assign IF_TEMP[`TIMER]     = I_TIMER_INTERRUPT   | (I_IF_DATA[`TIMER] & O_IF_LOAD);
    assign IF_TEMP[`SERIAL]    = I_SERIAL_INTERRUPT  | (I_IF_DATA[`SERIAL] & O_IF_LOAD);
    assign IF_TEMP[`JOYPAD]    = I_JOYPAD_INTERRUPT  | (I_IF_DATA[`JOYPAD] & O_IF_LOAD);

    assign O_IF = (IF_CPU_WE & ~I_MEM_WE_L) ? IO_CPU_DATA : IF_TEMP;
    assign O_IE = 5'd0; // IE loading handled by CPU

   assign O_VBLANK_ACK = I_IF_DATA[`VBLANK];
   assign O_LCDSTAT_ACK = I_IF_DATA[`LCDSTAT];

endmodule // interrupt