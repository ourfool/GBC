module reset_controller(
			I_CLK,
			I_ASYNC_RESET,

			/*will be held high for 5 cycles*/
			O_SYNC_RESET
            );


   input      I_CLK, I_ASYNC_RESET;
   output reg O_SYNC_RESET;

   reg [7:0] count = 0;

   always @(posedge I_CLK) begin

        O_SYNC_RESET <= 0;
        if (count > 0) begin
            count <= count - 1;
            O_SYNC_RESET <= 1;
        end
        
        if (I_ASYNC_RESET)
            count <= 100;
   end

endmodule // reset_controller

      