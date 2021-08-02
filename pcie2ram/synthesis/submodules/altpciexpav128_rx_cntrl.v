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
module altpciexpav128_rx_cntrl

# ( 
     parameter              CB_PCIE_MODE           = 0,
     parameter              CB_PCIE_RX_LITE        = 0,      
     parameter              CB_RXM_DATA_WIDTH      = 128,
     parameter              port_type_hwtcl        = "Native endpoint",
      parameter             AVALON_ADDR_WIDTH = 32
    ) 
  
  ( input                     Clk_i,
    input                     Rstn_i,
    
    // Rx port interface to PCI Exp core
    output   reg              RxStReady_o,
    output                    RxStMask_o,
    input   [127:0]           RxStData_i,
    input   [64:0]            RxStParity_i,
    input   [15:0]            RxStBe_i,
    input   [1:0]             RxStEmpty_i,
    input   [7:0]             RxStErr_i,
    input                     RxStSop_i,
    input                     RxStEop_i,
    input                     RxStValid_i,
    input   [7:0]             RxStBarDec1_i,
    input   [7:0]             RxStBarDec2_i,
    
   /// RX Master Read Write Interface
   
   output                                 RxmWrite_0_o,
   output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_0_o,
   output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_0_o,
   output [(CB_RXM_DATA_WIDTH/8)-1:0]     RxmByteEnable_0_o,
   output [6:0]                           RxmBurstCount_0_o, 
   input                                  RxmWaitRequest_0_i,
   output                                 RxmRead_0_o,
   
   output                                 RxmWrite_1_o,
   output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_1_o,
   output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_1_o,
   output [(CB_RXM_DATA_WIDTH/8)-1:0]     RxmByteEnable_1_o,
   output [6:0]                           RxmBurstCount_1_o, 
   input                                  RxmWaitRequest_1_i,
   output                                 RxmRead_1_o,
   
   output                                 RxmWrite_2_o,
   output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_2_o,
   output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_2_o,
   output [(CB_RXM_DATA_WIDTH/8)-1:0]     RxmByteEnable_2_o,
   output [6:0]                           RxmBurstCount_2_o, 
   input                                  RxmWaitRequest_2_i,
   output                                 RxmRead_2_o,
   
   output                                 RxmWrite_3_o,
   output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_3_o,
   output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_3_o,
   output [(CB_RXM_DATA_WIDTH/8)-1:0]     RxmByteEnable_3_o,
   output [6:0]                           RxmBurstCount_3_o, 
   input                                  RxmWaitRequest_3_i,
   output                                 RxmRead_3_o,
   
   output                                 RxmWrite_4_o,
   output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_4_o,
   output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_4_o,
   output [(CB_RXM_DATA_WIDTH/8)-1:0]     RxmByteEnable_4_o,
   output [6:0]                           RxmBurstCount_4_o, 
   input                                  RxmWaitRequest_4_i,
   output                                 RxmRead_4_o,
   
   output                                 RxmWrite_5_o,
   output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_5_o,
   output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_5_o,
   output [(CB_RXM_DATA_WIDTH/8)-1:0]     RxmByteEnable_5_o,
   output [6:0]                           RxmBurstCount_5_o, 
   input                                  RxmWaitRequest_5_i,
   output                                 RxmRead_5_o,
   
   output  [130:0]                        RxRpFifoWrData_o,      
   output                                 RxRpFifoWrReq_o,     
    
    // Pending Read FIFO interface
    input  [3:0]              PndngRdFifoUsedW_i,
    input                     PndngRdFifoEmpty_i,
    output                    PndgRdFifoWrReq_o,
    output [56:0]             PndgRdHeader_o,
    
    input                     RxRdInProgress_i,
    

   // Completion data dual port ram interface
    output  [8:0]              CplRamWrAddr_o,
    output  [129:0]            CplRamWrDat_o,
    output                    CplRamWrEna_o,
    output  reg               CplReq_o,
    output  reg [5:0]         CplDesc_o,
    
    // Read respose module interface
    
    // Tx Completion interface
    input                      TxCpl_i,
    input  [4:0]               TxCplLen_i, // 128-bit lines
    input                      TxRespIdle_i,
    
      // cfg signals
    input  [31:0]               DevCsr_i,   
        /// paramter signals
    input  [31:0]              cb_p2a_avalon_addr_b0_i,
    input  [31:0]              cb_p2a_avalon_addr_b1_i,
    input  [31:0]              cb_p2a_avalon_addr_b2_i,
    input  [31:0]              cb_p2a_avalon_addr_b3_i,
    input  [31:0]              cb_p2a_avalon_addr_b4_i,
    input  [31:0]              cb_p2a_avalon_addr_b5_i,
    input  [31:0]              cb_p2a_avalon_addr_b6_i,
    input  [223:0]             k_bar_i
    
  );
  
  //state machine encoding
  localparam RX_IDLE_0                    = 12'h000;  
  localparam RX_RD_HEADER_0               = 12'h003; 
  localparam RX_CHECK_HEADER_0            = 12'h005;
  localparam RX_WRENA_0                   = 12'h009;
  localparam RX_WRWAIT_0                  = 12'h011;
  localparam RX_STORE_RD_0                = 12'h021;
  localparam RX_RDENA_0                   = 12'h041;
  localparam RX_CHECK_TXCPLSIZE_0         = 12'h081;
  localparam RX_CPLENA_0                  = 12'h101;
  localparam RX_PIPE_0                    = 12'h201;  
  localparam RX_MSG_DUMP_0                = 12'h401;
  localparam RX_RP_STREAM_0                 = 12'h801;
  
  localparam RX_IDLE_1                    = 11'h000;  
  localparam RX_RD_HEADER_1               = 11'h003; 
  localparam RX_CHECK_HEADER_1            = 11'h005;
  localparam RX_WRENA_1                   = 11'h009;
  localparam RX_WRWAIT_1                  = 11'h011;
  localparam RX_STORE_RD_1                = 11'h021;
  localparam RX_RDENA_1                   = 11'h041;
  localparam RX_CHECK_TXCPLSIZE_1         = 11'h081;
  localparam RX_CPLENA_1                  = 11'h101;
  localparam RX_PIPE_1                    = 11'h201;  
  localparam RX_MSG_DUMP_1                = 11'h401;


wire              input_fifo_wrreq;
wire   [154:0]    input_fifo_datain;
reg               input_fifo_wrreq_reg;
reg    [154:0]    nput_fifo_datain_reg;
wire   [5:0]      input_fifo_wrusedw;
wire              input_fifo_rdreq;
wire              input_fifo_rdempty;
wire   [154:0]    input_fifo_dataout;
wire   [154:0]    fifo_mux_out;
reg    [154:0]    rx_tlp_reg;
reg               input_fifo_rdreq_reg;
wire               rx_eop_reg2;
wire    [15:0]     rx_tlp_be_reg;
wire   [15:0]     input_fifo_be_out;
reg               rxsm_rd_header_0_reg;
reg    [127:0]    rx_header0_reg;
reg    [6:0]      bar_dec0_reg; 
wire              rxsm_wrena_0;     
wire              rxsm_cplena_0;
wire              header1_sel;
wire    [127:0]   rx_header_reg;
wire    [6:0]     bar_hit_reg;
wire    [6:0]     fabric_bar_hit_reg;
wire              tlp_3dw_header;
wire              tlp_4dw_header;
wire   [3:0]      rx_address_lsb;
wire   [63:0]     rx_addr;
wire   [7:0]      rdreq_tag;
wire              is_rd; 
wire   [15:0]     requestor_id; 
wire   [3:0]      rx_fbe; 
wire   [3:0]      rx_lbe; 
wire              is_flush;
wire              is_uns_rd_size;
wire   [2:0]      rx_tc;
wire   [1:0]      rx_attr;
wire   [10:0]     rx_dwlen;
wire   [10:0]     rx_dwlen_fifo;
wire   [4:0]      cpl_tag;
wire   [11:0]     cpl_bytecount;
wire              is_cpl_wd; 
wire              rx_only = 1'b0;
wire              last_cpl;
reg   [10:0]      rx_dwlen_reg;
reg   [127:0]     rx_data_reg;
reg   [(CB_RXM_DATA_WIDTH/8)-1:0]      rx_wr_be_reg;   
reg   [(CB_RXM_DATA_WIDTH/8)-1:0]      rx_rd_be_reg;
wire  [(CB_RXM_DATA_WIDTH/8)-1:0]      rx_be;
wire              first_data_phase;
wire              rx_sop_fifo;
wire  [3:0]       rx_address_lsb_fifo;
reg   [9:0]       rx_dw_count_0;
wire  [9:0]       rx_dw_count;
reg   [15:0]      tail_mask;
reg   [11:0]       rx_state_0; 
reg   [11:0]       rx_nxt_state_0;
reg  [7:0]       rx_modlen_qdword;    
reg  [7:0]       rx_modlen_qdword_reg_0;   
wire  [7:0]       rx_modlen_qdword_reg;          
reg  [7:0]       txcpl_buffer_size;
wire              cpl_buff_ok;
reg   [63:0]      avl_addr_reg;
wire  [31:0]      avl_translated_addr;
wire  [63:0]      avl_addr;
wire[3:0]         zeros_4;   assign zeros_4  = 4'h0; 
wire[7:0]         zeros_8;   assign zeros_8  = 8'h0; 
reg               pndgrd_fifo_ok_reg;
wire              rx_eop_fifo;
wire              is_wr_fifo; 
wire              is_cpl_wd_fifo;    
wire              is_cpl_fifo;
wire              is_rd_fifo;
wire              is_flush_fifo;
wire              is_uns_rd_size_fifo;
wire              is_uns_wr_size_fifo;
wire              is_msg_fifo;
wire              is_msg_wd_fifo;            
wire              is_wr_hdrreg_0;
wire              is_cpl_wd_reg_0;
wire              rxsm_idle_0;
wire              is_rd_hdrreg_0;
wire              rxsm_rdena_0;      
wire              store_rd;
wire              rxsm_store_rd_0;
reg    [5:0]     cpl_add_cntr_previous[15:0];         
reg    [5:0]     cpl_add_cntr;           
wire             rxsm_chk_hdr_0;
wire             rxsm_rd_header_0;
wire             rxsm_wrwait_0;
wire             rxsm_msg_dump_0;
wire             rxsm_pipe_0;  
reg              rxsm_pipe_0_reg;
wire             first_write_state;  
wire             last_write_state; 
wire  [3:0]      rx_fbe_fifo;
wire  [3:0]      rx_lbe_fifo;
reg   [154:0]    input_fifo_datain_reg;
wire  [5:0]      bar_hit;
reg   [5:0]      bar_dec_reg;
wire             is_read_bar_changed;
reg   [5:0]      previous_bar_read;
wire             rxm_wait_req;
reg              rxm_wait_req_reg;
wire             rxm_wait_req_fall;
wire             rxm_wait_rise;
wire             rxm_data_reg_clk_ena;
wire   [5:0]     rx_modlen_sel;
wire             fifo_over_rd;
reg              fifo_over_rd_reg;
reg    [154:0]   fifo_over_rd_data_reg;
reg              temp_data_reg_sel_sreg;
wire             over_rd_sreg;
wire             fabric_transmit;
wire             wr_1dw_fbe_eq_0_fifo;
wire             is_msg_wod_fifo;
wire             tx_accumulator_dump;
reg   [7:0]      txcpl_buffer_accumulator;
reg  [15:0]      rx_st_be;             
wire  [3:0]      rx_st_fbe;
wire             is_rx_lite_core;
reg   [31:0]     rx_wr_data_reg;      
wire             rxsm_rp_stream;
wire             fabric_write;              
wire             fabric_read;               
wire  [AVALON_ADDR_WIDTH-1:0]     fabric_address;          
wire  [127:0]    fabric_write_data;     
wire  [15:0]     fabric_write_be;      
wire  [6:0]      fabric_burst_count;   
wire             fabric_wait_req;      
wire             tlp_4dw_header_fifo;


generate if(CB_PCIE_RX_LITE == 1)
 assign is_rx_lite_core = 1'b1;
else
 assign is_rx_lite_core = 1'b0;
endgenerate  


// derive the Avalon Byte Enable

assign  rx_st_fbe = RxStData_i[35:32];       

always @ *
  begin
  	case ({RxStEmpty_i[0], RxStSop_i})
  		2'b01   : rx_st_be = {rx_st_fbe, 8'h00, 4'h0};
  		2'b10   : rx_st_be = {8'h00, RxStBe_i[7:0]};
  		default : rx_st_be = RxStBe_i;
   endcase
  end
  
  
  /// Rx Input FIFO to hold Rx Streaming data
  /// This is needed since there is a 3 data phases latency when throtleing the Rx St interface
  //  This is also used for clock domain crossing purpuse (PCI-Avalon Clock)        
  
 
  assign fabric_transmit =  rxsm_wrena_0 & ~rxm_wait_req;
  assign input_fifo_wrreq  = RxStValid_i;
  assign input_fifo_datain = {RxStEmpty_i,RxStBarDec1_i[7:0],RxStEop_i,RxStSop_i,rx_st_be[15:0],RxStData_i[127:0]};    
  
always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
     begin
      input_fifo_wrreq_reg <= 0;
      input_fifo_datain_reg <= 0;
      input_fifo_rdreq_reg <= 1'b0;
       RxStReady_o <= 0;             
       rxsm_rd_header_0_reg <= 1'b0;
       fifo_over_rd_reg <= 1'b0;
    end
    else
      begin
      input_fifo_wrreq_reg <= input_fifo_wrreq;
      input_fifo_datain_reg <= input_fifo_datain;
      RxStReady_o <= (input_fifo_wrusedw <= 56);
      input_fifo_rdreq_reg <= input_fifo_rdreq; 
       rxsm_rd_header_0_reg <= rxsm_rd_header_0; 
        fifo_over_rd_reg <= fifo_over_rd;
      end
  end
  
 
 // Instantiation of the input FIFO
 // This fifo holds the Rx data stream comming out of the HIP
 
	scfifo	# (
	             .add_ram_output_register("ON"),
		     .intended_device_family("Stratix IV"),
		     .lpm_numwords(64),
		     .lpm_showahead("OFF"),
		     .lpm_type("scfifo"),
		     .lpm_width(155),
		     .lpm_widthu(6),
		     .overflow_checking("ON"),
		     .underflow_checking("ON"),
		     .use_eab("ON")
		  ) 
	          
       rx_input_fifo (
                     .rdreq (input_fifo_rdreq),
                     .clock (Clk_i),
                     .wrreq (input_fifo_wrreq_reg),
                     .data (input_fifo_datain_reg),
                     .usedw (input_fifo_wrusedw),
                     .empty (input_fifo_rdempty),
                     .q (input_fifo_dataout),
                     .full (),
                     .aclr (~Rstn_i),
                     .almost_empty (),
                     .almost_full (),
                     .sclr ()
);
                                   
                                   

/// Pipe-line stage 1
always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      begin
        rx_tlp_reg[154:0] <= 154'h0;
      end
      //else if(input_fifo_rdreq_reg & ~fifo_over_rd_reg)
        else if(fabric_transmit | rxsm_pipe_0 | rxsm_chk_hdr_0 | rxsm_cplena_0)
        begin
          rx_tlp_reg[154:0] <= fifo_mux_out;
        end
  end

// register to hold the data from the input fifo when the fifo is read while
// in wr_ena and wait is asserted due the the fact that rxm_wait is registered
// before feeding rdreq signal

always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      begin
        fifo_over_rd_data_reg[154:0] <= 154'h0;
      end
      else if(((rxsm_wrena_0 & ~input_fifo_rdempty & ~rx_eop_fifo & ~rxm_wait_req_reg) & ~fifo_over_rd_reg) | rxsm_pipe_0_reg) // save at every fifo read but not the overead data. Also save at pre-read (before write state)
        begin
          fifo_over_rd_data_reg[154:0] <= input_fifo_dataout;
        end
  end


always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
        temp_data_reg_sel_sreg <= 1'b0;
      else if(fifo_over_rd)
        temp_data_reg_sel_sreg <= 1'b1;
      else if (rxsm_wrwait_0 | rxsm_idle_0)
        temp_data_reg_sel_sreg <= 1'b0;
  end

assign over_rd_sreg = temp_data_reg_sel_sreg;

assign first_write_state = rxsm_pipe_0_reg & rxsm_wrena_0;      
assign last_write_state =  rxsm_wrena_0 & ((rx_dw_count_0 <= 4 | is_rx_lite_core) & !rxm_wait_req ) ;
assign fifo_mux_out = temp_data_reg_sel_sreg? fifo_over_rd_data_reg : input_fifo_dataout;
assign rxm_wait_rise = rxm_wait_req & ~rxm_wait_req_reg;
assign rxm_wait_req_fall = ~rxm_wait_req & rxm_wait_req_reg;
assign fifo_over_rd = (rxsm_wrena_0 & rxm_wait_rise & ~rx_eop_fifo) | (first_write_state & rxm_wait_req);
  

  
  assign rx_eop_reg2 = rx_tlp_reg[145];         
  assign rx_tlp_be_reg[15:0] = rx_tlp_reg[143:128]; 
  assign input_fifo_be_out[15:0] = fifo_mux_out[143:128];

                     
  
  
/// Storing the separate headers register for each state machine
always @(posedge Clk_i or negedge Rstn_i)  
  begin
    if(~Rstn_i)
      begin
        rx_header0_reg <= 128'h0;
      end
    else if(rxsm_rd_header_0_reg)
      begin
        rx_header0_reg <= input_fifo_dataout[127:0];
      end
  end


generate if (port_type_hwtcl != "Native endpoint") // Root Port

always @(posedge Clk_i or negedge Rstn_i)  
  begin
    if(~Rstn_i)
      begin
        bar_dec0_reg   <= 7'h0000001;
      end
    else if(rxsm_rd_header_0_reg)
      begin
        bar_dec0_reg   <= 7'h0000001;
      end
  end
else   // End point
  always @(posedge Clk_i or negedge Rstn_i)  
  begin
    if(~Rstn_i)
      begin
        bar_dec0_reg   <= 7'h0;
      end
    else if(rxsm_rd_header_0_reg)
      begin
        bar_dec0_reg   <= input_fifo_dataout[152:146];
      end
  end
endgenerate


// The mux to select header0 or header1 for the data re-alignment

assign rx_header_reg = rx_header0_reg;

generate if (port_type_hwtcl != "Native endpoint")
    begin
  	  assign bar_hit_reg   = 7'h01;
    end
else
    begin
      assign bar_hit_reg   =  bar_dec0_reg;
    end
endgenerate

/// Decode TLP header
assign tlp_3dw_header = ~rx_header_reg[29];  
assign first_data_phase = rx_tlp_reg[144];
assign tlp_4dw_header = rx_header_reg[29];              
assign rx_address_lsb[3:2] =  tlp_4dw_header? rx_header_reg[99:98] : rx_header_reg[67:66];
assign rx_address_lsb[1:0] = 2'b00;

assign rx_addr[63:0] = tlp_4dw_header? {rx_header_reg[95:64], rx_header_reg[127:96]} : {32'h0, rx_header_reg[95:64]};
assign rdreq_tag     = rx_header_reg[47:40];
assign is_rd =  ~rx_header_reg[30] & (rx_header_reg[28:26]== 3'b000) & ~rx_header_reg[24];
assign requestor_id  = rx_header_reg[63:48];
assign rx_fbe = rx_header_reg[35:32];
assign rx_lbe = rx_header_reg[39:36];
assign is_flush = (is_rd & rx_lbe == 4'h0 & rx_fbe == 4'h0);   /// read with no byte enable to flush
assign rx_tc        = rx_header_reg[22:20];
assign rx_attr        = rx_header_reg[13:12];
assign rx_dwlen = rx_header_reg[9:0];
assign cpl_tag  = rx_header_reg[76:72];
assign cpl_bytecount = rx_header_reg[43:32];
assign is_cpl_wd        = rx_header_reg[30] & (rx_header_reg[28:24]==5'b01010) & ~rx_only;
assign last_cpl = ((cpl_bytecount[11:2] == rx_dwlen ) | (cpl_bytecount <= 8)) & is_cpl_wd;     
assign rx_eop_fifo = fifo_mux_out[145];
assign is_wr_fifo = fifo_mux_out[30] & (fifo_mux_out[28:24]==5'b00000);  
assign is_rd_fifo =  ~fifo_mux_out[30] & (fifo_mux_out[28:26]== 3'b000) & ~fifo_mux_out[24];   
assign rx_fbe_fifo = fifo_mux_out[35:32];
assign rx_lbe_fifo = fifo_mux_out[39:36];
assign wr_1dw_fbe_eq_0_fifo = is_wr_fifo & rx_dwlen_fifo == 1 & rx_fbe_fifo == 4'h0;
assign is_flush_fifo = (is_rd_fifo & rx_lbe_fifo == 4'h0 & rx_fbe_fifo == 4'h0);       
 assign rx_dwlen_fifo = fifo_mux_out[9:0];

generate if(CB_PCIE_RX_LITE == 0)
 begin
     assign is_uns_rd_size_fifo =  (rx_dwlen_fifo == 0 | rx_dwlen_fifo > 128) & is_rd_fifo;
     assign is_uns_wr_size_fifo =  1'b0; 
     assign is_uns_rd_size =  (rx_dwlen > 128 | rx_dwlen == 0) & is_rd;
     assign fabric_wait_req = RxmWaitRequest_0_i & fabric_bar_hit_reg[0] | RxmWaitRequest_1_i &  fabric_bar_hit_reg[1] | RxmWaitRequest_2_i &  fabric_bar_hit_reg[2]| RxmWaitRequest_3_i &  fabric_bar_hit_reg[3] | RxmWaitRequest_4_i & fabric_bar_hit_reg[4] |
                              RxmWaitRequest_5_i &  fabric_bar_hit_reg[5];
 end
else
  begin
  	  assign is_uns_rd_size_fifo =  (rx_dwlen_fifo == 0 | rx_dwlen_fifo > 1) & is_rd_fifo;
  	  assign is_uns_wr_size_fifo =  rx_dwlen_fifo > 1  & is_wr_fifo; 
  	  assign is_uns_rd_size =  (rx_dwlen > 1 | rx_dwlen == 0) & is_rd;
  	  assign rxm_wait_req = RxmWaitRequest_0_i & bar_hit_reg[0] | RxmWaitRequest_1_i &  bar_hit_reg[1] | RxmWaitRequest_2_i &  bar_hit_reg[2]| RxmWaitRequest_3_i &  bar_hit_reg[3] | RxmWaitRequest_4_i & bar_hit_reg[4] |
                          RxmWaitRequest_5_i &  bar_hit_reg[5];
  end
endgenerate

assign is_msg_fifo        = fifo_mux_out[29:27] == 3'b110;
assign is_msg_wod_fifo    = ~fifo_mux_out[30] & is_msg_fifo;
assign is_msg_wd_fifo     = fifo_mux_out[30] & is_msg_fifo;    
assign rx_sop_fifo        = fifo_mux_out[144];
assign is_cpl_wd_fifo     = fifo_mux_out[30] & (fifo_mux_out[28:24]==5'b01010) & ~rx_only;    
assign is_cpl_fifo         = (fifo_mux_out[28:24]==5'b01010);
wire [4:0] cpl_tag_fifo;
assign cpl_tag_fifo        = fifo_mux_out[76:72];  
assign tlp_4dw_header_fifo = fifo_mux_out[29];    
assign rx_address_lsb_fifo[3:2] =  tlp_4dw_header_fifo? fifo_mux_out[99:98] : fifo_mux_out[67:66];  
assign rx_address_lsb_fifo[1:0] =  2'b00;      
assign is_wr_hdrreg_0 = rx_header0_reg[30] & (rx_header0_reg[28:24]==5'b00000);       
assign is_cpl_wd_reg_0        = rx_header0_reg[30] & (rx_header0_reg[28:24]==5'b01010) & ~rx_only;
assign is_rd_hdrreg_0 =  ~rx_header0_reg[30] & (rx_header0_reg[28:26]== 3'b000) & ~rx_header0_reg[24];   

         

assign rxm_data_reg_clk_ena = (~rxm_wait_req & (rxsm_wrena_0 )) | rxsm_pipe_0  | rxsm_cplena_0;

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     begin
      rx_dwlen_reg <= 11'h0;
      rxm_wait_req_reg <= 1'b1;
      rxsm_pipe_0_reg  <= 1'b0;
     end
    else
     begin
      rx_dwlen_reg <= rx_dwlen;
      rxm_wait_req_reg <= rxm_wait_req;
      rxsm_pipe_0_reg <= rxsm_pipe_0;
     end
  end

// re-aligned rx data register going out to the fabric


 always @(posedge Clk_i) 
   begin
    if (rxm_data_reg_clk_ena)
     begin
       if (tlp_3dw_header)     // 3DW header
           case (rx_address_lsb)
               4'h0: rx_data_reg <= {fifo_mux_out[127:96], fifo_mux_out[95:64], fifo_mux_out[63:32], fifo_mux_out[31:0]}; // start addr is on 128-bit addr boundary
               4'h4: rx_data_reg <= {fifo_mux_out[63:32], fifo_mux_out[31:0], rx_tlp_reg[127:96], rx_tlp_reg[95:64]};          // start addr is 1DW offset from 128-bit addr boundary  (first QW is saved from desc phase, and appended to next QW))
               4'h8: rx_data_reg <= {fifo_mux_out[63:32], fifo_mux_out[31:0], rx_tlp_reg[127:96], rx_tlp_reg[95:64]};          // first QW is shifted left by a QW
               4'hC: rx_data_reg <= {rx_tlp_reg[127:96], rx_tlp_reg[95:64], rx_tlp_reg[63:32], rx_tlp_reg[31:0]};  // start addr is 1DW + 1QW offset from 128-bit addr boundary  (first QW is saved from desc phase, and placed in high QW of next phase.  all other dataphases are delayed 1 clk.)
           endcase
       else
           // for 4DW header pkts, only QW alignment adjustment is required
           case (rx_address_lsb)
               4'h0: rx_data_reg <= {fifo_mux_out[127:96], fifo_mux_out[95:64], fifo_mux_out[63:32], fifo_mux_out[31:0]}; 
               4'h4: rx_data_reg <= {fifo_mux_out[127:96], fifo_mux_out[95:64], fifo_mux_out[63:32], fifo_mux_out[31:0]};        
               4'h8: rx_data_reg <= {fifo_mux_out[63:32], fifo_mux_out[31:0], rx_tlp_reg[127:96], rx_tlp_reg[95:64]};        
               4'hC: rx_data_reg <= {fifo_mux_out[63:32], fifo_mux_out[31:0], rx_tlp_reg[127:96], rx_tlp_reg[95:64]}; 
           endcase
      
     end
  end

generate if(CB_PCIE_RX_LITE == 1)
  begin
  	   always @(posedge Clk_i)                                                                                                                                                                                                                                                                           
  	     begin                                                                                                                                                                                                                                                                                           
  	      if (rxm_data_reg_clk_ena)                                                                                                                                                                                                                                                                      
  	       begin                                                                                                                                                                                                                                                                                         
  	         if (tlp_3dw_header)     // 3DW header                                                                                                                                                                                                                                                       
  	             case (rx_address_lsb)                                                                                                                                                                                                                                                                   
  	                 4'h0: rx_wr_data_reg <=  fifo_mux_out[31:0];                                                                                                                               
  	                 4'h4: rx_wr_data_reg <=  rx_tlp_reg[127:96];                                            
  	                 4'h8: rx_wr_data_reg <=  fifo_mux_out[31:0];                                                                                                                               
  	                 4'hC: rx_wr_data_reg <=  rx_tlp_reg[127:96];
  	             endcase                                                                                                                                                                                                                                                                                 
  	         else                                                                                                                                                                                                                                                                                        
  	             // for 4DW header pkts, only QW alignment adjustment is required                                                                                                                                                                                                                        
  	             case (rx_address_lsb)                                                                                                                                                                                                                                                                   
  	                 4'h0: rx_wr_data_reg <=  fifo_mux_out[31:0];                                                                                                                                                                          
  	                 4'h4: rx_wr_data_reg <=  fifo_mux_out[63:32];                                                                                                                                                                          
  	                 4'h8: rx_wr_data_reg <=  fifo_mux_out[31:0];                                                                                                                                                                              
  	                 4'hC: rx_wr_data_reg <=  fifo_mux_out[63:32];                                                                                                                                                                              
  	             endcase                                                                                                                                                                                                                                                                                 
  	       end                                                                                                                                                                                                                                                                                           
  	    end                                                                                                                                                                                                                                                                                              
  end
 endgenerate



// Re-aligned byte enable

generate if(CB_PCIE_RX_LITE == 0)
           begin
                always @(posedge Clk_i) 
                  begin
                      if (first_data_phase & tlp_3dw_header & rxm_data_reg_clk_ena)     // 3DW header first data phase
                        begin
                          case (rx_address_lsb)
                              4'h0: rx_wr_be_reg <= {input_fifo_be_out[15:12], input_fifo_be_out[11:8], input_fifo_be_out[7:4], input_fifo_be_out[3:0]} & tail_mask; 
                              4'h4: rx_wr_be_reg <= {input_fifo_be_out[7:4], input_fifo_be_out[3:0], rx_tlp_be_reg[15:12], zeros_4} & tail_mask;        
                              4'h8: rx_wr_be_reg <= {input_fifo_be_out[7:4], input_fifo_be_out[3:0], zeros_8} & tail_mask;   
                              4'hC: rx_wr_be_reg <= {rx_tlp_be_reg[15:12], zeros_4, zeros_8} & tail_mask; 
                          endcase
                        end
                      
                      else if (tlp_3dw_header & rxm_data_reg_clk_ena)  // subsequent data phases
                        begin
                          case (rx_address_lsb)
                              4'h0: rx_wr_be_reg <= {input_fifo_be_out[15:12], input_fifo_be_out[11:8], input_fifo_be_out[7:4], input_fifo_be_out[3:0]} & tail_mask; 
                              4'h4: rx_wr_be_reg <= {input_fifo_be_out[7:4], input_fifo_be_out[3:0], rx_tlp_be_reg[15:12], rx_tlp_be_reg[11:8]} & tail_mask;        
                              4'h8: rx_wr_be_reg <= {input_fifo_be_out[7:4], input_fifo_be_out[3:0], rx_tlp_be_reg[15:12], rx_tlp_be_reg[11:8]} & tail_mask;   
                              4'hC: rx_wr_be_reg <= {rx_tlp_be_reg[15:12], rx_tlp_be_reg[11:8], rx_tlp_be_reg[7:4], rx_tlp_be_reg[3:0]} & tail_mask; 
                          endcase
                       end
                      
                       else if (first_data_phase & ~tlp_3dw_header & rxm_data_reg_clk_ena)  // first data phases 4dw header    
                         begin
                          case (rx_address_lsb)
                              4'h0: rx_wr_be_reg <= {input_fifo_be_out[15:12], input_fifo_be_out[11:8], input_fifo_be_out[7:4], input_fifo_be_out[3:0]} & tail_mask; 
                              4'h4: rx_wr_be_reg <= {input_fifo_be_out[15:12], input_fifo_be_out[11:8], input_fifo_be_out[7:4], zeros_4 } & tail_mask;        
                              4'h8: rx_wr_be_reg <= {input_fifo_be_out[7:4], input_fifo_be_out[3:0], zeros_8} & tail_mask;   
                              4'hC: rx_wr_be_reg <= {input_fifo_be_out[7:4], zeros_4, zeros_8} & tail_mask; 
                          endcase
                        end
                      else if(~tlp_3dw_header & rxm_data_reg_clk_ena) 
                          // for 4DW header pkts, only QW alignment adjustment is required
                        begin
                          case (rx_address_lsb)
                              4'h0: rx_wr_be_reg <= {input_fifo_be_out[15:12], input_fifo_be_out[11:8], input_fifo_be_out[7:4], input_fifo_be_out[3:0]} & tail_mask; 
                              4'h4: rx_wr_be_reg <= {input_fifo_be_out[15:12], input_fifo_be_out[11:8], input_fifo_be_out[7:4], input_fifo_be_out[3:0]} & tail_mask;      
                              4'h8: rx_wr_be_reg <= {input_fifo_be_out[7:4], input_fifo_be_out[3:0], rx_tlp_be_reg[15:12], rx_tlp_be_reg[11:8]} & tail_mask;   
                              4'hC: rx_wr_be_reg <= {input_fifo_be_out[7:4], input_fifo_be_out[3:0], rx_tlp_be_reg[15:12], rx_tlp_be_reg[11:8]} & tail_mask;  
                          endcase
                       end
                  end
           end
else //generate
           begin
               always @(posedge Clk_i)                                                                                                                                                       
                 begin                                                                                                                                                                       
                     if ( tlp_3dw_header & rxm_data_reg_clk_ena)     // 3DW header first data phase                                                                        
                       begin                                                                                                                                                                 
                         case (rx_address_lsb)                                                                                                                                               
                             4'h0: rx_wr_be_reg[3:0] <=  input_fifo_be_out[3:0];                          
                             4'h4: rx_wr_be_reg[3:0] <=  rx_tlp_be_reg[15:12];                                              
                             4'h8: rx_wr_be_reg[3:0] <=  input_fifo_be_out[3:0];                                                                    
                             4'hC: rx_wr_be_reg[3:0] <=  rx_tlp_be_reg[15:12];                                                                                     
                         endcase                                                                                                                                                             
                       end                                                                                                                                                                   
                                                                                                                                                                                             
                      else if (~tlp_3dw_header & rxm_data_reg_clk_ena)  // first data phases 4dw header                                                                   
                        begin                                                                                                                                                                
                         case (rx_address_lsb)                                                                                                                                               
                             4'h0: rx_wr_be_reg[3:0] <= input_fifo_be_out[3:0];                          
                             4'h4: rx_wr_be_reg[3:0] <= input_fifo_be_out[7:4];                                        
                             4'h8: rx_wr_be_reg[3:0] <= input_fifo_be_out[3:0];                                                                    
                             4'hC: rx_wr_be_reg[3:0] <= input_fifo_be_out[7:4];                                                                                   
                         endcase                                                                                                                                                             
                       end                                                                                                                                                                   
                 end                                                                                                                                                                         
           end
endgenerate
   
   /// read bytenable created based on address, LBE, FBE of the TLP
generate if(CB_PCIE_RX_LITE == 0) 
       begin 
           always @(posedge Clk_i) 
           begin
             if (rx_dwlen == 1)  
                 begin
                   case (rx_address_lsb)
                       4'h0: rx_rd_be_reg <= {12'h000, rx_fbe}; 
                       4'h4: rx_rd_be_reg <= {8'h0, rx_fbe, 4'h0};        
                       4'h8: rx_rd_be_reg <= {4'h0, rx_fbe, 8'h00};   
                       4'hC: rx_rd_be_reg <= {rx_fbe, 12'h0}; 
                   endcase
                end
              else if(rx_dwlen == 2)
                 begin
                   case (rx_address_lsb)
                       4'h0: rx_rd_be_reg <= {8'h0, rx_lbe, rx_fbe}; 
                       4'h4: rx_rd_be_reg <= {4'h0,rx_lbe, rx_fbe, 4'h0};        
                       4'h8: rx_rd_be_reg <= {rx_lbe, rx_fbe, 8'h00};   
                       4'hC: rx_rd_be_reg <= 16'hFFFF; 
                   endcase
                 end
               else if(rx_dwlen == 3)
                 begin
                   case (rx_address_lsb)
                       4'h0: rx_rd_be_reg <= {4'h0, rx_lbe, 4'hF, rx_fbe}; 
                       4'h4: rx_rd_be_reg <= {rx_lbe,4'hF, rx_fbe, 4'h0};        
                       default: rx_rd_be_reg <= 16'hFFFF; 
                   endcase
                 end
               else
                 begin
                   rx_rd_be_reg <= 16'hFFFF; 
                 end
           end     
       end
else // generate
      begin
      	     always @(posedge Clk_i)                                                  
      	       begin                                                                    
      	         if (rx_dwlen == 1)                                                     
      	             rx_rd_be_reg[3:0] <= rx_fbe;                     
      	         else                                                                 
      	            rx_rd_be_reg[3:0]       <= 4'hF;                                        
      	       end                                                                      
      end
endgenerate
 // after shifting the DWs to the correct positions, the empty hole(s) (size of DW)
 // is created. The number of holes for empty slots accounts for the additional length of 
 // payload. The following logic adjust the length according to this effect.
 
 
 always @(posedge Clk_i or negedge Rstn_i)  begin
     if (Rstn_i==1'b0)
       rx_dw_count_0  <= 0;
     else if (rxsm_rd_header_0_reg & rx_sop_fifo & (is_wr_fifo | is_cpl_wd_fifo )) // load the counter with adjusted length
       begin
         case (rx_address_lsb_fifo)
             4'h0: rx_dw_count_0 <= rx_dwlen_fifo;      // represents payload length (in DWs) not yet passed on rx_data0/rx_dv0
             4'h4: rx_dw_count_0 <= rx_dwlen_fifo + 1;
             4'h8: rx_dw_count_0 <= rx_dwlen_fifo + 2;
             4'hC: rx_dw_count_0 <= rx_dwlen_fifo + 3;
         endcase
       end
     else if ((rx_dw_count_0 > 3) & (rxsm_wrena_0 & !rxm_wait_req))      // update when data is transmit the fabric
       rx_dw_count_0 <= rx_dw_count_0 - 4;
   end
               


        

assign rx_dw_count =  rx_dw_count_0;
   
 
 always @* begin
      if (rx_dw_count[9:2] > 1 | rxsm_pipe_0) begin     // # of payload DWs left to pass to rx_data0 including this cycle is >4 DWs.  This count is already adjusted for addr offsets.
          tail_mask = 16'hffff;
      end
      else begin                                        // this is the last payload cycle.  mask out non-Payload bytes.
          case (rx_dw_count[1:0])
              2'b00: tail_mask = 16'h0000;
              2'b01: tail_mask = 16'h000f;
              2'b10: tail_mask = 16'h00ff;
              2'b11: tail_mask = 16'h0fff;
              default : tail_mask = 16'hffff;
          endcase
      end
  end

// Using two state machines to get max throughput
// This is needed due to the deep pipe-line in the Rx path to make FMAX 
// Rx Control SM1

always @(posedge Clk_i, negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      rx_state_0 <= RX_IDLE_0;
    else
      rx_state_0 <= rx_nxt_state_0;
  end
  

always @*
  begin   
    case(rx_state_0)
      RX_IDLE_0 :
        if(input_fifo_wrusedw > 0 &  pndgrd_fifo_ok_reg )
          rx_nxt_state_0 <= RX_RD_HEADER_0;
        else
          rx_nxt_state_0 <= RX_IDLE_0;
                    
      RX_RD_HEADER_0:
        rx_nxt_state_0 <= RX_CHECK_HEADER_0;
        
        
      RX_CHECK_HEADER_0:    // decode header at fifo_q, also latch the fifo_q into the fifo_q_reg, read fifo if !eop & !(sm_wr & rxmwait). Store the header_0 in a separate register
        if(is_cpl_fifo & (cpl_tag_fifo >= 16 & rx_address_lsb_fifo[2] | ~is_cpl_wd_fifo))  
           rx_nxt_state_0 <= RX_IDLE_0;
        else if (is_cpl_fifo & cpl_tag_fifo >= 16 & ~rx_address_lsb_fifo[2])               
           rx_nxt_state_0 <= RX_RP_STREAM_0;
        else if(is_msg_wod_fifo | wr_1dw_fbe_eq_0_fifo) 
           rx_nxt_state_0 <= RX_IDLE_0;
        else if((is_wr_fifo & ~is_uns_wr_size_fifo | is_cpl_wd_fifo | is_rd_fifo))
          rx_nxt_state_0 <= RX_PIPE_0;  
        else if(is_flush_fifo | is_uns_rd_size_fifo)
          rx_nxt_state_0 <= RX_STORE_RD_0;
        else if (is_msg_wd_fifo | is_uns_wr_size_fifo)
           rx_nxt_state_0 <= RX_MSG_DUMP_0;
        else
           rx_nxt_state_0 <= RX_CHECK_HEADER_0;
           
      RX_PIPE_0:
        if(is_wr_hdrreg_0)
          rx_nxt_state_0 <= RX_WRENA_0;
        else if((is_rd_hdrreg_0) )
           rx_nxt_state_0 <= RX_CHECK_TXCPLSIZE_0;
        else if(is_cpl_wd_reg_0)
          rx_nxt_state_0 <= RX_CPLENA_0;
        else 
          rx_nxt_state_0 <= RX_PIPE_0;
          
      RX_CHECK_TXCPLSIZE_0:
        if((cpl_buff_ok & ~is_rx_lite_core & (~is_read_bar_changed | is_read_bar_changed & TxRespIdle_i)) |  ( is_rx_lite_core & ~RxRdInProgress_i))
           rx_nxt_state_0 <= RX_STORE_RD_0;
        else
           rx_nxt_state_0 <= RX_CHECK_TXCPLSIZE_0;
          
      RX_WRENA_0:
         if((rx_dw_count_0 <= 4 | is_rx_lite_core) & !rxm_wait_req )
          rx_nxt_state_0 <= RX_IDLE_0;
        else if (rxm_wait_req_fall & over_rd_sreg) 
           rx_nxt_state_0 <= RX_WRWAIT_0;
        else
           rx_nxt_state_0 <= RX_WRENA_0;    
           
      RX_WRWAIT_0 :
         if(!rxm_wait_req)
           rx_nxt_state_0 <= RX_WRENA_0;
         else
           rx_nxt_state_0 <= RX_WRWAIT_0;    
     
      RX_STORE_RD_0:    
        if(is_flush | is_uns_rd_size)      
          rx_nxt_state_0 <= RX_IDLE_0;
        else
          rx_nxt_state_0 <= RX_RDENA_0;  
         
         
      RX_RDENA_0 :
        if(~rxm_wait_req)
          rx_nxt_state_0 <= RX_IDLE_0;
        else
          rx_nxt_state_0 <= RX_RDENA_0;  
          
      RX_CPLENA_0 :
       if(rx_eop_reg2)
         rx_nxt_state_0 <= RX_IDLE_0;
       else
         rx_nxt_state_0 <= RX_CPLENA_0; 
                          
       RX_MSG_DUMP_0:
         if(rx_eop_fifo)
           rx_nxt_state_0 <= RX_IDLE_0; 
         else
           rx_nxt_state_0 <= RX_MSG_DUMP_0; 
                               
       RX_RP_STREAM_0 : 
         //if(rx_eop_fifo)
            rx_nxt_state_0 <= RX_IDLE_0; 
         //else
         //    rx_nxt_state_0 <= RX_RP_STREAM_0; 
       default:           
         rx_nxt_state_0 <= RX_IDLE_0;
       
     endcase
  end
  
/// state machine output assignments
assign rxsm_idle_0          = !rx_state_0[0];
assign rxsm_rd_header_0     = rx_state_0[1];
assign rxsm_chk_hdr_0       = rx_state_0[2];
assign rxsm_wrena_0         = rx_state_0[3];
assign rxsm_wrwait_0        = rx_state_0[4];
assign rxsm_store_rd_0      = rx_state_0[5];
assign rxsm_rdena_0         = rx_state_0[6];
assign rxsm_cplena_0        = rx_state_0[8];
assign rxsm_pipe_0          =  rx_state_0[9];
assign rxsm_msg_dump_0      = rx_state_0[10];
assign rxsm_rp_stream       = rx_state_0[11];       
assign RxRpFifoWrReq_o      = (rxsm_chk_hdr_0 & (is_cpl_fifo & cpl_tag_fifo >= 16)) |
                               rxsm_rp_stream & ~rx_header0_reg[66]; // ~odd address
                               
assign RxRpFifoWrData_o     = {input_fifo_dataout[154] ,input_fifo_dataout[145] ,input_fifo_dataout[144],  input_fifo_dataout[127:0]};



/// The payload count in DQWORD. Adjusted to account for the unused space of the DQWORDs       

assign rx_modlen_sel = {rx_address_lsb_fifo, rx_dwlen_fifo[1:0]};
    
    always @ *
      begin
        case (rx_modlen_sel)
          6'b0000_00:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2];       // data is 128-bit aligned and modulo-128
          6'b0000_01:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1;   // data is 128-bit aligned
          6'b0000_10:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1;   // data is 128-bit aligned
          6'b0000_11:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1;   // data is 128-bit aligned
          6'b0100_00:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1; 
          6'b0100_01:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1;   
          6'b0100_10:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1;
          6'b0100_11:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1;
          6'b1000_00:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1;
          6'b1000_01:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1;
          6'b1000_10:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1;
          6'b1000_11:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 2;
          6'b1100_00:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1;
          6'b1100_01:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 1;
          6'b1100_10:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 2;
          6'b1100_11:  rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2] + 2;     
          default:     rx_modlen_qdword[7:0] <= rx_dwlen_fifo[9:2];  
        endcase
      end
      
always @(posedge Clk_i or negedge Rstn_i)        
  begin                                             
    if(~Rstn_i)                                     
       rx_modlen_qdword_reg_0 <= 0;                       
    else if(rxsm_rd_header_0_reg)                                            
      rx_modlen_qdword_reg_0 <= is_uns_rd_size_fifo? 0 : rx_modlen_qdword;  
  end     
      


assign rx_modlen_qdword_reg =  rx_modlen_qdword_reg_0[5:0];


/// Tx Completion Buffer status       

// Tx Cpl space accumulator to be put back to the pool

assign tx_accumulator_dump = !store_rd & txcpl_buffer_accumulator != 0;

 always @(posedge Clk_i or negedge Rstn_i)                
    begin                                                 
      if(~Rstn_i)                                         
        txcpl_buffer_accumulator <= 8'h00; 
      else if (TxCpl_i)
        txcpl_buffer_accumulator <= txcpl_buffer_accumulator + TxCplLen_i;
      else if(tx_accumulator_dump)
        txcpl_buffer_accumulator <= 8'h00;
    end
    
 
                     
 always @(posedge Clk_i or negedge Rstn_i)
    begin
      if(~Rstn_i)
        txcpl_buffer_size <= 64; // 256 DW available
      else if(store_rd)
        txcpl_buffer_size <= txcpl_buffer_size - rx_modlen_qdword_reg;
      else if(tx_accumulator_dump)
        txcpl_buffer_size <= txcpl_buffer_size + txcpl_buffer_accumulator;
    end

assign store_rd = rxsm_store_rd_0 ;
// always @(posedge Clk_i or negedge Rstn_i)
//    begin
//      if(~Rstn_i)
//        txcpl_buffer_size <= 64; // 64 lines of 128-bit available
//      else if(store_rd & ~TxCpl_i)
//        txcpl_buffer_size <= txcpl_buffer_size - rx_modlen_qdword_reg;
//      else if(TxCpl_i & ~store_rd)
//        txcpl_buffer_size <= txcpl_buffer_size + TxCplLen_i;
//      else if(TxCpl_i & store_rd)
//        txcpl_buffer_size <= txcpl_buffer_size + TxCplLen_i - rx_modlen_qdword_reg;
//    end


assign  cpl_buff_ok = (txcpl_buffer_size > rx_modlen_qdword_reg) | is_rx_lite_core; 

// address translation (PCIe to Avl)
altpciexpav128_p2a_addrtrans
   p2a_addr_trans
 (    .k_bar_i(k_bar_i), 
      .cb_p2a_avalon_addr_b0_i(cb_p2a_avalon_addr_b0_i),
      .cb_p2a_avalon_addr_b1_i(cb_p2a_avalon_addr_b1_i),
      .cb_p2a_avalon_addr_b2_i(cb_p2a_avalon_addr_b2_i),
      .cb_p2a_avalon_addr_b3_i(cb_p2a_avalon_addr_b3_i),
      .cb_p2a_avalon_addr_b4_i(cb_p2a_avalon_addr_b4_i),
      .cb_p2a_avalon_addr_b5_i(cb_p2a_avalon_addr_b5_i),
      .cb_p2a_avalon_addr_b6_i(cb_p2a_avalon_addr_b6_i),
      .PCIeAddr_i(rx_addr[31:0]),   
      .BarHit_i(bar_hit_reg),    
      .AvlAddr_o(avl_translated_addr[31:0])      
);                      

    assign avl_addr = {32'h0, avl_translated_addr};


always @(posedge Clk_i or negedge Rstn_i) 
  begin
    if(~Rstn_i)
       avl_addr_reg <= 64'h0;
    else
      avl_addr_reg <= avl_addr;
  end
  
  
  
  /// Previous Read Bar registers

generate
   genvar j;
 for(j=0; j< 6; j=j+1)
   begin: previous_read_bar 
       always @(posedge Clk_i or negedge Rstn_i) 
         begin
           if(~Rstn_i)
              previous_bar_read[j] <= 1'b1;
           else if((rxsm_rdena_0 ) & bar_hit_reg[j])   /// set when the bar is hit 
             previous_bar_read[j] <= 1'b1;
           else if((rxsm_rdena_0 ) & ~bar_hit_reg[j])   // reset when something else hit
             previous_bar_read[j] <= 1'b0;
         end
     end
endgenerate


//generate
//   genvar j;
// for(j=0; j< 6; j=j+1)
//   begin: previous_read_bar 
//       always @(posedge AvlClk_i or negedge Rstn_i) 
//         begin
//           if(~Rstn_i)
//              previous_bar_read[j] <= 1'b1;
//           else if(rdena & bar_hit[j])   /// set when the bar is hit 
//             previous_bar_read[j] <= 1'b1;
//           else if(rdena & ~bar_hit[j])   // reset when something else hit
//             previous_bar_read[j] <= 1'b0;
//         end
//     end
//endgenerate





        
assign is_read_bar_changed = ((previous_bar_read[0] ^ bar_hit_reg[0]) & bar_hit_reg[0])|
                             ((previous_bar_read[1] ^ bar_hit_reg[1]) & bar_hit_reg[1])| 
                             ((previous_bar_read[2] ^ bar_hit_reg[2]) & bar_hit_reg[2])| 
                             ((previous_bar_read[3] ^ bar_hit_reg[3]) & bar_hit_reg[3])| 
                             ((previous_bar_read[4] ^ bar_hit_reg[4]) & bar_hit_reg[4])| 
                             ((previous_bar_read[5] ^ bar_hit_reg[5]) & bar_hit_reg[5]) ;
  

assign rx_be = rxsm_rdena_0? rx_rd_be_reg : rx_wr_be_reg;
  
  
 generate if(CB_PCIE_RX_LITE == 0)
  begin
     
     
     altpciexpav128_rxm_adapter 
      # (
           .CB_RXM_DATA_WIDTH(CB_RXM_DATA_WIDTH),
           .AVALON_ADDR_WIDTH(AVALON_ADDR_WIDTH)
        )
  altpciexpav128_rxm_adapter    
 (
        
  .Clk_i(Clk_i),                   
  .Rstn_i(Rstn_i),                  
  .CoreRxmWrite_i(rxsm_wrena_0),          
  .CoreRxmRead_i(rxsm_rdena_0),           
  .CoreRxmWriteSOP_i(first_write_state | rxsm_rdena_0),       
  .CoreRxmWriteEOP_i(last_write_state | rxsm_rdena_0),      
  .CoreRxmBarHit_i(bar_hit_reg),
  .CoreRxmAddress_i({avl_addr_reg[AVALON_ADDR_WIDTH - 1:4], 4'h0}),        
  .CoreRxmWriteData_i(rx_data_reg),      
  .CoreRxmByteEnable_i(rx_be),     
  .CoreRxmBurstCount_i(rx_modlen_qdword_reg),     
  .CoreRxmWaitRequest_o(rxm_wait_req),    
                          
  .FabricRxmWrite_o(fabric_write),       
  .FabricRxmRead_o(fabric_read),        
  .FabricRxmAddress_o(fabric_address[AVALON_ADDR_WIDTH-1 : 0]),     
  .FabricRxmWriteData_o(fabric_write_data),   
  .FabricRxmByteEnable_o(fabric_write_be),  
  .FabricRxmBurstCount_o(fabric_burst_count),  
  .FabricRxmWaitRequest_i(fabric_wait_req),
  .FabricRxmBarHit_o(fabric_bar_hit_reg)
);
  
  end
endgenerate 
  
  
// Avalon master port interface

generate if(CB_PCIE_RX_LITE == 0)
  begin
    assign RxmWrite_0_o = (fabric_write ) &  fabric_bar_hit_reg[0];
    assign RxmRead_0_o = (fabric_read ) &  fabric_bar_hit_reg[0];
    assign RxmAddress_0_o = fabric_address;
    assign RxmWriteData_0_o = fabric_write_data[127:0];
    assign RxmBurstCount_0_o = fabric_burst_count;
    assign RxmByteEnable_0_o = fabric_write_be;
    
    
    assign RxmWrite_1_o = (fabric_write ) &  fabric_bar_hit_reg[1];
    assign RxmRead_1_o = (fabric_read ) &  fabric_bar_hit_reg[1];
    assign RxmAddress_1_o = fabric_address;
    assign RxmWriteData_1_o = fabric_write_data[127:0];
    assign RxmBurstCount_1_o = fabric_burst_count;
    assign RxmByteEnable_1_o = fabric_write_be;
    
     assign RxmWrite_2_o = (fabric_write ) &  fabric_bar_hit_reg[2];
    assign RxmRead_2_o = (fabric_read ) &  fabric_bar_hit_reg[2];
    assign RxmAddress_2_o = fabric_address;
    assign RxmWriteData_2_o = fabric_write_data[127:0];
    assign RxmBurstCount_2_o = fabric_burst_count;
    assign RxmByteEnable_2_o = fabric_write_be;
    
    assign RxmWrite_3_o = (fabric_write ) &  fabric_bar_hit_reg[3];
    assign RxmRead_3_o = (fabric_read ) &  fabric_bar_hit_reg[3];
    assign RxmAddress_3_o = fabric_address;
    assign RxmWriteData_3_o = fabric_write_data[127:0];
    assign RxmBurstCount_3_o = fabric_burst_count;
    assign RxmByteEnable_3_o = fabric_write_be;
    
    
    assign RxmWrite_4_o = (fabric_write) &  fabric_bar_hit_reg[4];
    assign RxmRead_4_o = (fabric_read ) &  fabric_bar_hit_reg[4];
    assign RxmAddress_4_o = fabric_address;
    assign RxmWriteData_4_o = fabric_write_data[127:0];
    assign RxmBurstCount_4_o = fabric_burst_count;
    assign RxmByteEnable_4_o = fabric_write_be;

    assign RxmWrite_5_o = (fabric_write) &  fabric_bar_hit_reg[5];
    assign RxmRead_5_o = (fabric_read ) &  fabric_bar_hit_reg[5];
    assign RxmAddress_5_o = fabric_address;
    assign RxmWriteData_5_o = fabric_write_data[127:0];
    assign RxmBurstCount_5_o = fabric_burst_count;
    assign RxmByteEnable_5_o = fabric_write_be;
  end
else // generate
  begin
  	     assign RxmWrite_0_o = (rxsm_wrena_0) &  bar_hit_reg[0];   
  	     assign RxmRead_0_o = (rxsm_rdena_0 ) &  bar_hit_reg[0];  
  	     assign RxmAddress_0_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:2], 2'h0};                    
  	     assign RxmWriteData_0_o = rx_wr_data_reg;                          
  	     assign RxmBurstCount_0_o = rx_modlen_qdword_reg;                       
  	     assign RxmByteEnable_0_o = rx_be;                                      
  	                                                                            
  	                                                                            
  	     assign RxmWrite_1_o = (rxsm_wrena_0) &  bar_hit_reg[1]; 
  	     assign RxmRead_1_o = (rxsm_rdena_0 ) &  bar_hit_reg[1];  
  	     assign RxmAddress_1_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:2], 2'h0};                    
  	     assign RxmWriteData_1_o = rx_wr_data_reg;                          
  	     assign RxmBurstCount_1_o = rx_modlen_qdword_reg;                       
  	     assign RxmByteEnable_1_o = rx_be;                                      
  	                                                                            
  	      assign RxmWrite_2_o = (rxsm_wrena_0) &  bar_hit_reg[2];
  	     assign RxmRead_2_o = (rxsm_rdena_0 ) &  bar_hit_reg[2];  
  	     assign RxmAddress_2_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:2], 2'h0};                    
  	     assign RxmWriteData_2_o = rx_wr_data_reg;                         
  	     assign RxmBurstCount_2_o = rx_modlen_qdword_reg;                       
  	     assign RxmByteEnable_2_o = rx_be;                                      
  	                                                                            
  	     assign RxmWrite_3_o = (rxsm_wrena_0) &  bar_hit_reg[3]; 
  	     assign RxmRead_3_o = (rxsm_rdena_0 ) &  bar_hit_reg[3];  
  	     assign RxmAddress_3_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:2], 2'h0};                    
  	     assign RxmWriteData_3_o = rx_wr_data_reg;                          
  	     assign RxmBurstCount_3_o = rx_modlen_qdword_reg;                       
  	     assign RxmByteEnable_3_o = rx_be;                                      
  	                                                                            
  	     assign RxmWrite_4_o = (rxsm_wrena_0 ) &  bar_hit_reg[4]; 
  	     assign RxmRead_4_o = (rxsm_rdena_0 ) &  bar_hit_reg[4];  
  	     assign RxmAddress_4_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:2], 2'h0};                    
  	     assign RxmWriteData_4_o = rx_wr_data_reg;                         
  	     assign RxmBurstCount_4_o = rx_modlen_qdword_reg;                       
  	     assign RxmByteEnable_4_o = rx_be;                                      
  	                                                                            
  	     assign RxmWrite_5_o = (rxsm_wrena_0 ) &  bar_hit_reg[5]; 
  	     assign RxmRead_5_o = (rxsm_rdena_0 ) &  bar_hit_reg[5];  
  	     assign RxmAddress_5_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:2], 2'h0};                    
  	     assign RxmWriteData_5_o = rx_wr_data_reg;                          
  	     assign RxmBurstCount_5_o = rx_modlen_qdword_reg;                       
  	     assign RxmByteEnable_5_o = rx_be;                                      
  end
endgenerate

// RX Completion RAM Interface -- NOT Yet Done


/// an array to store the last write address for each tag

generate
   genvar k;
 for(k=0; k< 16; k=k+1)
   begin: cpl_address_counter_back_trace   
   always @(negedge Rstn_i or posedge Clk_i)
    begin
       if (Rstn_i == 1'b0)
          cpl_add_cntr_previous[k][5:0] <= 6'h0;
       else
             if(cpl_tag == k & last_cpl & rx_eop_reg2) // good last completion, reset
               cpl_add_cntr_previous[k] <= 0;
             else if (cpl_tag == k & is_cpl_wd & rx_eop_reg2)   // good completion, save new address pointer
                cpl_add_cntr_previous[k] <= cpl_add_cntr[5:0]; 
    end 
 end
 endgenerate

  // address counter for each CPL buffer segment
 
   always @(negedge Rstn_i or posedge Clk_i)
    begin
       if (Rstn_i == 1'b0)
          cpl_add_cntr <= 5'h0 ; 
       else if((rxsm_chk_hdr_0 ) & is_cpl_wd_fifo)
          cpl_add_cntr <= cpl_add_cntr_previous[cpl_tag_fifo[3:0]];   // load the previous stored pointer of a current tag
       else if (CplRamWrEna_o)
           cpl_add_cntr <= cpl_add_cntr + 1; 
    end 
    

assign CplRamWrAddr_o[8:0] = {cpl_tag[3:0], cpl_add_cntr[4:0]};
assign CplRamWrEna_o = rxsm_cplena_0 ;
assign CplRamWrDat_o = {(last_cpl & rx_eop_reg2), 1'b0, rx_data_reg[127:0]};

always @(posedge Clk_i or negedge Rstn_i) 
  begin
    if(~Rstn_i)
     begin
      CplReq_o <= 1'b0;
      CplDesc_o <= 0;
     end
    else
     begin
      CplReq_o <= (rxsm_cplena_0 ) & is_cpl_wd;
      CplDesc_o <= {last_cpl, 1'b1, cpl_tag[3:0]};
     end
  end
  
/// Pending FIFO interface

always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
     begin
      pndgrd_fifo_ok_reg <= 1'b0;
     end
    else
     begin
      pndgrd_fifo_ok_reg <= is_rx_lite_core? 1'b1 : (PndngRdFifoUsedW_i <= 8);
     end
  end  
  
assign PndgRdHeader_o      = {is_uns_rd_size, rx_lbe, rx_tc, rx_attr, rx_fbe, rx_dwlen_reg, requestor_id, is_flush, rx_addr[6:0], rdreq_tag};
assign PndgRdFifoWrReq_o   = rxsm_store_rd_0 ;
                                                      

/// Fifo Interface

assign input_fifo_rdreq = rxsm_rd_header_0 | (rxsm_rp_stream & ~rx_eop_fifo) |
                         ((rxsm_chk_hdr_0 ) & ~input_fifo_rdempty & (is_wr_fifo | is_cpl_wd_fifo | is_msg_wd_fifo) & ~rx_eop_fifo) |
                       ((rxsm_wrena_0  ) & ~input_fifo_rdempty & ~rx_eop_fifo & (~rxm_wait_req_reg | rxsm_pipe_0_reg  ))|
                       ((rxsm_pipe_0 ) & ~rx_eop_fifo) |
                       ((rxsm_cplena_0 ) & ~input_fifo_rdempty & ~rx_eop_fifo) | 
                        ((rxsm_msg_dump_0 ) & ~rx_eop_fifo);

// Mask Hardwired
assign RxStMask_o = 1'b0;

endmodule
