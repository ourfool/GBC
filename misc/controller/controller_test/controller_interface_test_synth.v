`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:04:56 10/26/2014 
// Design Name: 
// Module Name:    controller_interface_test_synth 
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
module controller_interface_test_synth(
									USER_CLK,
                            		GPIO_DIP_SW1,
								    GPIO_LED_0,       									 
									GPIO_LED_1,
								    GPIO_LED_2,
								    GPIO_LED_3,
                            		GPIO_LED_4,
                            		GPIO_LED_5,
                            		GPIO_LED_6,
                            		GPIO_LED_7,
									GPIO_SW_W,
									GPIO_SW_C,
									CLK_33MHZ_FPGA,
									HDR2_2_SM_8_N,
									HDR2_4_SM_8_P,
									HDR2_6_SM_7_N
									 
    );
	input 	USER_CLK;
   	input 	GPIO_DIP_SW1, GPIO_SW_W, GPIO_SW_C, CLK_33MHZ_FPGA;
	input 	HDR2_6_SM_7_N;
	output 	GPIO_LED_0,GPIO_LED_1,GPIO_LED_2,
			GPIO_LED_3,GPIO_LED_4,GPIO_LED_5,
          	GPIO_LED_6,GPIO_LED_7;
	output 	HDR2_2_SM_8_N, HDR2_4_SM_8_P;
	


	wire reset;
	wire [7:0] buttons;
	wire latch;
	wire pulse;
	wire data;
	integer count;
	
	assign { GPIO_LED_7, GPIO_LED_6, GPIO_LED_5, GPIO_LED_4, GPIO_LED_3, GPIO_LED_2, GPIO_LED_1, GPIO_LED_0 } = buttons;
	assign HDR2_2_SM_8_N = latch;
	assign HDR2_4_SM_8_P = pulse;
	assign data = HDR2_6_SM_7_N;
	assign reset = GPIO_SW_W;

	controller_interface controller(
		// outputs
		.O_BUTTONS(buttons),
		.O_LATCH(latch),
		.O_PULSE(pulse),
	
		// inputs
		.I_CLK_33MHZ(CLK_33MHZ_FPGA),
		.I_DATA(data),
	
		.I_RESET(reset)
	);


endmodule
