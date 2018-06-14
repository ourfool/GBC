module interrupt_test();
    reg            clock, reset, mem_we_l;
    reg            I_VBLANK_INTERRUPT, I_LCDSTAT_INTERRUPT, I_TIMER_INTERRUPT, I_SERIAL_INTERRUPT, I_JOYPAD_INTERRUPT;

    reg [15:0]     addr;
    reg [7:0]      data;

    reg [4:0]      I_IF_DATA, I_IE_DATA;

    wire [4:0]     O_IF, O_IE;
    wire           O_IF_LOAD, O_IE_LOAD;
    wire           O_VBLANK_ACK, O_LCDSTAT_ACK;

    always @(posedge clock) begin
        if(reset)
            I_IF_DATA <= 8'd0;
        else if(O_IF_LOAD)
            I_IF_DATA <= O_IF;
    end

    always
     #2 clock = ~clock;

    interrupt int(
        .I_CLOCK(clock),
        .I_RESET(reset),
        .I_VBLANK_INTERRUPT(I_VBLANK_INTERRUPT),
        .I_LCDSTAT_INTERRUPT(I_LCDSTAT_INTERRUPT),
        .I_TIMER_INTERRUPT(I_TIMER_INTERRUPT),
        .I_SERIAL_INTERRUPT(I_SERIAL_INTERRUPT),
        .I_JOYPAD_INTERRUPT(I_JOYPAD_INTERRUPT),
        .I_MEM_WE_L(mem_we_l),
        .I_CPU_ADDR(addr),
        .I_CPU_DATA(data),
        .I_IF_DATA(I_IF_DATA),
        .I_IE_DATA(I_IE_DATA),
        .O_IF(O_IF),
        .O_IE(O_IE),
        .O_IF_LOAD(O_IF_LOAD),
        .O_IE_LOAD(O_IE_LOAD),
        .O_VBLANK_ACK(O_VBLANK_ACK),
        .O_LCDSTAT_ACK(O_LCDSTAT_ACK)
        );

    initial begin
        clock = 0;
        reset = 0;
        mem_we_l = 1;
        I_VBLANK_INTERRUPT = 0;
        I_LCDSTAT_INTERRUPT = 0;
        I_TIMER_INTERRUPT = 0;
        I_SERIAL_INTERRUPT = 0;
        I_JOYPAD_INTERRUPT = 0;
        addr = 16'd0;
        data = 16'd0;
        I_IF_DATA = 5'd0; 
        I_IE_DATA = 5'd0;

        @(posedge clock);
        reset = 1;
        @(posedge clock);
        reset = 0;
        @(posedge clock);
        I_VBLANK_INTERRUPT =  1;
        @(posedge clock);
        I_VBLANK_INTERRUPT =  0;
        @(posedge clock);
        I_LCDSTAT_INTERRUPT =  1;
        @(posedge clock);
        I_LCDSTAT_INTERRUPT =  0;
        @(posedge clock);
        I_TIMER_INTERRUPT =  1;
        @(posedge clock);
        I_TIMER_INTERRUPT =  0;
        @(posedge clock);
        I_SERIAL_INTERRUPT =  1;
        @(posedge clock);
        I_SERIAL_INTERRUPT =  0;
        @(posedge clock);
        I_JOYPAD_INTERRUPT =  1;
        @(posedge clock);
        I_JOYPAD_INTERRUPT =  0;
        @(posedge clock);
        addr = 16'hff0f;
        data = 8'h55;
        mem_we_l = 0;
        @(posedge clock);
        mem_we_l = 1;
        @(posedge clock);
        reset = 1;
        @(posedge clock);
        reset = 0;

        #1 $finish;
    end

endmodule // interrupt_test