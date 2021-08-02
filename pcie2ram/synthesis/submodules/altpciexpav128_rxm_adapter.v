// (C) 2001-2020 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// altera message_off 10230 10036
// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module altpciexpav128_rxm_adapter
# ( 
     parameter              CB_RXM_DATA_WIDTH      = 128,
     parameter              AVALON_ADDR_WIDTH      = 32
    ) 
(

   input                                 Clk_i,
   input                                 Rstn_i,
                      
   input                                 CoreRxmWrite_i,
   input                                 CoreRxmRead_i,
   input                                 CoreRxmWriteSOP_i,
   input                                 CoreRxmWriteEOP_i,
   input [6:0]                           CoreRxmBarHit_i,
   input [AVALON_ADDR_WIDTH-1:0]         CoreRxmAddress_i,
   input [CB_RXM_DATA_WIDTH-1:0]         CoreRxmWriteData_i,
   input [(CB_RXM_DATA_WIDTH/8)-1:0]     CoreRxmByteEnable_i,
   input [6:0]                           CoreRxmBurstCount_i, 
   output                                CoreRxmWaitRequest_o,
   
   
   output                                 FabricRxmWrite_o,
   output                                 FabricRxmRead_o,
   output [AVALON_ADDR_WIDTH-1:0]         FabricRxmAddress_o,
   output [CB_RXM_DATA_WIDTH-1:0]         FabricRxmWriteData_o,
   output [(CB_RXM_DATA_WIDTH/8)-1:0]     FabricRxmByteEnable_o,
   output  [6:0]                          FabricRxmBurstCount_o, 
   input                                  FabricRxmWaitRequest_i,
   output [6:0]                           FabricRxmBarHit_o
);



  //state machine encoding
  localparam RXM_ADP_IDLE         = 2'h0;
  localparam RXM_ADP_ACTIVE       = 2'h3;
  
wire            fifo_wrreq;
wire [193 + AVALON_ADDR_WIDTH -32 :0]    fifo_wr_data;
wire            fabric_transmit;
wire [193 + AVALON_ADDR_WIDTH -32:0]    fifo_data_out;
wire [3:0]      fifo_count;
wire            fifo_empty;      
wire            rxm_eop;
reg [1:0]        rxm_adp_state;
reg [1:0]        rxm_adp_nxt_state;
wire            rxm_write;
wire            rxm_read;

assign    CoreRxmWaitRequest_o = (  fifo_count > 2 );
assign    fifo_wrreq =   ~CoreRxmWaitRequest_o & (CoreRxmWrite_i | CoreRxmRead_i); 
assign    fifo_wr_data = {CoreRxmBurstCount_i, CoreRxmAddress_i,CoreRxmBarHit_i,CoreRxmRead_i, CoreRxmWrite_i, CoreRxmWriteEOP_i, CoreRxmWriteSOP_i, CoreRxmByteEnable_i, CoreRxmWriteData_i};

// instantiate FIFO
altpciexpav128_fifo 
#  (
       .FIFO_DEPTH(3),
       .DATA_WIDTH(194 + AVALON_ADDR_WIDTH -32)
     )

rxm_fifo
 
(  .clk(Clk_i),
   .rstn(Rstn_i),
   .srst(1'b0),
   .wrreq(fifo_wrreq),
   .rdreq(fabric_transmit),
   .data(fifo_wr_data),  
   .q(fifo_data_out),
   .fifo_count(fifo_count)
  );
  

always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
     rxm_adp_state  <= RXM_ADP_IDLE;
    else
      rxm_adp_state <= rxm_adp_nxt_state;
  end

always @*
  begin
    case(rxm_adp_state)
      RXM_ADP_IDLE :
         if(~fifo_empty )
          rxm_adp_nxt_state <= RXM_ADP_ACTIVE;
        else
          rxm_adp_nxt_state <= RXM_ADP_IDLE;
                                                              
      RXM_ADP_ACTIVE:
        if(rxm_eop & ~FabricRxmWaitRequest_i )
           rxm_adp_nxt_state <= RXM_ADP_IDLE;
        else
          rxm_adp_nxt_state <= RXM_ADP_ACTIVE;
       
      default:
          rxm_adp_nxt_state <= RXM_ADP_IDLE;
       
    endcase
end      

assign FabricRxmWrite_o = rxm_adp_state[1] & rxm_write;       
assign FabricRxmRead_o  = rxm_adp_state[1] & rxm_read; 

assign fabric_transmit = (FabricRxmWrite_o | FabricRxmRead_o ) & ~FabricRxmWaitRequest_i;

assign FabricRxmWriteData_o = fifo_data_out[127:0];
assign FabricRxmByteEnable_o =  fifo_data_out[143:128];
assign FabricRxmAddress_o    = fifo_data_out[186+ AVALON_ADDR_WIDTH -32:155];         
assign FabricRxmBurstCount_o = fifo_data_out[193 + AVALON_ADDR_WIDTH -32:187 + AVALON_ADDR_WIDTH -32]; 
assign rxm_eop = fifo_data_out[145];    
assign rxm_write = fifo_data_out[146];
assign rxm_read = fifo_data_out[147];
assign FabricRxmBarHit_o = fifo_data_out[154:148];
assign fifo_empty = (fifo_count == 4'h0);


endmodule
  






