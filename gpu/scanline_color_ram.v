`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:04:16 11/18/2013 
// Design Name: 
// Module Name:    scanline_ram 
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

module scanline_color_ram(//Outputs
					rd_data,
					
					//Inputs
					clk,
					wr_en,
					addr,					
					wr_data,
					);
	//Outputs
	output [14:0] rd_data;
	//Inputs
	input clk;
	input wr_en;
	input [7:0] addr;
	input [14:0] wr_data;
	
	/*
	Bit 3 -> background or not
	Bits 2-0 -> color pallette
	*/
	reg [3:0] RAM [159:0];
	
	always @(posedge clk) begin
		if (wr_enA) RAM[addr] <= wr_data;
	end
	
	assign rd_data = RAM[addr];
endmodule
