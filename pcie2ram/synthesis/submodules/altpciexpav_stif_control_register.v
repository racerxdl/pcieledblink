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
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//      Logic Core:  PCI/Avalon Bridge Megacore Function
//         Company:  Altera Corporation.
//                       www.altera.com 
//          Author:  IPBU SIO Group               
//
//     Description:  Control Register Module  
// 
// Copyright (c) 2004 Altera Corporation. All rights reserved.  This source code
// is highly confidential and proprietary information of Altera and is being
// provided in accordance with and subject to the protections of a
// Non-Disclosure Agreement which governs its use and disclosure.  Altera
// products and services are protected under numerous U.S. and foreign patents,
// maskwork rights, copyrights and other intellectual property laws.  Altera
// assumes no responsibility or liability arising out of the application or use
// of this source code.
// 
// For Best Viewing Set tab stops to 4 spaces.
// 
// $Id: //acds/main/ip/pci_express/src/rtl/lib/avalon/altpciexpav_control_register.v#6 $
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// Note the CG_A2P_NUM_MAILBOX and CG_NUM_P2A_MAILBOX parameters were added 
// at the last minute to address an issue. They are redundant with the 
// cg_num_a2p_mailbox_i and cg_num_p2a_mailbox_i signals they should always be 
// the same but that is not verified here.

module altpciexpav_stif_control_register
  #(
    parameter INTENDED_DEVICE_FAMILY = "Stratix",
    parameter CG_NUM_A2P_MAILBOX = 8,
    parameter CG_NUM_P2A_MAILBOX = 8,
    parameter CG_ENABLE_A2P_INTERRUPT = 0,
    parameter              CG_RXM_IRQ_NUM = 16,
    parameter port_type_hwtcl   = "Native endpoint",
    parameter direct_tlp_enable_hwtcl = 0
    )
  (
   // Avalon Interface signals (all synchronous to CraClk_i)
   input             CraClk_i,           // Clock for register access port
   input             CraRstn_i,          // Reset signal  
   input             CraChipSelect_i,    // Chip Select signals
   input [13:2]      CraAddress_i,       // Register (DWORD) specific address
   input [3:0]       CraByteEnable_i,    // Register Byte Enables
   input             CraRead_i,          // Read indication
   output [31:0]     CraReadData_o,      // Read data lines
   input             CraWrite_i,         // Write indication 
   input [31:0]      CraWriteData_i,     // Write Data in 
   output            CraWaitRequest_o,   // Wait indication out 
   input             CraBeginTransfer_i, // Begin Transfer (Not Used)
   // PCI Bus, Status, Control and Error Signals
   // Most synchronous to PciClk_i (execpt async Rstn and Intan)
   input             PciClk_i,           // PCI Bus Clock
   input             PciRstn_i,          // PCI Bus Reset
   input             PciIntan_i,         // PCI Bus interrupt
   input [5:0]       PciComp_Stat_Reg_i, // PCI Compiler Stat_Reg
   output            PciComp_lirqn_o,    // PCI Compiler IRQ 
   output            MsiReq_o,
   input             MsiAck_i,
   output          [2:0]                  MsiTc_o,
   output          [4:0]                  MsiNum_o,     
   input             PciNonpDataDiscardErr_i, // NonPre Data Discarded
   input             PciMstrWriteFail_i, // PCI Master Write failed
   input             PciMstrReadFail_i,  // PCI Master Read failed
   input             PciMstrWritePndg_i, // PCI Master Write Pending
   input             PciComp_MstrEnb_i,  // PCI Master Enable
   // Avalon Interrupt Signals
   // All synchronous to CraClk_i
   output            CraIrq_o,           // Interrupt Request out
   input  [15 : 0]          RxmIrq_i,
   input [5:0]       RxmIrqNum_i,
   // Modified Avalon signals to the Address Translation logic
   // All synchronous to CraClk_i
   output            AdTrWriteReqVld_o,  // Valid Write Cycle to AddrTrans  
   output            AdTrReadReqVld_o,   // Read Valid out to AddrTrans
   output [11:2]     AdTrAddress_o,      // Address to AddrTrans
   output [31:0]     AdTrWriteData_o,    // Write Data to AddrTrans
   output [3:0]      AdTrByteEnable_o,   // Write Byte Enables to AddrTrans
   input [31:0]      AdTrReadData_i,     // Read Data in from AddrTrans
   input             AdTrReadDataVld_i,  // Read Valid in from AddrTrans
   // Signalized parameters used for basic configuration
   // Treated as static signals
   input             cg_common_clock_mode_i, // High if common clock mode
   output [31:0]     PciRuptEnable_o,
   output            A2PMbWriteReq_o,
   output [11:0]     A2PMbWriteAddr_o,
   
    // Rp mode interface               
     input            TxRpFifoRdReq_i, 
     output [65:0]    TxRpFifoData_o,  
     output           RpTLPReady_o,    
     input            RpTLPAck_i,
     input            RxRpFifoWrReq_i, 
     input  [131:0]   RxRpFifoWrData_i ,
     
     input  [4:0]     AvalonIrqReq_i,
     input            TxBufferEmpty_i,
     input     [4:0]  ltssm_state,      
     input            rxcntrl_sm_idle,
     
     input [3:0]      CfgAddr_i, 
     input [31:0]     CfgCtl_i,
     input  [1:0]     CurrentSpeed_i,     
     input  [3:0]     LaneAct_i              
     
   ) ;

   // Internal connection wires 
   // Modified Avalon signals broadcast to internal modules
   wire   [13:2]     IcrAddress ;       // Address to Internal
   wire   [31:0]     IcrWriteData ;     // Write Data to Internal
   wire   [3:0]      IcrByteEnable ;    // Byte Enables to Internal
   // Modified Avalon signals to/from specific internal modules
   // Avalon to Pci Mailbox
   wire              A2PMbWriteReqVld ; // Valid Write Cycle 
   wire              A2PMbReadReqVld ;  // Read Valid out 
   wire  [31:0]      A2PMbReadData ;    // Read Data in 
   wire              A2PMbReadDataVld ; // Read Valid in 
   assign            A2PMbWriteReq_o  = A2PMbWriteReqVld;
   assign            A2PMbWriteAddr_o = IcrAddress; 
   // Pci to Avalon Mailbox
   wire              P2AMbWriteReqVld ; // Valid Write Cycle 
   wire              P2AMbReadReqVld ;  // Read Valid out 
   wire  [31:0]      P2AMbReadData ;    // Read Data in 
   wire              P2AMbReadDataVld ; // Read Valid in 
   // Interrupt Module
   wire              RuptWriteReqVld ;  // Valid Write Cycle 
   wire              RuptReadReqVld ;   // Read Valid out 
   wire  [31:0]      RuptReadData ;     // Read Data in 
   wire              RuptReadDataVld ;  // Read Valid in   
   
    // Root Port Module                                        
   wire              RpWriteReqVld ;  // Valid Write Cycle  
   wire              RpReadReqVld ;   // Read Valid out     
   wire  [31:0]      RpReadData ;     // Read Data in       
   wire              RpReadDataVld ;  // Read Valid in       
   
   /// Cfg Status Module
 
   wire              CfgReadReqVld ;   // Read Valid out       
   wire  [31:0]      CfgReadData ;     // Read Data in         
   wire              CfgReadDataVld ;  // Read Valid in        

   // Mailbox Interrupt Requests
   wire [7:0]        A2PMbRuptReq ;     // Avalon to PCI Interrupt Request         
   wire [7:0]        P2AMbRuptReq ;     // PCI to Avalon Interrupt Request
   wire              dummy_rdbak;
   wire              rp_tx_fifo_full; 
   wire              RpRuptReq;

   altpciexpav_stif_cr_avalon i_avalon
   (
    .CraClk_i(CraClk_i),
    .CraRstn_i(CraRstn_i),
    .CraChipSelect_i(CraChipSelect_i),
    .CraAddress_i(CraAddress_i),
    .CraByteEnable_i(CraByteEnable_i),
    .CraRead_i(CraRead_i),
    .CraReadData_o(CraReadData_o),
    .CraWrite_i(CraWrite_i),
    .CraWriteData_i(CraWriteData_i),
    .CraWaitRequest_o(CraWaitRequest_o),
    .AdTrWriteReqVld_o(AdTrWriteReqVld_o),
    .AdTrReadReqVld_o(AdTrReadReqVld_o),
    .AdTrAddress_o(AdTrAddress_o),
    .AdTrByteEnable_o(AdTrByteEnable_o),
    .AdTrReadData_i(AdTrReadData_i),
    .AdTrWriteData_o(AdTrWriteData_o),
    .AdTrReadDataVld_i(AdTrReadDataVld_i),
    .IcrAddress_o(IcrAddress),
    .IcrWriteData_o(IcrWriteData),
    .IcrByteEnable_o(IcrByteEnable),
    .A2PMbWriteReqVld_o(A2PMbWriteReqVld),
    .A2PMbReadReqVld_o(A2PMbReadReqVld),
    .A2PMbReadData_i(A2PMbReadData),
    .A2PMbReadDataVld_i(A2PMbReadDataVld),
    .P2AMbWriteReqVld_o(P2AMbWriteReqVld),
    .P2AMbReadReqVld_o(P2AMbReadReqVld),
    .P2AMbReadData_i(P2AMbReadData),
    .P2AMbReadDataVld_i(P2AMbReadDataVld),
    .RuptWriteReqVld_o(RuptWriteReqVld),
    .RuptReadReqVld_o(RuptReadReqVld),
    .RuptReadData_i(RuptReadData),
    .RuptReadDataVld_i(RuptReadDataVld),
        
    .RpWriteReqVld_o(RpWriteReqVld),       
    .RpReadReqVld_o(RpReadReqVld),         
    .RpReadData_i(RpReadData),             
    .RpReadDataVld_i(RpReadDataVld),       
        
    .CfgReadReqVld_o(CfgReadReqVld),    
    .CfgReadData_i(CfgReadData),        
    .CfgReadDataVld_i(CfgReadDataVld),  
     
    .RdBakReadReqVld_o(dummy_rdbak),                                  
    .RdBakReadData_i(32'hdead_beef),                                  
    .RdBakReadDataVld_i(dummy_rdbak),
    
    .RpTxBusy_i(RpTLPReady_o)
   ) ;

   altpciexpav_stif_cr_mailbox 
     #(
       .INTENDED_DEVICE_FAMILY(INTENDED_DEVICE_FAMILY),
       .CG_NUM_MAILBOX(CG_NUM_A2P_MAILBOX)
       )
       i_a2p_mb
     (
      .CraClk_i(CraClk_i),
      .CraRstn_i(CraRstn_i),
      .IcrAddress_i(IcrAddress),
      .IcrWriteData_i(IcrWriteData),
      .IcrByteEnable_i(IcrByteEnable),
      .MbWriteReqVld_i(A2PMbWriteReqVld),
      .MbReadReqVld_i(A2PMbReadReqVld),
      .MbReadData_o(A2PMbReadData),
      .MbReadDataVld_o(A2PMbReadDataVld),
      .MbRuptReq_o(A2PMbRuptReq),
      .cg_num_mailbox_i(CG_NUM_A2P_MAILBOX)
      ) ;
     
   altpciexpav_stif_cr_mailbox 
     #(
       .INTENDED_DEVICE_FAMILY(INTENDED_DEVICE_FAMILY),
       .CG_NUM_MAILBOX(CG_NUM_P2A_MAILBOX)
       )
       i_p2a_mb
     (
      .CraClk_i(CraClk_i),
      .CraRstn_i(CraRstn_i),
      .IcrAddress_i(IcrAddress),
      .IcrWriteData_i(IcrWriteData),
      .IcrByteEnable_i(IcrByteEnable),
      .MbWriteReqVld_i(P2AMbWriteReqVld),
      .MbReadReqVld_i(P2AMbReadReqVld),
      .MbReadData_o(P2AMbReadData),
      .MbReadDataVld_o(P2AMbReadDataVld),
      .MbRuptReq_o(P2AMbRuptReq),
      .cg_num_mailbox_i(CG_NUM_P2A_MAILBOX)
      ) ;
   
   altpciexpav_stif_cr_interrupt 
   
    # (
       .CG_ENABLE_A2P_INTERRUPT(CG_ENABLE_A2P_INTERRUPT),
       .port_type_hwtcl(port_type_hwtcl)
       )
    i_interrupt
     (
      .CraClk_i(CraClk_i),
      .CraRstn_i(CraRstn_i),
      .IcrAddress_i(IcrAddress),
      .IcrWriteData_i(IcrWriteData),
      .IcrByteEnable_i(IcrByteEnable),
      .RuptWriteReqVld_i(RuptWriteReqVld),
      .RuptReadReqVld_i(RuptReadReqVld),
      .RuptReadData_o(RuptReadData),
      .RuptReadDataVld_o(RuptReadDataVld),
      .A2PMbRuptReq_i(A2PMbRuptReq),
      .P2AMbRuptReq_i(P2AMbRuptReq),
      .AvalonIrqReq_i(AvalonIrqReq_i), // root port only
      .PciClk_i(PciClk_i),
      .PciRstn_i(PciRstn_i),
      .PciIntan_i(PciIntan_i),
      .PciComp_Stat_Reg_i(PciComp_Stat_Reg_i),
      .PciComp_lirqn_o(PciComp_lirqn_o),
      .MsiReq_o(MsiReq_o),
      .MsiAck_i(MsiAck_i),
      .MsiTc_o(MsiTc_o),
      .MsiNum_o(MsiNum_o),
      .PciNonpDataDiscardErr_i(PciNonpDataDiscardErr_i),
      .PciMstrWriteFail_i(PciMstrWriteFail_i),
      .PciMstrReadFail_i(PciMstrReadFail_i),
      .PciMstrWritePndg_i(PciMstrWritePndg_i),
      .PciComp_MstrEnb_i(PciComp_MstrEnb_i),
      .CraIrq_o(CraIrq_o),
      .NpmIrq_i(1'b0),
      .RxmIrq_i(RxmIrq_i[15:0]),
      .PmIrq_i(1'b0),
      .cg_impl_nonp_av_master_port_i(1'b0),
      .cg_num_a2p_mailbox_i(CG_NUM_A2P_MAILBOX),
      .cg_num_p2a_mailbox_i(CG_NUM_P2A_MAILBOX),
      .cg_common_clock_mode_i(cg_common_clock_mode_i),
      .cg_host_bridge_mode_i(1'b0),
      .cg_pci_target_only_i(1'b0),
      .cg_common_reset_i(1'b1),
      .PciRuptEnable_o(PciRuptEnable_o),
      .TxBufferEmpty_i(TxBufferEmpty_i)
      ) ;
      
 /// Status and Config registers
 
 
    altpciexpav_stif_cfg_status i_cfg_stat
     (
      .CraClk_i(CraClk_i),
      .CraRstn_i(CraRstn_i),
      .IcrAddress_i({IcrAddress[13:2], 2'b00}),
      .CfgReadReqVld_i(CfgReadReqVld),
      .CfgReadData_o(CfgReadData),
      .CfgReadDataVld_o(CfgReadDataVld),
      .CfgAddr_i(CfgAddr_i), 
      .CfgCtl_i(CfgCtl_i),
      .Ltssm_i(ltssm_state),          
      .CurrentSpeed_i(CurrentSpeed_i),   
      .LaneAct_i(LaneAct_i)         
        
      ) ;
   
   
 generate if (port_type_hwtcl == "Root port" | direct_tlp_enable_hwtcl == 1)
  begin
     altpciexpav_stif_cr_rp rp_registers
     
     (
        .CraClk_i(CraClk_i),          
        .CraRstn_i(CraRstn_i),         
        .IcrAddress_i(IcrAddress),      
        .IcrWriteData_i(IcrWriteData),    
        .IcrByteEnable_i(IcrByteEnable),   
        .RpWriteReqVld_i(RpWriteReqVld),   
        .RpReadReqVld_i(RpReadReqVld),    
        .RpReadData_o(RpReadData),      
        .RpReadDataVld_o(RpReadDataVld),   
        .RpRuptReq_o(RpRuptReq),       
        .TxRpFifoRdReq_i(TxRpFifoRdReq_i),
        .TxRpFifoData_o(TxRpFifoData_o),
        .RpTLPReady_o(RpTLPReady_o),
        .RpTLPAck_i(RpTLPAck_i),
        .RxRpFifoWrReq_i(RxRpFifoWrReq_i),
        .RxRpFifoWrData_i(RxRpFifoWrData_i),
        .RpTxFifoFull_o(rp_tx_fifo_full),
        .ltssm_state(ltssm_state),       
        .rxcntrl_sm_idle(rxcntrl_sm_idle)  
        
     );
  end
else
  begin
     assign TxRpFifoData_o = 66'h0;
     assign RpTLPReady_o   = 1'b0;
     assign rp_tx_fifo_full = 1'b0;
  end
endgenerate                           

endmodule // altpciav_control_register

     



  
