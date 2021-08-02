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
//     Description:  Control Register Interrupt Status and Enable Module  
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
// $Id: //acds/main/ip/pci_express/src/rtl/lib/avalon/altpciexpav_cr_interrupt.v#8 $
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// This module implements the Interrupt Status and Interrupt Enable registers
// and asserts the interrupt lines when enabled.
// It drives interrupts to both PCI and to Avalon.
// The logic is rather straightforward so no block diagram is provided.
// Synchronous signals coming from PCI are run through synchronization logic
// unless we are common clock mode. The single cycle bridge errors need to
// be clock stretched to make sure they make the clock crossing.
// The read/only PCI Status Register signals are just synchronized.
// The async rstn and intan inputs are always synchronized.
// Care is taken to reduce as many registers as possible based on signalized
// parameters which are assumed static.
// 
module altpciexpav_stif_cr_interrupt

#(
    parameter       CG_ENABLE_A2P_INTERRUPT = 0,
    parameter       CG_RXM_IRQ_NUM = 16,
    parameter       port_type_hwtcl = "Native endpoint"
  )
  (
   // Clock and Reset
   input             CraClk_i,           // Clock for register access port
   input             CraRstn_i,          // Reset signal  
   // Broadcast Avalon signals
   // All synchronous to CraClk_i
   input [13:2]      IcrAddress_i,       // Address 
   input [31:0]      IcrWriteData_i,     // Write Data 
   input [3:0]       IcrByteEnable_i,    // Byte Enables
   // Modified Avalon signals to/from specific internal modules
   // All synchronous to CraClk_i
   input             RuptWriteReqVld_i,  // Valid Write Cycle in 
   input             RuptReadReqVld_i,   // Read Valid in  
   output reg [31:0] RuptReadData_o,     // Read Data out
   output reg        RuptReadDataVld_o,  // Read Valid out
   // Mailbox specific Interrupt Request pulse inputs
   // All synchronous to CraClk_i
   input [7:0]       A2PMbRuptReq_i,     // Avalon to PCI Interrupt Requests
   input [7:0]       P2AMbRuptReq_i,     // PCI to Avalon Interrupt Requests
   
   // Intx or RP Cpmpletion Received
   input [4:0]       AvalonIrqReq_i,
   // PCI Bus, Status, Control and Error Signals
   // Most synchronous to PciClk_i
   input             PciClk_i,           // PCI Bus Clk 
   input             PciRstn_i,          // PCI Bus Reset (async)
   input             PciIntan_i,         // PCI Bus interrupt (async)
   input [5:0]       PciComp_Stat_Reg_i, // PCI Compiler Stat_Reg
   output            PciComp_lirqn_o,    // PCI Compiler IRQ 
   output     reg    MsiReq_o,
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
   output reg        CraIrq_o,           // Interrupt Request out
   input             NpmIrq_i,           // NonP Master Interrupt in
   input        [CG_RXM_IRQ_NUM-1 : 0]      RxmIrq_i,
   input                PmIrq_i,            // NonP Master Interrupt in
   // Configuration Signals
   input             cg_impl_nonp_av_master_port_i,
   input [3:0]       cg_num_a2p_mailbox_i,
   input [3:0]       cg_num_p2a_mailbox_i,
   input             cg_common_clock_mode_i, // High if common clock mode
   input             cg_host_bridge_mode_i,
   input             cg_pci_target_only_i,
   input             cg_common_reset_i,      // High if common reset
   
   output [31:0]     PciRuptEnable_o,
   input             TxBufferEmpty_i
   ) ;

   // Address assignments (Range to 0 to make it easy to read)
   localparam [13:0] ADDR_PCI_RUPT_STATUS = 14'h0040 ;
   localparam [13:0] ADDR_PCI_RUPT_ENABLE = 14'h0050 ;
   localparam [13:0] ADDR_AVL_RUPT_STATUS = 14'h3060 ;
   localparam [13:0] ADDR_AVL_CURR_VAL    = 14'h306C ;
   localparam [13:0] ADDR_AVL_RUPT_ENABLE = 14'h3070 ;
   // Decode bit ranges for writes and reads
   localparam WR_DCD_MSB = 13 ;
   localparam WR_DCD_LSB = 2 ;
   localparam RD_DCD_MSB = 6 ;
   localparam RD_DCD_LSB = 3 ;
   // Bit and Byte Assignments for INTAN status bits
   localparam INTAN_R_BIT   = 7 ;
   localparam INTAN_F_BIT   = 6 ;
   localparam INTAN_RF_BYTE = 0 ;
   localparam INTAN_CUR_VAL = 6 ;
   // Bit assignment for Avalon IRQ read only status
   localparam AVL_IRQ_BIT   = 7 ;
   // Byte assignment for Mailbox Rupt assignments
   // (Needs many other changes if no longer a full byte or 
   //  no longer byte aligned)
   localparam MB_BYTE     = 2 ;
   // Bit and Byte Assignments for RSTN status bits
   localparam RSTN_R_BIT   = 15 ;
   localparam RSTN_F_BIT   = 14 ;
   localparam RSTN_RF_BYTE = 1 ;
   localparam RSTN_CUR_VAL = 14 ;
   // Bit and Byte Assignments for Master Enable bits
   localparam MSEN_R_BIT   = 4 ;
   localparam MSEN_F_BIT   = 3 ;
   localparam MSEN_RF_BYTE = 0 ;
   localparam MSEN_CUR_VAL = 3 ;
   // Bit range assignment for read-only PCI core status
   localparam PCI_COMP_MSB   = 13 ;
   localparam PCI_COMP_LSB   = 8 ;
   localparam PCI_COMP_WIDTH = 1 + PCI_COMP_MSB - PCI_COMP_LSB ;
   // Bit, Byte and range assignments for bridge PCI errors
   localparam BPE_NP_DISC = 2 ;
   localparam BPE_RD_FAIL = 1 ;
   localparam BPE_WR_FAIL = 0 ;
   localparam BPE_LSB     = BPE_WR_FAIL ;
   localparam BPE_MSB     = BPE_NP_DISC ;
   localparam BPE_BYTE    = 0 ;
   // Write Pending Bit
   localparam WRPNDG_CUR_VAL = 5 ;
   
   // Interrupt Status sub-registers
   reg [BPE_MSB:BPE_LSB] bridge_pci_errors ;
   reg [7:0]       a2p_mb_rupts ;
   reg [7:0]       p2a_mb_rupts ;
   reg [4:0]       avl_irq_reg;
   reg             rstn_rose ;
   reg             rstn_fell ;
   reg             intan_rose ;
   reg             intan_fell ;
   reg             msen_rose ;
   reg             msen_fell ;
  // wire            SelAvlIrq_sig ;
   reg             lirq_n_reg;

   // Synchronized wires
   wire            PciNonpDataDiscardErr_q2 ;  // NonPre Data Discarded
   wire            PciMstrWriteFail_q2 ; // PCI Master Write failed
   wire            PciMstrReadFail_q2 ;  // PCI Master Read failed
   // Additional FF's for detecting rising edge 
   reg             PciNonpDataDiscardErr_q3 ;
   reg             PciMstrWriteFail_q3 ; 
   reg             PciMstrReadFail_q3 ;  
   reg [BPE_MSB:BPE_LSB] bridge_pci_errors_set ;
   // Synchronizing FF's
   reg             PciRstn_q1 ;
   reg             PciRstn_q2 ;
   reg             PciRstn_q3 ;
   reg             PciIntan_q1 ;
   reg             PciIntan_q2 ;
   reg             PciIntan_q3 ;
   reg [5:0]       PciComp_Stat_Reg_q1 ;
   reg [5:0]       PciComp_Stat_Reg_q2 ;
   reg             PciMstrWritePndg_q1 ;
   reg             PciMstrWritePndg_q2 ;
   wire            PciMstrWritePndg_sync ;
   reg             PciComp_MstrEnb_q1 ;
   reg             PciComp_MstrEnb_q2 ;
   wire            PciComp_MstrEnb_sync ;
   reg             PciComp_MstrEnb_q3 ;
  
   // Interrupt Enable Registers
   reg [31:0]      PciRuptEnable_reg ; // PCI Enable register
   reg [31:0]      AvlRuptEnable_reg ; // Avalon Enable register
   reg [31:0]      PciRuptImpl_sig ; // Used to reduce the implemented bits
   reg [31:0]      AvlRuptImpl_sig ; // Used to reduce the implemented bits 
   // Concatenated Status Registers
   reg [31:0]      PciRuptStatus_sig ;
   reg [31:0]      AvlRuptStatus_sig ;

   // PCI Interrupt Request synchronization
   reg             Cra_lirqn ;
  (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)  reg             Pci_lirqn_q1;
  (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)  reg             Pci_lirqn_q2;
   wire            irq_edge;
   wire [31:0]      pci_interrupt_ini;
   wire [3:0]       legacy_irq_req;
   reg  [3:0]       legacy_irq_req_reg;
   wire [3:0]       legacy_irq_rise;
   wire             rp_rxcpl_received;
   reg              rp_rxcpl_received_reg;
   wire             rp_rxcpl_received_rise;
        
   // Iterators for byte enable loops
   integer         ip ;
   integer         ia ;
   
   // Function to create a mask from the number of implemented Mailboxes
   function [7:0] mb_num_to_mask ;
      input [3:0] mb_num ;
      begin
         case(mb_num)
           4'h0 : mb_num_to_mask = 8'h00 ;
           4'h1 : mb_num_to_mask = 8'h01 ;
           4'h2 : mb_num_to_mask = 8'h03 ;
           4'h3 : mb_num_to_mask = 8'h07 ;
           4'h4 : mb_num_to_mask = 8'h0F ;
           4'h5 : mb_num_to_mask = 8'h1F ;
           4'h6 : mb_num_to_mask = 8'h3F ;
           4'h7 : mb_num_to_mask = 8'h7F ;
           4'h8 : mb_num_to_mask = 8'hFF ;
           default : mb_num_to_mask = 8'h00 ;
         endcase
      end
   endfunction // mb_num_to_mask
   
   
   generate if (CG_ENABLE_A2P_INTERRUPT == 1)
     begin
        assign pci_interrupt_ini = 32'h0000FFFF;  // enable bit 7 at reset
     end
   else
     begin
        assign pci_interrupt_ini = 32'h00000000;
     end
  endgenerate
   
      
   // For the error signals that are just an occasional pulse we need
   // use the altpciav_clksync that stretches the pulse as needed 
   altpciexpav_clksync datadiscard_sync
     (
      .cg_common_clock_mode_i(cg_common_clock_mode_i), 
      .Clk1_i(PciClk_i), 
      .Clk2_i(CraClk_i), 
      .Clk1Rstn_i(PciRstn_i), 
       .Clk2Rstn_i(CraRstn_i), 
      .Sig1_i(PciNonpDataDiscardErr_i), 
      .Sig2_o(PciNonpDataDiscardErr_q2),
      .Ack_o()
      );

   altpciexpav_clksync writefail_sync
     (
      .cg_common_clock_mode_i(cg_common_clock_mode_i), 
      .Clk1_i(PciClk_i), 
      .Clk2_i(CraClk_i), 
      .Clk1Rstn_i(PciRstn_i), 
      .Clk2Rstn_i(CraRstn_i), 
      .Sig1_i(PciMstrWriteFail_i), 
      .Sig2_o(PciMstrWriteFail_q2),
      .Ack_o()
      );

   altpciexpav_clksync readfail_sync
     (
      .cg_common_clock_mode_i(cg_common_clock_mode_i), 
      .Clk1_i(PciClk_i), 
      .Clk2_i(CraClk_i), 
      
     .Clk1Rstn_i(PciRstn_i), 
     .Clk2Rstn_i(CraRstn_i), 
      .Sig1_i(PciMstrReadFail_i), 
      .Sig2_o(PciMstrReadFail_q2),
      .Ack_o()
      );

   
   // Synchronize the PCI Signals over to the Avalon Clock domain
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             PciRstn_q2 <= 1'b0 ;
             PciIntan_q2 <= 1'b0 ;
             PciComp_Stat_Reg_q2 <= 6'b000000 ;
             PciMstrWritePndg_q2 <= 1'b0 ;
             PciComp_MstrEnb_q2 <= 1'b0 ;             
             PciRstn_q1 <= 1'b0 ;
             PciIntan_q1 <= 1'b0 ;
             PciComp_Stat_Reg_q1 <= 6'b000000 ;
             PciMstrWritePndg_q1 <= 1'b0 ;
             PciComp_MstrEnb_q1 <= 1'b0 ;
          end // if (CraRstn_i == 1'b0)
        else
          begin
             PciRstn_q2 <= PciRstn_q1 & ~cg_common_reset_i;
             PciIntan_q2 <= PciIntan_q1 ;
             PciComp_Stat_Reg_q2 <= PciComp_Stat_Reg_q1 ;
             PciMstrWritePndg_q2 <= PciMstrWritePndg_q1 ;
             PciComp_MstrEnb_q2 <= PciComp_MstrEnb_q1 ;
             PciRstn_q1 <= PciRstn_i & ~cg_common_reset_i;
             PciIntan_q1 <= PciIntan_i ;
             PciComp_Stat_Reg_q1 <= PciComp_Stat_Reg_i ;
             PciMstrWritePndg_q1 <= PciMstrWritePndg_i ;
             PciComp_MstrEnb_q1 <= PciComp_MstrEnb_i ;
          end
     end // always @ (posedge CraClk_i or negedge CraRstn_i)

   // Select between the FF's and the Raw signal based on clock mode
   // Note: PciRstn and PciIntan are completely asynchronous so they
   //       need synchronization in any event
   assign PciMstrWritePndg_sync = cg_common_clock_mode_i ? 
          PciMstrWritePndg_i : PciMstrWritePndg_q2 ;
   assign PciComp_MstrEnb_sync = cg_common_clock_mode_i ?
          PciComp_MstrEnb_i : PciComp_MstrEnb_q2 ;   
   
   // Create registered copies of signals that we need to compare
   // the previous value of 
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             PciRstn_q3 <= 1'b0 ;
             PciIntan_q3 <= 1'b0 ;
             PciNonpDataDiscardErr_q3 <= 1'b0 ;
             PciMstrWriteFail_q3 <= 1'b0 ;
             PciMstrReadFail_q3 <= 1'b0 ;
             PciComp_MstrEnb_q3 <= 1'b0 ;
          end // if (CraRstn_i == 1'b0)
        else
          begin
             PciRstn_q3 <= PciRstn_q2 & ~cg_common_reset_i ;
             PciIntan_q3 <= PciIntan_q2 ;
             PciNonpDataDiscardErr_q3 <= PciNonpDataDiscardErr_q2 ;
             PciMstrWriteFail_q3 <= PciMstrWriteFail_q2 ;
             PciMstrReadFail_q3 <= PciMstrReadFail_q2 ;
             PciComp_MstrEnb_q3 <= PciComp_MstrEnb_sync ;
          end
     end
   
   // Implement the bridge_pci_errors sub-register
   // First calculate if any new errors showed up
   always @(PciNonpDataDiscardErr_q3 or PciNonpDataDiscardErr_q2 or
            PciMstrWriteFail_q3 or PciMstrWriteFail_q2 or
            PciMstrReadFail_q3 or PciMstrReadFail_q2 or
            cg_pci_target_only_i or cg_impl_nonp_av_master_port_i)
     begin
        if (cg_pci_target_only_i == 1'b0)
          begin
             bridge_pci_errors_set[BPE_WR_FAIL] 
               = ~PciMstrWriteFail_q3 & PciMstrWriteFail_q2 ;
             bridge_pci_errors_set[BPE_RD_FAIL] 
               = ~PciMstrReadFail_q3 & PciMstrReadFail_q2 ;
          end
        else
          begin
             bridge_pci_errors_set[BPE_RD_FAIL] = 1'b0 ;
             bridge_pci_errors_set[BPE_WR_FAIL] = 1'b0 ;
          end // else: !if(cg_pci_target_only_i == 1'b0)
        if (cg_impl_nonp_av_master_port_i == 1'b1)
          begin
             bridge_pci_errors_set[BPE_NP_DISC] 
               = ~PciNonpDataDiscardErr_q3 & PciNonpDataDiscardErr_q2 ;
          end
        else
          begin
             bridge_pci_errors_set[BPE_NP_DISC] = 1'b0 ;
          end
     end // always @ (PciNonpDataDiscardErr_q3 or PciNonpDataDiscardErr_q2 or...

   // Actual Register control, resetable from both addresses
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             bridge_pci_errors <= 0 ;
          end
        else
          begin
             if ( ( (IcrAddress_i == 
                     ADDR_PCI_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) ||
                    (IcrAddress_i == 
                     ADDR_AVL_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) ) &&
                  (RuptWriteReqVld_i == 1'b1) &&
                  (IcrByteEnable_i[BPE_BYTE] == 1'b1) )
               begin
                  // Write 1 to clear, a new set will override
                  bridge_pci_errors <= (bridge_pci_errors & 
                                        ~IcrWriteData_i[BPE_MSB:BPE_LSB]) |
                                       bridge_pci_errors_set ;
               end
             else
               begin
                  // Set any new ones
                  bridge_pci_errors <= bridge_pci_errors |
                                       bridge_pci_errors_set ;
               end // else: !if( ( (IcrAddress_i ==...
          end // if (cg_host_bridge_mode_i == 1'b1)
     end // always @ (posedge CraClk_i or negedge CraRstn_i)

   // Implement the Avalon to PCI Mailbox interrupt register
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             a2p_mb_rupts <= 0 ;
          end
        else
          begin
             if ( (IcrAddress_i == 
                   ADDR_PCI_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) &&
                  (RuptWriteReqVld_i == 1'b1) &&
                  (IcrByteEnable_i[MB_BYTE] == 1'b1) )
               begin
                  // Write 1 to clear, a new set will override
                  a2p_mb_rupts <= (a2p_mb_rupts & 
                                   ~IcrWriteData_i[((MB_BYTE*8)+7):(MB_BYTE*8)]) |
                                  A2PMbRuptReq_i & 
                                  mb_num_to_mask(cg_num_a2p_mailbox_i) ;
               end
             else
               begin
                  // Set any new ones
                  a2p_mb_rupts <= a2p_mb_rupts |
                                  A2PMbRuptReq_i & 
                                  mb_num_to_mask(cg_num_a2p_mailbox_i);
               end
          end
     end // always @ (posedge CraClk_i or negedge CraRstn_i)
             
   // Implement the PCI to Avalon Mailbox interrupt register
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             p2a_mb_rupts <= 8'h00 ;
          end
        else
          begin
             if ( (IcrAddress_i == ADDR_AVL_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) && (RuptWriteReqVld_i == 1'b1) && (IcrByteEnable_i[MB_BYTE] == 1'b1) )
               begin
                  // Write 1 to clear, a new set will override
                  p2a_mb_rupts <= (p2a_mb_rupts & ~IcrWriteData_i[((MB_BYTE*8)+7):(MB_BYTE*8)]) | P2AMbRuptReq_i & mb_num_to_mask(cg_num_p2a_mailbox_i) ;
               end
             else
               begin
                  // Set any new ones
                  p2a_mb_rupts <= p2a_mb_rupts | P2AMbRuptReq_i & mb_num_to_mask(cg_num_p2a_mailbox_i) ;
               end
          end
     end // always @ (posedge CraClk_i or negedge CraRstn_i)
     
generate if(port_type_hwtcl == "Root port")
	begin
		
		assign legacy_irq_req[3:0] = AvalonIrqReq_i[3:0];
		assign rp_rxcpl_received   =  AvalonIrqReq_i[4];
		
			always @(posedge CraClk_i or negedge CraRstn_i)
			  begin
				  if (CraRstn_i == 1'b0)
				   begin
				    legacy_irq_req_reg[3:0] <= 4'h0;
				    rp_rxcpl_received_reg <= 1'b0;
				   end
				  else
				   begin
				    legacy_irq_req_reg[3:0] <= legacy_irq_req[3:0];
				     rp_rxcpl_received_reg <= rp_rxcpl_received;
				   end
				  end
				end
			
	assign legacy_irq_rise[0] = legacy_irq_req[0] & ~legacy_irq_req_reg[0];
	assign legacy_irq_rise[1] = legacy_irq_req[1] & ~legacy_irq_req_reg[1];
	assign legacy_irq_rise[2] = legacy_irq_req[2] & ~legacy_irq_req_reg[2];
	assign legacy_irq_rise[3] = legacy_irq_req[3] & ~legacy_irq_req_reg[3];
	assign rp_rxcpl_received_rise = rp_rxcpl_received & ~rp_rxcpl_received_reg;

      		always @(posedge CraClk_i or negedge CraRstn_i)
      			begin
      				if (CraRstn_i == 1'b0)
      					avl_irq_reg[0] <= 1'b0;
      			  else if(legacy_irq_rise[0] && AvlRuptEnable_reg[0])
      			    avl_irq_reg[0] <= 1'b1;
      				else if ( (IcrAddress_i == ADDR_AVL_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) && IcrByteEnable_i[0] && (RuptWriteReqVld_i == 1'b1) && IcrWriteData_i[0] )
      					avl_irq_reg[0] <= 1'b0 ;  // write 1 to clear
      			end
	
	
     		always @(posedge CraClk_i or negedge CraRstn_i)
      			begin
      				if (CraRstn_i == 1'b0)
      					avl_irq_reg[1] <= 1'b0;
      			  else if(legacy_irq_rise[1]  && AvlRuptEnable_reg[1])
      			    avl_irq_reg[1] <= 1'b1;
      				else if ( (IcrAddress_i == ADDR_AVL_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) && IcrByteEnable_i[0] && (RuptWriteReqVld_i == 1'b1) && IcrWriteData_i[1] )
      					avl_irq_reg[1] <= 1'b0 ;  // write 1 to clear
      			end
      	
     		always @(posedge CraClk_i or negedge CraRstn_i)
      			begin
      				if (CraRstn_i == 1'b0)
      					avl_irq_reg[2] <= 1'b0;
      			  else if(legacy_irq_rise[2] && AvlRuptEnable_reg[2])
      			    avl_irq_reg[2] <= 1'b1;
      				else if ( (IcrAddress_i == ADDR_AVL_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) && IcrByteEnable_i[0] && (RuptWriteReqVld_i == 1'b1) && IcrWriteData_i[2] )
      					avl_irq_reg[2] <= 1'b0 ;  // write 1 to clear
      			end
      	
     		always @(posedge CraClk_i or negedge CraRstn_i)
      			begin
      				if (CraRstn_i == 1'b0)
      					avl_irq_reg[3] <= 1'b0;
      			  else if(legacy_irq_rise[3] && AvlRuptEnable_reg[3])
      			    avl_irq_reg[3] <= 1'b1;
      				else if ( (IcrAddress_i == ADDR_AVL_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) && IcrByteEnable_i[0] && (RuptWriteReqVld_i == 1'b1) && IcrWriteData_i[3] )
      					avl_irq_reg[3] <= 1'b0 ;  // write 1 to clear
      			end
      			
      			
    		always @(posedge CraClk_i or negedge CraRstn_i)
      			begin
      				if (CraRstn_i == 1'b0)
      					avl_irq_reg[4] <= 1'b0;
      			  else if(rp_rxcpl_received_rise && AvlRuptEnable_reg[4])
      			    avl_irq_reg[4] <= 1'b1;
      				else if ( (IcrAddress_i == ADDR_AVL_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) && IcrByteEnable_i[0] && (RuptWriteReqVld_i == 1'b1) && IcrWriteData_i[4] )
      					avl_irq_reg[4] <= 1'b0 ;  // write 1 to clear
      			end
      			
endgenerate

   
   // Implement the Master Enable status registers
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             msen_rose <= 1'b0 ;
             msen_fell <= 1'b0 ;
          end
        else
          begin
             if ( (IcrAddress_i == 
                   ADDR_AVL_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) &&
                  (RuptWriteReqVld_i == 1'b1) &&
                  (IcrByteEnable_i[MSEN_RF_BYTE] == 1'b1) )
               begin
                  // Write 1 to clear, a new set will override
                  msen_rose <= (msen_rose & ~IcrWriteData_i[MSEN_R_BIT]) |
                               (~PciComp_MstrEnb_q3 & PciComp_MstrEnb_sync) ;
                  msen_fell <= (msen_fell & ~IcrWriteData_i[MSEN_F_BIT]) |
                               (PciComp_MstrEnb_q3 & ~PciComp_MstrEnb_sync) ;
               end
             else
               begin
                  // Set any new ones
                  msen_rose <= (~PciComp_MstrEnb_q3 & PciComp_MstrEnb_sync) | 
                               msen_rose ;
                  msen_fell <= (PciComp_MstrEnb_q3 & ~PciComp_MstrEnb_sync) | 
                               msen_fell ;
               end
          end
     end // always @ (posedge CraClk_i or negedge CraRstn_i)

   // Implement the PCI RSTN status registers
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             rstn_rose <= 1'b0 ;
             rstn_fell <= 1'b0 ;
          end
        else
          begin
             if ( (IcrAddress_i == 
                   ADDR_AVL_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) &&
                  (RuptWriteReqVld_i == 1'b1) &&
                  (IcrByteEnable_i[RSTN_RF_BYTE] == 1'b1) && 
                  (cg_common_reset_i == 1'b0) )
               begin
                  // Write 1 to clear, a new set will override
                  rstn_rose <= (rstn_rose & ~IcrWriteData_i[RSTN_R_BIT]) |
                               (~PciRstn_q3 & PciRstn_q2) ;
                  rstn_fell <= (rstn_fell & ~IcrWriteData_i[RSTN_F_BIT]) |
                               (PciRstn_q3 & ~PciRstn_q2) ;
               end
             else
               begin
                  // Set any new ones
                  rstn_rose <= (~PciRstn_q3 & PciRstn_q2) | rstn_rose ;
                  rstn_fell <= (PciRstn_q3 & ~PciRstn_q2) | rstn_fell ;
               end
          end
     end // always @ (posedge CraClk_i or negedge CraRstn_i)

   // Implement the PCI INTAN status registers
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             intan_rose <= 1'b0 ;
             intan_fell <= 1'b0 ;
          end
        else
          begin
             if ( (IcrAddress_i == 
                   ADDR_AVL_RUPT_STATUS[WR_DCD_MSB:WR_DCD_LSB]) &&
                  (RuptWriteReqVld_i == 1'b1) &&
                  (IcrByteEnable_i[INTAN_RF_BYTE] == 1'b1) )
               begin
                  // Write 1 to clear, a new set will override
                  intan_rose <= ( (intan_rose & ~IcrWriteData_i[INTAN_R_BIT]) |
                                  (~PciIntan_q3 & PciIntan_q2) ) &
                                cg_host_bridge_mode_i ;
                  intan_fell <= ( (intan_fell & ~IcrWriteData_i[INTAN_F_BIT]) |
                                  (PciIntan_q3 & ~PciIntan_q2) ) &
                                cg_host_bridge_mode_i ;
               end
             else
               begin
                  // Set any new ones
                  intan_rose <= ( (~PciIntan_q3 & PciIntan_q2) &
                                  cg_host_bridge_mode_i) | intan_rose ;
                  intan_fell <= ( (PciIntan_q3 & ~PciIntan_q2) &
                                  cg_host_bridge_mode_i) | intan_fell ;
               end
          end
     end // always @ (posedge CraClk_i or negedge CraRstn_i)

   // Create the mask values to reduce the implemented bits in the enable
   // registers 

generate if (port_type_hwtcl == "Root port")
	begin   
   always @ (posedge CraClk_i)
     begin
        // PCI Interrupt Enable Implemented bits mask
        PciRuptImpl_sig = 32'h00000000 ;
        PciRuptImpl_sig[23:0] = 24'hFFFFFF;
        AvlRuptImpl_sig = 32'h00000000 ;
        AvlRuptImpl_sig[4:0] = 5'b11111;
     end
  end
else
	begin
		 always @ (posedge CraClk_i)
     begin
		  PciRuptImpl_sig = 32'h00000000 ;
      PciRuptImpl_sig[23:0] = 24'hFFFFFF;
      AvlRuptImpl_sig = 32'h00000000 ;
      AvlRuptImpl_sig[((MB_BYTE*8)+7):(MB_BYTE*8)] = mb_num_to_mask(cg_num_p2a_mailbox_i) ;
     end
	end
endgenerate

   // Implement the actual PCI interrupt enable registers
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             PciRuptEnable_reg <= pci_interrupt_ini;
          end
        else
          begin
             if ( (IcrAddress_i == ADDR_PCI_RUPT_ENABLE[WR_DCD_MSB:WR_DCD_LSB]) && (RuptWriteReqVld_i == 1'b1)  )
               begin
                  for (ip = 0 ; ip < 4 ; ip = ip + 1)
                    if (IcrByteEnable_i[ip] == 1'b1)
                      PciRuptEnable_reg[((ip*8)+7)-:8] <= IcrWriteData_i[((ip*8)+7)-:8] & PciRuptImpl_sig[((ip*8)+7)-:8] ;  
                    else
                      PciRuptEnable_reg[((ip*8)+7)-:8] <= PciRuptEnable_reg[((ip*8)+7)-:8] ;
               end
             else
               begin
                  PciRuptEnable_reg <= PciRuptEnable_reg ;
               end
          end
     end // always @ (posedge CraClk_i or negedge CraRstn_i)
   
    assign PciRuptEnable_o = PciRuptEnable_reg;
   // Implement the actual Avalon Interrupt Enable registers
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             AvlRuptEnable_reg <= 32'h0 ;
          end
        else
          begin
             if ( (IcrAddress_i == 
                   ADDR_AVL_RUPT_ENABLE[WR_DCD_MSB:WR_DCD_LSB]) &&
                  (RuptWriteReqVld_i == 1'b1)  )
               begin
                  for (ia = 0 ; ia < 4 ; ia = ia + 1)
                    if (IcrByteEnable_i[ia] == 1'b1)
                      AvlRuptEnable_reg[((ia*8)+7)-:8] <= IcrWriteData_i[((ia*8)+7)-:8] &  AvlRuptImpl_sig[((ia*8)+7)-:8] ;  
                  else
                    AvlRuptEnable_reg[((ia*8)+7)-:8]   <= AvlRuptEnable_reg[((ia*8)+7)-:8] ;
               end
             else
               begin
                  AvlRuptEnable_reg <= AvlRuptEnable_reg ;
               end
          end
     end // always @ (posedge CraClk_i or negedge CraRstn_i)
   
   // Create the selected Avalon Interupt Request
  //  assign SelAvlIrq_sig = (cg_impl_nonp_av_master_port_i == 1'b1) ?
  //        NpmIrq_i : PmIrq_i ;
          
   // assign SelAvlIrq_sig = |RxmIrq_i ;
    
generate if (port_type_hwtcl == "Root port")
	begin
   // Create the concatenated status registers of the above bits
   always @*
     begin
        // PCI Interrupt Status Vector
        PciRuptStatus_sig = 32'h00000000 ;
        PciRuptStatus_sig[CG_RXM_IRQ_NUM-1:0] = RxmIrq_i ;
        PciRuptStatus_sig[((MB_BYTE*8)+7):(MB_BYTE*8)] = a2p_mb_rupts ;
        AvlRuptStatus_sig = 32'h00000000 ;
        AvlRuptStatus_sig[4:0] = avl_irq_reg ;
     end
  end
else
	begin
		 always @*
     begin
		    PciRuptStatus_sig = 32'h00000000 ;
        PciRuptStatus_sig[CG_RXM_IRQ_NUM-1:0] = RxmIrq_i ;
        PciRuptStatus_sig[((MB_BYTE*8)+7):(MB_BYTE*8)] = a2p_mb_rupts ;
        AvlRuptStatus_sig = 32'h00000000 ;
        AvlRuptStatus_sig[((MB_BYTE*8)+7):(MB_BYTE*8)] = p2a_mb_rupts ;
        AvlRuptStatus_sig[2] = TxBufferEmpty_i;
     end
	end
endgenerate

   // Generate the actual interrupt signals, generate from a register
   // so no combinational switching output. 
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             CraIrq_o  <= 1'b0 ;
             Cra_lirqn <= 1'b1 ;
          end
        else
          begin
             CraIrq_o  <= |(AvlRuptStatus_sig & AvlRuptEnable_reg) ;
             Cra_lirqn <= ~(|(PciRuptStatus_sig & PciRuptEnable_reg)) ;
          end
     end // always @ (posedge CraClk_i or negedge CraRstn_i)

   // Synchronize the PCI Interrupt Request from Avalon to PCI
   always @(posedge PciClk_i or negedge PciRstn_i)
     begin
        if (PciRstn_i == 1'b0)
          begin
             Pci_lirqn_q2 <= 1'b1 ;
             Pci_lirqn_q1 <= 1'b1 ;
          end
        else
          begin
             Pci_lirqn_q2 <= Pci_lirqn_q1 ;
             Pci_lirqn_q1 <= Cra_lirqn ;
          end
     end // always @ (posedge PciClk_i or negedge PciRstn_i)

   // Select the correct signal based on clock mode
   assign PciComp_lirqn_o = cg_common_clock_mode_i ? Cra_lirqn : Pci_lirqn_q2 ;
   
   /// generate the MSI based on the 
    always @(posedge PciClk_i or negedge PciRstn_i)
      begin
        if (PciRstn_i == 1'b0)
          lirq_n_reg <= 1'b1;
        else
           lirq_n_reg <= PciComp_lirqn_o;
      end

  assign irq_edge = lirq_n_reg & ~PciComp_lirqn_o;
  
   always @(posedge PciClk_i or negedge PciRstn_i)
      begin
        if (PciRstn_i == 1'b0)
          MsiReq_o <= 1'b0;
        else if(irq_edge)
          MsiReq_o <= 1'b0; // disable MSi fucntion
        else if(MsiAck_i)
          MsiReq_o <= 1'b0;
      end
   
   /// detect the falling edge of the 
   // Readback data selection, just do a simple multiplexor, no register
   always @*
     begin
        RuptReadDataVld_o = RuptReadReqVld_i ;
        case(IcrAddress_i[RD_DCD_MSB:RD_DCD_LSB])
          ADDR_PCI_RUPT_STATUS[RD_DCD_MSB:RD_DCD_LSB] :
            RuptReadData_o = PciRuptStatus_sig ;
          ADDR_PCI_RUPT_ENABLE[RD_DCD_MSB:RD_DCD_LSB] :
            RuptReadData_o = PciRuptEnable_reg ;
          ADDR_AVL_RUPT_STATUS[RD_DCD_MSB:RD_DCD_LSB] :
            RuptReadData_o = AvlRuptStatus_sig ;
          ADDR_AVL_RUPT_ENABLE[RD_DCD_MSB:RD_DCD_LSB] :
            RuptReadData_o = AvlRuptEnable_reg ;
          ADDR_AVL_CURR_VAL[RD_DCD_MSB:RD_DCD_LSB] :
            begin
               RuptReadData_o = 32'h00000000 ;
               // Interrupt Current Value, only provide in host bridge mode
               RuptReadData_o[INTAN_CUR_VAL] 
                 = (PciIntan_q2 & cg_host_bridge_mode_i) ;
               RuptReadData_o[RSTN_CUR_VAL] = PciRstn_q2 & ~cg_common_reset_i ;
               RuptReadData_o[WRPNDG_CUR_VAL] = PciMstrWritePndg_sync ;
               RuptReadData_o[MSEN_CUR_VAL] = PciComp_MstrEnb_sync & 
                                              ~cg_pci_target_only_i ;               
            end
          default :
            RuptReadData_o = 32'h00000000 ;
        endcase               
     end // always @ (IcrAddress_i or RuptReadReqVld_i or...
   
   
   assign MsiTc_o = 3'h0;
   assign MsiNum_o = 5'h0;
endmodule // altpciav_interrupt

   
