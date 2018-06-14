module timer_module_test();
    reg             clock, reset, I_RE_L, I_WE_L;
    reg [15:0]      I_ADDR;
    reg [7:0]       I_DATA;       

    wire [7:0]      IO_DATA;
    wire            O_TIMER_INTERRUPT;
    
    tristate #(.width(8)) iobus(
        .out(IO_DATA),
        .in(I_DATA),
        .en(~I_WE_L)
        );

    always
     #2 clock = ~clock;

    timer_module tim(
        .O_TIMER_INTERRUPT(O_TIMER_INTERRUPT),
        .I_CLOCK(clock),
        .I_RESET(reset),
        .I_ADDR(I_ADDR),
        .IO_DATA(IO_DATA),
        .I_RE_L(I_RE_L),
        .I_WE_L(I_WE_L)
        );

    integer count;

    initial begin
        count = 0;
        clock = 0;
        reset = 0;
        I_RE_L = 1;
        I_WE_L = 1;
        I_ADDR = 16'h0000;
        I_DATA = 8'h00;

        @(posedge clock);
        reset = 1;
        @(posedge clock);
        reset = 0;
        I_WE_L = 0;
        I_ADDR = 16'hff06;
        I_DATA = 8'hAA;
        @(posedge clock);
        I_WE_L = 0;
        I_ADDR = 16'hff07;
        I_DATA = 8'b0000_0101;
        @(posedge clock);
        I_WE_L = 1;
        I_DATA = 8'h00;

        while (count < 1000000) begin
            count = count + 1;
            @(posedge clock);
        end

        @(posedge clock);
        I_WE_L = 0;
        I_ADDR = 16'hff04;
        I_DATA = 8'hAA;
        @(posedge clock);
        I_WE_L = 1;
        I_DATA = 8'h00;
        @(posedge clock);

        #1 $finish;
    end

endmodule // timer_module_test

module tristate(
   // Outputs
   out,
   // Inputs
   in, en
   );
   parameter
     width = 1;
   output wire [width-1:0] out;
   input [width-1:0]       in;
   input                   en;

   assign out = (en) ? in : {width{1'bz}};
   
endmodule // tristate