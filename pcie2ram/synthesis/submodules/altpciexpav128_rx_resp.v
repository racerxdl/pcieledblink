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

module altpciexpav128_rx_resp

#(

  parameter CG_COMMON_CLOCK_MODE = 1
)

  ( input          Clk_i,
    input          AvlClk_i,
    input          Rstn_i,
    input          RxmRstn_i,
    
    // Interface to Transaction layer
    input          CplReq_i,
    input  [5:0]   CplDesc_i, 
    
    /// interface to completion buffer
    output [8:0]    CplRdAddr_o,
    input [129:0]   CplBufData_i,
    
    // interface to tx control
    output         TagRelease_o,
    
    // interface to Avalon slave
    output  [127:0]  TxsReadData_o,
    output          TxsReadDataValid_o
  );
  
  //state machine encoding
  localparam RXCPL_IDLE         = 3'h0;
  localparam RXCPL_RDPIPE       = 3'h3;
  localparam RXCPL_RD_VALID     = 3'h5;
  
wire                          last_qword;
wire                          dw_swap;
reg                           dw_swap_reg;
reg        [2:0]              rxcpl_state;
reg        [2:0]              rxcpl_nxt_state;
wire                          rdpipe_st;
wire                          rdvalid_st;
reg        [4:0]              rd_addr_cntr;
reg        [3:0]              hol_cntr;
reg        [15:0]             tag_status_reg;
reg        [15:0]             last_cpl_reg;

reg                           cpl_req_reg;
wire                          cpl_req;
wire                          cpl_done;
reg                           cpl_done_reg;
wire       [3:0]              tag;
wire                           cpl_ack_reg;
wire                          cpl_req_int;
wire                          last_cpl;
wire                          rxcpl_idle_state;
wire                          cpl_req_rise;
wire 			      valid_cpl;
wire 			      cpl_eop;


///// NEW codes
// outstanding read status based on tag


always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
       cpl_req_reg <= 1'b0;
    else
       cpl_req_reg <= CplReq_i;
  end
  
  assign cpl_req_rise = ~cpl_req_reg & CplReq_i;


  assign    tag = CplDesc_i[3:0];
  assign    valid_cpl = CplDesc_i[4];
  assign    last_cpl = CplDesc_i[5];
  assign    cpl_eop  = CplBufData_i[129];
generate
  genvar i;
  for(i=0; i< 16; i=i+1)
    begin: tag_status_register
       always @(posedge AvlClk_i or negedge Rstn_i)
         begin
           if(~Rstn_i)
              last_cpl_reg[i] <= 1'b0;
           else if(cpl_req_rise & tag == i)
              last_cpl_reg[i] <= last_cpl;
           else if(cpl_done & hol_cntr == i & last_cpl_reg[i]) // release the tag
              last_cpl_reg[i] <= 1'b0;
         end
         
     always @(posedge AvlClk_i or negedge Rstn_i)
         begin
           if(~Rstn_i)
              tag_status_reg[i] <= 1'b0;
           else if(cpl_req_rise & last_cpl & tag == i)
              tag_status_reg[i] <= 1'b1;
           else if(cpl_done & hol_cntr == i) // release the tag
              tag_status_reg[i] <= 1'b0;
         end 

       end
  endgenerate
  
  
always @(posedge AvlClk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
     rxcpl_state  <= RXCPL_IDLE;
    else
      rxcpl_state <= rxcpl_nxt_state;
  end


always @*
  begin
    case(rxcpl_state)
      RXCPL_IDLE :
         if(tag_status_reg[hol_cntr])
          rxcpl_nxt_state <= RXCPL_RDPIPE; // read pipe state
        else
          rxcpl_nxt_state <= RXCPL_IDLE;
                                                              
      RXCPL_RDPIPE:
        if(cpl_eop)
           rxcpl_nxt_state <= RXCPL_IDLE;
        else
          rxcpl_nxt_state <= RXCPL_RD_VALID;
       
      RXCPL_RD_VALID: 
        if(cpl_eop)
          rxcpl_nxt_state <= RXCPL_IDLE;
        else
          rxcpl_nxt_state <= RXCPL_RD_VALID;
          
      default:
          rxcpl_nxt_state <= RXCPL_IDLE;
       
    endcase
end      

assign rxcpl_idle_state = ~rxcpl_state[0]; 
assign rdpipe_st = rxcpl_state[1];
assign rdvalid_st = rxcpl_state[2];
assign TxsReadDataValid_o = rdpipe_st | rdvalid_st;
assign TxsReadData_o[127:0] = CplBufData_i[127:0];
assign cpl_done = (rdvalid_st | rdpipe_st) & cpl_eop ;
assign TagRelease_o =  rxcpl_idle_state & (last_cpl_reg[hol_cntr]);
/*
always @(posedge AvlClk_i or negedge RxmRstn_i)
  begin
    if(~RxmRstn_i)
       cpl_done_reg <= 1'b0;
    else 
       cpl_done_reg <= cpl_done;
  end

assign TagRelease_o = cpl_done_reg;
*/
// head of line counter

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
       hol_cntr <= 4'h0;
    else if(cpl_done & last_cpl_reg[hol_cntr])
       hol_cntr <= hol_cntr + 1;
  end

/// completion buffer address counter
          
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
       rd_addr_cntr <= 5'h0;
    else if(cpl_done)
       rd_addr_cntr <= 5'h0;
    else if(rdpipe_st | rdvalid_st | (rxcpl_idle_state & tag_status_reg[hol_cntr]))
       rd_addr_cntr <= rd_addr_cntr + 1;
  end          
          
          
 assign CplRdAddr_o = {  hol_cntr,      rd_addr_cntr};                                                          
endmodule

