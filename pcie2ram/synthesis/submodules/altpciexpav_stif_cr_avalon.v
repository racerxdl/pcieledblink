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
//     Description:  Control Register Avalon Interface Module  
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
// $Id: //acds/main/ip/pci_express/src/rtl/lib/avalon/altpciexpav_cr_avalon.v#6 $
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// This sub module of the PCI/Avalon Bridge Control Register module handles the
// handshaking between the Avalon Switch Fabric and the other sub-modules that 
// actually implement the registers.
//
// A rough block diagram of this module is:
// 
// Avalon                                          Write Data, Byte Enables
// Write Data, >---------------------------------> Broadcast to
// Byte Enables    No registers on Write Data,     Sub-Modules
//                 Byte Enables or Address since
// Avalon          they are static (WaitReq)       Address
// Address >-+-----------------------------------> Broadcast to
//           |                                     Sub-Modules
//           |               
//           | +------+ +--+
//           +-|Decode|-|  |--+----------+
//             +------+ |> |  |          |
//                      +--+  |        +---+       Individual 
//                            |        |DE |       Read, Write 
//                 +----------+      +-|MUX|-----> Valids to each  
//                 |                 | +---+       Sub-Module 
//               +---+  +--+         |         
// Sub-Module    |MUX|--|  |---------)-----------> Read Data 
// Read Data >---|   |  |> |         |             to Avalon
//               +---+  +--+         |
//                 |                 |
// Sub-Module    +---+               |
// Read Data     |MUX|--+ (Selected  | 
// Valids >------|   |  |  Read      |
//               +---+  |  Valid)    |
//                      |            |
//           +----------+            |
//           |                       |
// Avalon    |  +-----+ +--+  State  | +------+   
// Write,    +--|Next |-|  |--+------+-|Decode|--> Wait Request
// Read, >------|State| |> |  |        +------+    to Avalon
// Chip-     +--|     | +--+  |
// Select    |  +-----+       |
//           |                |
//           +----------------+
//
// The register sub-module abbreviations and definitions are:
//   AdTr   - Address Translation (Actually external to Control Register)
//   A2PMb  - Avalon to PCI Mailbox registers
//   P2AMb  - PCI to Avalon Mailbox registers
//   Rupt   - Interrupt Status and Enable registers
//   Rp     - Root Port Tx Control registers
//   RdBak  - Parameter ReadBack registers
//   Icr    - Not a sub-module but Abbreviation for:
//              "Internal Control Register broadcast"
//     
module altpciexpav_stif_cr_avalon
  (
   // Avalon Interface signals (all synchronous to CraClk_i)
   input             CraClk_i,           // Clock for register access port
   input             CraRstn_i,          // Reset signal  
   input             CraChipSelect_i,    // Chip Select signals
   input [13:2]      CraAddress_i,       // Register (DWORD) specific address
   input [3:0]       CraByteEnable_i,    // Register Byte Enables
   input             CraRead_i,          // Read indication
   output reg [31:0] CraReadData_o,      // Read data lines
   input             CraWrite_i,         // Write indication 
   input [31:0]      CraWriteData_i,     // Write Data in 
   output reg        CraWaitRequest_o,   // Wait indication out 
   input             CraBeginTransfer_i, // Start of Transfer (not used)
   // Modified Avalon signals to the Address Translation logic
   // All synchronous to CraClk_i
   output reg        AdTrWriteReqVld_o,  // Valid Write Cycle to AddrTrans  
   output reg        AdTrReadReqVld_o,   // Read Valid out to AddrTrans
   output [11:2]     AdTrAddress_o,      // Register (DWORD) specific address
   output [3:0]      AdTrByteEnable_o,   // Register Byte Enables
   input [31:0]      AdTrReadData_i,     // Read Data in from AddrTrans
   output [31:0]     AdTrWriteData_o,    // Write Data out to AddrTrans
   input             AdTrReadDataVld_i,  // Read Valid in from AddrTrans
   // Modified Avalon signals broadcast to internal modules
   output reg [13:2] IcrAddress_o,       // Address to Internal
   output reg [31:0] IcrWriteData_o,     // Write Data to Internal
   output reg [3:0]  IcrByteEnable_o,    // Byte Enables to Internal
   // Modified Avalon signals to/from specific internal modules
   // Avalon to Pci Mailbox
   output reg        A2PMbWriteReqVld_o, // Valid Write Cycle 
   output reg        A2PMbReadReqVld_o,  // Read Valid out 
   input [31:0]      A2PMbReadData_i,    // Read Data in 
   input             A2PMbReadDataVld_i, // Read Valid in 
   // Pci to Avalon Mailbox
   output reg        P2AMbWriteReqVld_o, // Valid Write Cycle 
   output reg        P2AMbReadReqVld_o,  // Read Valid out 
   input [31:0]      P2AMbReadData_i,    // Read Data in 
   input             P2AMbReadDataVld_i, // Read Valid in 
   // Interrupt Module
   output reg        RuptWriteReqVld_o,  // Valid Write Cycle 
   output reg        RuptReadReqVld_o,   // Read Valid out 
   input [31:0]      RuptReadData_i,     // Read Data in 
   input             RuptReadDataVld_i,  // Read Valid in 
   
   /// Root Port Module
   output reg        RpWriteReqVld_o,  // Valid Write Cycle 
   output reg        RpReadReqVld_o,   // Read Valid out 
   input [31:0]      RpReadData_i,     // Read Data in 
   input             RpReadDataVld_i,  // Read Valid in 
   
   /// Cfg Module
   output reg        CfgReadReqVld_o,   // Read Valid out 
   input [31:0]      CfgReadData_i,     // Read Data in 
   input             CfgReadDataVld_i,  // Read Valid in    
   
   // RdBak Module
   output reg        RdBakReadReqVld_o,  // Read Valid out 
   input [31:0]      RdBakReadData_i,    // Read Data in 
   input             RdBakReadDataVld_i,  // Read Valid in 
   input             RpTxBusy_i
   ) ;

   // Registered versions of Avalon Inputs

   reg               sel_read_vld ;
   reg [31:0]        sel_read_data ;
   
   // State Machine for control the state of the interface
   localparam [5:0]   CRA_IDLE       = 6'b000000 ;
   localparam [5:0]   CRA_WRITE_ACK  = 6'b000011 ;
   localparam [5:0]   CRA_READ_FIRST = 6'b000101 ;
   localparam [5:0]   CRA_READ_WAIT  = 6'b001001 ;
   localparam [5:0]   CRA_READ_ACK   = 6'b010001 ;
   localparam [5:0]   CRA_PIPE       = 6'b100001 ;
   reg [5:0]         avalon_state_reg ;

   // Decoded Address Register 
   localparam CRA_NONE_SEL      = 0 ;
   localparam CRA_A2P_MB_SEL    = 1 ;
   localparam CRA_P2A_MB_SEL    = 2 ;
   localparam CRA_RUPT_SEL      = 3 ;
   localparam CRA_RDBAK_SEL     = 4 ;
   localparam CRA_ADDRTRANS_SEL = 5 ;
   localparam CRA_RP_SEL        = 6 ;
   localparam CRA_CFG_SEL       = 7;
   
   reg [CRA_CFG_SEL:CRA_NONE_SEL] addr_decode_reg ;    
   reg [13:2] cra_address_reg;
   
   // Address Decode Function
   // Encapsulate in a function to make the mainline code
   // streamlined and avoid need for another signal if we
   // were to do it in a separate combinational always block
   function [CRA_CFG_SEL:CRA_NONE_SEL] address_decode ;
      input [13:8] Address_i ;
      begin
         address_decode = 0 ;
         casez (Address_i)
           // 0000-00FF - PCI Interrupt registers
           // 3000-30FF - Avalon Interrupt registers
           6'b000000, 6'b110000 :
             address_decode[CRA_RUPT_SEL] = 1'b1 ;
           // 2000-20FF -- Root Port Tx registers
            6'b100000:
             address_decode[CRA_RP_SEL] = 1'b1 ;
            
            6'b111100:   /// 3CXX
             address_decode[CRA_CFG_SEL] = 1'b1 ;
           
           // 1000-1FFF - Address Translation
           6'b01????:
             address_decode[CRA_ADDRTRANS_SEL] = 1'b1 ;
           // 0800-08FF - PCI to Avalon Mailbox R/W
           // 3B00-0BFF - PCI to Avalon Mailbox R/O
           6'b001000, 6'b111011 :
             address_decode[CRA_P2A_MB_SEL] = 1'b1 ;
           // 3A00-3AFF - Avalon to PCI Mailbox R/W
           // 0900-09FF - Avalon to PCI Mailbox R/O
           6'b111010, 6'b001001 :
             address_decode[CRA_A2P_MB_SEL] = 1'b1 ;
           // 2C00-2FFF - Readback registers
           6'b1011?? :
             address_decode[CRA_RDBAK_SEL] = 1'b1 ;
           default
             address_decode[CRA_NONE_SEL] = 1'b1 ;
         endcase
     end
   endfunction // address_decode
                    
 always @(posedge CraClk_i or negedge CraRstn_i)
   begin
     if(~CraRstn_i)
       cra_address_reg <= 0;
     else if(avalon_state_reg == CRA_IDLE & CraChipSelect_i & (CraRead_i | CraWrite_i))
       cra_address_reg <= CraAddress_i;
   end
 
   // Address, Data, Control and Address Decode Register
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             addr_decode_reg <= 7'b000000 ;
             CraReadData_o  <= 32'h0;
          end
        else
          begin
             if (avalon_state_reg == CRA_PIPE)
               addr_decode_reg <= address_decode(cra_address_reg[13:8]) ;
             else
               addr_decode_reg <= addr_decode_reg ;          
             CraReadData_o  <= sel_read_data ;
          end
     end // always @ (posedge CraClk_i or negedge CraRstn_i)

   // Drive these signals straight through for now they are stable for
   // multiple cycles
   always @(CraWriteData_i or CraByteEnable_i or cra_address_reg)
     begin
        IcrAddress_o    = cra_address_reg ;
        IcrByteEnable_o = CraByteEnable_i ;
        IcrWriteData_o  = CraWriteData_i ;
     end

   // Provide Copies of these signals so hookup is straightforward at next 
   // level up
   assign AdTrWriteData_o  = IcrWriteData_o ;
   assign AdTrAddress_o    = IcrAddress_o[11:2] ;
   assign AdTrByteEnable_o = IcrByteEnable_o ;

   // Main state machine
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          avalon_state_reg <= CRA_IDLE ;
        else
          case (avalon_state_reg)
          
            CRA_IDLE :
              if(CraChipSelect_i & (CraRead_i | CraWrite_i))
                 avalon_state_reg <= CRA_PIPE ;
          
            CRA_PIPE :
                      if (CraRead_i == 1'b1)
                           avalon_state_reg <= CRA_READ_FIRST ;
                      else if(CraWrite_i == 1'b1 & RpTxBusy_i == 1'b0)
                           avalon_state_reg <= CRA_WRITE_ACK ;
                      
                      
            CRA_READ_FIRST, CRA_READ_WAIT :
              begin
                 if (sel_read_vld == 1'b1)
                   begin
                      avalon_state_reg <= CRA_READ_ACK ;
                   end
                 else
                   begin
                      avalon_state_reg <= CRA_READ_WAIT ;
                   end
              end // case: CRA_READ_FIRST, CRA_READ_WAIT
            CRA_READ_ACK, CRA_WRITE_ACK :
              begin
                 avalon_state_reg <= CRA_IDLE ;
              end // case: CRA_READ_ACK, CRA_WRITE_ACK
          endcase // case(avalon_state_reg)
     end // always @ (posedge CraClk_i or negedge CraRstn_i)
   
   // Generate the Output Controls
   always @*
     begin
        if (avalon_state_reg == CRA_READ_FIRST)
          begin
             AdTrReadReqVld_o   = addr_decode_reg[CRA_ADDRTRANS_SEL] ;
             A2PMbReadReqVld_o  = addr_decode_reg[CRA_A2P_MB_SEL] ;
             P2AMbReadReqVld_o  = addr_decode_reg[CRA_P2A_MB_SEL] ;
             RuptReadReqVld_o   = addr_decode_reg[CRA_RUPT_SEL] ;
             RpReadReqVld_o     = addr_decode_reg[CRA_RP_SEL] ;       
             CfgReadReqVld_o     = addr_decode_reg[CRA_CFG_SEL] ;
             RdBakReadReqVld_o  = addr_decode_reg[CRA_RDBAK_SEL] ;
          end
        else
          begin
             AdTrReadReqVld_o   = 1'b0 ;
             A2PMbReadReqVld_o  = 1'b0 ;
             P2AMbReadReqVld_o  = 1'b0 ;
             RuptReadReqVld_o   = 1'b0 ;
             RpReadReqVld_o     = 1'b0 ;  
             CfgReadReqVld_o    = 1'b0 ; 
             RdBakReadReqVld_o  = 1'b0 ;
          end
        if (avalon_state_reg == CRA_WRITE_ACK)
          begin
             AdTrWriteReqVld_o  = addr_decode_reg[CRA_ADDRTRANS_SEL] ;
             A2PMbWriteReqVld_o = addr_decode_reg[CRA_A2P_MB_SEL] ;
             P2AMbWriteReqVld_o = addr_decode_reg[CRA_P2A_MB_SEL] ;
             RuptWriteReqVld_o  = addr_decode_reg[CRA_RUPT_SEL] ;
             RpWriteReqVld_o    = addr_decode_reg[CRA_RP_SEL] ;
             
          end
        else
          begin
             AdTrWriteReqVld_o  = 1'b0 ;
             A2PMbWriteReqVld_o = 1'b0 ;
             P2AMbWriteReqVld_o = 1'b0 ;
             RuptWriteReqVld_o  = 1'b0 ;
             RpWriteReqVld_o    = 1'b0 ;
             
          end // else: !if(avalon_state_reg == CRA_WRITE_ACK)
        if ( (avalon_state_reg == CRA_WRITE_ACK) || 
             (avalon_state_reg == CRA_READ_ACK) )
          CraWaitRequest_o = 1'b0 ;
        else
          CraWaitRequest_o = 1'b1 ;
     end // always @ (avalon_state_reg or addr_decode_reg)

   // Select the returned read data and read valid
   always @*
     begin
        sel_read_vld  = 1'b0 ;
        sel_read_data = 1'b0 ;
        if (addr_decode_reg[CRA_ADDRTRANS_SEL] == 1'b1)
          begin
             sel_read_vld  = sel_read_vld  | AdTrReadDataVld_i ;
             sel_read_data = sel_read_data | AdTrReadData_i ;
          end
        if (addr_decode_reg[CRA_A2P_MB_SEL] == 1'b1)
          begin
             sel_read_vld  = sel_read_vld  | A2PMbReadDataVld_i ;
             sel_read_data = sel_read_data | A2PMbReadData_i ;
          end
        if (addr_decode_reg[CRA_P2A_MB_SEL] == 1'b1)
          begin
             sel_read_vld  = sel_read_vld  | P2AMbReadDataVld_i ;
             sel_read_data = sel_read_data | P2AMbReadData_i ;
          end
        if (addr_decode_reg[CRA_RUPT_SEL] == 1'b1)
          begin
             sel_read_vld  = sel_read_vld  | RuptReadDataVld_i ;
             sel_read_data = sel_read_data | RuptReadData_i ;
          end
        
        if (addr_decode_reg[CRA_RP_SEL] == 1'b1)
          begin
             sel_read_vld  = sel_read_vld  | RpReadDataVld_i ;
             sel_read_data = sel_read_data | RpReadData_i ;
          end          
                         
        if (addr_decode_reg[CRA_CFG_SEL] == 1'b1)
          begin
             sel_read_vld  = sel_read_vld  | CfgReadDataVld_i ;
             sel_read_data = sel_read_data | CfgReadData_i ;
          end          
                  
        if (addr_decode_reg[CRA_RDBAK_SEL] == 1'b1)
          begin
             sel_read_vld  = sel_read_vld  | RdBakReadDataVld_i ;
             sel_read_data = sel_read_data | RdBakReadData_i ;
          end
        if (addr_decode_reg[CRA_NONE_SEL] == 1'b1)
          begin
             sel_read_vld  = 1'b1 ;
          end
     end
   
endmodule // altpciav_cr_avalon

