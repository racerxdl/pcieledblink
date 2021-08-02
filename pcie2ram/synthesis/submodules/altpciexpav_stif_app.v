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
module altpciexpav_stif_app

#(   
     parameter              INTENDED_DEVICE_FAMILY = "Arria V",
     parameter              CG_AVALON_S_ADDR_WIDTH = 24,
     parameter              CG_COMMON_CLOCK_MODE   = 1,     
     parameter              CG_IMPL_CRA_AV_SLAVE_PORT = 1,
     parameter              CB_A2P_PERF_PROFILE    = 3,
     parameter              CB_P2A_PERF_PROFILE    = 3,
     parameter              CB_PCIE_MODE   = 0,
     parameter              CB_A2P_ADDR_MAP_IS_FIXED = 1,
     parameter  [1023:0]    CB_A2P_ADDR_MAP_FIXED_TABLE = 0,
     parameter              CB_A2P_ADDR_MAP_NUM_ENTRIES = 4,
     parameter              CB_A2P_ADDR_MAP_PASS_THRU_BITS = 22,   
     parameter              CB_P2A_AVALON_ADDR_B0 = 32'h01000000,
     parameter              CB_P2A_AVALON_ADDR_B1 = 32'h00000000,
     parameter              CB_P2A_AVALON_ADDR_B2 = 32'h00000000,
     parameter              CB_P2A_AVALON_ADDR_B3 = 32'h00000000,
     parameter              CB_P2A_AVALON_ADDR_B4 = 32'h00000000,
     parameter              CB_P2A_AVALON_ADDR_B5 = 32'h00000000,
     parameter              CB_P2A_AVALON_ADDR_B6 = 32'h00000000,
     parameter              bar0_64bit_mem_space = "true",          
     parameter              bar0_io_space = "false",                
     parameter              bar0_prefetchable = "true",             
     parameter              bar0_size_mask =  32 ,                  
     parameter              bar1_64bit_mem_space = "false",         
     parameter              bar1_io_space = "false",                
     parameter              bar1_prefetchable = "false",         
     parameter              bar1_size_mask =  0 ,                   
     parameter              bar2_64bit_mem_space = "false",         
     parameter              bar2_io_space = "false",                
     parameter              bar2_prefetchable = "false",            
     parameter              bar2_size_mask =  0 ,                   
     parameter              bar3_64bit_mem_space = "false",         
     parameter              bar3_io_space = "false",                
     parameter              bar3_prefetchable = "false",            
     parameter              bar3_size_mask =  0 ,                   
     parameter              bar4_64bit_mem_space = "false",         
     parameter              bar4_io_space = "false",                
     parameter              bar4_prefetchable = "false",            
     parameter              bar4_size_mask =  0 ,                   
     parameter              bar5_64bit_mem_space = "false",         
     parameter              bar5_io_space = "false",                
     parameter              bar5_prefetchable = "false",            
     parameter              bar5_size_mask =  0,
     parameter              bar_io_window_size = "NONE",           
     parameter              bar_prefetchable =  0 ,
     parameter              expansion_base_address_register =  0,
     parameter              EXTERNAL_A2P_TRANS     = 0,
     parameter              CG_ENABLE_A2P_INTERRUPT = 0,
     parameter              CG_ENABLE_ADVANCED_INTERRUPT = 0,
     parameter              CG_RXM_IRQ_NUM = 16,
     parameter              NUM_PREFETCH_MASTERS = 1,
     parameter              CB_PCIE_RX_LITE = 0,
     parameter              CB_RXM_DATA_WIDTH = 64,
     parameter              port_type_hwtcl   = "Native endpoint",
     parameter 							AVALON_ADDR_WIDTH = 32,
     parameter 							BYPASSS_A2P_TRANSLATION = 0,
     parameter              in_cvp_mode_hwtcl = 0,
     parameter              direct_tlp_enable_hwtcl = 0
     

  )  
     
     
 (   
     
// system iinputs
   input                               AvlClk_i,
   input                               Rstn_i,
     
// rx application interface
   // Rx port interface to PCI Exp HIP
   output                              RxStReady_o,
   output                              RxStMask_o,
   input   [63:0]                      RxStData_i,
   input   [31:0]                      RxStParity_i,
   input   [7:0]                       RxStBe_i,
   input   [1:0]                       RxStEmpty_i,
   input                               RxStErr_i,
   input                               RxStSop_i,
   input                               RxStEop_i,
   input                               RxStValid_i,
   input   [7:0]                       RxStBarDec1_i,
   input   [7:0]                       RxStBarDec2_i,
// Tx application interface
   input                               TxStReady_i  ,
   output   [63:0]                     TxStData_o   ,
   output   [31:0]                     TxStParity_o ,
   output                              TxStErr_o    ,
   output                              TxStSop_o    ,
   output                              TxStEop_o    ,
   output   [1:0]                      TxStEmpty_o  ,
   output                              TxStValid_o  ,
   input                               TxAdapterFifoEmpty_i,
   output                              CplPending_o,
/// tx Credit interface
   input   [11 : 0]                    TxCredPDataLimit_i, 
   input   [11 : 0]                    TxCredNpDataLimit_i,
   input   [11 : 0]                    TxCredCplDataLimit_i,
   input   [5 : 0]                     TxCredHipCons_i,
   input   [5 : 0]                     TxCredInfinit_i,
   input   [7 : 0]                     TxCredPHdrLimit_i,
   input   [7 : 0]                     TxCredNpHdrLimit_i,
   input   [7 : 0]                     TxCredCplHdrLimit_i,
   input   [7:0]                       ko_cpl_spc_header,
   input   [11:0]                      ko_cpl_spc_data,
   input    [35:0]                     TxCredit_i,
   input                               TxNpCredOne_i,

  // Config interface          
  input                                CfgCtlWr_i,  
  input [3:0]                          CfgAddr_i, 
  input [31:0]                         CfgCtl_i,  

// MSI and Interrupt interface
output                                 MsiReq_o,
input                                  MsiAck_i,
output          [2:0]                  MsiTc_o,
output          [4:0]                  MsiNum_o,    

output                                 IntxReq_o,
input                                  IntxAck_i,                             

// Avalon Tx Slave interface
input                                  TxsClk_i,
input                                  TxsRstn_i,
input                                  TxsChipSelect_i,
input                                  TxsRead_i,
input                                  TxsWrite_i,
input  [63:0]                          TxsWriteData_i,
input  [6:0]                           TxsBurstCount_i,
input  [CG_AVALON_S_ADDR_WIDTH-1:0]    TxsAddress_i,
input  [7:0]                           TxsByteEnable_i,
output                                 TxsReadDataValid_o, // This comes from Rx Completion to be returned to Avalon master
output  [63:0]                         TxsReadData_o,      // This comes from Rx Completion to be returned to Avalon master
output                                 TxsWaitRequest_o,

// Avalon Rx Master interface                                       
    
output                                 RxmWrite_0_o,
output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_0_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_0_o,
output [7:0]                           RxmByteEnable_0_o,
output [6:0]                           RxmBurstCount_0_o, 
input                                  RxmWaitRequest_0_i,
output                                 RxmRead_0_o,
input  [CB_RXM_DATA_WIDTH-1:0]         RxmReadData_0_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_0_i,     // this comes from Avalon Slave to be routed to Tx completion

output                                 RxmWrite_1_o,
output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_1_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_1_o,
output [7:0]                           RxmByteEnable_1_o,
output [6:0]                           RxmBurstCount_1_o, 
input                                  RxmWaitRequest_1_i,
output                                 RxmRead_1_o,
input  [CB_RXM_DATA_WIDTH-1:0]         RxmReadData_1_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_1_i,     // this comes from Avalon Slave to be routed to Tx completion

output                                 RxmWrite_2_o,
output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_2_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_2_o,
output [7:0]                           RxmByteEnable_2_o,
output [6:0]                           RxmBurstCount_2_o, 
input                                  RxmWaitRequest_2_i,
output                                 RxmRead_2_o,
input [CB_RXM_DATA_WIDTH-1:0]          RxmReadData_2_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_2_i,     // this comes from Avalon Slave to be routed to Tx completion

output                                 RxmWrite_3_o,
output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_3_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_3_o,
output [7:0]                           RxmByteEnable_3_o,
output [6:0]                           RxmBurstCount_3_o, 
input                                  RxmWaitRequest_3_i,
output                                 RxmRead_3_o,
input  [CB_RXM_DATA_WIDTH-1:0]         RxmReadData_3_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_3_i,     // this comes from Avalon Slave to be routed to Tx completion

output                                 RxmWrite_4_o,
output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_4_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_4_o,
output [7:0]                           RxmByteEnable_4_o,
output [6:0]                           RxmBurstCount_4_o, 
input                                  RxmWaitRequest_4_i,
output                                 RxmRead_4_o,
input [CB_RXM_DATA_WIDTH-1:0]          RxmReadData_4_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_4_i,     // this comes from Avalon Slave to be routed to Tx completion

output                                 RxmWrite_5_o,
output [AVALON_ADDR_WIDTH-1:0]         RxmAddress_5_o,
output [CB_RXM_DATA_WIDTH-1:0]         RxmWriteData_5_o,
output [7:0]                           RxmByteEnable_5_o,
output [6:0]                           RxmBurstCount_5_o, 
input                                  RxmWaitRequest_5_i,
output                                 RxmRead_5_o,
input  [CB_RXM_DATA_WIDTH-1:0]         RxmReadData_5_i,         // this comes from Avalon Slave to be routed to Tx completion
input                                  RxmReadDataValid_5_i,     // this comes from Avalon Slave to be routed to Tx completion

input  [CG_RXM_IRQ_NUM-1 : 0]          RxmIrq_i,

// Avalon Contol Register Access (CRA) Slave (This is 32-bit interface)
input                                  CraClk_i,
input                                  CraRstn_i,
input                                  CraChipSelect_i,
input                                  CraRead,
input                                  CraWrite,
input  [31:0]                          CraWriteData_i,
input  [13:2]                          CraAddress_i,
input  [3:0]                           CraByteEnable_i,
output [31:0]                          CraReadData_o,      // This comes from Rx Completion to be returned to Avalon master
output                                 CraWaitRequest_o,
output                                 CraIrq_o,
  /// MSI/MSI-X supported signals
output  [81:0]                         MsiIntfc_o,
output  [15:0]                         MsiControl_o,
output  [15:0]                         MsixIntfc_o,
input   [3:0]                          RxIntStatus_i,

input                                  pld_clk_inuse,
output                                 tx_cons_cred_sel,
input   [4:0]                          ltssm_state,
input   [1:0]                          current_speed,
input   [3:0]                          lane_act

/// Parmeter signals

 );

localparam CG_NUM_A2P_MAILBOX = (CB_P2A_PERF_PROFILE == 3)? 8 : 1;
localparam CG_NUM_P2A_MAILBOX = (CB_A2P_PERF_PROFILE == 3)? 8 : 1;
localparam FIXED_ADDRESS_TRANS = (INTENDED_DEVICE_FAMILY == "Stratix IV" ||  INTENDED_DEVICE_FAMILY == "Cyclone IV GX" || INTENDED_DEVICE_FAMILY == "HardCopy IV" || INTENDED_DEVICE_FAMILY == "Arria II GZ" || INTENDED_DEVICE_FAMILY == "Arria II GX" ) ? CB_A2P_ADDR_MAP_IS_FIXED  : 0;

wire                                   rxpndgrd_fifo_empty;
wire [56:0]                            rxpndgrd_fifo_dato;
wire                                   rxcpl_freed;
wire [10:0]                            rxcpl_dw_freed;
wire                                   rxcpl_tagram_wrena;
wire  [22:0]                           rxcpl_tagram_wrdat;
wire  [4:0]                            rxcpl_tagram_addr;
wire  [22:0]                           rxcpl_tagram_rddat;
wire                                   rxpndgrd_fifo_rdreq;
wire                                   txcpl_sent;
wire  [9:0]                            txcpl_dw_sent;
wire [9:0] 			                       atrans_table_addr;
wire [3:0] 			                       atrans_bena;
wire [31:0] 			                     atrans_wr_dat;
wire [31:0] 			                     atrans_rd_dat;
wire 				                           CraRead_i = CraRead;
wire 				                           CraWrite_i = CraWrite;
wire 	  															 cg_common_clock_mode_i = (CG_COMMON_CLOCK_MODE == 0) ? 0 : 1;
reg  [31:0]    dev_csr_reg            /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL =D101" */        ;
reg  [227:0]                             init_k_bar;
wire [227:0]                             k_bar;
reg  [12:0]                              cfg_busdev;
reg  [31:0]                              cfg_dev_csr;
reg  [15:0]                              msi_ena;   
reg  [15:0]                              msix_control;
reg  [15:0]                              cfg_prmcsr;
reg  [63:0]                              msi_addr;
reg  [15:0]                              msi_data;
wire [31:0]															 pcie_intr_ena;
wire 																		 a2p_mb_wrreq;
wire [11:0]	 														 a2p_mb_wraddr;
wire      															 cpl_tag_release;
wire 	  																 atrans_wr_ena;
wire 	  																 atrans_rdaddr_vld;
wire 	  																 pci_irqn;
wire 	  																 atrans_rdat_vld;
reg       															 rstn_r; 
wire      															 rstn_reg; 
reg       															 rstn_rr;       
wire      															 rxm_read_data_valid;
reg  [63:0] 														 rxm_read_data;
wire  [5:0]   													 read_valid_vector;
wire          													 rxm_read_data_valid_0;
wire          													 rxm_wait_request_0;
wire  [63:0]  													 rxm_read_data_0;
wire          													 rxm_read_data_valid_1;
wire          													 rxm_wait_request_1;
wire  [63:0]  													 rxm_read_data_1;
wire          													 rxm_read_data_valid_2;
wire          													 rxm_wait_request_2;
wire  [63:0]  													 rxm_read_data_2;
wire          													 rxm_read_data_valid_3;
wire          													 rxm_wait_request_3;
wire  [63:0]  													 rxm_read_data_3;
wire          													 rxm_read_data_valid_4;
wire          													 rxm_wait_request_4;
wire  [63:0]  													 rxm_read_data_4;
wire          													 rxm_read_data_valid_5;
wire          													 rxm_wait_request_5;
wire  [63:0]  													 rxm_read_data_5;
wire          													 tx_resp_idle;
reg   [15:0]   													 msi_ena_reg;      
reg   [15:0]  													 msix_control_reg;
reg   [63:0]  													 msi_addr_reg; 
reg   [15:0]  													 msi_data_reg;  
wire          													 rxrp_fifo_wrreq;  
wire [130:0]  													 rxrp_fifo_datain;      
wire [65:0]  								  					 txrp_fifo_dataout;        
wire                                     tx_cmd_empty;
wire                                     rxcntrl_sm_idle;
wire                                     txrp_fifo_rdreq;
wire                                     txrp_tlp_ready;
reg  [3:0]                               cfgctl_add_reg;
reg  [3:0]                               cfgctl_add_reg2;
reg  [31:0]                              cfgctl_data_reg;
reg  [3:0]                               lane_act_reg;
reg  [1:0]                               current_speed_reg;
reg   [31:0]                             captured_cfg_data_reg;     
reg   [3:0]                              captured_cfg_addr_reg;     
reg                                      cfgctl_addr_change;        
reg                                      cfgctl_addr_change2;       
reg                                      cfgctl_addr_strobe;        

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

always @*
  begin
    case (read_valid_vector)
        6'b000001 : rxm_read_data = rxm_read_data_0[63:0];
        6'b000010 : rxm_read_data = rxm_read_data_1[63:0];
        6'b000100 : rxm_read_data = rxm_read_data_2[63:0];
        6'b001000 : rxm_read_data = rxm_read_data_3[63:0];
        6'b010000 : rxm_read_data = rxm_read_data_4[63:0];
        6'b100000 : rxm_read_data = rxm_read_data_5[63:0];
        default   : rxm_read_data = 64'h0;
  endcase
end
 
always @(posedge AvlClk_i or negedge rstn_reg)
  begin
    if(~rstn_reg)
      begin
       dev_csr_reg[31:0] <= 32'h0;
       msi_ena_reg       <= 16'h0;    
       msix_control_reg  <= 16'h0;
       msi_data_reg      <= 16'h0;
       msi_addr_reg      <= 64'h0;
      end
    else
      begin
       dev_csr_reg[31:0] <= cfg_dev_csr;
       msi_ena_reg       <= msi_ena;     
       msix_control_reg  <= msix_control;
       msi_data_reg      <= msi_data;   
       msi_addr_reg      <= msi_addr;   
     end
  end

assign MsiControl_o = msi_ena_reg;
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
  	if(~Rstn_i)
  	  begin
        rstn_r <= 1'b0; 
        rstn_rr <= 1'b0;
       end
    else
       begin
       	  rstn_r <= 1'b1;
          rstn_rr <= rstn_r;
       end
  end
 
 assign rstn_reg = rstn_rr;



/// Instantiate the Rx interface

altpciexpav_stif_rx
# ( 

     .CG_COMMON_CLOCK_MODE(CG_COMMON_CLOCK_MODE),
     .CB_A2P_PERF_PROFILE(CB_A2P_PERF_PROFILE),
     .CB_P2A_PERF_PROFILE(CB_P2A_PERF_PROFILE),
     .CB_PCIE_MODE(CB_PCIE_MODE),
     .CB_RXM_DATA_WIDTH(CB_RXM_DATA_WIDTH),
     .CB_PCIE_RX_LITE(CB_PCIE_RX_LITE),
     .port_type_hwtcl(port_type_hwtcl),
     .AVALON_ADDR_WIDTH (AVALON_ADDR_WIDTH)
)
rx

  ( .Clk_i(AvlClk_i),
    .AvlClk_i(AvlClk_i),
    .Rstn_i(rstn_reg),
    .RxmRstn_i(rstn_reg),
    
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
    
   .TxCpl_i(txcpl_sent),        // side band from Tx module to release Tx Cpl Credit 
   .TxCplLen_i(txcpl_dw_sent),  // side band from Tx module to release Tx Cpl Credit in dword
    
   .RxPndgRdFifoDat_o(rxpndgrd_fifo_dato), // stuff the header to the pending read buffer when accepting a read
   .RxPndgRdFifoEmpty_o(rxpndgrd_fifo_empty),
   .RxPndgRdFifoRdReq_i(rxpndgrd_fifo_rdreq),
   .CplTagRelease_o(cpl_tag_release),
    
 /// RX Master Read Write Interface
   
   .RxmWrite_0_o          ( RxmWrite_0_o       ),
   .RxmAddress_0_o        ( RxmAddress_0_o     ),
   .RxmWriteData_0_o      ( RxmWriteData_0_o   ),
   .RxmByteEnable_0_o     ( RxmByteEnable_0_o  ),
   .RxmBurstCount_0_o     ( RxmBurstCount_0_o  ),
   .RxmWaitRequest_0_i    ( rxm_wait_request_0 ),
   .RxmRead_0_o           ( RxmRead_0_o        ),
   .RxmWrite_1_o          ( RxmWrite_1_o       ),
   .RxmAddress_1_o        ( RxmAddress_1_o     ),
   .RxmWriteData_1_o      ( RxmWriteData_1_o   ),
   .RxmByteEnable_1_o     ( RxmByteEnable_1_o  ),
   .RxmBurstCount_1_o     ( RxmBurstCount_1_o  ),
   .RxmWaitRequest_1_i    ( rxm_wait_request_1 ),
   .RxmRead_1_o           ( RxmRead_1_o        ),
   .RxmWrite_2_o          ( RxmWrite_2_o       ),
   .RxmAddress_2_o        ( RxmAddress_2_o     ),
   .RxmWriteData_2_o      ( RxmWriteData_2_o   ),
   .RxmByteEnable_2_o     ( RxmByteEnable_2_o  ),
   .RxmBurstCount_2_o     ( RxmBurstCount_2_o  ),
   .RxmWaitRequest_2_i    ( rxm_wait_request_2 ),
   .RxmRead_2_o           ( RxmRead_2_o        ),
   .RxmWrite_3_o          ( RxmWrite_3_o       ),
   .RxmAddress_3_o        ( RxmAddress_3_o     ),
   .RxmWriteData_3_o      ( RxmWriteData_3_o   ),
   .RxmByteEnable_3_o     ( RxmByteEnable_3_o  ),
   .RxmBurstCount_3_o     ( RxmBurstCount_3_o  ),
   .RxmWaitRequest_3_i    ( rxm_wait_request_3 ),
   .RxmRead_3_o           ( RxmRead_3_o        ),
   .RxmWrite_4_o          ( RxmWrite_4_o       ),
   .RxmAddress_4_o        ( RxmAddress_4_o     ),
   .RxmWriteData_4_o      ( RxmWriteData_4_o   ),
   .RxmByteEnable_4_o     ( RxmByteEnable_4_o  ),
   .RxmBurstCount_4_o     ( RxmBurstCount_4_o  ),
   .RxmWaitRequest_4_i    ( rxm_wait_request_4 ),
   .RxmRead_4_o           ( RxmRead_4_o        ),
   .RxmWrite_5_o          ( RxmWrite_5_o       ),
   .RxmAddress_5_o        ( RxmAddress_5_o     ),
   .RxmWriteData_5_o      ( RxmWriteData_5_o   ),
   .RxmByteEnable_5_o     ( RxmByteEnable_5_o  ),
   .RxmBurstCount_5_o     ( RxmBurstCount_5_o  ),
   .RxmWaitRequest_5_i    ( rxm_wait_request_5 ),
   .RxmRead_5_o           ( RxmRead_5_o        ),
   .TxRespIdle_i          (tx_resp_idle        ),
   .RxRpFifoWrReq_o       (rxrp_fifo_wrreq     ),  
   .RxRpFifoWrData_o      (rxrp_fifo_datain    ), 
   .rxcntrl_sm_idle       (rxcntrl_sm_idle     ),
    
    
    .TxReadData_o(TxsReadData_o),
    .TxReadDataValid_o(TxsReadDataValid_o),
    
    .cb_p2a_avalon_addr_b0_i(CB_P2A_AVALON_ADDR_B0),
    .cb_p2a_avalon_addr_b1_i(CB_P2A_AVALON_ADDR_B1),
    .cb_p2a_avalon_addr_b2_i(CB_P2A_AVALON_ADDR_B2),
    .cb_p2a_avalon_addr_b3_i(CB_P2A_AVALON_ADDR_B3),
    .cb_p2a_avalon_addr_b4_i(CB_P2A_AVALON_ADDR_B4),
    .cb_p2a_avalon_addr_b5_i(CB_P2A_AVALON_ADDR_B5),
    .cb_p2a_avalon_addr_b6_i(CB_P2A_AVALON_ADDR_B6),
    .k_bar_i(k_bar),
    .DevCsr_i(dev_csr_reg)
  );		


/// instantiate the Tx module

 altpciexpav_stif_tx
 
 #( .INTENDED_DEVICE_FAMILY(INTENDED_DEVICE_FAMILY),
    .CG_AVALON_S_ADDR_WIDTH(CG_AVALON_S_ADDR_WIDTH),
    .CG_COMMON_CLOCK_MODE(CG_COMMON_CLOCK_MODE),
    .CB_PCIE_MODE(CB_PCIE_MODE),
    .CB_A2P_PERF_PROFILE(CB_A2P_PERF_PROFILE),
    .CB_P2A_PERF_PROFILE(CB_P2A_PERF_PROFILE),
    .CB_A2P_ADDR_MAP_IS_FIXED(FIXED_ADDRESS_TRANS),
    .CB_A2P_ADDR_MAP_FIXED_TABLE(CB_A2P_ADDR_MAP_FIXED_TABLE),
    .CB_A2P_ADDR_MAP_NUM_ENTRIES(CB_A2P_ADDR_MAP_NUM_ENTRIES),
    .CB_A2P_ADDR_MAP_PASS_THRU_BITS(CB_A2P_ADDR_MAP_PASS_THRU_BITS),
    .EXTERNAL_A2P_TRANS(EXTERNAL_A2P_TRANS),
    .CG_RXM_IRQ_NUM(CG_RXM_IRQ_NUM),
    .CB_PCIE_RX_LITE(CB_PCIE_RX_LITE),
    .deviceFamily(INTENDED_DEVICE_FAMILY),
    .BYPASSS_A2P_TRANSLATION(BYPASSS_A2P_TRANSLATION),
    .AVALON_ADDR_WIDTH(AVALON_ADDR_WIDTH),
    .in_cvp_mode_hwtcl(in_cvp_mode_hwtcl)
  )
 
 
 tx

  ( 
     .Clk_i(AvlClk_i),
     .Rstn_i(rstn_reg),
     .AvlClk_i(AvlClk_i),
     .TxsRstn_i(rstn_reg),
     .TxChipSelect_i(TxsChipSelect_i),
     .TxRead_i(TxsRead_i),
     .TxWrite_i(TxsWrite_i),
     .TxWriteData_i(TxsWriteData_i),
     .TxBurstCount_i(TxsBurstCount_i),
     .TxAddress_i(TxsAddress_i),
     .TxByteEnable_i(TxsByteEnable_i),
     .TxReadDataValid_i(rxm_read_data_valid),
     .TxReadData_i(rxm_read_data),
     .TxWaitRequest_o(TxsWaitRequest_o),
     .TxsReadDataValid_i(TxsReadDataValid_o),
     .RxmIrq_i(RxmIrq_i),     
     .MasterEnable_i(cfg_prmcsr[2]),
     
     .TxStReady_i  (TxStReady_i),
     .TxStData_o   (TxStData_o),
     .TxStParity_o (TxStParity_o),
     .TxStErr_o    (TxStErr_o),
     .TxStSop_o    (TxStSop_o),
     .TxStEop_o    (TxStEop_o),
     .TxStEmpty_o  (TxStEmpty_o),
     .TxStValid_o  (TxStValid_o),
     .TxAdapterFifoEmpty_i(TxAdapterFifoEmpty_i),
     
     .CplPending_o(CplPending_o),
     .DevCsr_i(dev_csr_reg), 
     .BusDev_i(cfg_busdev), 
     .TxCredHipCons_i(TxCredHipCons_i),    
     .TxCredInfinit_i(TxCredInfinit_i),    
     .TxCredNpHdrLimit_i(TxCredNpHdrLimit_i),
     
     .ko_cpl_spc_header(ko_cpl_spc_header),
     .ko_cpl_spc_data(ko_cpl_spc_data),
     
     .TxCredit_i(TxCredit_i),
     .TxNpCredOne_i(TxNpCredOne_i),
     
     .RxPndgRdFifoEmpty_i(rxpndgrd_fifo_empty),
     .RxPndgRdFifoDato_i(rxpndgrd_fifo_dato),
      .CplTagRelease_i(cpl_tag_release),
     
     .RxPndgRdFifoRdReq_o(rxpndgrd_fifo_rdreq),
     .TxCplSent_o(txcpl_sent),
     .TxCplDwSent_o(txcpl_dw_sent),
     
     .AdTrAddress_i(atrans_table_addr),    
     .AdTrByteEnable_i(atrans_bena), 
     .AdTrWriteVld_i(atrans_wr_ena),  
     .AdTrWriteData_i(atrans_wr_dat), 
     .AdTrReadVld_i(atrans_rdaddr_vld),   
     .AdTrReadData_o(atrans_rd_dat),  
     .AdTrReadVld_o(atrans_rdat_vld),
     .MsiCsr_i(msi_ena_reg),
     .MsiAddr_i(msi_addr_reg),
     .MsiData_i(msi_data_reg),
     .MsiReq_o(MsiReq_o),
     .MsiAck_i(MsiAck_i),
     .IntxReq_o(),
     .IntxAck_i(),
     .PCIeIrqEna_i(pcie_intr_ena),
     .A2PMbWrReq_i(a2p_mb_wrreq),
     .A2PMbWrAddr_i(a2p_mb_wraddr),
     .TxRespIdle_o(tx_resp_idle),
     
     .TxRpFifoRdReq_o(txrp_fifo_rdreq),
     .TxRpFifoData_i(txrp_fifo_dataout),
     .RpTLPReady_i(txrp_tlp_ready),
     .RpTLPAck_o(txrp_tlp_ack),
     .pld_clk_inuse(pld_clk_inuse),
     .tx_cons_cred_sel(tx_cons_cred_sel),
     .TxBufferEmpty_o(tx_cmd_empty)
     
  );

/// instantiate the control register module

generate if(CG_IMPL_CRA_AV_SLAVE_PORT == 1)

begin

altpciexpav_stif_control_register
  #(
    .INTENDED_DEVICE_FAMILY(INTENDED_DEVICE_FAMILY),
    .CG_NUM_A2P_MAILBOX(CG_NUM_A2P_MAILBOX),
    .CG_NUM_P2A_MAILBOX(CG_NUM_P2A_MAILBOX),
    .CG_ENABLE_A2P_INTERRUPT(CG_ENABLE_A2P_INTERRUPT),
    .CG_RXM_IRQ_NUM(CG_RXM_IRQ_NUM),
    .port_type_hwtcl(port_type_hwtcl),
    .direct_tlp_enable_hwtcl(direct_tlp_enable_hwtcl)

        )
cntrl_reg
  (
   // Avalon Interface signals (all synchronous to CraClk_i)
   .CraClk_i(AvlClk_i),           // Clock for register access port
   .CraRstn_i(rstn_reg),          // Reset signal  
   .CraChipSelect_i(CraChipSelect_i),    // Chip Select signals
   .CraAddress_i(CraAddress_i),       // Register (DWORD) specific address
   .CraByteEnable_i(CraByteEnable_i),    // Register Byte Enables
   .CraRead_i(CraRead_i),          // Read indication
   .CraReadData_o(CraReadData_o),      // Read data lines
   .CraWrite_i(CraWrite_i),         // Write indication 
   .CraWriteData_i(CraWriteData_i),     // Write Data in 
   .CraWaitRequest_o(CraWaitRequest_o),   // Wait indication out 
   .PciClk_i(AvlClk_i),           // PCI Bus Clock
   .PciRstn_i(rstn_reg),          // PCI Bus Reset
   .PciIntan_i(1'b1),         // PCI Bus interrupt
   .PciComp_Stat_Reg_i(6'h0), // PCI Compiler Stat_Reg
   .PciComp_lirqn_o(pci_irqn),    // PCI Compiler IRQ 
   .MsiReq_o(),
   .MsiAck_i(1'b0),
   .MsiTc_o(),
   .MsiNum_o(),
   .PciNonpDataDiscardErr_i(1'b0), // NonPre Data Discarded
   .PciMstrWriteFail_i(1'b0), // PCI Master Write failed
   .PciMstrReadFail_i(1'b0),  // PCI Master Read failed
   .PciMstrWritePndg_i(1'b0), // PCI Master Write Pending
   .PciComp_MstrEnb_i(1'b1),
   // Avalon Interrupt Signals
   // All synchronous to CraClk_i
   .CraIrq_o(CraIrq_o),           // Interrupt Request out
   .RxmIrq_i(RxmIrq_i),            // NonP Master Interrupt in
   .RxmIrqNum_i(),
   // Modified Avalon signals to the Address Translation logic
   // All synchronous to CraClk_i
   .cg_common_clock_mode_i(cg_common_clock_mode_i),
   .AdTrWriteReqVld_o(atrans_wr_ena),  // Valid Write Cycle to AddrTrans  
   .AdTrReadReqVld_o(atrans_rdaddr_vld),   // Read Valid out to AddrTrans
   .AdTrAddress_o(atrans_table_addr),      // Address to AddrTrans
   .AdTrWriteData_o(atrans_wr_dat),    // Write Data to AddrTrans
   .AdTrByteEnable_o(atrans_bena),   // Write Byte Enables to AddrTrans
   .AdTrReadData_i(atrans_rd_dat),     // Read Data in from AddrTrans
   .AdTrReadDataVld_i(atrans_rdat_vld),  // Read Valid in from AddrTrans,
   .PciRuptEnable_o(pcie_intr_ena),
   .A2PMbWriteReq_o(a2p_mb_wrreq),
   .A2PMbWriteAddr_o(a2p_mb_wraddr),
   
   .TxRpFifoRdReq_i(txrp_fifo_rdreq),
   .TxRpFifoData_o(txrp_fifo_dataout),
   .RpTLPReady_o(txrp_tlp_ready),
   .RpTLPAck_i(txrp_tlp_ack),
   .RxRpFifoWrReq_i(rxrp_fifo_wrreq),
   .RxRpFifoWrData_i(rxrp_fifo_datain),
   .AvalonIrqReq_i({rxrp_fifo_wrreq, RxIntStatus_i}),
   .TxBufferEmpty_i(tx_cmd_empty),
   .ltssm_state(ltssm_state),        
   .rxcntrl_sm_idle(rxcntrl_sm_idle),
   
   .CfgAddr_i(captured_cfg_addr_reg), 
   .CfgCtl_i(captured_cfg_data_reg),
   .CurrentSpeed_i(current_speed_reg),     
   .LaneAct_i(lane_act_reg)          
   
   
   
    
   ) ;
end

else
 begin
//   assign MsiReq_o = 1'b0;
   assign MsiTc_o  = 3'h0;
   assign MsiNum_o  = 5'h0;
   assign pcie_intr_ena = 32'h0;
   assign a2p_mb_wraddr = 12'h0;
   assign a2p_mb_wrreq = 1'b0;
   assign pci_irqn = 1'b1;
   assign txrp_fifo_dataout = 66'h0;
   assign txrp_tlp_ready = 1'b0;
 end

endgenerate

   assign MsiTc_o  = 3'h0;
   assign MsiNum_o  = 5'h0;
   assign IntxReq_o = ~pci_irqn;
   
   
   // Pipeline reg for CfgCtl interface
    always @(posedge AvlClk_i or negedge rstn_reg) 
     begin
        if (rstn_reg == 0)
          begin
            cfgctl_add_reg  <= 4'h0;
            cfgctl_data_reg <= 32'h0;
            lane_act_reg    <= 4'h0;
            current_speed_reg <= 2'b00;
          end
        else 
          begin
             cfgctl_add_reg  <= CfgAddr_i;
             cfgctl_add_reg2  <= cfgctl_add_reg;
             cfgctl_data_reg <= CfgCtl_i;
             lane_act_reg    <= lane_act;
             current_speed_reg <= current_speed;
          end
     end            

///////////// Synch and Demux the BusDev from configuration signals
    //Synchronise to pld side 

    //Configuration Demux logic 
    always @(posedge AvlClk_i or negedge Rstn_i) 
     begin
        if (Rstn_i == 0)
          begin
            cfg_busdev  <= 13'h0;
            cfg_dev_csr <= 32'h0;
            msi_ena     <= 16'b0;
            msix_control <= 16'h0;
            msi_data    <= 16'h0;
            msi_addr    <= 64'h0;
            cfg_prmcsr  <= 16'h0;
          end
        else 
          begin
            cfg_busdev          <= (captured_cfg_addr_reg[3:0]==4'hF) ? captured_cfg_data_reg[12 : 0]  : cfg_busdev;
            cfg_dev_csr         <= (captured_cfg_addr_reg[3:0]==4'h0) ? {16'h0, captured_cfg_data_reg[31 : 16]}  : cfg_dev_csr;
            msi_ena             <= (captured_cfg_addr_reg[3:0]==4'hD) ? captured_cfg_data_reg[15:0]   :  msi_ena;
            msix_control        <= (captured_cfg_addr_reg[3:0] == 4'hD) ? captured_cfg_data_reg[31:16]  :  msix_control; 
            cfg_prmcsr          <= (captured_cfg_addr_reg[3:0]==4'h3) ? captured_cfg_data_reg[23:8]   :  cfg_prmcsr;
            msi_addr[11:0]      <= (captured_cfg_addr_reg[3:0]==4'h5) ? captured_cfg_data_reg[31:20]  :  msi_addr[11:0];
            msi_addr[31:12]     <= (captured_cfg_addr_reg[3:0]==4'h9) ? captured_cfg_data_reg[31:12]  :  msi_addr[31:12];
            msi_addr[43:32]     <= (captured_cfg_addr_reg[3:0]==4'h6) ? captured_cfg_data_reg[31:20]  :  msi_addr[43:32];
            msi_addr[63:44]     <= (captured_cfg_addr_reg[3:0]==4'hB) ? captured_cfg_data_reg[31:12]  :  msi_addr[63:44];
            msi_data[15:0]      <= (captured_cfg_addr_reg[3:0]==4'hF) ? captured_cfg_data_reg[31:16]  :  msi_data[15:0];
          end
     end 
               
assign MsiIntfc_o[63:0]  = msi_addr_reg;
assign MsiIntfc_o[79:64] = msi_data_reg;
assign MsiIntfc_o[80]    = msi_ena_reg[0];
assign MsiIntfc_o[81]    = cfg_prmcsr[2];  // Master Enable
assign MsixIntfc_o[15:0] = msix_control_reg;

/// Parameters conversion to signals
initial begin
    
	init_k_bar[0:0] = (bar0_io_space == "true" ? 1'b1 : 1'b0);
	init_k_bar[2:1] = (bar0_64bit_mem_space == "true" ? 2'b10 : 2'b00);
	init_k_bar[3:3] = (bar0_prefetchable == "true" ? 1'b1 : 1'b0);
	if (bar0_64bit_mem_space == "true")
	begin
		init_k_bar[63:4] = 60'hffff_ffff_ffff_fff << (bar0_size_mask - 3'b100);
	end
	else begin
		init_k_bar[31:4] = 28'hffff_fff << (bar0_size_mask - 3'b100);
		init_k_bar[32:32] = (bar1_io_space == "true" ? 1'b1 : 1'b0);
		init_k_bar[34:33] = (bar1_64bit_mem_space == "true" ? 2'b10 : 2'b00);
		init_k_bar[35:35] = (bar1_prefetchable == "true" ? 1'b1 : 1'b0);
		init_k_bar[63:36] = 28'hffff_fff << (bar1_size_mask - 3'b100);
	end
	init_k_bar[64:64] = (bar2_io_space == "true" ? 1'b1 : 1'b0);
	init_k_bar[66:65] = (bar2_64bit_mem_space == "true" ? 2'b10 : 2'b00);
	init_k_bar[67:67] = (bar2_prefetchable == "true" ? 1'b1 : 1'b0);
	if (bar2_64bit_mem_space == "true")
	begin
		init_k_bar[127:68] = 60'hffff_ffff_ffff_fff << (bar2_size_mask - 3'b100);
	end
	else begin
		init_k_bar[95:68] = 28'hffff_fff << (bar2_size_mask - 3'b100);
		init_k_bar[96:96] = (bar3_io_space == "true" ? 1'b1 : 1'b0);
		init_k_bar[98:97] = (bar3_64bit_mem_space == "true" ? 2'b10 : 2'b00);
		init_k_bar[99:99] = (bar3_prefetchable == "true" ? 1'b1 : 1'b0);
		init_k_bar[127:100] = 28'hffff_fff << (bar3_size_mask - 3'b100);
	end
	init_k_bar[128:128] = (bar4_io_space == "true" ? 1'b1 : 1'b0);
	init_k_bar[130:129] = (bar4_64bit_mem_space == "true" ? 2'b10 : 2'b00);
	init_k_bar[131:131] = (bar4_prefetchable == "true" ? 1'b1 : 1'b0);
	if (bar4_64bit_mem_space == "true")
	begin
		init_k_bar[191:132] = 60'hffff_ffff_ffff_fff << (bar4_size_mask - 3'b100);
	end
	else begin
		init_k_bar[159:132] = 28'hffff_fff << (bar4_size_mask - 3'b100);
		init_k_bar[160:160] = (bar5_io_space == "true" ? 1'b1 : 1'b0);
		init_k_bar[162:161] = (bar5_64bit_mem_space == "true" ? 2'b10 : 2'b00);
		init_k_bar[163:163] = (bar5_prefetchable == "true" ? 1'b1 : 1'b0);
		init_k_bar[191:164] = 28'hffff_fff << (bar5_size_mask - 3'b100);
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
	init_k_bar[227:226] = bar_prefetchable[1:0];

end

assign k_bar =  init_k_bar;

/// sample the Cfg CTL interface a few clocks after transition
// detect the address transition
 always @(posedge AvlClk_i)
   begin
     cfgctl_addr_change <=   cfgctl_add_reg[3:0] != cfgctl_add_reg2[3:0];     // detect address change
     cfgctl_addr_change2 <=  cfgctl_addr_change;                      // delay two clock and use as strobe to sample the input 32-bit data
     cfgctl_addr_strobe  <=  cfgctl_addr_change2;
   end
// captured cfg ctl addr/data bus with the strobe
 always @(posedge AvlClk_i)
   if(cfgctl_addr_strobe)
     begin
        captured_cfg_addr_reg[3:0] <= cfgctl_add_reg[3:0];
        captured_cfg_data_reg[31:0] <= cfgctl_data_reg[31:0];
     end
     
endmodule