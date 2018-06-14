`timescale 1ns / 1ps
module SignExtender_testbench0;
    reg clock;

    // Outputs
    wire [15:0] extended;
    reg [8:0] vram_outA;
    reg [13:0] vram_addrA;
    
    always
     #1 clock = ~clock;


    initial begin
        // Initialize Inputs
        vram_outA <= 8'h96;
        
        (@posedge clk)
        
        vram_addrA <= 13'h1000 + { vram_outA[7], vram_outA, 4'b0 };
        
        $display("%h", vram_addrA);
        (@posedge clk)

    end

endmodule