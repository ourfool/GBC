// The Flash memory stores bytes from the hex -> mcs file as follows:
// Little Endian
// Notice that the Flash clock should be 1 for asynchronous read mode, which is
// the default mode.

// The CPU's clock is 4194304 Hz, or 2^22 Hz.

`default_nettype none

module gpu_test_top(CLK_33MHZ_FPGA,
	       CLK_27MHZ_FPGA,
	       USER_CLK,
			 GPIO_SW_C,
	       dvi_d, dvi_vs, dvi_hs, dvi_xclk_p, dvi_xclk_n, dvi_reset_b,
	       dvi_de,
	       dvi_sda, dvi_scl,
);
   parameter
     I_HILO = 4, I_SERIAL = 3, I_TIMA = 2, I_LCDC = 1, I_VBLANK = 0;
  
   input wire CLK_33MHZ_FPGA, CLK_27MHZ_FPGA, USER_CLK, GPIO_SW_C;
   output [11:0] 	dvi_d;			//DIV Outputs
   output 		dvi_vs, dvi_hs, 	//DIV Outputs
			dvi_xclk_p, 		//DIV Outputs
			dvi_xclk_n, 		//DIV Outputs
			dvi_de, 		//DIV Outputs
			dvi_reset_b;		//DIV Outputs
   inout 		dvi_sda, dvi_scl;

   /* The GPU */
   wire [1:0]  mode_video;
   wire [7:0]  do_video;
	wire [1:0] int_req, int_ack;
   wire        mem_enable_video;
	wire mem_re;
	wire mem_we;
	wire [15:0] video_addr;
	wire reset;

	wire [7:0] video_data_in;
	
   assign mem_enable_video = 1'b1;
	assign mem_re = 1'b1;
	assign mem_we = 1'b1;
	assign int_ack = 2'b0;
	assign int_req = 2'b0;
	assign video_addr = 16'b0;
	assign video_data_in = 8'b0;
	assign reset = GPIO_SW_C;

   gpu_top gpu (// Outputs
		.do_video		(do_video[7:0] ),
		.mode_video		(mode_video[1:0]),
		.int_req		(int_req[1:0]),
		.dvi_d			(dvi_d[11:0]),
		.dvi_vs			(dvi_vs),
		.dvi_hs			(dvi_hs),
		.dvi_xclk_p		(dvi_xclk_p),
		.dvi_xclk_n		(dvi_xclk_n),
		.dvi_de			(dvi_de),
		.dvi_reset_b		(dvi_reset_b),
		.led_out		(),
		.iic_done		(),
		// Inouts
		.dvi_sda		(dvi_sda),
		.dvi_scl		(dvi_scl),
		// Inputs
		.clk27			(CLK_27MHZ_FPGA),
		.clk33			(CLK_33MHZ_FPGA),
		.clk100			(USER_CLK),
		.top_rst_b		(~reset),
		.mem_enable_video	(mem_enable_video),
		.rd_n_video		(~mem_re),
		.wr_n_video		(~mem_we),
		.A_video		(video_addr),
		.di_video		(video_data_in),
		.int_ack		(int_ack[1:0]),
		.switches78		());

   
endmodule
