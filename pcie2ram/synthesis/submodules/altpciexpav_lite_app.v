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


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on


module altpciexpav_lite_app

#(
     parameter              CB_P2A_AVALON_ADDR_B0 = 32'h00000000,
     parameter              CB_P2A_AVALON_ADDR_B1 = 32'h00000000,
     parameter              CB_P2A_AVALON_ADDR_B2 = 32'h00000000,
     parameter              CB_P2A_AVALON_ADDR_B3 = 32'h00000000,
     parameter              CB_P2A_AVALON_ADDR_B4 = 32'h00000000,
     parameter              CB_P2A_AVALON_ADDR_B5 = 32'h00000000,
     parameter              CB_P2A_AVALON_ADDR_B6 = 32'h00000000,

parameter bar0_64bit_mem_space = "true",
parameter bar0_io_space = "false",
parameter bar0_prefetchable = "true",
parameter bar0_size_mask =  32 ,
parameter bar1_64bit_mem_space = "false",
parameter bar1_io_space = "false",
parameter bar1_prefetchable = "false",
parameter bar1_size_mask =  4 ,
parameter bar2_64bit_mem_space = "false",
parameter bar2_io_space = "false",
parameter bar2_prefetchable = "false",
parameter bar2_size_mask =  4 ,
parameter bar3_64bit_mem_space = "false",
parameter bar3_io_space = "false",
parameter bar3_prefetchable = "false",
parameter bar3_size_mask =  4 ,
parameter bar4_64bit_mem_space = "false",
parameter bar4_io_space = "false",
parameter bar4_prefetchable = "false",
parameter bar4_size_mask =  4 ,
parameter bar5_64bit_mem_space = "false",
parameter bar5_io_space = "false",
parameter bar5_prefetchable = "false",
parameter bar5_size_mask =  4 ,
parameter bar_io_window_size = "NONE",
parameter bar_prefetchable =  0 ,
parameter expansion_base_address_register =  0,
parameter CB_RXM_DATA_WIDTH = 32,
parameter CG_RXM_IRQ_NUM = 16  ,
parameter deviceFamily = "Arria V"
)

  (


    // clock, reset inputs
    input          Clk_i,
    input          Rstn_i,

    // Rx streamming interface to the HIP
    input          RxStEmpty_i,
    output         RxStMask_o,
    input          RxStSop_i,
    input          RxStEop_i,
    input [63:0]   RxStData_i,
    input          RxStValid_i,
    output         RxStReady_o,
    input [7:0]    RxStBarDec_i,

    // Tx streaming interface to the HIP
    input         TxStReady_i,
    output        TxStSop_o,
    output        TxStEop_o,
    output [63:0] TxStData_o,
    output        TxStValid_o,
    // AvalonMM Rx Master port (32-bit)


// Avalon Rx Master interface

output                                 RxmWrite_0_o,
output [31:0]                          RxmAddress_0_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_0_o,
output [3:0]                           RxmByteEnable_0_o,
input                                  RxmWaitRequest_0_i,
output                                 RxmRead_0_o,
input  [CB_RXM_DATA_WIDTH-1:0]         RxmReadData_0_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_0_i,     // this comes from Avalon Slave to be routed to Tx completion

output                                 RxmWrite_1_o,
output [31:0]                          RxmAddress_1_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_1_o,
output [3:0]                           RxmByteEnable_1_o,
input                                  RxmWaitRequest_1_i,
output                                 RxmRead_1_o,
input  [CB_RXM_DATA_WIDTH-1:0]         RxmReadData_1_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_1_i,     // this comes from Avalon Slave to be routed to Tx completion


output                                 RxmWrite_2_o,
output [31:0]                          RxmAddress_2_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_2_o,
output [3:0]                           RxmByteEnable_2_o,
input                                  RxmWaitRequest_2_i,
output                                 RxmRead_2_o,
input [CB_RXM_DATA_WIDTH-1:0]          RxmReadData_2_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_2_i,     // this comes from Avalon Slave to be routed to Tx completion

output                                 RxmWrite_3_o,
output [31:0]                          RxmAddress_3_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_3_o,
output [3:0]                           RxmByteEnable_3_o,
input                                  RxmWaitRequest_3_i,
output                                 RxmRead_3_o,
input  [CB_RXM_DATA_WIDTH-1:0]         RxmReadData_3_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_3_i,     // this comes from Avalon Slave to be routed to Tx completion

output                                 RxmWrite_4_o,
output [31:0]                          RxmAddress_4_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_4_o,
output [3:0]                           RxmByteEnable_4_o,
input                                  RxmWaitRequest_4_i,
output                                 RxmRead_4_o,
input [CB_RXM_DATA_WIDTH-1:0]          RxmReadData_4_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_4_i,     // this comes from Avalon Slave to be routed to Tx completion

output                                 RxmWrite_5_o,
output [31:0]                          RxmAddress_5_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_5_o,
output [3:0]                           RxmByteEnable_5_o,
input                                  RxmWaitRequest_5_i,
output                                 RxmRead_5_o,
input  [CB_RXM_DATA_WIDTH-1:0]         RxmReadData_5_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_5_i,     // this comes from Avalon Slave to be routed to Tx completion


input  [CG_RXM_IRQ_NUM-1 : 0]          RxmIrq_i,



    // Config interface
    input           CfgCtlWr_i,
    input [3:0]       CfgAddr_i,
    input [31:0]      CfgCtl_i,

    // Interrupt signals
    output           AppIntSts_o,
    output reg       MsiReq_o,
    input           MsiAck_i,
    output [2:0]     MsiTc_o,
    output [4:0]     MsiNum_o


  );


  //state machine encoding
  localparam RX_IDLE              = 12'h000;
  localparam RX_RD_HEADER1        = 12'h003;
  localparam RX_LATCH_HEADER1     = 12'h005;
  localparam RX_RD_HEADER2        = 12'h009;
  localparam RX_LATCH_HEADER2     = 12'h011;
   localparam RX_CHECK_HEADER     = 12'h021;
  localparam RX_RD_DATA           = 12'h041;
  localparam RX_LATCH_DATA        = 12'h081;
  localparam RX_PENDING           = 12'h101;
  localparam RX_CPL_REQ           = 12'h201;
  localparam RX_CLEAR_BUF         = 12'h401;
  localparam RX_WAIT_EOP          = 12'h801;

  localparam RXAVL_IDLE       = 4'h0;
  localparam RXAVL_WRITE      = 4'h3;
  localparam RXAVL_READ       = 4'h5;
  localparam RXAVL_WRITE_DONE = 4'h9;

  localparam TX_IDLE          = 4'h0;
  localparam TX_SOP           = 4'h3;
  localparam TX_CPL_HDR2      = 4'h5;
  localparam TX_EOP           = 4'h9;


 wire             is_read;
 wire             is_write;
 wire             is_flush;
 wire             is_msg;
 wire             is_msg_wd;
 wire             is_msg_wod;
 wire  [3:0]      rx_fbe;
 wire  [3:0]      rx_lbe;
 wire  [9:0]     rx_dwlen;
 wire             rx_3dw_header;
 wire  [31:0]     rx_addr;
 wire             is_valid_read;
 wire             is_write_32;
 wire             addr_bit2;
 wire             is_valid_write;
 wire             is_flush_wr32;
 wire              is_flush_wr64;
wire              rx_check_header;

 reg  [63:0]       rx_header1_reg;
 reg  [63:0]       rx_header2_reg;
 reg  [7:0]        rx_bar_hit_reg;
 reg  [31:0]       rx_writedata_reg;
 reg  [11:0]        rx_state;
 reg   [11:0]       rx_nxt_state;
 reg               rx_pending_reg;

 reg  [3:0]        rxavl_state;
 reg  [3:0]        rxavl_nxt_state;

 reg [12:0]       cfg_busdev;
 reg              msi_ena;
 reg [31:0]       read_data_reg;
 reg [11:0]       normal_byte_count;
 reg [11:0]       abort_byte_count;
 reg [6:0]        lower_addr;
 wire [63:0]      tx_st_header1;
 wire [63:0]      tx_st_header2;
 wire [63:0]      tx_st_data;
 reg              cpl_data_available;

 reg [3:0]        tx_state;
 reg [3:0]        tx_nxt_state;

 wire [127:0]     cpl_header;

 reg              irq_reg;
 wire             irq_edge;
 wire [2:0]       cpl_tc;
 wire [1:0]       cpl_attr;
 wire [9:0]       dw_len;
 wire [11:0]      remain_bytes;
 wire [15:0]      cpl_req_id;
 wire [7:0]       cpl_tag;
 wire             latch_rx_header1;
 wire             latch_rx_header2;
 reg              latch_rx_header2_reg;
 wire             rx_get_header1;
 wire             adjusted_amount_data_dw;
 wire             adjusted_amount_dec_dw;
 wire             adjusted_amount_inc_dw;
reg  [10:0]      adjusted_data_dw_reg;
 wire [9:0]       adjusted_data_qw;
 reg  [9:0]       rx_qword_counter;
 wire             addr_bit2_reg;
 wire             rx_idle;
 wire             rx_get_write_data;
 wire             rx_latch_write_data;
 wire             rx_pndg;
 wire             tx_cpl_req;
 wire             clear_rxbuff;
 wire             rxavl_req;
 wire             tx_idle_st;
 wire [31:0]      pcie_addr;
wire  [227:0]                       k_bar;
reg  [227:0]                        init_k_bar;
reg   [3:0]        header_poll_counter;
wire [11:0]        rx_byte_len;
wire               rx_get_header2;
wire               rxm_wait_request;
wire  [31:0]       avl_addr;
reg   [31:0]       avl_addr_reg;
wire            wrena;
wire            rdena;
wire           rxm_read_data_valid;
reg  [31:0]    rxm_read_data;
wire  [5:0]    read_valid_vector;

wire          rxm_read_data_valid_0;
wire          rxm_wait_request_0;
wire  [31:0]  rxm_read_data_0;

wire          rxm_read_data_valid_1;
wire          rxm_wait_request_1;
wire  [31:0]  rxm_read_data_1;

wire          rxm_read_data_valid_2;
wire          rxm_wait_request_2;
wire  [31:0]  rxm_read_data_2;

wire          rxm_read_data_valid_3;
wire          rxm_wait_request_3;
wire  [31:0]  rxm_read_data_3;

wire          rxm_read_data_valid_4;
wire          rxm_wait_request_4;
wire  [31:0]  rxm_read_data_4;

wire          rxm_read_data_valid_5;
wire          rxm_wait_request_5;
wire  [31:0]  rxm_read_data_5;

reg           rx_eop_reg;

  // decode the Rx header to extract various information to support the state machine
  assign is_read       = ~rx_header1_reg[30] & (rx_header1_reg[28:26]== 3'b000) & ~rx_header1_reg[24];
  assign is_write      = rx_header1_reg[30] & (rx_header1_reg[28:24]==5'b00000);
  assign is_msg        = rx_header1_reg[29:27] == 3'b110;
  assign is_msg_wd     = rx_header1_reg[30] & is_msg;
  assign is_msg_wod    = ~rx_header1_reg[30] & is_msg;
  assign is_flush      = (is_read & rx_lbe == 4'h0 & rx_fbe == 4'h0);   /// read with no byte enable to flush
  assign rx_lbe        = rx_header1_reg[39:36];
  assign rx_fbe        = rx_header1_reg[35:32];
  assign rx_dwlen      = rx_header1_reg[9:0];
  assign rx_byte_len   = {rx_dwlen[9:0], 2'b00};
  assign rx_3dw_header = !rx_header1_reg[29];
  assign rx_addr[31:0] = rx_header1_reg[29]? RxStData_i[63:32] : RxStData_i[31:0];

  assign is_valid_read   = is_read & (rx_dwlen == 4'h1);
  assign is_write_32    = is_write & rx_3dw_header;
  assign is_flush_wr32  = is_valid_write & is_write_32 &  rx_fbe == 4'h0;
  assign is_flush_wr64   = is_valid_write & ~is_write_32 & rx_fbe == 4'h0;
  assign addr_bit2       = rx_3dw_header?   RxStData_i[2]: RxStData_i[34];
  assign is_valid_write  = is_write & (rx_dwlen == 4'h1);


assign addr_bit2_reg = rx_3dw_header? rx_header2_reg[2] : rx_header2_reg[34];


// poll counter to look for the first header
always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      header_poll_counter <= 0;
    else if(rx_idle)
      header_poll_counter <= 0;
    else if(rx_state[2])
      header_poll_counter <= header_poll_counter + 1;
  end


// Rx Control SM to the HIP ST interface

always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      rx_state <= RX_IDLE;
    else
      rx_state <= rx_nxt_state;
  end


always @*
  begin
    case(rx_state)

      RX_IDLE :
          rx_nxt_state <= RX_RD_HEADER1;

      RX_RD_HEADER1:
         rx_nxt_state <= RX_LATCH_HEADER1;

      RX_LATCH_HEADER1:
        if(RxStValid_i)
           rx_nxt_state <= RX_RD_HEADER2;
         else if(header_poll_counter == 4'hF)
           rx_nxt_state <= RX_IDLE;
         else
            rx_nxt_state <= RX_LATCH_HEADER1;

      RX_RD_HEADER2:
         rx_nxt_state <= RX_LATCH_HEADER2;

      RX_LATCH_HEADER2:
        if(RxStValid_i)
           rx_nxt_state <= RX_CHECK_HEADER;
        else
           rx_nxt_state <= RX_LATCH_HEADER2;

      RX_CHECK_HEADER:
        if(is_msg_wod | is_flush_wr32 & addr_bit2)
          rx_nxt_state <= RX_IDLE;
        else if(rx_eop_reg & (is_valid_read & ~is_flush| is_write_32 & addr_bit2 & is_valid_write & rx_fbe != 4'h0) )
          rx_nxt_state <= RX_PENDING;
        else if(is_write | is_msg_wd |is_flush_wr32 | is_flush_wr64)
          rx_nxt_state <= RX_RD_DATA;
        else if(rx_eop_reg & (!is_valid_read | is_flush) )  // not a valid read or flush
          rx_nxt_state <= RX_CPL_REQ;          // completion without data
        else
          rx_nxt_state <= RX_CHECK_HEADER;

     RX_RD_DATA:
         rx_nxt_state <= RX_LATCH_DATA;

     RX_LATCH_DATA:

       if(RxStValid_i & RxStEop_i & (is_msg_wd & rx_dwlen <= 2 & ~addr_bit2_reg| is_flush_wr32 |is_flush_wr64) )
         rx_nxt_state <= RX_IDLE;
       else if(RxStValid_i & RxStEop_i & is_valid_write)
         rx_nxt_state <= RX_PENDING;
       else if (~is_valid_write & RxStValid_i & RxStEop_i)
         rx_nxt_state <= RX_IDLE;
       else if((~is_valid_write & is_write & RxStValid_i)| (is_msg_wd & rx_dwlen > 2) |(is_msg_wd & rx_dwlen == 2 & addr_bit2_reg) )
         rx_nxt_state <= RX_CLEAR_BUF;
       else
         rx_nxt_state <= RX_LATCH_DATA;


     RX_PENDING:
         if((wrena & ~rxm_wait_request) | TxStEop_o)
           rx_nxt_state <= RX_IDLE;
          else
            rx_nxt_state <= RX_PENDING;

       RX_CPL_REQ:
         if(TxStEop_o)
           rx_nxt_state <= RX_IDLE;
         else
           rx_nxt_state <= RX_CPL_REQ;


       RX_CLEAR_BUF:
         if(rx_qword_counter == 1 | rx_qword_counter == 0)
          rx_nxt_state <= RX_WAIT_EOP;
         else
           rx_nxt_state <= RX_CLEAR_BUF;


       RX_WAIT_EOP:
         if(RxStEop_i)
          rx_nxt_state <= RX_IDLE;
         else
           rx_nxt_state <= RX_WAIT_EOP;

       default:
          rx_nxt_state <= RX_IDLE;

    endcase
  end


assign rx_idle             = ~rx_state[0];
assign rx_get_header1      = rx_state[1];
assign latch_rx_header1     =  rx_state[2] & RxStValid_i;
assign rx_get_header2       = rx_state[3];
assign latch_rx_header2     =  rx_state[4] & RxStValid_i;
assign rx_check_header      = rx_state[5];
assign rx_get_write_data    = rx_state[6];
assign rx_latch_write_data  = rx_state[7] & RxStValid_i;
assign rx_pndg              = rx_state[8];
assign tx_cpl_req           = rx_state[9];
assign clear_rxbuff         = rx_state[10];

// latch the first header QWORD
always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      rx_header1_reg <= 64'h0;
    else if(latch_rx_header1)
      rx_header1_reg <= RxStData_i[63:0];
    end

// Latch Second Header QWORD and the BAR decode (Bar Hit)
always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     begin
      rx_header2_reg <= 64'h0;
      rx_bar_hit_reg     <= 8'h0;
     end
    else if(latch_rx_header2)
     begin
      rx_header2_reg <= RxStData_i[63:0];
      rx_bar_hit_reg     <= RxStBarDec_i[7:0];
     end
    end

// Latch RX write data

 always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      rx_writedata_reg <= 32'h0;
    else if(latch_rx_header2 | rx_latch_write_data & addr_bit2_reg)
      rx_writedata_reg <= RxStData_i[63:32];
    else if(rx_latch_write_data)
      rx_writedata_reg <= RxStData_i[31:0];
    end

 // hold the eop since it might assert before the check header state

  always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      rx_eop_reg <= 1'b0;
    else if(rx_idle)
      rx_eop_reg <= 1'b0;
    else if(RxStEop_i & RxStValid_i)
      rx_eop_reg <= 1'b1;
    end

// logic to keep track the number of data word extracted from the Rx buffer

assign adjusted_amount_dec_dw = (rx_3dw_header & addr_bit2); // 3 dw header and the data is not QWORD aligned => decrement by 1 dw, otherwise no adjustment
assign adjusted_amount_inc_dw = (~rx_3dw_header & addr_bit2); // 4 dw header and the data is not QWORD aligned => increment by 1 dw, otherwise no adjustment

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     begin
       adjusted_data_dw_reg <= 11'h0;
       latch_rx_header2_reg <= 1'b0;
     end
    else
      begin
       adjusted_data_dw_reg <= rx_dwlen - adjusted_amount_dec_dw + adjusted_amount_inc_dw;
       latch_rx_header2_reg <= latch_rx_header2;
      end
  end



assign adjusted_data_qw = adjusted_data_dw_reg[10:1] +  adjusted_data_dw_reg[0]; // divided by 2 plus the remainder DW

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      rx_qword_counter <= 10'h0;
    else if(latch_rx_header2_reg)   // for fmax
      rx_qword_counter <= adjusted_data_qw;
    else if(RxStReady_o)
      rx_qword_counter <= rx_qword_counter - 1;
  end


// Assign Outputs signals
// To AvalonMM interface to send the request to the AvalonM target

// address translation (PCIe to Avl)
altpciexpav_stif_p2a_addrtrans
   p2a_addr_trans
 (    .k_bar_i(k_bar),
      .cb_p2a_avalon_addr_b0_i(CB_P2A_AVALON_ADDR_B0),
      .cb_p2a_avalon_addr_b1_i(CB_P2A_AVALON_ADDR_B1),
      .cb_p2a_avalon_addr_b2_i(CB_P2A_AVALON_ADDR_B2),
      .cb_p2a_avalon_addr_b3_i(CB_P2A_AVALON_ADDR_B3),
      .cb_p2a_avalon_addr_b4_i(CB_P2A_AVALON_ADDR_B4),
      .cb_p2a_avalon_addr_b5_i(CB_P2A_AVALON_ADDR_B5),
      .cb_p2a_avalon_addr_b6_i(CB_P2A_AVALON_ADDR_B6),
      .PCIeAddr_i(pcie_addr),
      .BarHit_i(rx_bar_hit_reg[6:0]),
      .AvlAddr_o(avl_addr)
);

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     begin
       avl_addr_reg <= 32'h0;
     end
    else
     begin
      avl_addr_reg <= avl_addr;
    end
  end


 always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      rx_pending_reg <= 1'b0;
    else
      rx_pending_reg <= rx_pndg;
  end


    assign RxmWrite_0_o = wrena & rx_bar_hit_reg[0];
    assign RxmRead_0_o = rdena & rx_bar_hit_reg[0];
    assign RxmAddress_0_o = {avl_addr_reg[31:2], 2'h0};
    assign RxmWriteData_0_o = rx_writedata_reg;

    assign RxmWrite_1_o = wrena & rx_bar_hit_reg[1];
    assign RxmRead_1_o = rdena & rx_bar_hit_reg[1];
    assign RxmAddress_1_o = {avl_addr_reg[31:2], 2'h0};
    assign RxmWriteData_1_o = rx_writedata_reg;

    assign RxmWrite_2_o = wrena & rx_bar_hit_reg[2];
    assign RxmRead_2_o = rdena & rx_bar_hit_reg[2];
    assign RxmAddress_2_o = {avl_addr_reg[31:2], 2'h0};
    assign RxmWriteData_2_o =  rx_writedata_reg;

    assign RxmWrite_3_o = wrena & rx_bar_hit_reg[3];
    assign RxmRead_3_o = rdena & rx_bar_hit_reg[3];
    assign RxmAddress_3_o = {avl_addr_reg[31:2], 2'h0};
    assign RxmWriteData_3_o = rx_writedata_reg;

    assign RxmWrite_4_o = wrena & rx_bar_hit_reg[4];
    assign RxmRead_4_o = rdena & rx_bar_hit_reg[4];
    assign RxmAddress_4_o = {avl_addr_reg[31:2], 2'h0};
    assign RxmWriteData_4_o =  rx_writedata_reg;

    assign RxmWrite_5_o = wrena & rx_bar_hit_reg[5];
    assign RxmRead_5_o = rdena & rx_bar_hit_reg[5];
    assign RxmAddress_5_o = {avl_addr_reg[31:2], 2'h0};
    assign RxmWriteData_5_o =  rx_writedata_reg;


 assign rxavl_req            = !rx_pending_reg & rx_pndg;


assign RxmByteEnable_0_o =  rx_fbe[3:0];
assign RxmByteEnable_1_o =  rx_fbe[3:0];
assign RxmByteEnable_2_o =  rx_fbe[3:0];
assign RxmByteEnable_3_o =  rx_fbe[3:0];
assign RxmByteEnable_4_o =  rx_fbe[3:0];
assign RxmByteEnable_5_o =  rx_fbe[3:0];


/// Tie off the inputs when not available

    assign rxm_read_data_valid_0 = RxmReadDataValid_0_i;
    assign rxm_wait_request_0    = RxmWaitRequest_0_i;
    assign rxm_read_data_0       = RxmReadData_0_i;


generate if (bar1_size_mask == 0)
  begin
    assign rxm_read_data_valid_1 = 1'b0;
    assign rxm_wait_request_1    = 1'b1;
    assign rxm_read_data_1       = 64'h0;
  end
else
  begin
    assign rxm_read_data_valid_1 = RxmReadDataValid_1_i;
    assign rxm_wait_request_1    = RxmWaitRequest_1_i;
    assign rxm_read_data_1       = RxmReadData_1_i;
  end
endgenerate


generate if (bar2_size_mask == 0)
  begin
    assign rxm_read_data_valid_2 = 1'b0;
    assign rxm_wait_request_2    = 1'b1;
    assign rxm_read_data_2       = 64'h0;
  end
else
  begin
    assign rxm_read_data_valid_2 = RxmReadDataValid_2_i;
    assign rxm_wait_request_2    = RxmWaitRequest_2_i;
    assign rxm_read_data_2       = RxmReadData_2_i;
  end
endgenerate


generate if (bar3_size_mask == 0)
  begin
    assign rxm_read_data_valid_3 = 1'b0;
    assign rxm_wait_request_3    = 1'b1;
    assign rxm_read_data_3       = 64'h0;
  end
else
  begin
    assign rxm_read_data_valid_3 = RxmReadDataValid_3_i;
    assign rxm_wait_request_3    = RxmWaitRequest_3_i;
    assign rxm_read_data_3       = RxmReadData_3_i;
  end
endgenerate


generate if (bar4_size_mask == 0)
  begin
    assign rxm_read_data_valid_4 = 1'b0;
    assign rxm_wait_request_4    = 1'b1;
    assign rxm_read_data_4       = 64'h0;
  end
else
  begin
    assign rxm_read_data_valid_4 = RxmReadDataValid_4_i;
    assign rxm_wait_request_4    = RxmWaitRequest_4_i;
    assign rxm_read_data_4       = RxmReadData_4_i;
  end
endgenerate

generate if (bar5_size_mask == 0)
  begin
    assign rxm_read_data_valid_5 = 1'b0;
    assign rxm_wait_request_5    = 1'b1;
    assign rxm_read_data_5       = 64'h0;
  end
else
  begin
    assign rxm_read_data_valid_5 = RxmReadDataValid_5_i;
    assign rxm_wait_request_5    = RxmWaitRequest_5_i;
    assign rxm_read_data_5       = RxmReadData_5_i;
  end
endgenerate



assign rxm_read_data_valid =  rxm_read_data_valid_0 | rxm_read_data_valid_1 | rxm_read_data_valid_2 | rxm_read_data_valid_3 |
                              rxm_read_data_valid_4 | rxm_read_data_valid_5;

assign read_valid_vector  = {rxm_read_data_valid_5, rxm_read_data_valid_4, rxm_read_data_valid_3, rxm_read_data_valid_2, rxm_read_data_valid_1, rxm_read_data_valid_0};


assign rxm_wait_request = rxm_wait_request_0 & rx_bar_hit_reg[0] | rxm_wait_request_1 & rx_bar_hit_reg[1] | rxm_wait_request_2 & rx_bar_hit_reg[2] |
                          rxm_wait_request_3 & rx_bar_hit_reg[3] | rxm_wait_request_4 & rx_bar_hit_reg[4] | rxm_wait_request_5 & rx_bar_hit_reg[5];



always @*
  begin
    case (read_valid_vector)
        6'b000001 : rxm_read_data = rxm_read_data_0[31:0];
        6'b000010 : rxm_read_data = rxm_read_data_1[31:0];
        6'b000100 : rxm_read_data = rxm_read_data_2[31:0];
        6'b001000 : rxm_read_data = rxm_read_data_3[31:0];
        6'b010000 : rxm_read_data = rxm_read_data_4[31:0];
        6'b100000 : rxm_read_data = rxm_read_data_5[31:0];
        default   : rxm_read_data = 32'h0;
  endcase
end

 assign pcie_addr         = rx_3dw_header? rx_header2_reg[31:0] : rx_header2_reg[63:32];


 // Interface to the HIP streaming interface
 assign RxStReady_o =    rx_get_header1 | rx_get_header2 | rx_get_write_data | clear_rxbuff;

 //assign RxStReady_o =  !(rx_pndg |  tx_cpl_req);  // do not accept any rx request while one ispending


/// Control logic interfacing to AvalonMM

always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      rxavl_state <= RXAVL_IDLE;
    else
      rxavl_state <= rxavl_nxt_state;
  end


always @(rxavl_state, rxavl_req, is_write, is_read, rxm_wait_request )
  begin
    case(rxavl_state)
      RXAVL_IDLE :
        if(rxavl_req & is_write)
          rxavl_nxt_state <= RXAVL_WRITE;
        else if(rxavl_req & is_read)
          rxavl_nxt_state <= RXAVL_READ;
        else
          rxavl_nxt_state <= RXAVL_IDLE;

      RXAVL_WRITE:
        if(~rxm_wait_request)
          rxavl_nxt_state <= RXAVL_WRITE_DONE;
        else
          rxavl_nxt_state <= RXAVL_WRITE;

       RXAVL_READ:
         if(~rxm_wait_request)
           rxavl_nxt_state <= RXAVL_IDLE;
          else
           rxavl_nxt_state <= RXAVL_READ;

       RXAVL_WRITE_DONE:
          rxavl_nxt_state <= RXAVL_IDLE;

       default:
          rxavl_nxt_state <= RXAVL_IDLE;

    endcase
  end



assign wrena  = rxavl_state[1];
assign rdena  = rxavl_state[2];

//// Tx response logic


 // Latching the response data

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      read_data_reg <= 32'h0;
    else if(rxm_read_data_valid)
      read_data_reg <= rxm_read_data[31:0];
    end


// Form an Tx Completion packet

assign cpl_tc = rx_header1_reg[22:20];
assign cpl_attr= rx_header1_reg[13:12];
assign dw_len = tx_cpl_req & ~is_flush? 10'h0 : 10'h1;


always @(rx_fbe)   // only first completion uses the fbe for byte count
 begin
  case(rx_fbe)
    4'b0001 : normal_byte_count = 12'h1;
    4'b0010 : normal_byte_count = 12'h1;
    4'b0100 : normal_byte_count = 12'h1;
    4'b1000 : normal_byte_count = 12'h1;
    4'b0011 : normal_byte_count = 12'h2;
    4'b0110 : normal_byte_count = 12'h2;
    4'b1100 : normal_byte_count = 12'h2;
    4'b0111 : normal_byte_count = 12'h3;
    4'b1110 : normal_byte_count = 12'h3;
    default : normal_byte_count = 12'h4;
  endcase
end


always @*  // only first completion uses the fbe for byte count
 begin
  case({rx_fbe, rx_lbe})
    8'b1000_0001 : abort_byte_count = rx_byte_len - 6;
    8'b1000_0011 : abort_byte_count = rx_byte_len - 5;
    8'b1000_1111 : abort_byte_count = rx_byte_len - 3;

    8'b1100_0001 : abort_byte_count = rx_byte_len - 5;
    8'b1100_0011 : abort_byte_count = rx_byte_len - 4;
    8'b1100_1111 : abort_byte_count = rx_byte_len - 2;

    8'b1111_0001 : abort_byte_count = rx_byte_len - 3;
    8'b1111_0011 : abort_byte_count = rx_byte_len - 2;
    default : abort_byte_count = rx_byte_len;
  endcase
end

assign remain_bytes = is_flush? 12'h1 : tx_cpl_req? abort_byte_count: normal_byte_count;
assign cpl_req_id   = rx_header1_reg[63:48];
assign cpl_tag      = rx_header1_reg[47:40];

// calculate the 7 bit lower address of the first enable byte
// based on the first byte enable

always @(rx_fbe, is_flush, rx_addr)
 begin
  casex({rx_fbe, is_flush})
    5'bxxx10 : lower_addr = {rx_addr[6:2], 2'b00};
    5'bxx100 : lower_addr = {rx_addr[6:2], 2'b01};
    5'bx1000 : lower_addr = {rx_addr[6:2], 2'b10};
    5'b10000 : lower_addr = {rx_addr[6:2], 2'b11};
    5'bxxxx1 : lower_addr = {rx_addr[6:2], 2'b00};
    default:  lower_addr = 7'b0000000;
  endcase
end


///////////// Synch and Demux the BusDev from configuration signals
    //Synchronise to pld side

    //Configuration Demux logic
     always @(posedge Clk_i or negedge Rstn_i)
     begin
        if (Rstn_i == 0)
          begin
            cfg_busdev  <= 13'h0;
            msi_ena     <= 1'b0;
          end
        else
          begin
            cfg_busdev          <= (CfgAddr_i[3:0]==4'hF) ? CfgCtl_i[12 : 0]  : cfg_busdev;
            msi_ena             <= (CfgAddr_i[3:0]==4'hD) ? CfgCtl_i[0]   :  msi_ena;
          end
     end

assign cpl_header = {
                          1'b0, is_valid_read, 6'b001010, 1'b0, cpl_tc, 4'h0, 2'h0, cpl_attr, 2'b00, dw_len,
                                                           cfg_busdev,3'b000, ~is_valid_read ,3'b000, remain_bytes,
                                                                       cpl_req_id, cpl_tag, 1'b0,lower_addr,
                                                                                         read_data_reg[31:0]
                     };


assign tx_st_header1[63:0] = {cpl_header[95:64], cpl_header[127:96]};
assign tx_st_header2[63:0] = {cpl_header[31:0], cpl_header[63:32]};
assign tx_st_data[63:0]    = {read_data_reg[31:0], read_data_reg[31:0]};

 always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      cpl_data_available <= 1'b0;
    else if(rxm_read_data_valid)
      cpl_data_available <= 1'b1;
    else if(TxStEop_o)
     cpl_data_available <= 1'b0;
  end

/// Control logic interfacing to Tx Streaming

always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      tx_state <= TX_IDLE;
    else
      tx_state <= tx_nxt_state;
  end


always @(tx_state, cpl_data_available, tx_cpl_req, TxStReady_i, addr_bit2_reg,
         is_valid_read)
  begin
    case(tx_state)
      TX_IDLE :
        if( (cpl_data_available | tx_cpl_req)& TxStReady_i)
          tx_nxt_state <= TX_SOP;
        else
          tx_nxt_state <= TX_IDLE;

      TX_SOP:
        if(addr_bit2_reg | ~is_valid_read)
          tx_nxt_state <= TX_EOP;
        else
          tx_nxt_state <= TX_CPL_HDR2;

       TX_CPL_HDR2:
         tx_nxt_state <= TX_EOP;

       TX_EOP:
         tx_nxt_state <= TX_IDLE;

       default:
          tx_nxt_state <= TX_IDLE;

    endcase
 end
 assign tx_idle_st = !tx_state[0];
 assign TxStSop_o  =  tx_state[1];
 assign TxStEop_o  =  tx_state[3];
 assign TxStData_o = TxStSop_o? tx_st_header1[63:0] : (TxStEop_o & !addr_bit2_reg & ~tx_cpl_req)? tx_st_data[63:0] :  tx_st_header2[63:0];
 assign TxStValid_o = !tx_idle_st;
 assign RxStMask_o  = 1'b0;

// INTx Interrupt logic

assign AppIntSts_o = |RxmIrq_i;

 /// generate the MSI based on the
    always @(posedge Clk_i or negedge Rstn_i)
      begin
        if (Rstn_i == 1'b0)
          irq_reg <= 1'b0;
        else
           irq_reg<= RxmIrq_i;
      end

  assign irq_edge = ~irq_reg & RxmIrq_i;

   always @(posedge Clk_i or negedge Rstn_i)
      begin
        if (Rstn_i == 1'b0)
          MsiReq_o <= 1'b0;
        else if(irq_edge & msi_ena)
          MsiReq_o <= 1'b1;
        else if(MsiAck_i)
          MsiReq_o <= 1'b0;
      end


      assign MsiTc_o = 3'h0;
      assign MsiNum_o = 5'h0;


/// Parameters conversion to signals
initial begin

        init_k_bar[0:0] = (bar0_io_space == "true" ? 1'b1 : 1'b0);
        init_k_bar[2:1] = (bar0_64bit_mem_space == "true" ? 2'b10 : 2'b00);
        init_k_bar[3:3] = (bar0_prefetchable == "true" ? 1'b1 : 1'b0);
        if (bar0_64bit_mem_space == "true")
        begin
                init_k_bar[63:4] = 60'hffff_ffff_ffff_fff << (bar0_size_mask - 4);
        end
        else begin
                init_k_bar[31:4] = 28'hffff_fff << (bar0_size_mask - 4);
                init_k_bar[32:32] = (bar1_io_space == "true" ? 1'b1 : 1'b0);
                init_k_bar[34:33] = (bar1_64bit_mem_space == "true" ? 2'b10 : 2'b00);
                init_k_bar[35:35] = (bar1_prefetchable == "true" ? 1'b1 : 1'b0);
                init_k_bar[63:36] = 28'hffff_fff << (bar1_size_mask - 4);
        end
        init_k_bar[64:64] = (bar2_io_space == "true" ? 1'b1 : 1'b0);
        init_k_bar[66:65] = (bar2_64bit_mem_space == "true" ? 2'b10 : 2'b00);
        init_k_bar[67:67] = (bar2_prefetchable == "true" ? 1'b1 : 1'b0);
        if (bar2_64bit_mem_space == "true")
        begin
                init_k_bar[127:68] = 60'hffff_ffff_ffff_fff << (bar2_size_mask - 4);
        end
        else begin
                init_k_bar[95:68] = 28'hffff_fff << (bar2_size_mask - 4);
                init_k_bar[96:96] = (bar3_io_space == "true" ? 1'b1 : 1'b0);
                init_k_bar[98:97] = (bar3_64bit_mem_space == "true" ? 2'b10 : 2'b00);
                init_k_bar[99:99] = (bar3_prefetchable == "true" ? 1'b1 : 1'b0);
                init_k_bar[127:100] = 28'hffff_fff << (bar3_size_mask - 4);
        end
        init_k_bar[128:128] = (bar4_io_space == "true" ? 1'b1 : 1'b0);
        init_k_bar[130:129] = (bar4_64bit_mem_space == "true" ? 2'b10 : 2'b00);
        init_k_bar[131:131] = (bar4_prefetchable == "true" ? 1'b1 : 1'b0);
        if (bar4_64bit_mem_space == "true")
        begin
                init_k_bar[191:132] = 60'hffff_ffff_ffff_fff << (bar4_size_mask - 4);
        end
        else begin
                init_k_bar[159:132] = 28'hffff_fff << (bar4_size_mask - 4);
                init_k_bar[160:160] = (bar5_io_space == "true" ? 1'b1 : 1'b0);
                init_k_bar[162:161] = (bar5_64bit_mem_space == "true" ? 2'b10 : 2'b00);
                init_k_bar[163:163] = (bar5_prefetchable == "true" ? 1'b1 : 1'b0);
                init_k_bar[191:164] = 28'hffff_fff << (bar5_size_mask - 4);
        end
        if (expansion_base_address_register > 0)
                init_k_bar[223:192] = 32'hffff_ffff << expansion_base_address_register;
        else
                init_k_bar[223:192] = expansion_base_address_register;
        init_k_bar[225:224] = (
                (bar_io_window_size == "NONE" ? 2'b00 : 2'b00) |
                (bar_io_window_size == "16BIT" ? 2'b01 : 2'b00) |
                (bar_io_window_size == "32BIT" ? 2'b10 : 2'b00) |
                 2'b00);
        init_k_bar[227:226] = bar_prefetchable;

end


assign k_bar =  init_k_bar;



endmodule
