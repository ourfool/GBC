`include "../../memory/io_bus_parser/io_bus_parser.v"
`include "../../memory/memory_router/memdef.vh"
`default_nettype none

module dma_controller(
                      I_CLK,
                      I_DMA_CLK,
                      I_SYNC_RESET,

                      /*IO Register Bus*/
                      I_IOREG_ADDR,
                      IO_IOREG_DATA,
                      I_IOREG_WE_L,
                      I_IOREG_RE_L,

                      /*DMA Reader Signals*/
                      O_RDMA_ADDR,
                      I_RDMA_DATA,
                      O_RDMA_RE_L,

                      /*DMA Write Signals*/
                      O_WDMA_ADDR,
                      O_WDMA_DATA,
                      O_WDMA_WE_L,

                      /*System Status Signals*/
                      I_HBLANK, //to be held high during duration of
                                //horizontal blanking period
                      O_HALT_CPU, // stop cpu execution durind DMA
                      
                      /*for debugging*/
                      O_DMA_DATA,
                      O_HDMA1_DATA, 
                      O_HDMA2_DATA, 
                      O_HDMA3_DATA, 
                      O_HDMA4_DATA, 
                      O_HDMA5_DATA
                      );

   input I_CLK, I_DMA_CLK;
   input I_SYNC_RESET;

   input [15:0] I_IOREG_ADDR;
   inout [7:0] IO_IOREG_DATA;
   input I_IOREG_WE_L;
   input I_IOREG_RE_L;
   output [15:0] O_RDMA_ADDR;
   input [7:0]   I_RDMA_DATA;
   output 	 O_RDMA_RE_L;
   output [15:0] O_WDMA_ADDR;
   output [7:0]  O_WDMA_DATA;
   output 	 O_WDMA_WE_L;
   input         I_HBLANK;
   output        O_HALT_CPU;
   output [7:0]  O_DMA_DATA,O_HDMA1_DATA, O_HDMA2_DATA, 
                  O_HDMA3_DATA, O_HDMA4_DATA, O_HDMA5_DATA;

   reg           gdma_cpu_halt, hdma_cpu_halt;
   assign O_HALT_CPU = gdma_cpu_halt | hdma_cpu_halt;


   wire gnd = 0;
   wire high = 1;
   wire[7:0]  gnd_data = 8'd0;
   wire          start_new_dma;
   wire [7:0]    dma_staddr_high;
   wire [15:0]   oam_rdma_addr;
   wire [15:0]   oam_wdma_addr;
   reg [7:0]     oam_count;
   reg           oam_dma_active;
   reg           oam_dma_we_l;
   reg           oam_dma_re_l;
   reg           gdma_active, hdma_active;
   reg           gdma_we_l, gdma_re_l,
                 hdma_we_l, hdma_re_l;
   wire [15:0]   gdma_rdma_addr, hdma_rdma_addr;
   wire [15:0]   gdma_wdma_addr, hdma_wdma_addr;

   /*the output is always gonna be the input in this DMA, since
    *memory r/w operations are 0 cycle latency*/
   assign O_WDMA_DATA = I_RDMA_DATA;

   /*multiplex which dma controller gets access to the port*/
   assign O_RDMA_ADDR = (oam_dma_active) ? oam_rdma_addr  :
                        (gdma_active)    ? gdma_rdma_addr :
                        (hdma_active)    ? hdma_rdma_addr : 16'h0000;
   assign O_WDMA_ADDR = (oam_dma_active) ? oam_wdma_addr  :
                        (gdma_active)    ? gdma_wdma_addr :
                        (hdma_active)    ? hdma_wdma_addr : 16'h0000;
   assign O_RDMA_RE_L = (oam_dma_active) ? oam_dma_re_l   :
                        (gdma_active)    ? gdma_re_l      :
                        (hdma_active)    ? hdma_re_l      : 1;
   assign O_WDMA_WE_L = (oam_dma_active) ? oam_dma_we_l   :
                        (gdma_active)    ? gdma_we_l      :
                        (hdma_active)    ? hdma_we_l      : 1;

   /*DMA Register - stores the high bytes in the
    * address that the source of the DMA transfer is from*/
   io_bus_parser_reg #(`DMA,0,0,0,0) dma_reg(
                                             .I_CLK(I_CLK),
                                             .I_SYNC_RESET(I_SYNC_RESET),
                                             .IO_DATA_BUS(IO_IOREG_DATA),
                                             .I_ADDR_BUS(I_IOREG_ADDR),
                                             .I_WE_BUS_L(I_IOREG_WE_L),
                                             .I_RE_BUS_L(I_IOREG_RE_L),
                                             .I_DATA_WR(gnd_data), //no writing to this register
                                             .O_DATA_READ(dma_staddr_high), //to read from the io register
                                             .I_REG_WR_EN(gnd), //no writing to this register
                                             .O_DBUS_WRITE(start_new_dma));

   /*use base address high bits and the count as the offset*/
   assign oam_rdma_addr[15:8] = dma_staddr_high;
   assign oam_rdma_addr[7:0]  = oam_count;

   /*use oam memory base addr high bits, and the count
    *as the offset*/
   assign oam_wdma_addr[15:8] = 8'hFE; //OAM high bits
   assign oam_wdma_addr[7:0] =  oam_count;

   reg           oam_dma_state;

   /*OAM DMA Controller State Declarations*/
   parameter OAM_DMA_WAIT = 1'b0;
   parameter OAM_DMA_WRITE = 1'b1;

   /*OAM DMA CONTROLLER*/
   always @(posedge I_CLK) begin

      oam_dma_re_l <= 1;
      oam_dma_we_l <= 1;
      oam_dma_active <= 0;

      case(oam_dma_state)
        OAM_DMA_WAIT: begin
           /*register indicates that a write took place to
            *DMA register, so start the DMA transactiong*/
           if (start_new_dma) begin
              oam_dma_state <= OAM_DMA_WRITE;
              oam_count <= 0;
              oam_dma_re_l <= 0;
              oam_dma_we_l <= 0;
              oam_dma_active <= 1;
           end
           else begin
             oam_dma_state <= OAM_DMA_WAIT;
           end
        end

        OAM_DMA_WRITE: begin
           /*oam dma transfer must be exactly 160 cycles,
            and 160 bytes of information*/
           if (oam_count == 'd159) begin
              oam_dma_state <= OAM_DMA_WAIT;
              oam_count <= 'd0;
              oam_dma_active <= 0;
           end
           else begin
              oam_dma_active <= 1;
              oam_count <= oam_count + 1;
              oam_dma_state <= OAM_DMA_WRITE;
              oam_dma_re_l <= 0;
              oam_dma_we_l <= 0;
           end
        end
      endcase

      if (I_SYNC_RESET) begin
         oam_dma_state <= OAM_DMA_WAIT;
         oam_count <= 0;
      end
   end // always @ (posedge I_CLK)

   wire [7:0] hdma_source_high, hdma_source_low,
              hdma_dest_high,   hdma_dest_low;
   wire [7:0] hdma5_specification, hdma5_status;
   wire       hdma_init_change;

   /*HDMA Register Instantiations - we only care about the contents
    *of what is in them, so ground the inputs (on our interface)
    *and read the data*/
   io_bus_parser_reg #(`HDMA1,0,0,0,0) hdma1_reg(
                                               .I_CLK(I_CLK),
                                               .I_SYNC_RESET(I_SYNC_RESET),
                                               .IO_DATA_BUS(IO_IOREG_DATA),
                                               .I_ADDR_BUS(I_IOREG_ADDR),
                                               .I_WE_BUS_L(I_IOREG_WE_L),
                                               .I_RE_BUS_L(I_IOREG_RE_L),
                                               .I_DATA_WR(gnd_data),
                                               .O_DATA_READ(hdma_source_high),
                                               .I_REG_WR_EN(gnd));

   io_bus_parser_reg #(`HDMA2,0,0,0,0) hdma2_reg(
                                               .I_CLK(I_CLK),
                                               .I_SYNC_RESET(I_SYNC_RESET),
                                               .IO_DATA_BUS(IO_IOREG_DATA),
                                               .I_ADDR_BUS(I_IOREG_ADDR),
                                               .I_WE_BUS_L(I_IOREG_WE_L),
                                               .I_RE_BUS_L(I_IOREG_RE_L),
                                               .I_DATA_WR(gnd_data),
                                               .O_DATA_READ(hdma_source_low),
                                               .I_REG_WR_EN(gnd));

   io_bus_parser_reg #(`HDMA3,0,0,0,0) hdma3_reg(
                                               .I_CLK(I_CLK),
                                               .I_SYNC_RESET(I_SYNC_RESET),
                                               .IO_DATA_BUS(IO_IOREG_DATA),
                                               .I_ADDR_BUS(I_IOREG_ADDR),
                                               .I_WE_BUS_L(I_IOREG_WE_L),
                                               .I_RE_BUS_L(I_IOREG_RE_L),
                                               .I_DATA_WR(gnd_data),
                                               .O_DATA_READ(hdma_dest_high),
                                               .I_REG_WR_EN(gnd));

   io_bus_parser_reg #(`HDMA4,0,0,0,0) hdma4_reg(
                                               .I_CLK(I_CLK),
                                               .I_SYNC_RESET(I_SYNC_RESET),
                                               .IO_DATA_BUS(IO_IOREG_DATA),
                                               .I_ADDR_BUS(I_IOREG_ADDR),
                                               .I_WE_BUS_L(I_IOREG_WE_L),
                                               .I_RE_BUS_L(I_IOREG_RE_L),
                                               .I_DATA_WR(gnd_data),
                                               .O_DATA_READ(hdma_dest_low),
                                               .I_REG_WR_EN(gnd));

   /*FOR HDMA5, we need two registers, one read only and one write only,
    *since reading and writing from the register goes to different operations.
    *Reading from HDMA5 gives the status of the DMA transfer, while writing to
    *to register initiates or cancels a dma operation*/

   /*write only register (01) */
   io_bus_parser_reg #(`HDMA5,0,0,0,'b01) hdma5w_reg(
                                                  .I_CLK(I_CLK),
                                                  .I_SYNC_RESET(I_SYNC_RESET),
                                                  .IO_DATA_BUS(IO_IOREG_DATA),
                                                  .I_ADDR_BUS(I_IOREG_ADDR),
                                                  .I_WE_BUS_L(I_IOREG_WE_L),
                                                  .I_RE_BUS_L(I_IOREG_RE_L),
                                                  .I_DATA_WR(gnd_data),
                                                  .O_DATA_READ(hdma5_specification),
                                                  .O_DBUS_WRITE(hdma_init_change),
                                                  .I_REG_WR_EN(gnd));

   /*read only register (10) - forward the status data*/
   io_bus_parser_reg #(`HDMA5,0,1,0,'b10) hdma5r_reg(
                                                    .I_CLK(I_CLK),
                                                    .I_SYNC_RESET(I_SYNC_RESET),
                                                    .IO_DATA_BUS(IO_IOREG_DATA),
                                                    .I_ADDR_BUS(I_IOREG_ADDR),
                                                    .I_WE_BUS_L(I_IOREG_WE_L),
                                                    .I_RE_BUS_L(I_IOREG_RE_L),
                                                    .I_DATA_WR(hdma5_status),
                                                    .I_REG_WR_EN(high)); //enables status to always be forwarded

   parameter GDMA_WAIT = 'b0;
   parameter GDMA_WRITE = 'b1;
   reg        gdma_state;
   wire [15:0] dest_base_addr, source_base_addr;
   wire [15:0] transfer_length;
   reg [15:0]  gdma_count;

   wire        dma_sel;

   assign dest_base_addr[15:13] = 3'b100;//top 3 bits have to be 100, (vram destination)
   assign dest_base_addr[12:8] = hdma_dest_high[4:0];
   assign dest_base_addr[7:0] = hdma_dest_low & 8'hF0; //lowest 4 bits are 0
   assign source_base_addr[15:8] = hdma_source_high;
   assign source_base_addr[5:0] = hdma_source_low & 8'hF0;
   assign dma_sel = hdma5_specification[7];
   assign transfer_length = (hdma5_specification[6:0] + 1) << 4; //16*(n+1)
   
   //when running at double speed, DMA transfer takes same time as single speed, 
   //hence [16:1] (doubles the time it takes)
   assign gdma_rdma_addr = source_base_addr + gdma_count;
   assign gdma_wdma_addr = dest_base_addr + gdma_count; 

   /*GENERAL DMA CONTROLLER*/
   always @(posedge I_DMA_CLK) begin

      gdma_re_l <= 1;
      gdma_we_l <= 1;

      case(gdma_state)
        GDMA_WAIT: begin
           /*register indicates that a write took place to
            *DMA register, so start the DMA transacting.
            * only activate when hdma is not running (writing 0
            * cancels the other dma engine if it is active*/
           if (hdma_init_change & (dma_sel == 0) & ~hdma_active) begin
              gdma_state <= GDMA_WRITE;
              gdma_count <= 0;
              gdma_re_l <= 0;
              gdma_we_l <= 0;
              gdma_active <= 1;
              gdma_cpu_halt <= 1;
           end
           else begin
             gdma_state <= GDMA_WAIT;
           end
        end

        GDMA_WRITE: begin
           if (gdma_count >= transfer_length - 1) begin
              gdma_state <= GDMA_WAIT;
              gdma_count <= 'd0;
              gdma_active <= 0;
              gdma_cpu_halt <= 0;
           end
           else begin
              gdma_cpu_halt <= 1;
              gdma_active <= 1;
              gdma_count <= gdma_count + 1;
              gdma_state <= GDMA_WRITE;
              gdma_re_l <= 0;
              gdma_we_l <= 0;
           end
        end
      endcase // case (gdma_state)
      
      if (I_SYNC_RESET) begin
        gdma_state <= GDMA_WAIT;
        gdma_count <= 0;
        gdma_active <= 0;
        gdma_cpu_halt <= 0;
      end
        

   end // always @ (posedge I_CLK)

   parameter HDMA_WAIT = 2'b00;
   parameter HDMA_WAIT_HBLANK = 2'b01;
   parameter HDMA_16WRITE = 2'b10;
   parameter HDMA_CHECK_WAIT = 2'b11;

   reg [1:0] hdma_state;
   reg [15:0] hdma_count;

   /*give the status of the DMA transfer to the read only register of HDMA5*/
   assign hdma5_status[7] = (hdma_state == HDMA_WAIT);
   assign hdma5_status[6:0] = ((transfer_length - hdma_count) >> 4) - 1;

   /*find the rising edge of the hblank signal to know
    *when to trigger the 16 bytes write of the hdma*/
   reg        hblank_d1;
   reg        rising_edge_hblank;
   wire [3:0] hdma_4bits;
   assign hdma_4bits = hdma_count;
   always @(posedge I_CLK) begin
      hblank_d1 <= I_HBLANK;
      rising_edge_hblank <= ~hblank_d1 & I_HBLANK;
   end

   assign hdma_rdma_addr = source_base_addr + hdma_count;
   assign hdma_wdma_addr = dest_base_addr + hdma_count;
   
   assign O_HDMA5_DATA = {6'b0, hdma_state};
   assign O_HDMA4_DATA = hdma5_status;
   assign O_HDMA3_DATA = hdma5_specification;

   /*Horizontal DMA Controller*/
   always @(posedge I_DMA_CLK) begin

      hdma_we_l <= 1;
      hdma_re_l <= 1;

      case(hdma_state)

        /*wait for an HDMA signal from the CPU*/
        HDMA_WAIT: begin

           /*indicatesthe CPU schedules DMA transaction*/
           if (hdma_init_change & (dma_sel == 1)) begin

              /*initiation on same cycle as start of hblank*/
              if (rising_edge_hblank) begin
                 hdma_state <= HDMA_16WRITE;
                 hdma_we_l <= 0;
                 hdma_re_l <= 0;
                 hdma_active <= 1;
                 hdma_count <= 0;
                 hdma_cpu_halt <= 1;
              end
              else /*go to wait for start of hblank*/
                hdma_state <= HDMA_WAIT_HBLANK;
           end
           else begin
              hdma_state <= HDMA_WAIT;
           end
        end // case: HDMA_WAIT

        /*wait for the start of Hblank after a
         *request was made*/
        HDMA_WAIT_HBLANK: begin

           /*if a cancel request*/
           hdma_active <= 1;
           if (hdma_init_change & (dma_sel == 0)) begin
              hdma_state <= HDMA_WAIT; 
              hdma_count <= 0;
              hdma_active <= 0;
           end

           /*start DMA on first hblank period*/
           else if (rising_edge_hblank) begin
              hdma_state <= HDMA_16WRITE;
              hdma_we_l <= 0;
              hdma_re_l <= 0;
              hdma_active <= 1;
              hdma_count <= 0;
              hdma_cpu_halt <= 1;
           end
           else begin
              hdma_state <= HDMA_WAIT_HBLANK;
           end
        end // case: HDMA_WAIT_HBLANK

        /*writing 16 bytes of data*/
        HDMA_16WRITE: begin

           hdma_active <= 1;

           /*if HDMA cancel*/
           if (hdma_init_change & (dma_sel == 0)) begin
              hdma_state <= HDMA_WAIT;
              hdma_count <= 0;
              hdma_cpu_halt <= 0;
              hdma_active <= 0;
           end

           /*this was the last burst of writing 16*/
           else if (hdma_count >= transfer_length -1) begin
              hdma_state <= HDMA_WAIT;
              hdma_cpu_halt <= 0;
              hdma_count <= hdma_count + 1; //rollover last byte to show FF for status data
              hdma_active <= 0;
           end

           /*write 16 values then wait for next hblank period*/
           else if (hdma_4bits >= 4'hF) begin
              hdma_state <= HDMA_CHECK_WAIT;
              hdma_count <= hdma_count + 1;
              hdma_cpu_halt <= 0;
           end

           /*in the middle of moving 16 bytes*/
           else begin
              hdma_cpu_halt <= 1;
              hdma_we_l <= 0;
              hdma_re_l <= 0;
              hdma_state <= HDMA_16WRITE;
              hdma_count <= hdma_count + 1;
           end
        end // case: HDMA_16WRITE

        /*waiting for the next hblank period*/
        HDMA_CHECK_WAIT: begin

           hdma_active <= 1;

           /*if cancel*/
           if ( hdma_init_change & (dma_sel == 0)) begin
              hdma_state <= HDMA_WAIT;
              hdma_count <= 0;
              hdma_active <= 0;
              hdma_cpu_halt <= 0;
           end

           /*start of new hblank period,
            *go to write 16 more bytes*/
           else if (rising_edge_hblank) begin
              hdma_state <= HDMA_16WRITE;
              hdma_we_l <= 0;
              hdma_re_l <= 0;
              hdma_cpu_halt <= 1;
           end

           /*continue waiting for next hblank*/
           else begin
              hdma_state <= HDMA_CHECK_WAIT;
           end
        end

      endcase // case (hdma_state)

      if (I_SYNC_RESET) begin
	     hdma_state <= HDMA_WAIT;
	     hdma_count <= 0;
         hdma_active <= 0;
         hdma_cpu_halt <= 0;
      end


   end


endmodule




