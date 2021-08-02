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
module altpciexpav128_tx_cntrl

# ( 
   parameter  ADDRESS_32BIT = 1,
   parameter  CB_PCIE_MODE = 0,
   parameter  CB_PCIE_RX_LITE = 0,
   parameter  deviceFamily = "Arria V",
   parameter  in_cvp_mode_hwtcl = 0 
  )  
  
( input                                Clk_i,     // Avalon clock
  input                                Rstn_i,    // Avalon reset    
  
  // PCIe HIP Tx interface
   input                    TxStReady_i,
   output   [127:0]         TxStData_o,
   output                   TxStSop_o,
   output                   TxStEop_o,
   output   [1:0]           TxStEmpty_o,
   output                   TxStValid_o,
   input                    TxAdapterFifoEmpty_i,
 // Tx Credit Interface
      /// Tx Credit interface                     
   input   [5 : 0]          TxCredHipCons_i,      
   input   [5 : 0]          TxCredInfinit_i,      
   input   [7 : 0]          TxCredNpHdrLimit_i,   
   input   [7:0]            ko_cpl_spc_header,
   input   [11:0]           ko_cpl_spc_data,
   
  // Command Fifo interface
  input [97:0]   CmdFifoDat_i,
  input          CmdFifoEmpty_i,
  output         CmdFifoRdReq_o,
  
  // Read bypass buffer interface
  input          RdBypassFifoEmpty_i,
  input          RdBypassFifoFull_i,
  input [6:0]    RdBypassFifoUsedw_i,
  input [97:0]   RdBypassFifoDat_i,
  output         RdBypassFifoWrReq_o,
  output         RdBypassFifoRdReq_o,
  
  // Completion buffer interface
  output  [6:0]   CplBuffRdAddr_o,
  input   [127:0] TxCplDat_i,
  
  // write data fifo interface
  output         WrDatFifoRdReq_o,
  input [128:0]  TxWrDat_i,
  
  // RP interface
  output           TxRpFifoRdReq_o,  
  input   [130:0]  TxRpFifoData_i,   
  input            RpTLPReady_i,      
  output           RpTLPAck_o,
  
  
   // Rx/Tx Completion interface for buffer credit keeping
  input          RxCplBuffFree_i,
  output         TxCplSent_o,
  output  [4:0]  TxCplLineSent_o, // in 128-bit line unit
  
  
  // Rx Completion interface for buffer credit keeping
  
  // cfg register
  input  [12:0]  BusDev_i,
  input  [15:0]  MsiCsr_i,
  output         MsiReq_o, 
  input          MsiAck_i,
  output         IntxReq_o,
  input          IntxAck_i,
  
  output         CplPending_o,
  input          pld_clk_inuse,
  output         tx_cons_cred_sel
);


localparam      TX_IDLE            = 14'h0000; 
localparam      TX_CHECK_CMDFIFO   = 14'h0003;
localparam      TX_RD_HDR          = 14'h0005;
localparam      TX_WR_HDR          = 14'h0009;
localparam      TX_WR_DATA         = 14'h0011;
localparam      TX_CPL_HDR         = 14'h0021;
localparam      TX_CPL_DATA        = 14'h0041;
localparam      TX_MSI_REQ         = 14'h0081;
localparam      TX_POP_BPFIFO      = 14'h0101;
localparam      TX_RBP_HDR         = 14'h0201;
localparam      TX_STORE_RD        = 14'h0401;
localparam      TX_WAIT            = 14'h0801;
localparam      TX_CHECK_BPFIFO    = 14'h1001;
localparam      TX_WAIT_ADPT_EMPTY = 14'h2001;  

localparam      TXRP_IDLE              = 3'h0; 
localparam      TXRP_FIFO_PREFETCH0    = 3'h1;
localparam      TXRP_FIFO_PREFETCH1    = 3'h2;
localparam      TXRP_STREAM            = 3'h3;
localparam      TXRP_WAIT              = 3'h4;
localparam      TXRP_RESET             = 3'h5;


wire         tlp_3dw_header;
wire         rx_only;
wire         is_rd;
wire         is_wr;
wire         is_cpl;

wire [9:0]  dw_len;
reg  [9:0]  ajusted_dwlen;
wire        addr_bit2;
wire        cpl_dat_clken;

wire        sm_pop_bpfifo ;
wire        sm_bp_rddesc; 
wire        sm_pop_cmdfifo; 
wire        sm_check_cmdfifo; 
wire        sm_rddesc; 
wire        sm_store_rd;
wire        sm_rbp_hdr; 
wire        sm_wrdesc; 
wire        sm_wrdata; 
wire        sm_cpldesc; 
wire        sm_cpl_data;
wire        sm_wait_bpfifo; 
wire        sm_idle;
wire        up_cpl_cnt;
reg         rxcplbuff_free_reg;
wire [63:0]  cmd_header1;     
wire  [63:0]  cmd_header2;    
                                 
reg [18:0]                         tx_state;
reg [18:0]                         tx_nxt_state;  
reg [7:0]                          cpl_dat_cntr;    
reg [7:0]                          tx_modlen_qdword;     
reg [7:0]                          txavl_modlen_qdword;
wire [5:0]                         tx_modlen_sel;
reg [8:0]                          cpl_addr_reg;
reg [5:0]                          outstanding_tag_cntr;

wire is_rd_32 ;
wire is_rd_64 ;
wire is_wr_32 ;
wire is_wr_64 ;
wire is_flush_cpl;
wire is_abort_cpl;
wire [15:0] requestor_id;      
wire [7:0] req_tag;                
wire [7:0] cpl_tag;                
wire [3:0] fbe;     
wire [3:0] lbe;                
wire [6:0] lower_adr;              
wire [15:0] cpl_req_id;             
wire [15:0] cpl_cplter_id;                  
wire [11:0] cpl_remain_bytes; 
wire [1:0] cpl_attr;             
wire [2:0] cpl_tc;           
     
reg [7:0] cmd_reg;
reg [9:0]dw_len_reg;
reg [7:0] req_tag_reg;
reg [3:0] fbe_reg;
reg [3:0] lbe_reg;
reg [63:0] cmdfifo_addr_reg;
reg [2:0] cpl_tc_reg;
reg [1:0] cpl_attr_reg;
reg [11:0] cpl_remain_bytes_reg;
reg [15:0] cpl_req_id_reg;
reg [6:0] lower_adr_reg;      
reg [7:0] cpl_tag_reg;
wire [31:0] adr_hi;
wire [31:0] adr_low;

wire [9:0] pb_dw_len; 
wire [7:0] pb_req_tag ;
wire [3:0] pb_fbe;
wire [3:0] pb_lbe;
wire pb_rd64;
wire [31:0] bp_adr_hi;
wire [31:0] bp_adr_low;
wire [127:0] pb_rd_header;
wire [31:0]  tlp_dw3;           
wire [31:0]  tlp_dw2;
wire         tlp_dw2_sel;
wire         tlp_dw3_sel;
wire [3:0]        output_fifo_wrusedw;
wire              output_fifo_rdempty;
wire  [127:0]             tlp_data;
reg  [127:0]        tlp_holding_reg;
wire  [127:0]       tlp_buff_data;
reg  [127:0]        tx_data;
wire              tlp_data_sel;
wire  [3:0]       tlp_emp_sel;
wire              tlp_sop;
wire              tlp_eop;   
wire              tlp_empty;
reg               tx_empty_int;
wire              output_fifo_wrreq;  
reg                output_fifo_wrreq_reg; 
wire              output_fifo_rdreq;
wire  [130:0]      output_fifo_data_in;
reg   [130:0]      output_fifo_data_in_reg;
wire  [130:0]      output_fifo_data_out;
reg   [130:0]      tx_tlp_out_reg;
reg               tx_sop_out_reg;
reg               tx_eop_out_reg;
reg               tx_empty_out_reg;
reg               output_valid_reg;
reg               fifo_valid_reg;
wire              output_transmit;
wire              fifo_transmit;
reg               output_fifo_ok_reg;
reg               tag_available_reg;
reg               irq_ack_reg;
wire              to_pop_bpfifo;      
reg               np_header_avail_reg;
wire              np_header_avail;
wire  [97:0]        cmd_fifo_dat;
wire  [31:0]      addr_low;
wire  [31:0]      addr_hi;
wire             rdbp_fifo_sel;
wire             sm_check_bpfifo;
wire             rdbypass_fifo_full;
wire 		 msi_req;
wire 		 sm_rd_hdr;
wire 		 sm_wr_hdr;
wire 		 sm_wr_data;
wire 		 sm_cpl_hdr;
wire 		 sm_msi_req;
wire 		 sm_wait;
reg              tx_st_ready_reg;
reg  [7:0]       cmd;
                                     
reg  [4:0]       adapter_fifo_write_cntr; 
wire             hdr_3dw_offset_4;
wire             hdr_3dw_offset_C;
wire  [3:0]      tx_address_lsb;
wire             wrdat_fifo_eop;    
wire              wr_dat_eop_mux;
reg              wr_dat_eop_holding_reg;
reg              wrdat_fifo_rd_reg;
wire  [4:0]      wr_dat_eop_sel;
reg   [4:0]      cpl_sent_reg;

reg  [7:0]       nph_cred_cons_reg;
wire             np_tlp_sent;
reg  [7:0]       nph_cred_limit_reg;
wire [7:0]       nph_cred_sub;
wire [63:0]      cpl_header1;
wire [63:0]      cpl_header2;
wire [63:0]      req_header1;
wire [63:0]      req_header2;
reg  [7:0]       cpl_clken_cntr;
reg              sm_cpldata_reg;
reg              sm_cpl_hdr_reg;
wire  [128:0]    tx_completion_data;
wire [5:0]       max_outstanding_read;

reg  [2:0]       txrp_state;
reg  [2:0]       txrp_nxt_state;   
wire             txrp_sm_idle;
wire             txrp_sm_stream;
wire             txrp_sm_prefetch0;
wire             txrp_sm_prefetch1;
wire             txrp_sm_wait;
wire             txrp_sm_rdfifo;        
wire             txrp_sop;
wire             is_rp_rd;      
wire             is_rp_cfg;
wire             is_rp_io;
wire             txrp_np;          
reg              pld_clk_inuse_reg2;     
reg              pld_clk_inuse_reg3;     
wire             pld_clk_inuse_rise;     
reg              skip_cons_reload_sreg;  
reg              pld_clk_inuse_rise_reg; 
reg              pld_clk_inuse_reg;
reg [3:0]        pulse_width_cntr;
wire             cons_load_pulse_clear;
reg              reload_nph_cons_from_hip_reg;     
wire             holding_eop_sel;
wire             cvp_mode;
reg  [130:0]     txrp_header_reg;
reg  [130:0]     txrp_tlp_reg;
wire             txrp_done;
wire             txrp_eop_reg;
reg             latch_rp_header_reg;
 

assign is_rp_rd       =  ~txrp_header_reg[30] & (txrp_header_reg[28:26]== 3'b000) & ~txrp_header_reg[24];
assign is_rp_cfg       = ~txrp_header_reg[29] & (txrp_header_reg[28:24]==5'b00101); //  type  1    
assign is_rp_io        = ~txrp_header_reg[29] & (txrp_header_reg[28:24]==5'b00010); // read/write 
assign txrp_np         =  is_rp_rd | is_rp_cfg | is_rp_io;

 

// Deriving number of supporting tag based on the Knock-out signals
/// only issue one read if low RX CPL buffer allocated
generate if (deviceFamily == "Arria V" ||  deviceFamily == "Cyclone V")
    assign max_outstanding_read = (ko_cpl_spc_data[11:0] > 32)? 16 : 1; 
 else
   assign max_outstanding_read = 16;  
endgenerate


assign dw_len = rdbp_fifo_sel? {1'b0, RdBypassFifoDat_i[93:85]} : {1'b0, CmdFifoDat_i[93:85]}; // for completion and write
assign requestor_id = {BusDev_i, 3'b000};

assign req_tag      = rdbp_fifo_sel? RdBypassFifoDat_i[81:74]: CmdFifoDat_i[81:74];
assign cpl_tag      = rdbp_fifo_sel? RdBypassFifoDat_i[14:7]: CmdFifoDat_i[14:7];
assign fbe          = rdbp_fifo_sel?  RdBypassFifoDat_i[73:70]: CmdFifoDat_i[73:70];
assign lbe          =  rdbp_fifo_sel? RdBypassFifoDat_i[97:94] : CmdFifoDat_i[97:94];
assign lower_adr    = rdbp_fifo_sel? RdBypassFifoDat_i[6:0]: CmdFifoDat_i[6:0];
assign cpl_req_id   = rdbp_fifo_sel? RdBypassFifoDat_i[30:15]: CmdFifoDat_i[30:15];
assign cpl_cplter_id = requestor_id;
assign cpl_remain_bytes = rdbp_fifo_sel? RdBypassFifoDat_i[81:70]: CmdFifoDat_i[81:70];
assign cpl_attr         = rdbp_fifo_sel? RdBypassFifoDat_i[97:94]: CmdFifoDat_i[97:94];
assign cpl_tc         = rdbp_fifo_sel? RdBypassFifoDat_i[84:82]: CmdFifoDat_i[84:82];
assign  msi_req       = CmdFifoDat_i[81] & (is_wr_32 | is_wr_64);
always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      begin
        cmd_reg <= 8'h0;
        dw_len_reg <= 10'h0;
        req_tag_reg <= 8'h0;
        fbe_reg     <= 4'h0;
        lbe_reg     <= 4'h0;
        cpl_tc_reg       <= 2'b00;
        cpl_attr_reg     <= 2'b00;
        cpl_remain_bytes_reg <= 12'h0;
        cpl_req_id_reg  <= 16'h0;
        cpl_tag_reg     <= 8'h0;
        lower_adr_reg   <= 7'h0;
      end
    else if(sm_check_cmdfifo | sm_check_bpfifo)
      begin
        cmd_reg <= cmd;
        dw_len_reg <= dw_len;
        req_tag_reg <= req_tag;
        fbe_reg     <= fbe;
        lbe_reg     <= lbe;
        cpl_tc_reg       <= cpl_tc;
        cpl_attr_reg     <= cpl_attr;
        cpl_remain_bytes_reg <= cpl_remain_bytes;
        cpl_req_id_reg  <= cpl_req_id;
        cpl_tag_reg     <= cpl_tag;
        lower_adr_reg   <= lower_adr;
      end
  end

generate if(in_cvp_mode_hwtcl == 1)
    assign cvp_mode = 1'b1;
else
    assign cvp_mode = 1'b0;
endgenerate 


generate if(CB_PCIE_MODE == 1)
  assign rx_only = 1'b1;
else
  assign rx_only = 1'b0;
endgenerate

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     begin
      output_fifo_ok_reg <= 1'b0;
      tag_available_reg <= 0;
      irq_ack_reg <= 1'b0;
      np_header_avail_reg <= 1'b0;
     end
    else
     begin
      np_header_avail_reg <= np_header_avail | cvp_mode; /// do not check NP credit in CVP mode;
      output_fifo_ok_reg <= output_fifo_wrusedw[3:0] <= 4;
      tag_available_reg <= (outstanding_tag_cntr != 0);
      irq_ack_reg <= MsiAck_i;
     end
  end

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      adapter_fifo_write_cntr <= 5'b0;
    else if (sm_check_cmdfifo & msi_req)
      adapter_fifo_write_cntr <= 5'b0;
    else if(fifo_transmit)
      adapter_fifo_write_cntr <= adapter_fifo_write_cntr + 1;
  end


assign hdr_3dw_offset_4 = (tx_address_lsb[3:0] == 4'h4) & tlp_3dw_header;
assign hdr_3dw_offset_C = (tx_address_lsb[3:0] == 4'hC) & tlp_3dw_header;



/// Credit available logic
always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      begin
        pld_clk_inuse_reg <= 1'b0;
        pld_clk_inuse_reg2 <= 1'b0;
        pld_clk_inuse_reg3 <= 1'b0;
        pld_clk_inuse_rise_reg <= 1'b0;
      end
    else
      begin
        pld_clk_inuse_reg <= pld_clk_inuse;
        pld_clk_inuse_reg2 <= pld_clk_inuse_reg;
        pld_clk_inuse_reg3 <= pld_clk_inuse_reg2;
        pld_clk_inuse_rise_reg <= pld_clk_inuse_rise;
      end
  end 
  
assign pld_clk_inuse_rise = pld_clk_inuse_reg2 & ~pld_clk_inuse_reg3;


always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      skip_cons_reload_sreg <= 1'b0;
    else if(pld_clk_inuse_rise & ~skip_cons_reload_sreg)
      skip_cons_reload_sreg <= ~skip_cons_reload_sreg;
   end
   

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      pulse_width_cntr <= 4'b0;
    else if(pld_clk_inuse_rise_reg & skip_cons_reload_sreg)
      pulse_width_cntr <= 4'b0;
    else if(pulse_width_cntr < 4'b1111)
      pulse_width_cntr <= pulse_width_cntr + 4'h1;
  end 

assign cons_load_pulse_clear = (pulse_width_cntr == 4'b1110);

/// extend the load signal to 16 clocks
always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      reload_nph_cons_from_hip_reg <= 1'b0;
    else if(pld_clk_inuse_rise & skip_cons_reload_sreg)
      reload_nph_cons_from_hip_reg <= 1'b1;
    else if (cons_load_pulse_clear)
      reload_nph_cons_from_hip_reg <= 1'b0;
  end 
assign tx_cons_cred_sel = reload_nph_cons_from_hip_reg;

//assign np_tlp_sent = sm_rd_hdr | sm_rbp_hdr | (txrp_sop);
assign np_tlp_sent = sm_rd_hdr | sm_rbp_hdr | (txrp_sop & txrp_np);

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
       nph_cred_cons_reg <= 8'h0;
    else if(reload_nph_cons_from_hip_reg)
       nph_cred_cons_reg <= TxCredNpHdrLimit_i; // this is consumed value from Hip based on mux select
    else if (np_tlp_sent ^ TxCredHipCons_i[3])   
       nph_cred_cons_reg <= nph_cred_cons_reg + 1;
    else if (np_tlp_sent & TxCredHipCons_i[3])
       nph_cred_cons_reg <= nph_cred_cons_reg + 2;
  end
  
always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
       nph_cred_limit_reg <= 8'h0;
    else
       nph_cred_limit_reg <= TxCredNpHdrLimit_i;
  end

assign nph_cred_sub = nph_cred_limit_reg - nph_cred_cons_reg;

assign np_header_avail = nph_cred_sub <= 128 | TxCredInfinit_i[3]; 

always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      tx_state <= TX_IDLE;
    else
      tx_state <= tx_nxt_state;
  end

// state machine next state gen

always @*
   begin
      case(tx_state)
         TX_IDLE :
            if(np_header_avail_reg & ~RdBypassFifoEmpty_i & (outstanding_tag_cntr != 0) & output_fifo_ok_reg & ~rx_only & txrp_sm_idle & ~RpTLPReady_i) // use tag_available instead of *_reg because it is not updated in time by read_header state
               tx_nxt_state <= TX_POP_BPFIFO;
            else if(~CmdFifoEmpty_i & txrp_sm_idle & ~RpTLPReady_i)
               tx_nxt_state <= TX_CHECK_CMDFIFO; // read the command fifo
            else
               tx_nxt_state <= TX_IDLE; // read the command fifo
         
         TX_POP_BPFIFO:
            tx_nxt_state <= TX_CHECK_BPFIFO;
       
         TX_CHECK_BPFIFO:           
           if(tag_available_reg & np_header_avail_reg)
            tx_nxt_state <= TX_RBP_HDR;
           else
             tx_nxt_state <= TX_CHECK_BPFIFO;
    
         TX_RBP_HDR:
            tx_nxt_state <= TX_IDLE;
       
         TX_CHECK_CMDFIFO:
            if(msi_req)
               tx_nxt_state <= TX_MSI_REQ;
            else if(is_rd & (~np_header_avail_reg | ~tag_available_reg) | (is_rd & ~RdBypassFifoEmpty_i) )
               tx_nxt_state <= TX_STORE_RD;
            else if(is_rd & tag_available_reg & output_fifo_ok_reg & np_header_avail_reg)
               tx_nxt_state <= TX_RD_HDR;
            else if(is_wr & output_fifo_ok_reg)
               tx_nxt_state <= TX_WR_HDR; 
            else if(is_cpl & output_fifo_ok_reg)
               tx_nxt_state <= TX_CPL_HDR;
            else
               tx_nxt_state <= TX_CHECK_CMDFIFO;
           
         TX_STORE_RD: 
            tx_nxt_state <= TX_IDLE;
       
         TX_RD_HDR:
            tx_nxt_state <= TX_IDLE;
    
         TX_WR_HDR:
            if((hdr_3dw_offset_4 | hdr_3dw_offset_C) & dw_len == 1)
               tx_nxt_state <= TX_IDLE;
            else
               tx_nxt_state <= TX_WR_DATA;
        
         TX_WR_DATA:
            if(wr_dat_eop_mux & (CmdFifoEmpty_i | ~RdBypassFifoEmpty_i | RpTLPReady_i))
               tx_nxt_state <= TX_IDLE;
            else if(wr_dat_eop_mux & ~CmdFifoEmpty_i )
               tx_nxt_state <= TX_CHECK_CMDFIFO;
            else if(~output_fifo_ok_reg)
               tx_nxt_state <= TX_WAIT;
            else
               tx_nxt_state <= TX_WR_DATA;
      
         TX_WAIT:
            if(output_fifo_ok_reg & is_cpl & cpl_dat_cntr == 1)
               tx_nxt_state <= TX_IDLE;
            else if(output_fifo_ok_reg & is_cpl)
                 tx_nxt_state <= TX_CPL_DATA;
            else if(output_fifo_ok_reg & is_wr)
               tx_nxt_state <= TX_WR_DATA;
            else
               tx_nxt_state <= TX_WAIT;
       
         TX_CPL_HDR:
            if((hdr_3dw_offset_4 | hdr_3dw_offset_C) & dw_len == 1 | is_abort_cpl)
               tx_nxt_state <= TX_IDLE;
            else
               tx_nxt_state <= TX_CPL_DATA;
          
         TX_CPL_DATA:
            if((cpl_dat_cntr == 1))
               tx_nxt_state <= TX_IDLE;
            else if(~output_fifo_ok_reg)
               tx_nxt_state <= TX_WAIT;
            else
               tx_nxt_state <= TX_CPL_DATA;
          
         TX_WAIT_ADPT_EMPTY:
            if (TxAdapterFifoEmpty_i | adapter_fifo_write_cntr == 16)
               tx_nxt_state <= TX_MSI_REQ;
            else
               tx_nxt_state <= TX_WAIT_ADPT_EMPTY;
          
         TX_MSI_REQ:
             if(irq_ack_reg)
                tx_nxt_state <= TX_IDLE;
             else
                tx_nxt_state <= TX_MSI_REQ;
           
         default:
            tx_nxt_state <= TX_IDLE;
       
      endcase
 end      
     

// state machine assignments
assign sm_idle          = ~tx_state[0];               
assign sm_check_cmdfifo = tx_state[1];                
assign sm_rd_hdr        = tx_state[2];                
assign sm_wr_hdr        = tx_state[3];                
assign sm_wr_data       = tx_state[4];                
assign sm_cpl_hdr       = tx_state[5];                
assign sm_cpl_data      = tx_state[6];                
assign sm_msi_req       = tx_state[7];                
assign sm_pop_bpfifo    = tx_state[8];                
assign sm_rbp_hdr       = tx_state[9];                
assign sm_store_rd      = tx_state[10];               
assign sm_wait          = tx_state[11];               
assign sm_check_bpfifo  = tx_state[12];    

// Completion DPRAM read address counter      

// counter to keep track of number of 128-bit data to read
/// from the Avalon bus (different from PCIe due to different address alingment scheme)
    
    always @ *
      begin
        case (tx_modlen_sel)   
          6'b0000_00:  txavl_modlen_qdword[7:0] <= dw_len[9:2];       // data is 128-bit aligned and modulo-128               
          6'b0000_01:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;   // data is 128-bit aligned                              
          6'b0000_10:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;   // data is 128-bit aligned                              
          6'b0000_11:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;   // data is 128-bit aligned                              
          6'b0100_00:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;                                                           
          6'b0100_01:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;                                                           
          6'b0100_10:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;                                                           
          6'b0100_11:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;                                                           
          6'b1000_00:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;                                                           
          6'b1000_01:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;                                                           
          6'b1000_10:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;                                                           
          6'b1000_11:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 2;                                                           
          6'b1100_00:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;                                                           
          6'b1100_01:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 1;                                                           
          6'b1100_10:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 2;                                                           
          6'b1100_11:  txavl_modlen_qdword[7:0] <= dw_len[9:2] + 2;                                                           
          default:     txavl_modlen_qdword[7:0] <= dw_len[9:2];                                                               
        endcase
      end 



always @(posedge Clk_i or negedge Rstn_i)
  begin
     if(~Rstn_i)
       cpl_clken_cntr <= 8'h0;
     else if(sm_check_cmdfifo & is_cpl) // load
       cpl_clken_cntr <= txavl_modlen_qdword; 
     else if(cpl_dat_clken)
       cpl_clken_cntr <= cpl_clken_cntr - 1;
  end


assign tx_address_lsb = rdbp_fifo_sel?  {RdBypassFifoDat_i[3:2], 2'b00}: {CmdFifoDat_i[3:2], 2'b00}; 
assign addr_bit2    = rdbp_fifo_sel? RdBypassFifoDat_i[2]: CmdFifoDat_i[2];       
assign cpl_dat_clken = ((sm_cpl_data ) |  (sm_wait & output_fifo_ok_reg & is_cpl) | (sm_cpl_hdr & (tx_address_lsb !=0))) & cpl_clken_cntr != 0 & ~is_abort_cpl;   
assign CplBuffRdAddr_o[6:0] = cpl_dat_clken & ~is_flush_cpl? (cpl_addr_reg + 1) : cpl_addr_reg;

always @(posedge Clk_i or negedge Rstn_i)
  begin
     if(~Rstn_i)
       cpl_addr_reg <= 9'h0;
     else
       cpl_addr_reg <= CplBuffRdAddr_o;
  end





// adjusted Dw Length for CPL 3-DW header only
/// this is the number adjusted for the PCIe TLP

assign tx_modlen_sel = {tx_address_lsb, dw_len[1:0]};
    
    always @ *
      begin
        case (tx_modlen_sel)   
          6'b0000_00:  tx_modlen_qdword[7:0] <= dw_len[9:2];       // data is 128-bit aligned and modulo-128
          6'b0000_01:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 1;   // data is 128-bit aligned
          6'b0000_10:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 1;   // data is 128-bit aligned
          6'b0000_11:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 1;   // data is 128-bit aligned
          
          6'b0100_00:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 1; 
          6'b0100_01:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 1;   
          6'b0100_10:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 2;
          6'b0100_11:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 2;
          
          6'b1000_00:  tx_modlen_qdword[7:0] <= dw_len[9:2];
          6'b1000_01:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 1;
          6'b1000_10:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 1;
          6'b1000_11:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 1;
          
          6'b1100_00:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 1;
          6'b1100_01:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 1;
          6'b1100_10:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 2;
          6'b1100_11:  tx_modlen_qdword[7:0] <= dw_len[9:2] + 2;
               
          default:     tx_modlen_qdword[7:0] <= dw_len[9:2];  
        endcase
      end


/// completion data counter
always @(posedge Clk_i or negedge Rstn_i)
  begin
     if(~Rstn_i)
       cpl_dat_cntr <= 8'h0;
     else if(is_cpl & sm_check_cmdfifo)
       cpl_dat_cntr <= tx_modlen_qdword;
     else if( cpl_dat_clken & !(tx_address_lsb == 8 & sm_cpl_hdr) & cpl_dat_cntr != 0)
       cpl_dat_cntr <= cpl_dat_cntr - 1;
  end
    
/// Tx Completion buffer release

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     begin
      sm_cpldata_reg <= 1'b0;
      sm_cpl_hdr_reg <= 1'b0;
    end
    else
     begin
      sm_cpldata_reg <= sm_cpl_data;
      sm_cpl_hdr_reg <= sm_cpl_hdr;
     end
  end


assign TxCplSent_o = is_cpl & tlp_eop;  // end of CPL data phases 

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      cpl_sent_reg <= 0;
    else if(is_cpl & sm_check_cmdfifo)
      cpl_sent_reg <= txavl_modlen_qdword[4:0];
  end
  
assign TxCplLineSent_o[4:0] =  is_abort_cpl? 5'h0:  cpl_sent_reg[4:0];



always @(posedge Clk_i or negedge Rstn_i)
  begin
    if (~Rstn_i)
      rxcplbuff_free_reg <= 1'b0;
    else
      rxcplbuff_free_reg <= RxCplBuffFree_i;
  end


assign up_cpl_cnt    = ~rxcplbuff_free_reg & RxCplBuffFree_i;   



always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     outstanding_tag_cntr <= max_outstanding_read ;
    else if((sm_rd_hdr | sm_rbp_hdr)  & ~up_cpl_cnt) 
      outstanding_tag_cntr <= outstanding_tag_cntr - 1;
    else if(up_cpl_cnt & ~(sm_rd_hdr | sm_rbp_hdr))
      outstanding_tag_cntr <= outstanding_tag_cntr + 1;
  end

assign CplPending_o = (outstanding_tag_cntr != max_outstanding_read);

/// Command FIFo Interface
assign to_pop_bpfifo  = (np_header_avail_reg & ~RdBypassFifoEmpty_i & (outstanding_tag_cntr != 0) & output_fifo_ok_reg & ~rx_only );  // will read bypass fifo on the next clock
assign CmdFifoRdReq_o = (sm_idle & ~CmdFifoEmpty_i & ~to_pop_bpfifo & txrp_sm_idle & ~RpTLPReady_i) | (sm_wr_data & RdBypassFifoEmpty_i &  ~RpTLPReady_i & (wr_dat_eop_mux  & ~CmdFifoEmpty_i));      

// Write Data FIFO Interface
always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     wrdat_fifo_rd_reg <= 1'b0 ;
    else 
       wrdat_fifo_rd_reg <= WrDatFifoRdReq_o;
   end
  
 assign WrDatFifoRdReq_o = (sm_wr_hdr & ~wrdat_fifo_eop) |(sm_wr_data & output_fifo_ok_reg & ~wrdat_fifo_eop) | (sm_check_cmdfifo & is_wr & output_fifo_ok_reg & ~msi_req) | (sm_wait & is_wr & output_fifo_ok_reg & ~wrdat_fifo_eop);
 
 

// Tx Header TLP

assign rdbp_fifo_sel = sm_check_bpfifo | sm_rbp_hdr;

assign addr_low      =  rdbp_fifo_sel? RdBypassFifoDat_i[31:0]: CmdFifoDat_i[31:0];
assign addr_hi       =  rdbp_fifo_sel? RdBypassFifoDat_i[63:32]: CmdFifoDat_i[63:32];
assign is_rd_32      =  rdbp_fifo_sel? RdBypassFifoDat_i[64]: CmdFifoDat_i[64];
assign is_rd_64      =  rdbp_fifo_sel? RdBypassFifoDat_i[65]: CmdFifoDat_i[65];
assign is_wr_32      =  rdbp_fifo_sel? RdBypassFifoDat_i[66]: CmdFifoDat_i[66];
assign is_wr_64      =  rdbp_fifo_sel? RdBypassFifoDat_i[67]: CmdFifoDat_i[67];
assign is_cpl        =  rdbp_fifo_sel? 1'b0: (CmdFifoDat_i[68] | rx_only);
assign is_flush_cpl  =  rdbp_fifo_sel? 1'b0: CmdFifoDat_i[69] & CmdFifoDat_i[68];
assign is_abort_cpl  =  rdbp_fifo_sel? 1'b0: CmdFifoDat_i[31] & CmdFifoDat_i[68];

assign is_rd = (is_rd_64 | is_rd_32) & ~rx_only;
assign is_wr = (is_wr_64 | is_wr_32) & ~rx_only;


// create header

always @(is_wr_64, is_rd_64, is_wr_32, is_rd_32)
  begin
    case({is_wr_64, is_rd_64, is_wr_32, is_rd_32})
      4'b0001 : cmd = 8'h00;
      4'b0010 : cmd = 8'h40;
      4'b0100 : cmd = 8'h20;
      default : cmd = 8'h60;
    endcase
  end

generate if(ADDRESS_32BIT == 1)
 begin
  always @(posedge Clk_i or negedge Rstn_i)
    if(~Rstn_i)
        cmdfifo_addr_reg <= 64'h0;
    else if(sm_check_cmdfifo | sm_check_bpfifo)
        cmdfifo_addr_reg <= {32'h0, addr_low};
 end
else 
  begin
  always @(posedge Clk_i or negedge Rstn_i)
    if(~Rstn_i)
        cmdfifo_addr_reg <= 64'h0;
    else if(sm_check_cmdfifo | sm_check_bpfifo)
        cmdfifo_addr_reg <= {addr_hi, addr_low};
   end
endgenerate


generate if(ADDRESS_32BIT == 1)
  begin
    assign adr_hi       =  (is_wr_64 | is_rd_64)? 32'h0: cmdfifo_addr_reg[31:0];
    assign adr_low      =  cmdfifo_addr_reg[31:0];
  end
else
   begin
    assign adr_hi       =  cmdfifo_addr_reg[63:32];
    assign adr_low      =  cmdfifo_addr_reg[31:0];
  end
endgenerate


assign wrdat_fifo_eop = TxWrDat_i[128];
assign tlp_dw2_sel = (is_wr_32 | is_rd_32);           
assign tlp_dw2     = tlp_dw2_sel? adr_low : adr_hi;
assign tlp_dw3_sel = (is_wr_32 | is_rd_32);           
assign tlp_dw3     = (tlp_dw3_sel & tx_address_lsb[2])? tx_data[127:96] : adr_low[31:0];


assign req_header1 = {requestor_id[15:0], req_tag_reg[7:0], lbe_reg, fbe_reg, cmd_reg[7:0], 8'h0, 6'h0, dw_len_reg[9:0]};
assign req_header2 = { tlp_dw3, tlp_dw2 };

assign cpl_header1 = {cpl_cplter_id, is_abort_cpl ,3'b000, cpl_remain_bytes_reg , 1'b0, ~is_abort_cpl, 6'b001010, 1'b0, cpl_tc_reg, 4'h0, 2'h0, cpl_attr_reg, 2'b00, dw_len_reg};
assign cpl_header2 = { tx_data[127:96], cpl_req_id_reg, cpl_tag_reg, 1'b0,lower_adr_reg};

assign cmd_header1 = is_cpl? cpl_header1 : req_header1; 
assign cmd_header2 = is_cpl? cpl_header2 : req_header2; 


/// Tx data TLP   
generate if (CB_PCIE_RX_LITE == 0)
   assign tx_completion_data = is_flush_cpl? 128'h0 : TxCplDat_i;
else
   assign tx_completion_data = is_flush_cpl? 128'h0 : {TxCplDat_i[31:0], TxCplDat_i[31:0],TxCplDat_i[31:0], TxCplDat_i[31:0]};  // duplicate 32-bit low and high
endgenerate

assign tlp_3dw_header = is_cpl | is_wr_32 | is_rd_32 | is_abort_cpl | is_flush_cpl;
assign tlp_buff_data = (sm_wr_data | sm_wr_hdr)? TxWrDat_i : tx_completion_data;


always @(posedge Clk_i or negedge Rstn_i)  // state machine registers  
  begin                                                                
    if(~Rstn_i)             
     begin                                           
      tlp_holding_reg <= 128'h0;
     end
    else if(wrdat_fifo_rd_reg | cpl_dat_clken)
     begin
      tlp_holding_reg <= tlp_buff_data;
     end
  end
  
  
  
  always @(posedge Clk_i or negedge Rstn_i)  // state machine registers  
  begin                                                                
    if(~Rstn_i)             
      wr_dat_eop_holding_reg <= 1'b0;
    else if(sm_check_cmdfifo)
      wr_dat_eop_holding_reg <= 1'b0;
    else if(wrdat_fifo_rd_reg)
      wr_dat_eop_holding_reg <= wrdat_fifo_eop;
  end                    
  
  
assign wr_dat_eop_sel = {tlp_3dw_header, tx_address_lsb[3:0]}; // might need to use len[1:0]

//    always @ *
//      begin
//        case (wr_dat_eop_sel)   
//          5'b0_0000:  wr_dat_eop_mux <= wr_dat_eop_holding_reg;   
//          5'b0_0100:  wr_dat_eop_mux <= wr_dat_eop_holding_reg;   
//          5'b0_1000:  wr_dat_eop_mux <= wrdat_fifo_eop;   // Harry
//          5'b0_1100:  wr_dat_eop_mux <= wrdat_fifo_eop;   // Harry
//          
//          5'b1_0000:  wr_dat_eop_mux <= wr_dat_eop_holding_reg;   
//          5'b1_0100:  wr_dat_eop_mux <= wrdat_fifo_eop;   
//          5'b1_1000:  wr_dat_eop_mux <= wrdat_fifo_eop; 
//          5'b1_1100:  wr_dat_eop_mux <= wrdat_fifo_eop;  
//          
//          default:   wr_dat_eop_mux <= 1'b0;  
//        endcase
//      end                                     


assign holding_eop_sel =    (wr_dat_eop_sel == 5'b0_0000) |
                            (wr_dat_eop_sel == 5'b0_0100) |
                            (wr_dat_eop_sel == 5'b0_1000) & tx_empty_int |
                            (wr_dat_eop_sel == 5'b0_1100) & tx_empty_int |      
                            (wr_dat_eop_sel == 5'b1_1000) & tx_empty_int |     
                            (wr_dat_eop_sel == 5'b1_0100)  & tx_empty_int |   
                            (wr_dat_eop_sel == 5'b1_0000);

assign wr_dat_eop_mux =  holding_eop_sel? wr_dat_eop_holding_reg : wrdat_fifo_eop;




       
always @* 
   begin
       if (tlp_3dw_header & is_cpl) begin    // 3DW header
           case (tx_address_lsb)
               4'h0: tx_data = {tlp_buff_data[127:96], tlp_buff_data[95:64], tlp_buff_data[63:32], tlp_buff_data[31:0]}; // start addr is on 128-bit addr boundary
               4'h4: tx_data = {tlp_buff_data[63:32],  tlp_buff_data[31:0],  tlp_holding_reg[127:96], tlp_holding_reg[95:64]};          // start addr is 1DW offset from 128-bit addr boundary  (first QW is saved from desc phase, and appended to next QW))
               4'h8: tx_data = {tlp_buff_data[63:32],  tlp_buff_data[31:0],  tlp_holding_reg[127:96], tlp_holding_reg[95:64]};          // first QW is shifted left by a QW
               4'hC: tx_data = {tlp_buff_data[127:96], tlp_buff_data[95:64], tlp_buff_data[63:32], tlp_buff_data[31:0]};  // start addr is 1DW + 1QW offset from 128-bit addr boundary  (first QW is saved from desc phase, and placed in high QW of next phase.  all other dataphases are delayed 1 clk.)
               default: tx_data = 128'h0;
           endcase
       end
       else if(tlp_3dw_header & is_wr_32) begin
            case (tx_address_lsb)
               4'h0: tx_data = {tlp_holding_reg[127:96], tlp_holding_reg[95:64], tlp_holding_reg[63:32], tlp_holding_reg[31:0]}; // start addr is on 128-bit addr boundary
               4'h4: tx_data = {tlp_buff_data[63:32],  tlp_buff_data[31:0],  tlp_holding_reg[127:96], tlp_holding_reg[95:64]};          // start addr is 1DW offset from 128-bit addr boundary  (first QW is saved from desc phase, and appended to next QW))
               4'h8: tx_data = {tlp_buff_data[63:32],  tlp_buff_data[31:0],  tlp_holding_reg[127:96], tlp_holding_reg[95:64]};          // first QW is shifted left by a QW
               4'hC: tx_data = {tlp_buff_data[127:96], tlp_buff_data[95:64], tlp_buff_data[63:32], tlp_buff_data[31:0]};  // start addr is 1DW + 1QW offset from 128-bit addr boundary  (first QW is saved from desc phase, and placed in high QW of next phase.  all other dataphases are delayed 1 clk.)
               default: tx_data = 128'h0;
           endcase
       end
       else begin
           // for 4DW header pkts, only QW alignment adjustment is required
           case (tx_address_lsb)
               4'h0: tx_data = {tlp_holding_reg[127:96], tlp_holding_reg[95:64], tlp_holding_reg[63:32], tlp_holding_reg[31:0]}; 
               4'h4: tx_data = {tlp_holding_reg[127:96], tlp_holding_reg[95:64], tlp_holding_reg[63:32], tlp_holding_reg[31:0]};        
               4'h8: tx_data = {tlp_buff_data[63:32], tlp_buff_data[31:0], tlp_holding_reg[127:96], tlp_holding_reg[95:64]};        
               4'hC: tx_data = {tlp_buff_data[63:32], tlp_buff_data[31:0], tlp_holding_reg[127:96], tlp_holding_reg[95:64]};
               default: tx_data = 128'h0;
           endcase
       end
   end

// mux header and data 

assign tlp_data_sel = (sm_wr_hdr | sm_rd_hdr | sm_rbp_hdr | sm_cpl_hdr);
assign tlp_data     = tlp_data_sel? {cmd_header2, cmd_header1} : tx_data;

// sop - eop - empty

assign tlp_sop =   (sm_wr_hdr | sm_rd_hdr | sm_rbp_hdr | sm_cpl_hdr);

assign tlp_eop = (sm_cpl_data & (cpl_dat_cntr == 1)) | (sm_wait & output_fifo_ok_reg &  (cpl_dat_cntr == 1)) |
                 (sm_wr_hdr & dw_len_reg == 1 & tx_address_lsb[2] & is_wr_32) |
                 (sm_wr_data  & (wr_dat_eop_mux)) |
                 (sm_rd_hdr | sm_rbp_hdr) |
                 (sm_cpl_hdr & ((dw_len == 1 & tx_address_lsb[2]) | is_abort_cpl));
 
           
assign tlp_emp_sel = {tlp_3dw_header, tx_address_lsb[2], dw_len_reg[1:0]};           
                                                                                          
    always @ *
      begin
        case (tlp_emp_sel)   
          4'b0000:  tx_empty_int <= 1'b0;   
          4'b0001:  tx_empty_int <= 1'b1;   
          4'b0010:  tx_empty_int <= 1'b1; 
          4'b0011:  tx_empty_int <= 1'b0;   
          
          4'b0100:  tx_empty_int <= 1'b1; 
          4'b0101:  tx_empty_int <= 1'b1; 
          4'b0110:  tx_empty_int <= 1'b0; 
          4'b0111:  tx_empty_int <= 1'b0; 
                                     
          4'b1000:  tx_empty_int <= 1'b0; 
          4'b1001:  tx_empty_int <= 1'b1; 
          4'b1010:  tx_empty_int <= 1'b1; 
          4'b1011:  tx_empty_int <= 1'b0;      
          
          4'b1100:  tx_empty_int <= 1'b0; 
          4'b1101:  tx_empty_int <= 1'b0; 
          4'b1110:  tx_empty_int <= 1'b1; 
          4'b1111:  tx_empty_int <= 1'b1; 
          
          default:  tx_empty_int <= 1'b0;  
        endcase
      end                                                                                        

assign tlp_empty = tlp_eop & tx_empty_int & ~is_rd;


assign output_fifo_wrreq = (sm_wr_data | sm_cpl_data) | 
                           (sm_rd_hdr | sm_rbp_hdr | sm_wr_hdr | sm_cpl_hdr ) | 
                           (sm_wait & output_fifo_ok_reg & is_cpl) |
                           (txrp_sm_stream);
                                             
assign output_fifo_data_in[130:0]  = txrp_sm_idle? {tlp_empty, tlp_eop, tlp_sop, tlp_data} : {txrp_tlp_reg[130],txrp_tlp_reg[129],txrp_tlp_reg[128],txrp_tlp_reg[127:0]}; 

/// register fifo input and write request
always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
     begin
      output_fifo_wrreq_reg <= 0;
      output_fifo_data_in_reg <= 0;
    end
    else
      begin
      output_fifo_wrreq_reg <= output_fifo_wrreq;    
      output_fifo_data_in_reg <= output_fifo_data_in;
      end
  end
                                             
/// Output FIFO

	scfifo	tx_output_fifo (
				.rdreq (output_fifo_rdreq),
				.clock (Clk_i),
				.wrreq (output_fifo_wrreq_reg),
				.data (output_fifo_data_in_reg),
				.usedw (output_fifo_wrusedw),
				.empty (output_fifo_rdempty),
				.q (output_fifo_data_out),
				.full (),
				.aclr (~Rstn_i),
				.almost_empty (),
				.almost_full (),
				.sclr ()
				);
	defparam
		tx_output_fifo.add_ram_output_register = "ON",
		tx_output_fifo.intended_device_family = "Stratix IV",
		tx_output_fifo.lpm_numwords = 16,
		tx_output_fifo.lpm_showahead = "OFF",
		tx_output_fifo.lpm_type = "scfifo",
		tx_output_fifo.lpm_width = 131,
		tx_output_fifo.lpm_widthu = 4,
		tx_output_fifo.overflow_checking = "ON",
		tx_output_fifo.underflow_checking = "ON",
		tx_output_fifo.use_eab = "ON";


/// Streaming interface to the HIP

// output registers
always @ (posedge Clk_i or negedge Rstn_i)
  begin
     if (~Rstn_i)
       tx_tlp_out_reg <= 128'h0;
     else if(fifo_transmit)
       tx_tlp_out_reg <= output_fifo_data_out[127:0];
  end

always @ (posedge Clk_i or negedge Rstn_i)
  begin
     if (~Rstn_i)
      begin
       tx_sop_out_reg <= 1'b0;
       tx_eop_out_reg <= 1'b0; 
       tx_empty_out_reg <= 1'b0;
      end
     else if(fifo_transmit)
      begin
       tx_sop_out_reg <= output_fifo_data_out[128];
       tx_eop_out_reg <= output_fifo_data_out[129];
       tx_empty_out_reg <= output_fifo_data_out[130];
      end
     else if(output_transmit)
      begin
       tx_sop_out_reg <= 1'b0;
       tx_eop_out_reg <= 1'b0;
       tx_empty_out_reg <= 1'b0;
      end
  end
  
always @ (posedge Clk_i or negedge Rstn_i)
  begin
     if (~Rstn_i)
       output_valid_reg <= 1'b0;
     else if(fifo_transmit)
       output_valid_reg <= 1'b1;
     else if (output_transmit)
       output_valid_reg <= 1'b0;
  end
  
always @ (posedge Clk_i or negedge Rstn_i)
  begin
     if (~Rstn_i)
       fifo_valid_reg <= 1'b0;
     else if(output_fifo_rdreq)
       fifo_valid_reg <= 1'b1;
     else if (fifo_transmit)
       fifo_valid_reg <= 1'b0;
  end
  
always @ (posedge Clk_i or negedge Rstn_i)
  begin
     if (~Rstn_i)
       tx_st_ready_reg <= 1'b0;
     else
       tx_st_ready_reg <= TxStReady_i;
  end
  
  
assign output_transmit = output_valid_reg & tx_st_ready_reg;
assign fifo_transmit   = fifo_valid_reg & (~output_valid_reg | output_valid_reg & output_transmit);
assign output_fifo_rdreq = ~output_fifo_rdempty & (~fifo_valid_reg | fifo_valid_reg & fifo_transmit);

assign TxStData_o =tx_tlp_out_reg;
assign TxStSop_o  = tx_sop_out_reg;
assign TxStEop_o  = tx_eop_out_reg; 
assign TxStEmpty_o[0] = tx_empty_out_reg;
assign TxStEmpty_o[1] = 1'b0;
assign TxStValid_o = output_transmit;


// MSI REQUEST                
 assign MsiReq_o = sm_msi_req & MsiCsr_i[0];
 
 // INTx Request
 
// assign IntxReq_o = sm_msi_req & ~MsiCsr_i[0];

 // assign IntxReq_o = 1'b0;
 
 /// By pass buffer control
assign RdBypassFifoWrReq_o =  sm_store_rd;             
assign RdBypassFifoRdReq_o = sm_pop_bpfifo;

/// ROOT PORT INTERFACE 

always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      txrp_state <= TXRP_IDLE;
    else
      txrp_state <= txrp_nxt_state;
  end
  
always @*
   begin
      case(txrp_state)
         TXRP_IDLE :
            if(sm_idle & output_fifo_ok_reg & RpTLPReady_i) 
               txrp_nxt_state <= TXRP_FIFO_PREFETCH0;  // read fifo and start to stream
            else
               txrp_nxt_state <= TXRP_IDLE; 
         
         TXRP_FIFO_PREFETCH0 :
            txrp_nxt_state <= TXRP_FIFO_PREFETCH1; 
            
         TXRP_FIFO_PREFETCH1 :
             txrp_nxt_state <= TXRP_STREAM;
         
         TXRP_STREAM :                         
              if(txrp_eop_reg)                        
                 txrp_nxt_state <= TXRP_RESET;     
              else if(~output_fifo_ok_reg)                                      
                txrp_nxt_state <= TXRP_WAIT;
              else
                txrp_nxt_state <= TXRP_STREAM;
        
         TXRP_WAIT:
           if(output_fifo_ok_reg)
              txrp_nxt_state <= TXRP_STREAM;
           else
              txrp_nxt_state <= TXRP_WAIT;        
              
         TXRP_RESET:
           if(~RpTLPReady_i)
            txrp_nxt_state <= TXRP_IDLE;
           else
             txrp_nxt_state <= TXRP_RESET; 
             
        default:
          txrp_nxt_state <= TXRP_IDLE; 
      endcase
   end
    
assign txrp_sm_idle       = txrp_state == TXRP_IDLE;    
assign txrp_sm_prefetch0  = txrp_state == TXRP_FIFO_PREFETCH0;
assign txrp_sm_prefetch1  = txrp_state == TXRP_FIFO_PREFETCH1;
assign txrp_sm_stream     = txrp_state == TXRP_STREAM;
assign txrp_done          = txrp_sm_stream & txrp_eop_reg;
assign RpTLPAck_o         = txrp_done;

assign TxRpFifoRdReq_o = txrp_sm_prefetch0 | txrp_sm_prefetch1 | txrp_sm_stream;

/// latch rp header
always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      txrp_header_reg[130:0] <= 64'h0;
    else if(txrp_sm_prefetch1)
      txrp_header_reg[130:0] <= TxRpFifoData_i[130:0];
  end
  
  always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      latch_rp_header_reg <= 1'b0;
    else
      latch_rp_header_reg <= txrp_sm_prefetch1;
  end
  
  /// RP TLP pipeline reg
always @(posedge Clk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      txrp_tlp_reg[130:0] <= 131'h0;
    else if(txrp_sm_prefetch1 | txrp_sm_stream)
      txrp_tlp_reg[130:0] <= TxRpFifoData_i[130:0];
  end
  
  assign txrp_eop_reg = txrp_tlp_reg[129];
  
  
 assign txrp_sop = latch_rp_header_reg & txrp_np; // rising edge
  
endmodule
