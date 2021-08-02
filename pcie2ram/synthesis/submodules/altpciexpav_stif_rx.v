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
module altpciexpav_stif_rx

# ( 

     parameter              CG_COMMON_CLOCK_MODE   = 0,     
     parameter              CB_A2P_PERF_PROFILE    = 3,
     parameter              CB_P2A_PERF_PROFILE    = 3,
     parameter              CB_PCIE_MODE           = 0,
     parameter              CB_PCIE_RX_LITE        = 0,
     parameter              CB_RXM_DATA_WIDTH      = 64,
     parameter              port_type_hwtcl   = "Native endpoint",
     parameter AVALON_ADDR_WIDTH = 32

)

  ( input          Clk_i,
    input          AvlClk_i,
    input          Rstn_i,
    input          RxmRstn_i,
    
   // Rx port interface to PCI Exp HIP
   output                    RxStReady_o,
   output                    RxStMask_o,
   input   [63:0]           RxStData_i,
   input   [31:0]            RxStParity_i,
   input   [7:0]            RxStBe_i,
   input   [1:0]             RxStEmpty_i,
   input                     RxStErr_i,
   input                    RxStSop_i,
   input                    RxStEop_i,
   input                    RxStValid_i,
   input   [7:0]             RxStBarDec1_i,
   input   [7:0]             RxStBarDec2_i,
    
    // Tx module interface
      // buffer credit for accepting rx read
    input          TxCpl_i,
    input  [9:0]   TxCplLen_i,  // Dw
      // Rx pnding read fifo
    output [56:0]  RxPndgRdFifoDat_o,
    output         RxPndgRdFifoEmpty_o,
    input          RxPndgRdFifoRdReq_i,
    
    output         CplTagRelease_o,
    
    
      output  [130:0]                        RxRpFifoWrData_o, 
      output                                 RxRpFifoWrReq_o,  
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
   output [(CB_RXM_DATA_WIDTH/8)-1:0]     RxmByteEnable_4_o,   
   output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_4_o,
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
    
    
    
    output [63:0] TxReadData_o,
    output        TxReadDataValid_o,
    
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
    input [31:0]   DevCsr_i,
    
    output         rxcntrl_sm_idle
    
  );
//define the clogb2 constant function
   function integer clogb2;
      input [31:0] depth;
      begin
         depth = depth - 1 ;
         for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1)
           depth = depth >> 1 ;       
      end
   endfunction // clogb2


localparam CB_RX_CD_BUFFER_DEPTH = (CB_P2A_PERF_PROFILE == 2)? 64 : 128;
localparam CB_RX_CPL_BUFFER_DEPTH =512;  // 8 tags , 512B
localparam RXCD_BUFF_ADDR_WIDTH     = clogb2(CB_RX_CD_BUFFER_DEPTH) ;   
localparam RX_CPL_BUFF_ADDR_WIDTH     =   clogb2(CB_RX_CPL_BUFFER_DEPTH) ;
wire   [7:0]      cdfifo_wrusedw;
wire              cdfifo_wrreq;
wire   [71:0]     cdfifo_datain;
wire   [3:0]      rxpndgrd_fifo_usedw;
wire              rxpndgrd_fifo_wrreq;
wire   [56:0]     rxpndgrd_fifo_datain;
wire              cdfifo_rdempty;
wire   [71:0]    cdfifo_dataout;
wire             rxpndgrd_fifo_wrfull;
wire             cdfifo_rdreq;

wire  [8:0]      cplram_wraddr;
wire   [8:0]     cplram_rdaddr;
wire  [65:0]     cplram_wrdat;
wire  [73:0]     cplram_data_out;   
reg   [63:0]     cplram_data_out_reg;       
wire             cpl_realease_tag;
wire  [4:0]      cpl_desc;
wire 		 cpl_req;
wire 		 cplram_wr_ena;
reg [56:0]       rx_pending_read_reg;
reg              rx_pending_valid_reg;
reg              rx_read_in_progress_reg;
wire             rx_read_in_progress;


// instantiate the Rx control module on the PCIe clock domain


altpciexpav_stif_rx_cntrl

#(

   .CG_COMMON_CLOCK_MODE(CG_COMMON_CLOCK_MODE),
   .CB_A2P_PERF_PROFILE(CB_A2P_PERF_PROFILE),
   .CB_P2A_PERF_PROFILE(CB_P2A_PERF_PROFILE),
   .CB_PCIE_MODE(CB_PCIE_MODE),
   .CB_RXM_DATA_WIDTH                    (CB_RXM_DATA_WIDTH),
   .CB_PCIE_RX_LITE                       (CB_PCIE_RX_LITE)  ,
   .port_type_hwtcl(port_type_hwtcl),
   .AVALON_ADDR_WIDTH (AVALON_ADDR_WIDTH) 
 )

rx_pcie_cntrl

 ( .Clk_i(Clk_i),
   .Rstn_i(Rstn_i),
   .AvlClk_i(AvlClk_i),
   .RxmRstn_i(RxmRstn_i),
    
    // Rx port interface to PCI Exp core
   .RxStReady_o(RxStReady_o),
   .RxStMask_o(RxStMask_o),
   .RxStData_i(RxStData_i),
   .RxStParity_i(RxStParity_i),
   .RxStBe_i(RxStBe_i),
   .RxStEmpty_i(RxStEmpty_i),
   .RxStErr_i(RxStErr_i),
   .RxStSop_i(RxStSop_i),
   .RxStEop_i(RxStEop_i),
   .RxStValid_i(RxStValid_i),
   .RxStBarDec1_i(RxStBarDec1_i),
   .RxStBarDec2_i(RxStBarDec2_i),
   
   /// RX Master Read Write Interface
   
   .RxmWrite_0_o          ( RxmWrite_0_o       ),
   .RxmAddress_0_o        ( RxmAddress_0_o     ),
   .RxmWriteData_0_o      ( RxmWriteData_0_o   ),
   .RxmByteEnable_0_o     ( RxmByteEnable_0_o  ),
   .RxmBurstCount_0_o     ( RxmBurstCount_0_o  ),
   .RxmWaitRequest_0_i    ( RxmWaitRequest_0_i ),
   .RxmRead_0_o           ( RxmRead_0_o        ),
   .RxmWrite_1_o          ( RxmWrite_1_o       ),
   .RxmAddress_1_o        ( RxmAddress_1_o     ),
   .RxmWriteData_1_o      ( RxmWriteData_1_o   ),
   .RxmByteEnable_1_o     ( RxmByteEnable_1_o  ),
   .RxmBurstCount_1_o     ( RxmBurstCount_1_o  ),
   .RxmWaitRequest_1_i    ( RxmWaitRequest_1_i ),
   .RxmRead_1_o           ( RxmRead_1_o        ),
   .RxmWrite_2_o          ( RxmWrite_2_o       ),
   .RxmAddress_2_o        ( RxmAddress_2_o     ),
   .RxmWriteData_2_o      ( RxmWriteData_2_o   ),
   .RxmByteEnable_2_o     ( RxmByteEnable_2_o  ),
   .RxmBurstCount_2_o     ( RxmBurstCount_2_o  ),
   .RxmWaitRequest_2_i    ( RxmWaitRequest_2_i ),
   .RxmRead_2_o           ( RxmRead_2_o        ),
   .RxmWrite_3_o          ( RxmWrite_3_o       ),
   .RxmAddress_3_o        ( RxmAddress_3_o     ),
   .RxmWriteData_3_o      ( RxmWriteData_3_o   ),
   .RxmByteEnable_3_o     ( RxmByteEnable_3_o  ),
   .RxmBurstCount_3_o     ( RxmBurstCount_3_o  ),
   .RxmWaitRequest_3_i    ( RxmWaitRequest_3_i ),
   .RxmRead_3_o           ( RxmRead_3_o        ),
   .RxmWrite_4_o          ( RxmWrite_4_o       ),
   .RxmAddress_4_o        ( RxmAddress_4_o     ),
   .RxmWriteData_4_o      ( RxmWriteData_4_o   ),
   .RxmByteEnable_4_o     ( RxmByteEnable_4_o  ),
   .RxmBurstCount_4_o     ( RxmBurstCount_4_o  ),
   .RxmWaitRequest_4_i    ( RxmWaitRequest_4_i ),
   .RxmRead_4_o           ( RxmRead_4_o        ),
   .RxmWrite_5_o          ( RxmWrite_5_o       ),
   .RxmAddress_5_o        ( RxmAddress_5_o     ),
   .RxmWriteData_5_o      ( RxmWriteData_5_o   ),
   .RxmByteEnable_5_o     ( RxmByteEnable_5_o  ),
   .RxmBurstCount_5_o     ( RxmBurstCount_5_o  ),
   .RxmWaitRequest_5_i    ( RxmWaitRequest_5_i ),
   .RxmRead_5_o           ( RxmRead_5_o        ),
   
   
   .CplReq_o(cpl_req),
   .CplDesc_o(cpl_desc),
    
    .PndngRdFifoUsedW_i(rxpndgrd_fifo_usedw),
    .PndgRdFifoWrReq_o(rxpndgrd_fifo_wrreq),
    .PndgRdHeader_o(rxpndgrd_fifo_datain),
    .PndngRdFifoEmpty_i(RxPndgRdFifoEmpty_o),
    .RxRdInProgress_i(rx_read_in_progress),
    
   // Completion data dual port ram interface
    .CplRamWrAddr_o(cplram_wraddr),
    .CplRamWrDat_o(cplram_wrdat),
    .CplRamWrEna_o(cplram_wr_ena),
    
    // Read respose module interface
    
    // Tx Completion interface
    .TxCpl_i(TxCpl_i),                                                        
    .TxCplLen_i(TxCplLen_i), // this is modified len (+1, +2, or unchanged)    
    
    .RxRpFifoWrData_o(RxRpFifoWrData_o),
    .RxRpFifoWrReq_o(RxRpFifoWrReq_o),  
      // cfg signals
    .DevCsr_i(DevCsr_i),    
        /// paramter signals  
    .k_bar_i(k_bar_i),                                    
    .cb_p2a_avalon_addr_b0_i(cb_p2a_avalon_addr_b0_i),    
    .cb_p2a_avalon_addr_b1_i(cb_p2a_avalon_addr_b1_i),    
    .cb_p2a_avalon_addr_b2_i(cb_p2a_avalon_addr_b2_i),    
    .cb_p2a_avalon_addr_b3_i(cb_p2a_avalon_addr_b3_i),    
    .cb_p2a_avalon_addr_b4_i(cb_p2a_avalon_addr_b4_i),    
    .cb_p2a_avalon_addr_b5_i(cb_p2a_avalon_addr_b5_i),    
    .cb_p2a_avalon_addr_b6_i(cb_p2a_avalon_addr_b6_i),
    .TxRespIdle_i(TxRespIdle_i),
    .rxcntrl_sm_idle(rxcntrl_sm_idle)      
  );                          




generate if (CB_PCIE_RX_LITE == 0)
begin
scfifo	pndgtxrd_fifo (
				.rdreq (RxPndgRdFifoRdReq_i),
				.clock (AvlClk_i),
				.wrreq (rxpndgrd_fifo_wrreq),
				.data (rxpndgrd_fifo_datain),
				.usedw (rxpndgrd_fifo_usedw),
				.empty (RxPndgRdFifoEmpty_o),
				.q (RxPndgRdFifoDat_o),
				.full () ,
				.aclr (~Rstn_i),
				.almost_empty (),
				.almost_full (),
				.sclr ()
				);
	defparam
		pndgtxrd_fifo.add_ram_output_register = "ON",
		pndgtxrd_fifo.intended_device_family = "Stratix IV",
		pndgtxrd_fifo.lpm_numwords = 16,
		pndgtxrd_fifo.lpm_showahead = "OFF",
		pndgtxrd_fifo.lpm_type = "scfifo",
		pndgtxrd_fifo.lpm_width = 57,
		pndgtxrd_fifo.lpm_widthu = 4,
		pndgtxrd_fifo.overflow_checking = "ON",
		pndgtxrd_fifo.underflow_checking = "ON",
		pndgtxrd_fifo.use_eab = "ON";
		
assign rx_read_in_progress = 1'b0;
end

else
  begin
   always @ (posedge Clk_i or negedge Rstn_i)
     if(~Rstn_i)
       rx_pending_read_reg <= 57'h0;
     else if(rxpndgrd_fifo_wrreq)
       rx_pending_read_reg <= rxpndgrd_fifo_datain;
 
  
 	        always @ (posedge Clk_i or negedge Rstn_i)         
  	          begin                                              
  	              if(~Rstn_i)                                     
  	                rx_pending_valid_reg <= 1'b0;                 
  	              else if(rxpndgrd_fifo_wrreq)                    
  	                rx_pending_valid_reg <= 1'b1;                 
  	              else if(RxPndgRdFifoRdReq_i)                    
  	                rx_pending_valid_reg <= 1'b0;                 
  	          end                                             
  	          
  	        always @ (posedge Clk_i or negedge Rstn_i)         
  	          begin                                              
  	              if(~Rstn_i)                                     
  	                rx_read_in_progress_reg <= 1'b0;                 
  	              else if(rxpndgrd_fifo_wrreq)                    
  	                rx_read_in_progress_reg <= 1'b1;                 
  	              else if(TxCpl_i)                    
  	                rx_read_in_progress_reg <= 1'b0;                 
  	          end                    
  	             
  
  assign RxPndgRdFifoEmpty_o = ~rx_pending_valid_reg;
  assign RxPndgRdFifoDat_o   = rx_pending_read_reg;
  assign rx_read_in_progress = rx_read_in_progress_reg;
 end
endgenerate
  
// instantiate the Rx Read respose module
altpciexpav_stif_rx_resp           
# ( 
     .CG_COMMON_CLOCK_MODE(CG_COMMON_CLOCK_MODE)
     
)
rxavl_resp

  
   ( .Clk_i(Clk_i),
     .AvlClk_i(AvlClk_i),
     .Rstn_i(Rstn_i),
     .RxmRstn_i(RxmRstn_i),
    
    // Interface to Transaction layer
     .CplReq_i(cpl_req),
     .CplDesc_i(cpl_desc), 
    
    /// interface to completion buffer
     .CplRdAddr_o(cplram_rdaddr),
     .CplBufData_i(cplram_data_out),
    
    // interface to tx control
     .TagRelease_o(CplTagRelease_o),
    
    // interface to Avalon slave
     //.TxsReadData_o(TxReadData_o),
     .TxsReadDataValid_o(TxReadDataValid_o)
  );
  
 // Muxing the tag ram read address
  // from the two reading sources : main control and read response
  
  
  //// instantiate the Rx Completion data ram
generate if(CB_PCIE_MODE == 0)
begin
altsyncram	
#(     
        .intended_device_family("Stratix"),              
        .operation_mode("DUAL_PORT"),                    
        .width_a(66),                                    
        .widthad_a(RX_CPL_BUFF_ADDR_WIDTH),                                  
        .numwords_a(CB_RX_CPL_BUFFER_DEPTH),                               
        .width_b(66),                                    
        .widthad_b(RX_CPL_BUFF_ADDR_WIDTH),                                  
        .numwords_b(CB_RX_CPL_BUFFER_DEPTH),                               
        .lpm_type("altsyncram"),                         
        .width_byteena_a(1),                             
        .outdata_reg_b("UNREGISTERED"),                        
        .indata_aclr_a("NONE"),                          
        .wrcontrol_aclr_a("NONE"),                       
        .address_aclr_a("NONE"),                         
        .address_reg_b("CLOCK0"),                        
        .address_aclr_b("NONE"),                         
        .outdata_aclr_b("NONE"),                         
        .read_during_write_mode_mixed_ports("DONT_CARE"),
        .power_up_uninitialized("FALSE")                
) 
  
  
cpl_ram (
				.wren_a (cplram_wr_ena),
				.clock0 (AvlClk_i),
				.address_a (cplram_wraddr),
				.address_b (cplram_rdaddr),
				.data_a (cplram_wrdat),
				.q_b (cplram_data_out),
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.rden_b (),
				.wren_b ()
				);

always @(posedge AvlClk_i)
   cplram_data_out_reg <= cplram_data_out[63:0];
				
assign TxReadData_o = cplram_data_out_reg[63:0];
				
end
  else
    begin
      assign TxReadData_o = 64'h0;
    end
    
endgenerate

endmodule
