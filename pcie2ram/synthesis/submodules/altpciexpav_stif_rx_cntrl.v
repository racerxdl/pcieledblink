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


module altpciexpav_stif_rx_cntrl


# ( 

     parameter              CG_COMMON_CLOCK_MODE   = 0,    
     parameter              CB_A2P_PERF_PROFILE    = 3,
     parameter              CB_P2A_PERF_PROFILE    = 3,
     parameter              CB_PCIE_MODE           = 0,
     parameter              CB_PCIE_RX_LITE        = 0,
     parameter              CB_RXM_DATA_WIDTH      = 64,
     parameter              port_type_hwtcl        = "Native endpoint",
     parameter AVALON_ADDR_WIDTH = 32
     

)

  ( input          Clk_i,
    input          Rstn_i,
    input          AvlClk_i,
    input          RxmRstn_i,
    
    // Rx port interface to PCI Exp core
   output   reg                 RxStReady_o,
   output                    RxStMask_o,
   input   [63:0]           RxStData_i,
   input   [31:0]            RxStParity_i,
   input   [7:0]            RxStBe_i,
   input   [1:0]             RxStEmpty_i,
   input   [3:0]             RxStErr_i,
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
   
  
    
    input  [3:0]                          PndngRdFifoUsedW_i,
    input                                 PndngRdFifoEmpty_i,
    output                                PndgRdFifoWrReq_o,
    output [56:0]                         PndgRdHeader_o,
    input                                 RxRdInProgress_i,
    

   // Completion data dual port ram interface
    output  [8:0] CplRamWrAddr_o,
    output [65:0] CplRamWrDat_o,
    output  CplRamWrEna_o,
    output  reg CplReq_o,
    output  reg [4:0] CplDesc_o,
    
    // Read respose module interface
    
    // Tx Completion interface
    input          TxCpl_i,
    input  [9:0]  TxCplLen_i,// this is modified len (+1, +2, or unchanged) (qw)
    
      // cfg signals
   input      [31:0]                    DevCsr_i,    
        /// paramter signals
    input  [31:0] cb_p2a_avalon_addr_b0_i,
    input  [31:0] cb_p2a_avalon_addr_b1_i,
    input  [31:0] cb_p2a_avalon_addr_b2_i,
    input  [31:0] cb_p2a_avalon_addr_b3_i,
    input  [31:0] cb_p2a_avalon_addr_b4_i,
    input  [31:0] cb_p2a_avalon_addr_b5_i,
    input  [31:0] cb_p2a_avalon_addr_b6_i,
    input  [227:0] k_bar_i,
    input          TxRespIdle_i,
    output         rxcntrl_sm_idle
    
  );
  
//state machine encoding
  localparam RX_IDLE          = 17'h00000;   
  localparam RX_RD_HEADER2    = 17'h00003;
  localparam RX_CHECK_HEADER  = 17'h00005;
  localparam RX_WRDAT_PRE     = 17'h00009;
  localparam RX_WRENA         = 17'h00011;
  localparam RX_WRWAIT        = 17'h00021;
  localparam RX_STORE_RD      = 17'h00041;
  localparam RX_RDENA         = 17'h00081;
  localparam RX_RDTAG         = 17'h00101;
  localparam RX_LD_PNDGTXRD   = 17'h00201;
  localparam RX_CPLDAT_PRE    = 17'h00401;
  localparam RX_CPLENA        = 17'h00801;
  localparam RX_CPLWAIT       = 17'h01001;
  localparam RX_CPLDONE       = 17'h02001;  
  localparam RX_PIPE          = 17'h04001;  
  localparam RX_MSG_DUMP      = 17'h08001;         
  localparam RX_RPCPL_DATA    = 17'h10001;

  //define the clogb2 constant function
   function integer clogb2;
      input [31:0] depth;
      begin
         depth = depth - 1 ;
         for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1)
           depth = depth >> 1 ;       
      end
   endfunction // clogb2
   
   
/// Temp P   
   

localparam AST_WIDTH  = 64;
localparam CB_RX_CD_BUFFER_DEPTH = 16;
localparam CB_RX_CPL_BUFFER_DEPTH = (CB_A2P_PERF_PROFILE == 1)? 128 : 512;
localparam RXINPUT_BUFF_ADDR_WIDTH     = clogb2(CB_RX_CD_BUFFER_DEPTH) ;   
localparam RX_CPL_BUFF_ADDR_WIDTH     =   clogb2(CB_RX_CPL_BUFFER_DEPTH) ;
  

wire is_wr;
wire is_flush;
wire is_rd;
wire is_cpl_wd;
wire is_cpl_wod;    
wire is_cpl;
wire is_msg;
wire is_msg_wd;
wire is_msg_wod;
wire last_cpl;

wire rd_hdr;
wire chk_hdr;
reg  chk_hdr_reg;
wire  chk_hdr_rise;
wire wrena;
wire cplena;

wire [31:0] avl_translated_addr;
wire [63:0] avl_addr;
wire [4:0] cpl_tag;
wire [9:0] current_wr_pntr;
wire [9:0] rd_dw;
wire [9:0] qw_length;
wire [6:0] bar_hit;
reg  [6:0] barhit_reg;
wire [6:0] bar_hit_reg;

reg [16:0] rx_state;
reg [16:0] rx_nxt_state;
reg [63:0] avl_addr_reg;
reg [4:0]  cpl_tag_reg;
reg  last_cpl_reg;
reg [(CB_RXM_DATA_WIDTH/8)-1:0]  rd_be_reg;
wire [(CB_RXM_DATA_WIDTH/8)-1:0]  wr_cpl_be;
wire rd_be_x_select;
wire rd_be_normal_sel;
wire rx_only;
wire   [3:0]      input_fifo_wrusedw;
wire              input_fifo_wrreq;
reg             input_fifo_wrreq_reg;
wire   [81:0]     input_fifo_datain;  
reg    [81:0]     input_fifo_datain_reg; 
wire              input_fifo_rdempty;
wire   [81:0]    input_fifo_dataout;
wire             is_uns_rd_size;
wire             is_uns_wr_size;
reg    [127:0]   header_reg;
reg    [6:0]     bar_dec_reg;
  wire                       is_wr_cpl;
  wire  [10:0]               rx_dwlen;       
  wire  [63:0]               rx_addr;     
  reg   [63:0]               rx_addr_reg;   
  wire  [11:0]               cpl_bytecount;
  wire  [7:0]                rdreq_tag;    
  wire  [15:0]               requestor_id; 
  wire  [3:0]                rx_fbe; 
  wire  [3:0]                rx_lbe;
  wire  [1:0]                rx_attr;
  wire  [2:0]                rx_tc;         
  wire                       len_plus_2;
  wire                       len_plus_1;
  wire                       cd_fifo_ok;    
  reg                        pndgrd_fifo_ok_reg;
  reg                        cpl_buff_ok_reg;   
  wire                       rx_wrack;  
  wire                       rx_wrdata;
  wire                       store_rd;
  wire                       msg_dump;  
  wire                       rxrp_cpl_ena; 
  wire                       rxidle; 
  wire  [71:0]               wr_header; 
  wire  [71:0]               cpl_header;
  wire  [71:0]               rd_header; 
  wire                       wr_header_sel; 
  wire                       cpl_header_sel;
  wire                       rd_header_sel; 
  wire  [2:0]                header_sel;
  wire  [9:0]                txcpl_dw;
  reg  [10:0]                rx_modlen; // actual length requested on avalon    
  reg  [10:0]                rx_modlen_reg;
  reg  [10:0]                rx_dwlen_reg;
  reg  [10:0]                txcpl_buffer_size;
  wire                       hdr_3dw_unaligned;
  wire                       hdr_3dw_unaligned_at_fifo;
 
 wire                       tlp_3dw_header;
 wire                       rx_eop;
 wire                       odd_address_at_fifo;
 wire                       is_rx_lite_core;
 
 wire                       rxrp_fifo_dat_sel;                                                                 
 wire  [63:0]               rx_rpcpl_low_dat;             
 wire  [63:0]               rx_rpcpl_hi_dat;                                                           
 wire                       rx_rpcpl_sop;                                            
 wire                       rx_rpcpl_eop;            
 wire                       rx_rpcpl_empty;
 
 
reg    [5:0] cpl_add_cntr;
reg    [5:0] cpl_add_cntr_previous[7:0];
wire   [2:0] rx_cpltag_tlp;
reg         rx_eop_reg;
wire 	     input_fifo_rdreq;
wire 	     rd_hdr1;
wire 	     rd_hdr2;
wire 	     wrwait;
wire 	     rdena;
wire 	     header_pipe;
wire 	     odd_address;
wire         rxm_wait_request;
reg    [5:0] previous_bar_read;
wire         rxm_write;
wire        is_read_bar_changed;
wire        wr_1dw_fbe_eq_0;


assign rxm_wait_request = RxmWaitRequest_0_i & bar_hit[0] | RxmWaitRequest_1_i &  bar_hit[1] | RxmWaitRequest_2_i &  bar_hit[2]| RxmWaitRequest_3_i &  bar_hit[3] | RxmWaitRequest_4_i & bar_hit[4] |
                          RxmWaitRequest_5_i &  bar_hit[5];
                        
                

assign rxm_write = RxmWrite_0_o | RxmWrite_1_o | RxmWrite_2_o | RxmWrite_3_o  | RxmWrite_4_o |
                          RxmWrite_5_o;

generate if(CB_PCIE_MODE == 1)
 assign rx_only = 1'b1;
else
 assign rx_only = 1'b0;
endgenerate  
  
generate if(CB_PCIE_RX_LITE == 1)
 assign is_rx_lite_core = 1'b1;
else
 assign is_rx_lite_core = 1'b0;
endgenerate  
  
  
  /// Rx Input FIFO to hold Rx Streaming data
  /// This is needed since there is a 3 data phases latency when throtleing the Rx St interface
  //  This is also used for clock domain crossing purpuse (PCI-Avalon Clock)
  
  assign input_fifo_wrreq = RxStValid_i;
  assign input_fifo_datain = {RxStBarDec1_i[7:0],RxStEop_i,RxStSop_i,RxStBe_i[7:0],RxStData_i[63:0]};     
  
  always @(posedge AvlClk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
     begin
      input_fifo_wrreq_reg <= 0;
      input_fifo_datain_reg <= 0;
       RxStReady_o <= 0;
    end
    else
      begin
      input_fifo_wrreq_reg <= input_fifo_wrreq;
      input_fifo_datain_reg <= input_fifo_datain;
      RxStReady_o <= (input_fifo_wrusedw <= 6);
      end
  end
  
  
                 
	scfifo	rx_input_fifo (
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
	defparam
		rx_input_fifo.add_ram_output_register = "ON",
		rx_input_fifo.intended_device_family = "Stratix IV",
		rx_input_fifo.lpm_numwords = 12,
		rx_input_fifo.lpm_showahead = "OFF",
		rx_input_fifo.lpm_type = "scfifo",
		rx_input_fifo.lpm_width = 82,
		rx_input_fifo.lpm_widthu = 4,
		rx_input_fifo.overflow_checking = "ON",
		rx_input_fifo.underflow_checking = "ON",
		rx_input_fifo.use_eab = "ON";



/// checking the Rx completion Buffer for space

 always @(posedge Clk_i or negedge Rstn_i)
    begin
      if(~Rstn_i)
        txcpl_buffer_size <= 11'h100; // 256 DW available
      else if(store_rd & ~TxCpl_i)
        txcpl_buffer_size <= txcpl_buffer_size - rx_modlen_reg;
      else if(TxCpl_i & ~store_rd)
        txcpl_buffer_size <= txcpl_buffer_size + TxCplLen_i;
      else if(TxCpl_i & store_rd)
        txcpl_buffer_size <= txcpl_buffer_size + TxCplLen_i - rx_modlen_reg;
    end
    

// write burst counter to keep track of the number of data words sent to Avalon

always @(posedge AvlClk_i or negedge Rstn_i)  // state machine registers
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


always @(posedge AvlClk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      cpl_buff_ok_reg    <= 1'b0; 
    else if(chk_hdr)
      cpl_buff_ok_reg    <= (txcpl_buffer_size > rx_modlen_reg) | is_rx_lite_core; 
    else
       cpl_buff_ok_reg    <= 1'b0; 
  end



always @(posedge AvlClk_i or negedge Rstn_i)  // state machine registers
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
        if(input_fifo_wrusedw > 1 &  pndgrd_fifo_ok_reg)  // read the fifo at the same clock to reduce latency
          rx_nxt_state <= RX_RD_HEADER2;
        else
          rx_nxt_state <= RX_IDLE;
          
      RX_RD_HEADER2:   // read the second QWORD of header
          rx_nxt_state <= RX_PIPE;
          
     RX_PIPE:
        rx_nxt_state <= RX_CHECK_HEADER;
          
      RX_CHECK_HEADER:
          if(is_msg_wod | wr_1dw_fbe_eq_0) 
          rx_nxt_state <= RX_IDLE;
        else if(is_wr & ~is_uns_wr_size)
          rx_nxt_state <= RX_WRENA;  
        else if( ((is_rd & cpl_buff_ok_reg | is_flush | is_uns_rd_size) & (~is_read_bar_changed | is_read_bar_changed & TxRespIdle_i) & ~is_rx_lite_core) |  // wait for all txdatavalid before sending another read
                 (is_rd & is_rx_lite_core & ~RxRdInProgress_i)
               )
          rx_nxt_state <= RX_STORE_RD;
        else if (is_cpl & ((cpl_tag >= 8 & odd_address) | is_cpl_wod))
           rx_nxt_state <= RX_IDLE;
           
        else if(is_cpl & cpl_tag >= 8 & ~odd_address)
           rx_nxt_state <= RX_RPCPL_DATA;
         
        else if(is_cpl_wd & cpl_tag < 8)                 // with data
         rx_nxt_state <= RX_CPLENA;
        else if(is_cpl_wod)                // without data
          rx_nxt_state <= RX_CPLDONE;  // update the dirty and invalid bit according to the cpl status
       else if (is_msg_wd | is_uns_wr_size)
           rx_nxt_state <= RX_MSG_DUMP;
        else
           rx_nxt_state <= RX_CHECK_HEADER;
    
           
      RX_WRENA :
         if(rx_eop & ~rxm_wait_request & (input_fifo_wrusedw <= 1 |  ~pndgrd_fifo_ok_reg | is_rx_lite_core))  // last data sent
          rx_nxt_state <= RX_IDLE;
         else if(rx_eop & ~rxm_wait_request & (input_fifo_wrusedw > 1 &  pndgrd_fifo_ok_reg))  // last data sent
          rx_nxt_state <= RX_RD_HEADER2;
        else if (!rx_eop & ~rxm_wait_request & input_fifo_rdempty)
           rx_nxt_state <= RX_WRWAIT;
        else
          rx_nxt_state <= RX_WRENA;
          
       RX_WRWAIT :
         if(~input_fifo_rdempty)
           rx_nxt_state <= RX_WRENA;
         else
           rx_nxt_state <= RX_WRWAIT;
      
       RX_STORE_RD:    
         if(is_flush | is_uns_rd_size)      
            rx_nxt_state <= RX_IDLE;
         else
         rx_nxt_state <= RX_RDENA;   
         
       RX_RDENA :
        if(~rxm_wait_request)
          rx_nxt_state <= RX_IDLE;
        else
          rx_nxt_state <= RX_RDENA;  
          
        RX_RDTAG:
         rx_nxt_state <= RX_LD_PNDGTXRD;
       
       RX_LD_PNDGTXRD :
        if(~input_fifo_rdempty | rx_eop)
          rx_nxt_state <= RX_CPLDAT_PRE;
        else
          rx_nxt_state <= RX_LD_PNDGTXRD;
          
      RX_CPLDAT_PRE :
         rx_nxt_state <= RX_CPLENA;
        
      RX_CPLENA :
       if(rx_eop  & (input_fifo_wrusedw <= 1 |  ~pndgrd_fifo_ok_reg))
         rx_nxt_state <= RX_IDLE;
        else if(rx_eop & (input_fifo_wrusedw > 1 &  pndgrd_fifo_ok_reg)) 
          rx_nxt_state <= RX_RD_HEADER2;
       else
         rx_nxt_state <= RX_CPLENA; 
   
       RX_RPCPL_DATA :
           rx_nxt_state <= RX_IDLE;  
                              
       RX_CPLDONE :   // done, restore the current write pointer and the remaning count for the read associated with the tag
         rx_nxt_state <= RX_IDLE; 
       
       RX_MSG_DUMP:
         if(rx_eop)
           rx_nxt_state <= RX_IDLE; 
         else
           rx_nxt_state <= RX_MSG_DUMP; 
                          
       default:           
         rx_nxt_state <= RX_IDLE;
                          
   endcase                
 end                      
 
 
 //// state machine output assignments
generate if (CB_PCIE_RX_LITE == 0)
    assign rd_hdr1       =  (~rx_state[0] & input_fifo_wrusedw > 1 & pndgrd_fifo_ok_reg) | 
                       ( wrena & (rx_eop & ~rxm_wait_request & input_fifo_wrusedw > 1 &  pndgrd_fifo_ok_reg)) |
                        ( cplena & rx_eop & input_fifo_wrusedw > 1 &  pndgrd_fifo_ok_reg );
else
    assign rd_hdr1       =  (~rx_state[0] & input_fifo_wrusedw > 1 & pndgrd_fifo_ok_reg) | 
                        ( cplena & rx_eop & input_fifo_wrusedw > 1 &  pndgrd_fifo_ok_reg );
endgenerate

assign rxcntrl_sm_idle = ~rx_state[0]; 
assign rd_hdr2       = rx_state[1];
assign chk_hdr        = rx_state[2];
assign wrena          = rx_state[4];
assign wrwait         = rx_state[5];  
assign store_rd       = rx_state[6];

assign rdena          = rx_state[7];
assign cplena         = rx_state[11];
assign header_pipe    = rx_state[14];
assign msg_dump       = rx_state[15];
assign rxrp_cpl_ena   = rx_state[16];


/// The header register
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      begin
       header_reg[63:0]  <= 0;
       header_reg[127:64]  <= 0;
      end
    else if(rd_hdr2)
       begin
        header_reg[63:0]   <= input_fifo_dataout[63:0];
       end
    else if(header_pipe)
       begin
        header_reg[127:64]   <= input_fifo_dataout[63:0];
       end
  end

generate if (port_type_hwtcl == "Native endpoint")
    begin
     always @(posedge AvlClk_i or negedge Rstn_i)
       begin
         if(~Rstn_i)
            bar_dec_reg[6:0]   <= 0;   
         else if(header_pipe)
             bar_dec_reg[6:0]    <= input_fifo_dataout[80:74];
       end
    end
else   /// Root Port 
  begin
  	 always @(posedge AvlClk_i or negedge Rstn_i)
       begin
         if(~Rstn_i)
            bar_dec_reg[6:0]   <= 6'b000001;   
         else if(header_pipe)
             bar_dec_reg[6:0]    <= 6'b000001;
       end
 	end
endgenerate

  // modified length from dw to qword length to match the internal 64-bit datapath
  // to compensate for the misaligned qwords
  assign odd_address_at_fifo = header_reg[29]? input_fifo_dataout[34] : input_fifo_dataout[2];
  assign odd_address = header_reg[29]? header_reg[98] : header_reg[66]; // 
  assign len_plus_2 = odd_address_at_fifo & ~rx_dwlen[0];
  assign len_plus_1 = rx_dwlen[0];
  assign tlp_3dw_header = ~header_reg[29];
  assign rx_eop = input_fifo_dataout[73];
  
  assign hdr_3dw_unaligned = odd_address & tlp_3dw_header;
  assign hdr_3dw_unaligned_at_fifo = odd_address_at_fifo & tlp_3dw_header;
  

  always @(len_plus_2, len_plus_1, rx_dwlen, is_uns_rd_size)
    begin
      case({is_uns_rd_size, len_plus_2,len_plus_1})
        3'b001   : rx_modlen = rx_dwlen + 10'd1;
        3'b010   : rx_modlen = rx_dwlen + 10'd2;
        3'b100   : rx_modlen = 0;
        default : rx_modlen = rx_dwlen;
      endcase
    end
                  
always @(posedge AvlClk_i or negedge Rstn_i)        
  begin                                             
    if(~Rstn_i)                                     
       rx_modlen_reg <= 11'h0;                       
    else if(header_pipe)                                            
      rx_modlen_reg <= is_uns_rd_size? 11'h0 : rx_modlen;                     
  end                                               
                                                    

// Decoding the Header

assign rx_addr[63:0] = header_reg[29]? {header_reg[95:64], header_reg[127:96]} : {32'h0, header_reg[95:64]};
assign cpl_bytecount = header_reg[43:32];
assign rdreq_tag     = header_reg[47:40];
assign requestor_id  = header_reg[63:48];
assign rx_dwlen = header_reg[9:0];
assign is_rd =  ~header_reg[30] & (header_reg[28:26]== 3'b000) & ~header_reg[24];
assign is_flush = (is_rd & rx_lbe == 4'h0 & rx_fbe == 4'h0);   /// read with no byte enable to flush  

generate if(CB_PCIE_RX_LITE == 0)
 begin
   assign is_uns_rd_size =  (rx_dwlen > 128 | rx_dwlen == 10'h0) & is_rd;
   assign is_uns_wr_size =  1'b0; 
 end
else
 begin
   assign is_uns_rd_size =  (rx_dwlen > 1 | rx_dwlen == 10'h0) & is_rd;  
   assign is_uns_wr_size =  rx_dwlen > 1  & is_wr;      
 end
endgenerate

assign is_wr     = header_reg[30] & (header_reg[28:24]==5'b00000);
assign wr_1dw_fbe_eq_0 = is_wr & rx_dwlen == 1 & rx_fbe == 4'h0;
assign is_cpl_wd        = header_reg[30] & (header_reg[28:24]==5'b01010);
assign is_cpl_wod       = ~header_reg[30] & (header_reg[28:24]==5'b01010) & ~rx_only;
assign is_cpl           = (header_reg[28:24]==5'b01010);
assign is_msg        = header_reg[29:27] == 3'b110;
assign is_msg_wd     = header_reg[30] & is_msg;
assign is_msg_wod    = ~header_reg[30] & is_msg;

assign last_cpl      = ((cpl_bytecount[11:2] == rx_dwlen ) | (cpl_bytecount <= 8)) & is_cpl_wd;
assign qw_length = rx_modlen_reg[10:1];    
//assign qw_length = rx_modlen[10:1];
//assign cpl_tag = input_fifo_dataout[12:8];
assign cpl_tag = header_reg[76:72];
assign bar_hit = bar_dec_reg[6:0];
assign rx_fbe = header_reg[35:32];
assign rx_lbe = header_reg[39:36];
assign rx_tc        = header_reg[22:20];
assign rx_attr        = header_reg[13:12];

// address translation (PCIe to Avl)
altpciexpav_stif_p2a_addrtrans
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
      .BarHit_i(bar_hit),    
      .AvlAddr_o(avl_translated_addr[31:0])      
);                          
generate if (AVALON_ADDR_WIDTH == 32)
  begin
    assign avl_addr = {32'h0, avl_translated_addr};
  end
else
  begin
  	 assign avl_addr = rx_addr[63:0];
  end
endgenerate
    

always @(posedge AvlClk_i or negedge Rstn_i) 
  begin
    if(~Rstn_i)
     begin
       avl_addr_reg <= 64'h0;
       rx_eop_reg <= 1'b0;
        barhit_reg[6:0]   <= 0;
     end
    else
     begin
      avl_addr_reg <= avl_addr;
      rx_eop_reg <= rx_eop;
      barhit_reg[6:0]   <= bar_hit;
    end
  end

generate if (port_type_hwtcl != "Native endpoint")
    begin
  	  assign bar_hit_reg   = 7'h01;
    end
else
    begin
      assign bar_hit_reg   =  barhit_reg;
    end
endgenerate

always @(posedge AvlClk_i or negedge Rstn_i) 
  begin
    if(~Rstn_i)
     begin
       last_cpl_reg <= 0;
      end
    else 
     begin
      last_cpl_reg <= last_cpl;
     end
  end
  
  
/// Previous Read Bar registers

generate
   genvar j;
 for(j=0; j< 6; j=j+1)
   begin: previous_read_bar 
       always @(posedge AvlClk_i or negedge Rstn_i) 
         begin
           if(~Rstn_i)
              previous_bar_read[j] <= 1'b1;
           else if(rdena & bar_hit[j])   /// set when the bar is hit 
             previous_bar_read[j] <= 1'b1;
           else if(rdena & ~bar_hit[j])   // reset when something else hit
             previous_bar_read[j] <= 1'b0;
         end
     end
endgenerate
        
assign is_read_bar_changed = ((previous_bar_read[0] ^ bar_hit[0]) & bar_hit[0])|
                             ((previous_bar_read[1] ^ bar_hit[1]) & bar_hit[1])| 
                             ((previous_bar_read[2] ^ bar_hit[2]) & bar_hit[2])| 
                             ((previous_bar_read[3] ^ bar_hit[3]) & bar_hit[3])| 
                             ((previous_bar_read[4] ^ bar_hit[4]) & bar_hit[4])| 
                             ((previous_bar_read[5] ^ bar_hit[5]) & bar_hit[5]) ;
  
// Avalon master Read/Write port interface
generate if(CB_PCIE_RX_LITE == 0 && AVALON_ADDR_WIDTH == 64)  /// no address translation
  begin
    assign RxmWrite_0_o = wrena & bar_hit_reg[0];
    assign RxmRead_0_o = rdena & bar_hit_reg[0];
    assign RxmAddress_0_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:3], 3'h0};
    assign RxmWriteData_0_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_0_o = qw_length[6:0]; 
    
    assign RxmWrite_1_o = wrena & bar_hit_reg[1];
    assign RxmRead_1_o = rdena & bar_hit_reg[1];
    assign RxmAddress_1_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:3], 3'h0};
    assign RxmWriteData_1_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_1_o = qw_length[6:0];     
   
    assign RxmWrite_2_o = wrena & bar_hit_reg[2];
    assign RxmRead_2_o = rdena & bar_hit_reg[2];
    assign RxmAddress_2_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:3], 3'h0};
    assign RxmWriteData_2_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_2_o = qw_length[6:0];     
    
    assign RxmWrite_3_o = wrena & bar_hit_reg[3];
    assign RxmRead_3_o = rdena & bar_hit_reg[3];
    assign RxmAddress_3_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:3], 3'h0};
    assign RxmWriteData_3_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_3_o = qw_length[6:0];     
    
    assign RxmWrite_4_o = wrena & bar_hit_reg[4];
    assign RxmRead_4_o = rdena & bar_hit_reg[4];
    assign RxmAddress_4_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:3], 3'h0};
    assign RxmWriteData_4_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_4_o = qw_length[6:0];     
 
    assign RxmWrite_5_o = wrena & bar_hit_reg[5];
    assign RxmRead_5_o = rdena & bar_hit_reg[5];
    assign RxmAddress_5_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:3], 3'h0};
    assign RxmWriteData_5_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_5_o = qw_length[6:0];  
end
endgenerate

generate if(CB_PCIE_RX_LITE == 0 && AVALON_ADDR_WIDTH == 32) /// use address translation
  begin
    assign RxmWrite_0_o = wrena & bar_hit_reg[0];
    assign RxmRead_0_o = rdena & bar_hit_reg[0];
    assign RxmAddress_0_o = {avl_addr_reg[31:3], 3'h0};
    assign RxmWriteData_0_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_0_o = qw_length[6:0]; 
    
    assign RxmWrite_1_o = wrena & bar_hit_reg[1];
    assign RxmRead_1_o = rdena & bar_hit_reg[1];
    assign RxmAddress_1_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:3], 3'h0};
    assign RxmWriteData_1_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_1_o = qw_length[6:0];     
   
    assign RxmWrite_2_o = wrena & bar_hit_reg[2];
    assign RxmRead_2_o = rdena & bar_hit_reg[2];
    assign RxmAddress_2_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:3], 3'h0};
    assign RxmWriteData_2_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_2_o = qw_length[6:0];     
    
    assign RxmWrite_3_o = wrena & bar_hit_reg[3];
    assign RxmRead_3_o = rdena & bar_hit_reg[3];
    assign RxmAddress_3_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:3], 3'h0};
    assign RxmWriteData_3_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_3_o = qw_length[6:0];     
    
    assign RxmWrite_4_o = wrena & bar_hit_reg[4];
    assign RxmRead_4_o = rdena & bar_hit_reg[4];
    assign RxmAddress_4_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:3], 3'h0};
    assign RxmWriteData_4_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_4_o = qw_length[6:0];     
 
    assign RxmWrite_5_o = wrena & bar_hit_reg[5];
    assign RxmRead_5_o = rdena & bar_hit_reg[5];
    assign RxmAddress_5_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:3], 3'h0};
    assign RxmWriteData_5_o = input_fifo_dataout[63:0];
    assign RxmBurstCount_5_o = qw_length[6:0];  
 end
endgenerate


generate if(CB_PCIE_RX_LITE == 1)
 begin
 	  assign RxmWrite_0_o = wrena & bar_hit_reg[0];
    assign RxmRead_0_o = rdena & bar_hit_reg[0];
    assign RxmAddress_0_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:2], 2'h0};
    assign RxmWriteData_0_o = odd_address? input_fifo_dataout[63:32] : input_fifo_dataout[31:0];
    assign RxmBurstCount_0_o = qw_length[6:0]; 
    
    assign RxmWrite_1_o = wrena & bar_hit_reg[1];
    assign RxmRead_1_o = rdena & bar_hit_reg[1];
    assign RxmAddress_1_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:2], 2'h0};
    assign RxmWriteData_1_o = odd_address? input_fifo_dataout[63:32] : input_fifo_dataout[31:0];
    assign RxmBurstCount_1_o = qw_length[6:0];     
   
    assign RxmWrite_2_o = wrena & bar_hit_reg[2];
    assign RxmRead_2_o = rdena & bar_hit_reg[2];
    assign RxmAddress_2_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:2], 2'h0};
    assign RxmWriteData_2_o =  odd_address? input_fifo_dataout[63:32] : input_fifo_dataout[31:0];
    assign RxmBurstCount_2_o = qw_length[6:0];     
    
    assign RxmWrite_3_o = wrena & bar_hit_reg[3];
    assign RxmRead_3_o = rdena & bar_hit_reg[3];
    assign RxmAddress_3_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:2], 2'h0};
    assign RxmWriteData_3_o = odd_address? input_fifo_dataout[63:32] : input_fifo_dataout[31:0];
    assign RxmBurstCount_3_o = qw_length[6:0];     
    
    assign RxmWrite_4_o = wrena & bar_hit_reg[4];
    assign RxmRead_4_o = rdena & bar_hit_reg[4];
    assign RxmAddress_4_o = {avl_addr_reg[31:2], 2'h0};
    assign RxmWriteData_4_o =  odd_address? input_fifo_dataout[63:32] : input_fifo_dataout[31:0];
    assign RxmBurstCount_4_o = qw_length[6:0];     
 
    assign RxmWrite_5_o = wrena & bar_hit_reg[5];
    assign RxmRead_5_o = rdena & bar_hit_reg[5];
    assign RxmAddress_5_o = {avl_addr_reg[AVALON_ADDR_WIDTH-1:2], 2'h0};
    assign RxmWriteData_5_o =  odd_address? input_fifo_dataout[63:32] : input_fifo_dataout[31:0];
    assign RxmBurstCount_5_o = qw_length[6:0];  
 end
endgenerate
    
/// figure out the read byte enable for single word (64-bit) transaction

/// crossing low be to high be when address is odd
assign rd_be_x_select = odd_address & (qw_length == 1);
// normal single qword aligned
assign rd_be_normal_sel = ~odd_address & (qw_length == 1);

generate if(CB_PCIE_RX_LITE == 0)
 
always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      rd_be_reg <= 0;
    else
      rd_be_reg <= rd_be_x_select? {rx_fbe, rx_lbe} : rd_be_normal_sel? {rx_lbe, rx_fbe} : 8'hFF;
  end
else
 always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      rd_be_reg <= 0;
    else
      rd_be_reg <=  rx_fbe;
  end

endgenerate

reg first_qword_reg;

// SR flop to mark the first write transaction
// set when check header, reset when the first word is transfer. Used for first write be
always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      first_qword_reg <= 0;
    else if(chk_hdr & is_wr)
      first_qword_reg <= 1'b1;
    else if(rxm_write & ~rxm_wait_request)
      first_qword_reg <= 1'b0;
  end



generate if(CB_PCIE_RX_LITE == 0)
begin
  assign wr_cpl_be[3:0] = hdr_3dw_unaligned & first_qword_reg?  4'h0 : input_fifo_dataout[67:64];
  assign wr_cpl_be[7:4] = input_fifo_dataout[71:68];
end

else
  begin
   assign wr_cpl_be[3:0] = odd_address ?  input_fifo_dataout[71:68] : input_fifo_dataout[67:64];
  end
endgenerate

assign RxmByteEnable_0_o = (rdena)? rd_be_reg :  wr_cpl_be; 
assign RxmByteEnable_1_o = (rdena)? rd_be_reg :  wr_cpl_be;
assign RxmByteEnable_2_o = (rdena)? rd_be_reg :  wr_cpl_be;
assign RxmByteEnable_3_o = (rdena)? rd_be_reg :  wr_cpl_be;
assign RxmByteEnable_4_o = (rdena)? rd_be_reg :  wr_cpl_be;
assign RxmByteEnable_5_o = (rdena)? rd_be_reg :  wr_cpl_be;

always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      rx_dwlen_reg <= 11'h0;
    else
      rx_dwlen_reg <= rx_dwlen;
  end


/// Pending Read FIFO 
assign PndgRdHeader_o      = {is_uns_rd_size, rx_lbe, rx_tc, rx_attr, rx_fbe, rx_dwlen_reg, requestor_id, is_flush, rx_addr[6:0], rdreq_tag};
assign PndgRdFifoWrReq_o   = store_rd;

// inp fifo read signal

generate if (CB_PCIE_RX_LITE == 0)
   assign input_fifo_rdreq = rd_hdr1 | rd_hdr2 | wrwait | 
                       (chk_hdr & ~input_fifo_rdempty & (is_wr | is_cpl_wd | is_msg_wd) & ~rx_eop & ~hdr_3dw_unaligned_at_fifo) |
                       (wrena & ~input_fifo_rdempty & ~rx_eop & ~rxm_wait_request )|
                       (cplena & ~input_fifo_rdempty & ~rx_eop) | 
                        (msg_dump & ~rx_eop) ;
else
   assign input_fifo_rdreq = rd_hdr1 | rd_hdr2 | wrwait | 
                       (chk_hdr & ~input_fifo_rdempty & (is_wr | is_cpl_wd | is_msg_wd) & ~rx_eop & ~hdr_3dw_unaligned_at_fifo) |
                       (cplena & ~input_fifo_rdempty & ~rx_eop) | 
                        (msg_dump & ~rx_eop) ;

endgenerate
                       
always @(posedge Clk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     begin
      chk_hdr_reg <= 0;
     end
    else 
     begin
      chk_hdr_reg <= chk_hdr;
     end
   end

assign chk_hdr_rise = ~chk_hdr_reg & chk_hdr;

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      cpl_tag_reg <= 0;
    else if(chk_hdr_rise)  // load with the the completion tag from the header
      cpl_tag_reg <= cpl_tag;
   end


/// Mask
assign RxStMask_o = 1'b0;

// Logic to handle the completion TLP from Root port
  // address counter for each CPL buffer segment
 
   always @(negedge Rstn_i or posedge AvlClk_i)
    begin
       if (Rstn_i == 1'b0)
          cpl_add_cntr <= 6'h0 ; 
       else if(chk_hdr & is_cpl_wd)
          cpl_add_cntr <= cpl_add_cntr_previous[cpl_tag[2:0]];   // load the previous stored pointer of a current tag
       else if (CplRamWrEna_o)
           cpl_add_cntr <= cpl_add_cntr + 6'd1; 
    end 

/// an array to store the last write address for each tag

generate
   genvar k;
 for(k=0; k< 8; k=k+1)
   begin: cpl_address_counter_back_trace   
   always @(negedge Rstn_i or posedge AvlClk_i)
    begin
       if (Rstn_i == 1'b0)
          cpl_add_cntr_previous[k][5:0] <= 6'h0;
       else if (cpl_tag_reg == k && cplena)  
              cpl_add_cntr_previous[k] <= last_cpl ? 0 : cpl_add_cntr + 6'd1; 
    end 
 end
 endgenerate
 
assign CplRamWrAddr_o[8:0] = {cpl_tag_reg[2:0], cpl_add_cntr[5:0]};
assign CplRamWrEna_o = cplena;
assign CplRamWrDat_o = {(last_cpl_reg & rx_eop),input_fifo_dataout[72],input_fifo_dataout[63:0]};

always @(posedge AvlClk_i or negedge Rstn_i) 
  begin
    if(~Rstn_i)
     begin
      CplReq_o <= 1'b0;
      CplDesc_o <= 0;
     end
    else
     begin
      CplReq_o <= cplena & is_cpl_wd;
      CplDesc_o <= {last_cpl_reg, 1'b1, cpl_tag_reg[2:0]};
     end
  end
          
// RP completion
assign  RxRpFifoWrReq_o   =  (chk_hdr & is_cpl & cpl_tag >=8) | rxrp_cpl_ena;  
assign  rxrp_fifo_dat_sel = rxrp_cpl_ena;     
assign  rx_rpcpl_low_dat  = rxrp_fifo_dat_sel?  input_fifo_dataout[63:0] : header_reg[63:0] ;  
assign  rx_rpcpl_hi_dat   = header_reg[127:64];
assign  rx_rpcpl_sop      =  (chk_hdr & is_cpl & cpl_tag >=8);
assign  rx_rpcpl_eop      =   rxrp_cpl_ena |   (chk_hdr & ((cpl_tag >= 8 & odd_address) | is_cpl_wod));    
assign  rx_rpcpl_empty      =   (rxrp_cpl_ena &  ~odd_address);   
assign  RxRpFifoWrData_o[130:0] = {rx_rpcpl_empty, rx_rpcpl_eop, rx_rpcpl_sop, rx_rpcpl_hi_dat, rx_rpcpl_low_dat};     
  

endmodule


















