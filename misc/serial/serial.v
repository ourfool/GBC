`include "../../memory/memory_router/memdef.vh"

`define SERIAL 0

module serial(
    I_CLK, I_RESET,
    I_ADDR_BUS, IO_DATA_BUS,
    I_WE_BUS_L, I_RE_BUS_L,
    O_SERIAL_INTERRUPT,

    I_EXTERNAL_CLOCK,
    O_SERIAL_CLOCK,
    I_SERIAL_DATA,
    O_SERIAL_DATA
    );

    input           I_CLK, I_RESET;

    input [15:0]    I_ADDR_BUS;
    inout [7:0]     IO_DATA_BUS;
    input           I_WE_BUS_L, I_RE_BUS_L;

    output          O_SERIAL_INTERRUPT;

    input           I_EXTERNAL_CLOCK;
    output          O_SERIAL_CLOCK;
    input           I_SERIAL_DATA;
    output          O_SERIAL_DATA;

    wire        transfer_active, is_internal;

    wire        SB_we, SC_we, serial_clock, is_double;

    reg         clock_gen, bit_out, req_interrupt;
    reg [3:0]   serial_count;
    reg [7:0]   SB, SC;

    assign transfer_active = SC[7];
    assign is_double = SC[1];
    assign is_internal = SC[0];

    assign O_SERIAL_INTERRUPT = req_interrupt;

    assign O_SERIAL_CLOCK = (transfer_active && is_internal) ? clock_gen : 0;
    assign O_SERIAL_DATA = bit_out;

    assign SB_we = (~I_WE_BUS_L) ? (I_ADDR_BUS == `SB) : 0;
    assign SC_we = (~I_WE_BUS_L) ? (I_ADDR_BUS == `SC) : 0;

    assign IO_DATA_BUS = (~I_RE_BUS_L && I_ADDR_BUS == `SB) ? SB:
                         (~I_RE_BUS_L && I_ADDR_BUS == `SC) ? SC:8'hzz;

    assign serial_clock = (is_internal) ? clock_gen : I_EXTERNAL_CLOCK;

    // 8192 Hz    = 2^13 = 2^22 - 2^9
    // 262144 Hz  = 2^18 = 2^22 - 2^4

    // 16384 Hz   = 2^14 = 2^23 - 2^9
    // 524288 Hz  = 2^19 - 2^23 - 2^4
    
    reg [9:0] counter;
                        
    always @(posedge I_CLK) begin
        if(I_RESET) begin
            clock_gen <= 0;
            counter <= 0;
        end else begin
            clock_gen <= 0;
            counter <= counter + 1;
            if (~is_double && counter == 'd511) begin
                clock_gen <= 1;
                counter <= 0;
            end else if (is_double && counter == 'd15) begin
                clock_gen <= 1;
                counter <= 0;
            end
        end
    end

    // always @(posedge increment) begin
    //     if(I_RESET) begin
    //         clock_gen <= 0;
    //     end else if() begin
    //         clock_gen <= ~clock_gen;
    //     end
    // end

    always @(posedge I_CLK) begin
        if(I_RESET) begin
            SC <= {1'b0, 5'b111_111, 1'b00};
            SB <= 0;
            bit_out <= 0;
            serial_count <= 0;
            req_interrupt <= 0;
        end else begin
            req_interrupt <= 0;
            if(transfer_active) begin
                if(serial_clock) begin
                    SB <= {SB[6:0] , I_SERIAL_DATA};
                    serial_count <= serial_count + 1;
                end else begin
                    bit_out <= SB[7];
                end

                if(serial_count >= 8) begin
                    serial_count <= 0;
                    if(is_internal) begin
                        req_interrupt <= 1;
                        SC <= {1'b0, 5'b111_11, SC[1:0]};
                    end else begin
                        req_interrupt <= 1;
                        SC <= {1'b0, 5'b111_11, SC[1:0]};
                    end
                end
            end

            if(SB_we)
                SB <= IO_DATA_BUS;
            if(SC_we)
                SC <= {IO_DATA_BUS[7], 5'b111_11, IO_DATA_BUS[1:0]};
        end
    end
endmodule // serial