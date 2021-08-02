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



// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module altpciexpav_stif_txresp_cntrl

#(

    parameter TXCPL_BUFF_ADDR_WIDTH = 9,
    parameter CB_PCIE_RX_LITE       = 0

)




( input                                AvlClk_i,     // Avalon clock
  input                                Rstn_i,    // Avalon reset

  // interface to the Rx pending read FIFO
  input                                RxPndgRdFifoEmpty_i,
  input    [56:0]                      RxPndgRdFifoDato_i,
  output                               RxPndgRdFifoRdReq_o,

  // interface to the Avalon bus
  input                                TxReadDataValid_i,


  // Interface to the Command Fifo
  output      [98:0]                   CmdFifoDatin_o,
  output                               CmdFifoWrReq_o,
  input       [3:0]                    CmdFifoUsedw_i,

  // Interface to Completion data buffer
  output     [TXCPL_BUFF_ADDR_WIDTH-1:0]                    CplRamWrAddr_o,

  // Interface to the Avalon Tx Control Module
  input                                CmdFifoBusy_i,

  // cfg signals
  input      [31:0]                    DevCsr_i,
  input      [12:0]                    BusDev_i,
  output                               TxRespIdle_o


);

localparam      TXRESP_IDLE          = 14'h0000;
localparam      TXRESP_RD_FIFO       = 14'h0003;
localparam      TXRESP_LD_BCNT       = 14'h0005;
localparam      TXRESP_WAIT_DATA     = 14'h0009;
localparam      TXRESP_SEND_FIRST    = 14'h0011;
localparam      TXRESP_SEND_LAST     = 14'h0021;
localparam      TXRESP_SEND_MAX      = 14'h0041;
localparam      TXRESP_DONE          = 14'h0081;
localparam      TXRESP_WAIT_FIRST    = 14'h0101;
localparam      TXRESP_WAIT_MAX      = 14'h0201;
localparam      TXRESP_WAIT_LAST     = 14'h0401;
localparam      TXRESP_PIPE_FIRST    = 14'h0801;
localparam      TXRESP_PIPE_MAX      = 14'h1001;
localparam      TXRESP_PIPE_LAST     = 14'h2001;


wire    sm_rd_fifo;
wire    sm_ld_bcnt;
wire    sm_wait_data;
wire    sm_send_first;
wire    sm_send_last;
wire [7:0]    bytes_to_RCB;
wire          over_rd_2dw;
wire          over_rd_1dw;
wire [12:0]   first_bytes_sent;
reg  [12:0]   first_bytes_sent_reg;
reg  [12:0]   last_bytes_sent_reg;
reg  [12:0]   max_bytes_sent_reg;
wire [12:0]   max_bytes_sent;
wire [12:0]   last_bytes_sent;
wire [7:0]    tag;
wire [15:0]  requester_id;
wire  [6:0]  rd_addr;
wire  [10:0] rd_dwlen;
wire  [3:0] fbe;
wire  [3:0] lbe;
wire  [1:0] attr;
wire [2:0]  tc;
wire  [11:0] remain_bytes;
reg   [11:0] remain_bytes_reg;
wire         is_flush;
wire         is_uns_rd_size;
wire         is_cpl;
wire [8:0]   dw_len;
reg  [3:0]   first_byte_mask;
reg  [3:0]   last_byte_mask;
reg  [3:0]   laddf_bytes_mask_reg;
reg  [13:0]   txresp_state;
reg  [13:0]   txresp_nxt_state;
reg          first_cpl_sreg;
wire         first_cpl;
reg [7:0]    bytes_to_RCB_reg;
reg [12:0]   curr_bcnt_reg;
reg [12:0]   max_payload;
reg [13:0]   payload_cntr;
reg [7:0]   payload_limit_cntr;
reg [10:0]   payload_consumed_cntr;
reg [10:0]  payload_required_reg;
wire[10:0]   payload_available_sub;
wire        payload_ok;
reg         payload_ok_reg;
reg [12:0]   bytes_sent;
reg [12:0]   actual_bytes_sent;
reg [12:0]   sent_bcnt_reg;
reg [6:0] lower_addr;
reg [6:0] lower_addr_reg;
reg [8:0]   cplbuff_addr_cntr;
wire        cmd_fifo_ok;
wire        sm_send_max;
wire        sm_wait_first;
wire        sm_wait_last;
wire        sm_wait_max;
wire        sm_idle;


assign cmd_fifo_ok = (CmdFifoUsedw_i < 8);

always @(posedge AvlClk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      txresp_state <= TXRESP_IDLE;
    else
      txresp_state <= txresp_nxt_state;
  end

// state machine next state gen


always @*

  begin
    case(txresp_state)
      TXRESP_IDLE :
        if(~RxPndgRdFifoEmpty_i)
          txresp_nxt_state <= TXRESP_RD_FIFO;
        else
          txresp_nxt_state <= TXRESP_IDLE;

      TXRESP_RD_FIFO :
          txresp_nxt_state <= TXRESP_LD_BCNT;

      TXRESP_LD_BCNT:  // load byte count reg and calculate the first byte 7 bit of address
           txresp_nxt_state <= TXRESP_WAIT_DATA;

      TXRESP_WAIT_DATA:

        if(first_cpl & ~CmdFifoBusy_i & cmd_fifo_ok & (  is_flush | is_uns_rd_size ))
          txresp_nxt_state <= TXRESP_SEND_LAST;
        else  if(first_cpl & ~CmdFifoBusy_i & cmd_fifo_ok &((curr_bcnt_reg > bytes_to_RCB_reg)))
          txresp_nxt_state <= TXRESP_WAIT_FIRST;

        else if((first_cpl & ~CmdFifoBusy_i & cmd_fifo_ok &(((curr_bcnt_reg <= bytes_to_RCB_reg)) ) ) |
                (~first_cpl & ~CmdFifoBusy_i & cmd_fifo_ok &(curr_bcnt_reg <= max_payload) )
                 )
          txresp_nxt_state <= TXRESP_WAIT_LAST;

        else if(~first_cpl & ~CmdFifoBusy_i & cmd_fifo_ok & (curr_bcnt_reg >  max_payload))
          txresp_nxt_state <= TXRESP_WAIT_MAX;
        else
          txresp_nxt_state <= TXRESP_WAIT_DATA;

      TXRESP_WAIT_FIRST:
           txresp_nxt_state <= TXRESP_PIPE_FIRST;

      TXRESP_PIPE_FIRST:
           if(payload_ok_reg & ~CmdFifoBusy_i & cmd_fifo_ok)
             txresp_nxt_state <= TXRESP_SEND_FIRST;
           else
             txresp_nxt_state <= TXRESP_PIPE_FIRST;

      TXRESP_WAIT_MAX:
                 txresp_nxt_state <= TXRESP_PIPE_MAX;

       TXRESP_PIPE_MAX:
         if(payload_ok_reg & ~CmdFifoBusy_i & cmd_fifo_ok)
            txresp_nxt_state <= TXRESP_SEND_MAX;
          else
            txresp_nxt_state <= TXRESP_PIPE_MAX;

        TXRESP_WAIT_LAST:
                   txresp_nxt_state <= TXRESP_PIPE_LAST;

        TXRESP_PIPE_LAST:
         if(payload_ok_reg & ~CmdFifoBusy_i & cmd_fifo_ok)
            txresp_nxt_state <= TXRESP_SEND_LAST;
          else
            txresp_nxt_state <= TXRESP_PIPE_LAST;


       TXRESP_SEND_FIRST:
           txresp_nxt_state <= TXRESP_WAIT_DATA;

       TXRESP_SEND_LAST:
         txresp_nxt_state <= TXRESP_DONE;

       TXRESP_SEND_MAX:
         if(remain_bytes_reg == 0)
           txresp_nxt_state <= TXRESP_DONE;
         else
           txresp_nxt_state <= TXRESP_WAIT_DATA;

       TXRESP_DONE:
           txresp_nxt_state <= TXRESP_IDLE;

       default:
         txresp_nxt_state <= TXRESP_IDLE;

    endcase
 end

 /// state machine output assignments
 assign   sm_idle       = ~txresp_state[0];
 assign   sm_rd_fifo    = txresp_state[1];
 assign   sm_ld_bcnt    = txresp_state[2];
 assign   sm_wait_data  = txresp_state[3];
 assign   sm_send_first = txresp_state[4];
 assign   sm_send_last  = txresp_state[5];
 assign   sm_send_max   = txresp_state[6];
 assign   sm_wait_first = txresp_state[8];
  assign   sm_wait_max = txresp_state[9];
  assign   sm_wait_last = txresp_state[10];

  assign TxRespIdle_o = sm_idle & RxPndgRdFifoEmpty_i ;
// SR reg to indicate the first completion of a read

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
     if(~Rstn_i)
       first_cpl_sreg <= 1'b0;
     else if(sm_ld_bcnt)
       first_cpl_sreg <= 1'b1;
     else if(sm_send_first)
       first_cpl_sreg <= 1'b0;
  end


// calculate the bytes to RCB that could be 64 or 128Bytes (6 or 7 zeros in address)

assign bytes_to_RCB = 8'h80 - rd_addr[6:0];

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      bytes_to_RCB_reg <= 0;
    else
      bytes_to_RCB_reg <= bytes_to_RCB;
  end


 /// the current byte count register that still need to be sent (completed)
 always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      curr_bcnt_reg <= 13'h0;
    else if(sm_ld_bcnt)
      curr_bcnt_reg <= {rd_dwlen, 2'b00};
    else if(sm_send_first)
      curr_bcnt_reg <= curr_bcnt_reg - bytes_to_RCB_reg;
    else if(sm_send_max)
      curr_bcnt_reg <= curr_bcnt_reg - max_payload;
    else if(sm_send_last)
      curr_bcnt_reg <= 0;
  end

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      laddf_bytes_mask_reg <= 0;
    else
      laddf_bytes_mask_reg <= (last_byte_mask + first_byte_mask);
  end


/// the remaining bcnt (for the header)
//assign remain_bytes = sm_send_last? 0 : (curr_bcnt_reg - bytes_sent);
// assign remain_bytes = is_flush? 12'h1 : is_uns_rd_size? 0 : curr_bcnt_reg - (laddf_bytes_mask_reg);
 assign remain_bytes = is_flush? 12'h1  : curr_bcnt_reg[11:0] - (laddf_bytes_mask_reg);

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      remain_bytes_reg <= 0;
    else
      remain_bytes_reg <= remain_bytes;
  end

/// completion payload counter to keep track of the data byte returned from avalon

/*
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      payload_cntr <= 0;
    else if(TxReadDataValid_i & ~sm_done & ~sm_send_first & ~sm_send_max & ~sm_send_last)
      payload_cntr <= payload_cntr  + 8;
    else if(sm_send_first &  TxReadDataValid_i)
      payload_cntr <= payload_cntr - sent_bcnt_reg + 8;
    else if(sm_send_first &  ~TxReadDataValid_i)
      payload_cntr <= payload_cntr - sent_bcnt_reg;
    else if(sm_send_max &  TxReadDataValid_i)
      payload_cntr <= payload_cntr - sent_bcnt_reg + 8;
    else if(sm_send_max &  ~TxReadDataValid_i)
      payload_cntr <= payload_cntr - sent_bcnt_reg;
    else if(sm_send_last &  TxReadDataValid_i)
      payload_cntr <= payload_cntr - sent_bcnt_reg + 8;
    else if(sm_send_last &  ~TxReadDataValid_i)
      payload_cntr <= payload_cntr - sent_bcnt_reg;
    else if(sm_done & TxReadDataValid_i)
      payload_cntr <= payload_cntr - over_rd_bytes_reg + 8 ;
    else if(sm_done & ~TxReadDataValid_i)
      payload_cntr <= payload_cntr - over_rd_bytes_reg ;
  end

  */

    /// Credit Limit Reg === payload_cntr (count up only by TxReadDatValid))
  /// Credit Consume Reg == updated by send first, max, last (count up only)

  // Credit Required = actual byte sent
/// Credit Consumed Counter


      always @(posedge AvlClk_i or negedge Rstn_i)
      begin
        if(~Rstn_i)
          payload_consumed_cntr <= 0;
        else if(sm_ld_bcnt & over_rd_2dw & ~is_uns_rd_size)
          payload_consumed_cntr <= payload_consumed_cntr + 11'h8;
        else if(sm_ld_bcnt & over_rd_1dw & ~is_uns_rd_size)
          payload_consumed_cntr <= payload_consumed_cntr + 11'h4;
        else if (sm_send_first | sm_send_max | sm_send_last)
          payload_consumed_cntr <= payload_consumed_cntr + actual_bytes_sent[9:0];
      end

 always @(posedge AvlClk_i or negedge Rstn_i)
      begin
        if(~Rstn_i)
          payload_required_reg <= 0;
        else if(sm_wait_first)
          payload_required_reg <= payload_consumed_cntr + first_bytes_sent_reg[9:0];
        else if (sm_wait_last)
         payload_required_reg <= payload_consumed_cntr + last_bytes_sent_reg[9:0];
        else if (sm_wait_max)
         payload_required_reg <= payload_consumed_cntr + max_bytes_sent_reg[9:0];
      end


 assign payload_available_sub = ({payload_limit_cntr,3'h0} - payload_required_reg);


always @(posedge AvlClk_i or negedge Rstn_i) begin
   if(~Rstn_i) begin
     payload_limit_cntr <= 8'h0;
   end
   else begin
     if (TxReadDataValid_i==1'b1) begin
        payload_limit_cntr <= payload_limit_cntr + 8'h1;
     end
   end
end


 assign payload_ok = payload_available_sub <= 1024 & ~sm_idle & ~sm_rd_fifo & ~sm_ld_bcnt & ~sm_wait_data & ~sm_wait_first & ~sm_wait_max & ~sm_wait_last;

   always @(posedge AvlClk_i or negedge Rstn_i)
      begin
        if(~Rstn_i) begin
          payload_ok_reg <= 1'b0;
          end
        else begin
          payload_ok_reg <= payload_ok;
          end
      end

//  always @(posedge AvlClk_i or negedge Rstn_i)
//  begin
//    if(~Rstn_i)
//      payload_cntr <= 0;
//    else if(TxReadDataValid_i & ~sm_done & ~sm_send_first & ~sm_send_max & ~sm_send_last)
//      payload_cntr <= payload_cntr  + 8;
//    else if ( (sm_send_first &  TxReadDataValid_i) | (sm_send_max &  TxReadDataValid_i) | (sm_send_last  & TxReadDataValid_i))
//      payload_cntr <= payload_cntr - actual_bytes_sent + 8;
//    else if((sm_send_first &  ~TxReadDataValid_i) | (sm_send_max &  ~TxReadDataValid_i) | (sm_send_last &  ~TxReadDataValid_i))
//      payload_cntr <= payload_cntr - actual_bytes_sent;
//    else if(sm_done & TxReadDataValid_i)
//      payload_cntr <= payload_cntr - over_rd_bytes_reg + 8 ;
//    else if(sm_done & ~TxReadDataValid_i)
//      payload_cntr <= payload_cntr - over_rd_bytes_reg ;
//  end


/// over read bytes caculation due to more data being read from the
// avalon to compensate for the alignment 32/64

assign over_rd_2dw = rd_addr[2] & ~rd_dwlen[0] & ~is_flush;
assign over_rd_1dw = rd_dwlen[0] & ~is_flush;


// sent_byte count for a cmpletion header
assign first_bytes_sent  = bytes_to_RCB;
assign max_bytes_sent    =  max_payload;
assign last_bytes_sent   =  curr_bcnt_reg;


///
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     begin
      first_bytes_sent_reg <= 0;
      last_bytes_sent_reg <= 0;
      max_bytes_sent_reg <= 0;
     end
    else
     begin
      first_bytes_sent_reg <= first_bytes_sent;
      last_bytes_sent_reg <= last_bytes_sent;
      max_bytes_sent_reg <= max_bytes_sent;
     end
  end


always @ *
  begin
    case({sm_send_first, sm_send_max, sm_send_last, is_flush, is_uns_rd_size})
      5'b00100 : bytes_sent = last_bytes_sent_reg;
      5'b01000 : bytes_sent = max_bytes_sent_reg;
      5'b10000 : bytes_sent = first_bytes_sent_reg;
      5'b00110 : bytes_sent = 4;
      default : bytes_sent = 0;
    endcase
  end

// actual byte sent is less due dummy flush read data
always @*
  begin
    case({sm_send_first, sm_send_max, sm_send_last, is_flush, is_uns_rd_size})
      5'b00100 : actual_bytes_sent = last_bytes_sent_reg;
      5'b01000 : actual_bytes_sent = max_bytes_sent_reg;
      5'b10000 : actual_bytes_sent = first_bytes_sent_reg;
      default :  actual_bytes_sent = 0;
    endcase
  end


// calculate the 7 bit lower address of the first enable byte
// based on the first byte enable

always @*
 begin
  casex({fbe, is_flush})
    5'bxxx10 : lower_addr = {rd_addr[6:2], 2'b00};
    5'bxx100 : lower_addr = {rd_addr[6:2], 2'b01};
    5'bx1000 : lower_addr = {rd_addr[6:2], 2'b10};
    5'b10000 : lower_addr = {rd_addr[6:2], 2'b11};
    5'bxxxx1 : lower_addr = {rd_addr[6:2], 2'b00};
    default:  lower_addr = 7'b0000000;
  endcase
end

/// decode the fbe and lbe fore the byte count field of the competion packets

assign first_cpl = first_cpl_sreg | sm_ld_bcnt;

always @*   // only first completion uses the fbe for byte count
 begin
  case({first_cpl, fbe})
    5'b10001 : first_byte_mask = 3;
    5'b10010 : first_byte_mask = 3;
    5'b10100 : first_byte_mask = 3;
    5'b11000 : first_byte_mask = 3;
    5'b10011 : first_byte_mask = 2;
    5'b10110 : first_byte_mask = 2;
    5'b11100 : first_byte_mask = 2;
    5'b10111 : first_byte_mask = 1;
    5'b11110 : first_byte_mask = 1;
    default  : first_byte_mask = 0;
  endcase
end

always @(lbe)
 begin
  case(lbe)
    4'b0111 : last_byte_mask = 1;
    4'b0011 : last_byte_mask = 2;
    4'b0001 : last_byte_mask = 3;
    default : last_byte_mask = 0;
  endcase
end



always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      lower_addr_reg <= 0;
    else if(sm_send_first)
      lower_addr_reg <= 0;
    else if(sm_ld_bcnt)
      lower_addr_reg <= lower_addr;
    end



///// Assemble the completion headers
// decode the max payload size
always @*
  begin
    case(DevCsr_i[7:5])
      3'b000 : max_payload= 128;
      default : max_payload = 256;
    endcase
  end

assign tag          = RxPndgRdFifoDato_i[7:0];
assign requester_id = RxPndgRdFifoDato_i[31:16];
assign rd_addr[6:0] = {RxPndgRdFifoDato_i[14:10], 2'b00};
assign rd_dwlen     = RxPndgRdFifoDato_i[42:32];
assign fbe          = RxPndgRdFifoDato_i[46:43];
assign lbe          = RxPndgRdFifoDato_i[55:52];
assign attr          = RxPndgRdFifoDato_i[48:47];
assign tc          = RxPndgRdFifoDato_i[51:49];
assign is_flush     = RxPndgRdFifoDato_i[15];
assign is_uns_rd_size = RxPndgRdFifoDato_i[56];

assign dw_len[8:0] = is_uns_rd_size? 9'h0 : bytes_sent[10:2];

assign CmdFifoDatin_o[98:0] = { 3'b000 ,attr, dw_len[8:0], tc, remain_bytes_reg, is_flush, 1'b1, 4'h0,
                                              32'h0, is_uns_rd_size, requester_id, tag, lower_addr_reg[6:0]};


assign CmdFifoWrReq_o = sm_send_first | sm_send_last | sm_send_max;

assign RxPndgRdFifoRdReq_o = sm_rd_fifo;

/// Completion buffer write address

always @(posedge AvlClk_i or negedge Rstn_i) begin
    if(~Rstn_i)
      cplbuff_addr_cntr <= 9'h0;
    else if(TxReadDataValid_i)
      cplbuff_addr_cntr <= cplbuff_addr_cntr + 9'h1;
end


assign CplRamWrAddr_o[TXCPL_BUFF_ADDR_WIDTH-1:0] = cplbuff_addr_cntr[TXCPL_BUFF_ADDR_WIDTH-1:0];

endmodule




