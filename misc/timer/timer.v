// jkleung1

`include "../../memory/memory_router/memdef.vh"
`default_nettype none

// Expects a clock of 2^23
module timer_module(
        O_TIMER_INTERRUPT,
        I_CLOCK, I_RESET,
        I_ADDR, IO_DATA,
        I_RE_L, I_WE_L, 
        
        /*for debugging*/
        O_DIV_DATA, O_TIMA_DATA, O_TMA_DATA, O_TAC_DATA
    );

    output          O_TIMER_INTERRUPT;
    output [7:0]    O_DIV_DATA, O_TIMA_DATA, O_TMA_DATA, O_TAC_DATA;

    input           I_CLOCK, I_RESET, I_RE_L, I_WE_L;

    input [15:0]    I_ADDR;
    inout [7:0]     IO_DATA;

    // Timer & Diver Register wires
    reg [10:0]      counter;
    wire [7:0]       DIV, TIMA, TMA;
    wire [2:0]       TAC;
    
    assign O_DIV_DATA = DIV;
    assign O_TIMA_DATA = TIMA;
    assign O_TMA_DATA = TMA;
    assign O_TAC_DATA = {5'b0, TAC};

    // Internal Variables
    reg     state, next_state, increment;
    wire    TIMA_ce;

    // State names
    `define COUNTER_RESET   1'b0
    `define COUNTER_TRIGGER 1'b1

    assign O_TIMER_INTERRUPT = (TIMA == 8'hff) & increment;

    // Counter incrments and when TIMA_ce is 1 for the first time
    // incrment TIMA. Then wait until TIMA_ce is 0 before allowing
    // TIMA to be incremented.

    // 00:   4096 Hz    = 2^12 = 2^23 - 2^11
    // 01: 262144 Hz    = 2^18 = 2^23 - 2^5
    // 10:  65536 Hz    = 2^17 = 2^23 - 2^6
    // 11:  16384 Hz    = 2^14 = 2^23 - 2^9

    assign TIMA_ce =    (TAC[1:0] == 2'b00 ) ? counter[10] :
                        (TAC[1:0] == 2'b01 ) ? counter[4] :
                        (TAC[1:0] == 2'b10 ) ? counter[6] : counter[8];
                        
    reg reset_counter;
    

    // Bus enables
    wire    DIV_we, TIMA_we, TMA_we, TAC_we;
    wire    DIV_re, TIMA_re, TMA_re, TAC_re;
    
    always @(posedge I_CLOCK) begin
    
        increment <= 0;
        counter <= counter + 1;
        
        if (TAC[1:0] == 2'b00 && counter == 'd1023) begin
            increment <= 1;
            counter <= 0;
        end
        else if (TAC[1:0] == 2'b01 && counter == 'd15) begin
            increment <= 1;
            counter <= 0;
        end
        else if (TAC[1:0] == 2'b10 && counter == 'd63) begin
            increment <= 1;
            counter <= 0;
        end
        else if (TAC[1:0] == 2'b01 && counter == 'd255) begin
            increment <= 1;
            counter <= 0;
        end

        // resets when reset and register writes
        if (I_RESET) begin 
            increment <= 0;
            counter <= 0;
        end else begin 
            if (TIMA_we) begin
                //increment <= 0;
            end
            if (TAC_we) begin
                // This instruction completes this action 3 cycles too early,
                increment <= 0;
                counter <= 1 - 4;
            end
        end
    end

    always @(posedge I_CLOCK or posedge I_RESET) begin
        if(I_RESET)
            state <= 0;
        else
            state <= next_state;
    end


    assign DIV_we  = (~I_WE_L) ? (I_ADDR == `DIV)  : 0;
    assign TIMA_we = (~I_WE_L) ? (I_ADDR == `TIMA) : 0;
    assign TMA_we  = (~I_WE_L) ? (I_ADDR == `TMA)  : 0;
    assign TAC_we  = (~I_WE_L) ? (I_ADDR == `TAC)  : 0;

    assign DIV_re  = (~I_RE_L) ? (I_ADDR == `DIV)  : 0;
    assign TIMA_re = (~I_RE_L) ? (I_ADDR == `TIMA) : 0;
    assign TMA_re  = (~I_RE_L) ? (I_ADDR == `TMA)  : 0;
    assign TAC_re  = (~I_RE_L) ? (I_ADDR == `TAC)  : 0;

    // Bus tristate
    tristate #(8) DIV_tri(
        .out(IO_DATA),
        .in(DIV),
        .en(DIV_re)
    );
    
    /*
    io_bus_parser_reg #(`DIV,0,1,0,01) div_register(
                              .I_CLK(I_CLOCK),
                              .I_SYNC_RESET(I_RESET),
                              .IO_DATA_BUS(IO_DATA),
                              .I_ADDR_BUS(I_ADDR),
                              .I_WE_BUS_L(I_WE_L),
                              .I_RE_BUS_L(I_RE_L),
                              .I_REG_WR_EN(1'b1),
                              .I_DATA_WR(DIV)
                              );
                              */
    
    tristate #(8) TIMA_tri(
        .out(IO_DATA),
        .in(TIMA[7:0]),
        .en(TIMA_re)
    );

    tristate #(8) TAC_tri(
        .out(IO_DATA),
        .in({5'd0, TAC}),
        .en(TAC_re)
    );

    tristate #(8) TMA_tri(
        .out(IO_DATA),
        .in(TMA[7:0]),
        .en(TMA_re)
    );

    // Increment DIV every 256 clock ticks
    wire [7:0] DIV_LO;
    wire [8:0] DIV_LO_sum;
    assign DIV_LO_sum = {1'b0, DIV_LO} + 9'b1;

    register #(8, 0) DIV_LO_reg(
        .q(DIV_LO),
        .d(DIV_LO_sum[7:0]),
        .load(1'b1),
        .clock(I_CLOCK),
        .reset(I_RESET)
    );

    register #(8, 0) DIV_reg(
        .q(DIV),
        .d(DIV + {7'b0, DIV_LO_sum[8]}),
        .load(1'b1),
        .clock(I_CLOCK),
        .reset(I_RESET | DIV_we)
    );

    register #(3, 0) TAC_reg(
        .q(TAC),
        .d(IO_DATA[2:0]),
        .load(TAC_we),
        .clock(I_CLOCK),
        .reset(I_RESET)
    );

    register #(8, 0) TMA_reg(
        .q(TMA),
        .d(IO_DATA),
        .load(TMA_we),
        .clock(I_CLOCK),
        .reset(I_RESET)
    );

    register #(8, 0) TIMA_reg(
        .q(TIMA),
        .d(
            (TIMA_we) ? IO_DATA :
            (TIMA == 8'hff) ? ((TMA_we) ? IO_DATA : TMA) :TIMA + 8'd1
        ),
        .load(TIMA_we | (increment & TAC[2])),
        .clock(I_CLOCK),
        .reset(I_RESET)
    );

endmodule // timer