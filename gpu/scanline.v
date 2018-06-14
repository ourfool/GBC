`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:37:48 11/13/2013 
// Design Name: 
// Module Name:    scanline 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module scanline(//Input
					 clk, rst, addrA, addrB, wr_csA, wr_csB, wr_dataA, wr_dataB,
					 //Output
					 rd_dataA, rd_dataB);
	//Input
	input wire clk, rst;
	input wire [4:0] addrA, addrB;
	input wire wr_csA, wr_csB;
	input wire [7:0] wr_dataA, wr_dataB;

	//Output
	output wire [7:0] rd_dataA;
	output wire [7:0] rd_dataB;
	
	parameter depth = 32;
	
	reg [7:0] mem [0:depth-1];
    integer i;
    
	always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < depth; i = i + 1) begin
                mem[i] = 8'b0;
            end
        end else begin
		    if(wr_csA)
			    mem[addrA] <= wr_dataA;
            if(wr_csB)
			    mem[addrB] <= wr_dataB;
        end
	end

	assign rd_dataA = mem[addrA];
	assign rd_dataB = mem[addrB];
	
endmodule
