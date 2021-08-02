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
module altpciexpav_stif_cr_rp
  (
   // All ports on this module are synchronous to CraClk_i
   input             CraClk_i,           // Clock for register access port
   input             CraRstn_i,          // Reset signal  
   // Broadcast Avalon signals
   input [13:2]      IcrAddress_i,       // Address 
   input [31:0]      IcrWriteData_i,     // Write Data 
   input [3:0]       IcrByteEnable_i,    // Byte Enables
   // Modified Avalon signals to/from specific internal modules
   // Local to Pci Mailbox
   input             RpWriteReqVld_i,    // Valid Write Cycle in 
   input             RpReadReqVld_i,     // Read Valid in  
   output reg [31:0] RpReadData_o,       // Read Data out
   output reg        RpReadDataVld_o,    // Read Valid out
   // Mailbox specific Interrupt Request pulses
   output   [7:0]  RpRuptReq_o,        // Interrupt Requests
   
   input             TxRpFifoRdReq_i,
   output    [65:0]  TxRpFifoData_o,
   output            RpTLPReady_o,
   input             RpTLPAck_i,
   input             RxRpFifoWrReq_i,
   input     [130:0] RxRpFifoWrData_i,
   output            RpTxFifoFull_o,
   
   input     [4:0]   ltssm_state,
   input             rxcntrl_sm_idle
   
         
   ) ;
   
localparam      RXCPL_IDLE       = 7'h00;  
localparam      RXCPL_RDFIFO     = 7'h03;
localparam      RXCPL_PIPE       = 7'h05;
localparam      RXCPL_LD_REG0    = 7'h09;
localparam      RXCPL_WAIT0      = 7'h11;
localparam      RXCPL_LD_REG1    = 7'h21;
localparam      RXCPL_WAIT1      = 7'h41;

localparam      CPL_GEN_IDLE        =   3'h0;
localparam      CPL_GEN_LATCH_QW0   =   3'h1;
localparam      CPL_GEN_WAIT_EOP    =   3'h2;
localparam      CPL_GEN_LATCH_QW1   =   3'h3;
localparam      CPL_GEN_WAIT_RXIDLE =   3'h4;
localparam      CPL_GEN_INSERT0     =   3'h5;
localparam      CPL_GEN_INSERT1     =   3'h6;
localparam      CPL_GEN_INSERT2     =   3'h7;

   
   wire [15:0]       cra_address;
   reg [31:0]        tx_data_low_reg;
   reg [31:0]        tx_data_hi_reg;
   reg [31:0]        tx_control_reg;
   
   reg [31:0]        cpl_data_low_reg;
   reg [31:0]        cpl_data_hi_reg;
   reg [31:0]        cpl_control_reg;
   wire              reg0_wrena;
   wire              reg1_wrena;
   reg [6:0]         rxcpl_state;    
   reg [6:0]         rxcpl_nxt_state;
   wire              rxcpl_reg1_rdreq;
   wire              rxcpl_eop;
   wire              rxcpl_sop;
   wire              rxcpl_empty;        
   wire              rxsm_load_first64;
   wire              rxsm_load_second64;                     
   reg  [31:0]       rx_data_hi_reg;
   reg  [31:0]       rx_data_low_reg;
   wire [31:0]       rx_status_reg;
   reg  [7:0]        rx_fifo_usedw_reg;
   wire  [3:0]       rxrp_fifo_usedw;
   wire              rxrp_fifo_empty;
   wire  [130:0]     rxrp_fifo_dataout;
   reg               tx_ctl_wrena_reg;
   wire              tx_ctl_wrena;
   wire  [65:0]      tx_low64_fifo_data_in;
   wire               tx_rp_sop;
   wire               tx_rp_eop;
   wire               tx_low64_fifo_rdempty;
   wire  [65:0]       tx_low64_fifo_dataout;
   wire  [4:0]        tx_low64_fifo_wrusedw;
   wire  [3:0]        tx_hi64_fifo_wrusedw;
   reg                rx_sop_reg;
   reg                rx_eop_reg;   
   wire               rxcpl_status_read;                   
   wire               rxrp_fifo_rdreq;
   reg                link_down_sreg;
   wire               is_type1_cfg;    
   reg  [2:0]         cplgen_state;      
   reg  [2:0]         cplgen_nxt_state;            
   wire               latch_tlp_qw0; 
   wire               latch_tlp_qw1; 
   wire               insert_cpl0;   
   wire               insert_cpl1;   
   wire               insert_cpl2;      
                                                                          
                    
   reg  [63:0]        cfg_type1_tlp_qw0;   
   reg  [63:0]        cfg_type1_tlp_qw1;                
                            
   wire  [31:0]       cpl_wd_dw0;
   wire  [31:0]       cpl_wd_dw1;
   wire  [31:0]       cpl_wd_dw2;
   
   wire  [31:0]       cpl_wod_dw0;
   wire  [31:0]       cpl_wod_dw1;
   wire  [31:0]       cpl_wod_dw2;
   wire [63:0]        cpl_wod_qw0;
   wire [63:0]        cpl_wod_qw1;                   
   wire               is_type1_wr;           
   
   wire  [63:0]       cpl_qw0;
   wire  [63:0]       cpl_qw1;  
   wire  [63:0]       cpl_qw3;                
   wire  [130:0]      cpl_tlp;         
   wire  [130:0]      rxrp_fifo_input;
   wire               insert_cpl;
   wire               aligned_address;          
  wire  [7:0]         cpltr_bus; 
  wire  [4:0]         cpltr_dev; 
  wire  [2:0]         cpltr_func;   
  wire  [7:0]         reg_num;                
  wire  [7:0]         tag;     
  wire  [15:0]        reqtr_id;         
  wire                tx_low64_fifo_wrreq;    
  wire                tx_hi64_fifo_wrreq;     
  wire                detect_type1_cfg;
  wire  [31:0]        cpl_wd_qw0;   
  wire  [31:0]        cpl_wd_qw1;
  wire  [31:0]        cpl_wd_qw2;    
  reg                 tx_tlp_req_sreg;
  
  
   assign cra_address[15:0] = {2'b00,IcrAddress_i[13:2], 2'b00}; // convert to byte address
   assign reg0_wrena = ((cra_address == 16'h2000) & RpWriteReqVld_i);    
   assign reg1_wrena = ((cra_address == 16'h2004) & RpWriteReqVld_i);
   assign tx_ctl_wrena = ((cra_address == 16'h2008) & RpWriteReqVld_i);
      
/// Tx Control Registers

   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
           tx_data_low_reg <= 32'h0;
        else     
         begin
        if(reg0_wrena & IcrByteEnable_i[0])
           tx_data_low_reg[7:0] <= IcrWriteData_i[7:0];
        if(reg0_wrena & IcrByteEnable_i[1])   
           tx_data_low_reg[15:8] <= IcrWriteData_i[15:8];
        if(reg0_wrena & IcrByteEnable_i[2])  
           tx_data_low_reg[23:16] <= IcrWriteData_i[23:16];
        if(reg0_wrena & IcrByteEnable_i[2])            
           tx_data_low_reg[31:24] <= IcrWriteData_i[31:24]; 
        end
      end
      
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
           tx_data_hi_reg <= 32'h0;
        else
          begin
         if(reg1_wrena & IcrByteEnable_i[0])
           tx_data_hi_reg[7:0] <= IcrWriteData_i[7:0];
         if(reg1_wrena & IcrByteEnable_i[1])   
           tx_data_hi_reg[15:8] <= IcrWriteData_i[15:8];
         if(reg1_wrena & IcrByteEnable_i[2])  
           tx_data_hi_reg[23:16] <= IcrWriteData_i[23:16];
         if(reg1_wrena & IcrByteEnable_i[2])            
           tx_data_hi_reg[31:24] <= IcrWriteData_i[31:24]; 
      end
      end    

   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
           tx_control_reg <= 32'h0;
        else
          begin 
           if(tx_ctl_wrena & IcrByteEnable_i[0])
              tx_control_reg[7:0] <= IcrWriteData_i[7:0];
           if(tx_ctl_wrena & IcrByteEnable_i[1])   
              tx_control_reg[15:8] <= IcrWriteData_i[15:8];
           if(tx_ctl_wrena & IcrByteEnable_i[2])  
              tx_control_reg[23:16] <= IcrWriteData_i[23:16];
           if(tx_ctl_wrena & IcrByteEnable_i[2])            
             tx_control_reg[31:24] <= IcrWriteData_i[31:24]; 
         end
      end    
      
// Tx FIFO

	scfifo	# (
	       .add_ram_output_register("ON"),
		     .intended_device_family("Stratix V"),
		     .lpm_numwords(32),
		     .lpm_showahead("OFF"),
		     .lpm_type("scfifo"),
		     .lpm_width(66),
		     .lpm_widthu(5),
		     .overflow_checking("ON"),
		     .underflow_checking("ON"),
		     .use_eab("ON")
		  ) 
	          
       txrp_low64_fifo (
                     .rdreq (TxRpFifoRdReq_i),
                     .clock (CraClk_i),
                     .wrreq (tx_low64_fifo_wrreq),
                     .data (tx_low64_fifo_data_in),
                     .usedw (tx_low64_fifo_wrusedw),
                     .empty (tx_low64_fifo_rdempty),
                     .q (tx_low64_fifo_dataout),
                     .full (),
                     .aclr (~CraRstn_i),
                     .almost_empty (),
                     .almost_full (),
                     .sclr ()
);


/// fifo control
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
       if(~CraRstn_i)
     	   tx_ctl_wrena_reg <= 1'b0;
     	 else
     	   tx_ctl_wrena_reg <= tx_ctl_wrena;
     end
     
assign tx_low64_fifo_wrreq = tx_ctl_wrena_reg & ~link_down_sreg;
assign tx_low64_fifo_data_in = {tx_rp_eop, tx_rp_sop,tx_data_hi_reg, tx_data_low_reg};

     
 assign tx_rp_sop   = tx_control_reg[0];
 assign tx_rp_eop   = tx_control_reg[1];
 
 assign TxRpFifoData_o = tx_low64_fifo_dataout;
 
  always @(posedge CraClk_i or negedge CraRstn_i)
     begin
       if(~CraRstn_i)
     	   tx_tlp_req_sreg <= 1'b0;
     	 else if (tx_control_reg[1] & tx_ctl_wrena_reg)
     	   tx_tlp_req_sreg <= 1'b1;
     	 else if (RpTLPAck_i)
     	   tx_tlp_req_sreg <= 1'b0;
     end
     
 
 assign RpTLPReady_o   = tx_tlp_req_sreg;
 
/// The RP Completion Data

	scfifo	# (
	       .add_ram_output_register("ON"),
		     .intended_device_family("Stratix V"),
		     .lpm_numwords(16),
		     .lpm_showahead("OFF"),
		     .lpm_type("scfifo"),
		     .lpm_width(131),
		     .lpm_widthu(4),
		     .overflow_checking("ON"),
		     .underflow_checking("ON"),
		     .use_eab("ON")
		  ) 
	          
       rxrp_fifo (
                     .rdreq (rxrp_fifo_rdreq),
                     .clock (CraClk_i),
                     .wrreq (RxRpFifoWrReq_i | insert_cpl),
                     .data (rxrp_fifo_input),
                     .usedw (rxrp_fifo_usedw),
                     .empty (rxrp_fifo_empty),
                     .q (rxrp_fifo_dataout),
                     .full (),
                     .aclr (~CraRstn_i),
                     .almost_empty (),
                     .almost_full (),
                     .sclr ()
);
assign rxcpl_sop =   rxrp_fifo_dataout[128];
assign rxcpl_eop =   rxrp_fifo_dataout[129];
assign rxcpl_empty =   rxrp_fifo_dataout[130];

/// state machine to control the completion data

assign rxcpl_reg1_rdreq = RpReadReqVld_i & cra_address[7:0] == 8'h18;      
assign rxcpl_status_read = RpReadDataVld_o & cra_address[7:0] == 8'h10; 


always @(posedge CraClk_i or negedge CraRstn_i)  // state machine registers
  begin
    if(~CraRstn_i)
     rxcpl_state  <= RXCPL_IDLE;
    else
      rxcpl_state <= rxcpl_nxt_state;
  end

always @*
  begin
    case(rxcpl_state)
      RXCPL_IDLE :
        if(~rxrp_fifo_empty)
            rxcpl_nxt_state <= RXCPL_RDFIFO;
       else
          rxcpl_nxt_state <= RXCPL_IDLE;
          
      RXCPL_RDFIFO :
        rxcpl_nxt_state <= RXCPL_PIPE; 
        
      RXCPL_PIPE :
        rxcpl_nxt_state <= RXCPL_LD_REG0;
     
     RXCPL_LD_REG0:  // load the first 64-bit data
        rxcpl_nxt_state <= RXCPL_WAIT0;
        
     RXCPL_WAIT0:
       if(rxcpl_reg1_rdreq & rxcpl_eop & rxcpl_empty) 
         rxcpl_nxt_state <= RXCPL_IDLE;
       else if(rxcpl_reg1_rdreq)
         rxcpl_nxt_state <= RXCPL_LD_REG1;
       else
          rxcpl_nxt_state <= RXCPL_WAIT0;
    
    RXCPL_LD_REG1:
       rxcpl_nxt_state <= RXCPL_WAIT1;
    
     RXCPL_WAIT1:
       if(rxcpl_reg1_rdreq & rxcpl_eop) 
         rxcpl_nxt_state <= RXCPL_IDLE;
       else if(rxcpl_reg1_rdreq)
         rxcpl_nxt_state <= RXCPL_RDFIFO;
       else
          rxcpl_nxt_state <= RXCPL_WAIT1;
    
      default:
          rxcpl_nxt_state <= RXCPL_IDLE;
 endcase
 
end
 
/// assign state machine output

assign  rxrp_fifo_rdreq   = rxcpl_state[1];
assign  rxsm_load_first64 =  rxcpl_state[3];
assign  rxsm_load_second64 =  rxcpl_state[5];

/// Rx CPL registers
 
    always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
           rx_data_low_reg <= 32'h0;
        else if(rxsm_load_first64)            
           rx_data_low_reg[31:0] <= rxrp_fifo_dataout[31:0];   
        else if(rxsm_load_second64)                          
           rx_data_low_reg[31:0] <= rxrp_fifo_dataout[95:64];
      end
     
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
           rx_data_hi_reg <= 32'h0;
        else if(rxsm_load_first64)            
           rx_data_hi_reg[31:0] <= rxrp_fifo_dataout[63:32];      
         else if(rxsm_load_second64)                           
            rx_data_hi_reg[31:0] <= rxrp_fifo_dataout[127:96]; 
      end
 
  always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
           rx_sop_reg <= 1'b0;
        else if(rxsm_load_first64 & rxcpl_sop)           
           rx_sop_reg <= 1'b1;
        else if (rxsm_load_second64 | rxcpl_status_read)
           rx_sop_reg <= 1'b0;
      end
      
  always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
           rx_eop_reg <= 1'b0;
        else if(rxsm_load_first64 & rxcpl_eop & rxcpl_empty)           
           rx_eop_reg <= 1'b1;
        else if (rxsm_load_second64 & rxcpl_eop & ~rxcpl_empty)
           rx_eop_reg <= 1'b1;
        else if (rxsm_load_first64 | rxcpl_status_read)
           rx_eop_reg <= 1'b0;
      end
      
  always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
           rx_fifo_usedw_reg <= 8'h0;
        else if(rxrp_fifo_rdreq)           
           rx_fifo_usedw_reg[7:0] <= {4'b000, rxrp_fifo_usedw};
      end
      
assign rx_status_reg[31:0] = {16'h0, rx_fifo_usedw_reg[7:0], 6'h0, rx_eop_reg, rx_sop_reg};

// Muxing the read data
always @ *
  begin
  	  case (cra_address[7:0])
  	  	8'h10 : RpReadData_o = rx_status_reg;
  	  	8'h14 : RpReadData_o = rx_data_low_reg;
  	  	8'h18 : RpReadData_o = rx_data_hi_reg;
  	  	default : RpReadData_o = 32'h0;
  	  endcase
  end
  
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
       if(~CraRstn_i)
     	   RpReadDataVld_o <= 1'b0;
     	 else
     	   RpReadDataVld_o <= RpReadReqVld_i;
     end
     
       
assign RpRuptReq_o = 1'b0;  // tied to GND for now
assign RpTxFifoFull_o = tx_low64_fifo_wrusedw > 8 ;

//////////////////////////////////////////////////////////////////////////////
///      logic to handle Type 1 CFG TX when link is down               //////////
////////////////////////////////////////////////////////////////////////////////
////
assign detect_type1_cfg = (IcrWriteData_i[0] & tx_ctl_wrena & ltssm_state != 5'h0F & is_type1_cfg);
/// cpl_gen state machine

always @(posedge CraClk_i or negedge CraRstn_i)  // state machine registers
  begin
    if(~CraRstn_i)
     cplgen_state  <= CPL_GEN_IDLE;
    else
      cplgen_state <= cplgen_nxt_state;
  end


always @*
  begin
    case(cplgen_state)
      CPL_GEN_IDLE :
        if(detect_type1_cfg)   /// SOP written
            cplgen_nxt_state <= CPL_GEN_LATCH_QW0;
       else
          cplgen_nxt_state   <= CPL_GEN_IDLE;
          
      CPL_GEN_LATCH_QW0:
          cplgen_nxt_state   <= CPL_GEN_WAIT_EOP;
      
      CPL_GEN_WAIT_EOP:
          if(IcrWriteData_i[1] & tx_ctl_wrena)
             cplgen_nxt_state <= CPL_GEN_LATCH_QW1;
          else
             cplgen_nxt_state <= CPL_GEN_WAIT_EOP;
      
      CPL_GEN_LATCH_QW1:
         cplgen_nxt_state   <= CPL_GEN_WAIT_RXIDLE;
      
      CPL_GEN_WAIT_RXIDLE:
        if(rxcntrl_sm_idle)
          cplgen_nxt_state   <= CPL_GEN_INSERT0;
        else
          cplgen_nxt_state   <= CPL_GEN_WAIT_RXIDLE;
      
      CPL_GEN_INSERT0:
         cplgen_nxt_state   <= CPL_GEN_INSERT1;
         
      CPL_GEN_INSERT1:
        if(aligned_address)
          cplgen_nxt_state <= CPL_GEN_INSERT2;
        else
          cplgen_nxt_state <= CPL_GEN_IDLE;
      
      CPL_GEN_INSERT2:
          cplgen_nxt_state <= CPL_GEN_IDLE;
      
      default:
        cplgen_nxt_state <= CPL_GEN_IDLE;
    endcase
end

assign latch_tlp_qw0 = (cplgen_state == CPL_GEN_LATCH_QW0) ;
assign latch_tlp_qw1 = (cplgen_state == CPL_GEN_LATCH_QW1) ;
assign insert_cpl0   = (cplgen_state == CPL_GEN_INSERT0) ;
assign insert_cpl1   = (cplgen_state == CPL_GEN_INSERT1) ;
assign insert_cpl2   = (cplgen_state == CPL_GEN_INSERT2) ;

assign is_type1_cfg = tx_data_low_reg[28:24] == 5'b00101;

   always @(posedge CraClk_i or negedge CraRstn_i)   
     begin                                           
       if(~CraRstn_i)                                
     	   link_down_sreg <= 1'b0;                    
     	 else if(IcrWriteData_i[0] & tx_ctl_wrena & ltssm_state != 5'h0F & is_type1_cfg)        /// set when write sop to control reg                                 
     	   link_down_sreg <= 1'b1;          
     	 else if(insert_cpl1)   /// reset after insert the completion
     	   link_down_sreg <= 1'b0;
     end                                             

//// 128-bit register to hold the Type 1 Tx TLP 

   always @(posedge CraClk_i or negedge CraRstn_i)   
     begin                                           
       if(~CraRstn_i)                                
     	   cfg_type1_tlp_qw0 <= 64'h0;                    
     	 else if(latch_tlp_qw0)                              
     	   cfg_type1_tlp_qw0 <= tx_low64_fifo_data_in[63:0];          
     end                    

   always @(posedge CraClk_i or negedge CraRstn_i)   
     begin                                           
       if(~CraRstn_i)                                
     	   cfg_type1_tlp_qw1 <= 64'h0;                    
     	 else if(latch_tlp_qw1)                            
     	   cfg_type1_tlp_qw1 <= tx_low64_fifo_data_in[63:0];          
     end                    
     
 /// forming CPL TLP with unsupported req     
 
assign cpltr_bus  = cfg_type1_tlp_qw1[31:24];
assign cpltr_dev  = cfg_type1_tlp_qw1[23:19];
assign cpltr_func = cfg_type1_tlp_qw1[18:16];
assign reg_num    = cfg_type1_tlp_qw1[7:0];
assign tag        = cfg_type1_tlp_qw0[47:40];
assign reqtr_id   = cfg_type1_tlp_qw0[63:48];    

assign aligned_address = ~reg_num[2];
    
     /// completion without data
 assign cpl_wod_dw0 = 32'h0A0000;
 assign cpl_wod_dw1 = {cpltr_func, cpltr_dev[3:0], cpltr_bus[7:0],4'b0010, 12'h0};
 assign cpl_wod_dw2 = {reqtr_id[15:0], tag[7:0], reg_num[7:0]};
 
 assign cpl_wod_qw0 = {cpl_wod_dw1, cpl_wod_dw0};
 assign cpl_wod_qw1 = {32'h0, cpl_wod_dw2};
 
     /// completion with data

 assign cpl_wd_dw0 = 32'h4A0001;
 assign cpl_wd_dw1 = {cpltr_func, cpltr_dev[4:0], cpltr_bus[7:0],4'b0010, 12'h4};
 assign cpl_wd_dw2 = {reqtr_id[15:0], tag[7:0], reg_num[7:0]};
 
 assign cpl_wd_qw0 = {cpl_wd_dw1, cpl_wd_dw0};
 assign cpl_wd_qw1 = {32'hFFFF, cpl_wd_dw2};
 
 assign is_type1_wr = is_type1_cfg & tx_data_low_reg[30];
 
 assign cpl_qw0 = is_type1_wr? cpl_wd_qw0 : cpl_wod_qw0;
 assign cpl_qw1 = is_type1_wr? cpl_wd_qw1 : cpl_wod_qw1;
 assign cpl_qw3 =  64'hFFFF_FFFF;
 
 assign cpl_tlp = insert_cpl0? {aligned_address,2'b01,cpl_qw0} : insert_cpl1? {aligned_address, ~aligned_address, 1'b0,cpl_qw1} : {aligned_address, 2'b10,cpl_qw3};
 // insert UR Completion counter
  
  assign insert_cpl = insert_cpl0 | insert_cpl1 | insert_cpl2;
  
  assign rxrp_fifo_input = insert_cpl? cpl_tlp : RxRpFifoWrData_i;
  
 
endmodule
 
 
  