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
//     Description:  Avalon to PCI Address Translation Module   
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
// $Id: //acds/main/ip/pci_express/src/rtl/lib/avalon/altpciexpav_a2p_addrtrans.v#5 $
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module altpciexpav_stif_a2p_addrtrans 
  #(
    parameter CB_A2P_ADDR_MAP_IS_FIXED = 1 ,
    parameter CB_A2P_ADDR_MAP_NUM_ENTRIES = 1 ,
    parameter CB_A2P_ADDR_MAP_PASS_THRU_BITS = 24 , 
    parameter CG_AVALON_S_ADDR_WIDTH = 24 ,
    parameter CG_PCI_ADDR_WIDTH = 64 ,
    parameter CG_PCI_DATA_WIDTH = 64 ,
    parameter [1023:0] CB_A2P_ADDR_MAP_FIXED_TABLE = 0,
    parameter INTENDED_DEVICE_FAMILY = "Stratix" ,
    parameter A2P_ADDR_TRANS_TR_OUTREG = 0,
    parameter A2P_ADDR_TRANS_RA_OUTREG = 0
    ) 
  (
   input                              PbaClk_i,        // Clock For Avalon to PCI Trans
   input                              PbaRstn_i,       // Reset signal  
   input [CG_AVALON_S_ADDR_WIDTH-1:0] PbaAddress_i,    // Must be a byte specific address
   input [(CG_PCI_DATA_WIDTH/8)-1:0]  PbaByteEnable_i, // ByteEnables 
   input                              PbaAddrVld_i,    // Valid indication in 
   output reg [CG_PCI_ADDR_WIDTH-1:0]     PciAddr_o,       // Is a byte specific address
   output reg [1:0]                       PciAddrSpace_o,  // DAC Needed 
   output reg                           PciAddrVld_o,    // Valid indication out (piped)
   input                              CraClk_i,        // Clock for register access port
   input                              CraRstn_i,       // Reset signal  
   input [11:2]                       AdTrAddress_i,   // Register (DWORD) specific address
   input [3:0]                        AdTrByteEnable_i,// Register Byte Enables
   input                              AdTrWriteVld_i,  // Valid Write Cycle in  
   input [31:0]                       AdTrWriteData_i, // Write Data in 
   input                              AdTrReadVld_i,   // Read Valid in
   output     [31:0]                  AdTrReadData_o,  // Read Data out
   output                             AdTrReadVld_o    // Read Valid out (piped) 
   ) ;

 wire [CG_PCI_ADDR_WIDTH-1:0]     pci_address;      // Is a byte specific address  
 reg  [1:0]                       pci_address_space;  // DAC Needed                  
 reg                              pci_address_valid;    // Valid indication out (piped)  
 wire  [1:0]                       pci_address_space_d;  // DAC Needed                  
 wire                              pci_address_valid_d;    // Valid indication out (piped)  
reg [CG_PCI_ADDR_WIDTH-1:0]       RawAddr ;
wire [CG_PCI_ADDR_WIDTH-1:0]       RawAddr_d ;



// register input from var_trans
always @(posedge CraClk_i or negedge CraRstn_i)
  begin
     if(~CraRstn_i)
       begin
         RawAddr <= 0;
         pci_address_space <= 0;
         pci_address_valid   <= 0;
       end
     else
       begin
          RawAddr <= RawAddr_d; 
          pci_address_space <= pci_address_space_d;    
          pci_address_valid   <= pci_address_valid_d;
       end
  end

/*
   // synthesis translate_off
   // Validate the parameters to make sure they are valid
   initial
     begin
        case (CB_A2P_ADDR_MAP_NUM_ENTRIES)
          1 : 
            if (CG_AVALON_S_ADDR_WIDTH != CB_A2P_ADDR_MAP_PASS_THRU_BITS)
              begin
                 $display("ERROR: CG_AVALON_S_ADDR_WIDTH (%d) != log2(CB_A2P_ADDR_MAP_NUM_ENTRIES (%d)) + CB_A2P_ADDR_MAP_PASS_THRU_BITS (%d)",
                          CG_AVALON_S_ADDR_WIDTH, CB_A2P_ADDR_MAP_NUM_ENTRIES, CB_A2P_ADDR_MAP_PASS_THRU_BITS) ;
                 $stop ;
              end 
            else if (CB_A2P_ADDR_MAP_IS_FIXED == 0)
              begin
                 // Note: If this case is actually parameterized, simulation (and synthesis) crashes with a fatal error before
                 //       you can even get this far.
                 $display("ERROR: CB_A2P_ADDR_MAP_NUM_ENTRIES (%d) must be 2 or greater when CB_A2P_ADDR_MAP_IS_FIXED is 0.",
                          CB_A2P_ADDR_MAP_NUM_ENTRIES) ;
                 $stop ;
              end
          2 : 
            if (CG_AVALON_S_ADDR_WIDTH != (CB_A2P_ADDR_MAP_PASS_THRU_BITS + 1))
              begin
                 $display("ERROR: CG_AVALON_S_ADDR_WIDTH (%d) != log2(CB_A2P_ADDR_MAP_NUM_ENTRIES (%d)) + CB_A2P_ADDR_MAP_PASS_THRU_BITS (%d)",
                          CG_AVALON_S_ADDR_WIDTH, CB_A2P_ADDR_MAP_NUM_ENTRIES, CB_A2P_ADDR_MAP_PASS_THRU_BITS) ;
                 $stop ;
              end
          4 : 
            if (CG_AVALON_S_ADDR_WIDTH != (CB_A2P_ADDR_MAP_PASS_THRU_BITS + 2))
              begin
                 $display("ERROR: CG_AVALON_S_ADDR_WIDTH (%d) != log2(CB_A2P_ADDR_MAP_NUM_ENTRIES (%d)) + CB_A2P_ADDR_MAP_PASS_THRU_BITS (%d)",
                          CG_AVALON_S_ADDR_WIDTH, CB_A2P_ADDR_MAP_NUM_ENTRIES, CB_A2P_ADDR_MAP_PASS_THRU_BITS) ;
                 $stop ;
              end
          8 : 
            if (CG_AVALON_S_ADDR_WIDTH != (CB_A2P_ADDR_MAP_PASS_THRU_BITS + 3))
              begin
                 $display("ERROR: CG_AVALON_S_ADDR_WIDTH (%d) != log2(CB_A2P_ADDR_MAP_NUM_ENTRIES (%d)) + CB_A2P_ADDR_MAP_PASS_THRU_BITS (%d)",
                          CG_AVALON_S_ADDR_WIDTH, CB_A2P_ADDR_MAP_NUM_ENTRIES, CB_A2P_ADDR_MAP_PASS_THRU_BITS) ;
                 $stop ;
              end
          16 : 
            if (CG_AVALON_S_ADDR_WIDTH != (CB_A2P_ADDR_MAP_PASS_THRU_BITS + 4))
              begin
                 $display("ERROR: CG_AVALON_S_ADDR_WIDTH (%d) != log2(CB_A2P_ADDR_MAP_NUM_ENTRIES (%d)) + CB_A2P_ADDR_MAP_PASS_THRU_BITS (%d)",
                          CG_AVALON_S_ADDR_WIDTH, CB_A2P_ADDR_MAP_NUM_ENTRIES, CB_A2P_ADDR_MAP_PASS_THRU_BITS) ;
                 $stop ;
              end 
          32 : 
            if (CG_AVALON_S_ADDR_WIDTH != (CB_A2P_ADDR_MAP_PASS_THRU_BITS + 5))
              begin
                 $display("ERROR: CG_AVALON_S_ADDR_WIDTH (%d) != log2(CB_A2P_ADDR_MAP_NUM_ENTRIES (%d)) + CB_A2P_ADDR_MAP_PASS_THRU_BITS (%d)",
                          CG_AVALON_S_ADDR_WIDTH, CB_A2P_ADDR_MAP_NUM_ENTRIES, CB_A2P_ADDR_MAP_PASS_THRU_BITS) ;
                 $stop ;
              end
            else if (CB_A2P_ADDR_MAP_IS_FIXED != 0)
              begin
                 $display("ERROR: CB_A2P_ADDR_MAP_NUM_ENTRIES (%d) must be 16 or less when CB_A2P_ADDR_MAP_IS_FIXED is 1.",
                          CB_A2P_ADDR_MAP_NUM_ENTRIES) ;
                 $stop ;
              end
          64 : 
            if (CG_AVALON_S_ADDR_WIDTH != (CB_A2P_ADDR_MAP_PASS_THRU_BITS + 6))
              begin
                 $display("ERROR: CG_AVALON_S_ADDR_WIDTH (%d) != log2(CB_A2P_ADDR_MAP_NUM_ENTRIES (%d)) + CB_A2P_ADDR_MAP_PASS_THRU_BITS (%d)",
                          CG_AVALON_S_ADDR_WIDTH, CB_A2P_ADDR_MAP_NUM_ENTRIES, CB_A2P_ADDR_MAP_PASS_THRU_BITS) ;
                 $stop ;
              end
            else if (CB_A2P_ADDR_MAP_IS_FIXED != 0)
              begin
                 $display("ERROR: CB_A2P_ADDR_MAP_NUM_ENTRIES (%d) must be 16 or less when CB_A2P_ADDR_MAP_IS_FIXED is 1.",
                          CB_A2P_ADDR_MAP_NUM_ENTRIES) ;
                 $stop ;
              end
          128 : 
            if (CG_AVALON_S_ADDR_WIDTH != (CB_A2P_ADDR_MAP_PASS_THRU_BITS + 7))
              begin
                 $display("ERROR: CG_AVALON_S_ADDR_WIDTH (%d) != log2(CB_A2P_ADDR_MAP_NUM_ENTRIES (%d)) + CB_A2P_ADDR_MAP_PASS_THRU_BITS (%d)",
                          CG_AVALON_S_ADDR_WIDTH, CB_A2P_ADDR_MAP_NUM_ENTRIES, CB_A2P_ADDR_MAP_PASS_THRU_BITS) ;
                 $stop ;
              end
            else if (CB_A2P_ADDR_MAP_IS_FIXED != 0)
              begin
                 $display("ERROR: CB_A2P_ADDR_MAP_NUM_ENTRIES (%d) must be 16 or less when CB_A2P_ADDR_MAP_IS_FIXED is 1.",
                          CB_A2P_ADDR_MAP_NUM_ENTRIES) ;
                 $stop ;
              end
          256 : 
            if (CG_AVALON_S_ADDR_WIDTH != (CB_A2P_ADDR_MAP_PASS_THRU_BITS + 8))
              begin
                 $display("ERROR: CG_AVALON_S_ADDR_WIDTH (%d) != log2(CB_A2P_ADDR_MAP_NUM_ENTRIES (%d)) + CB_A2P_ADDR_MAP_PASS_THRU_BITS (%d)",
                          CG_AVALON_S_ADDR_WIDTH, CB_A2P_ADDR_MAP_NUM_ENTRIES, CB_A2P_ADDR_MAP_PASS_THRU_BITS) ;
                 $stop ;
              end
            else if (CB_A2P_ADDR_MAP_IS_FIXED != 0)
              begin
                 $display("ERROR: CB_A2P_ADDR_MAP_NUM_ENTRIES (%d) must be 16 or less when CB_A2P_ADDR_MAP_IS_FIXED is 1.",
                          CB_A2P_ADDR_MAP_NUM_ENTRIES) ;
                 $stop ;
              end
          512 : 
            if (CG_AVALON_S_ADDR_WIDTH != (CB_A2P_ADDR_MAP_PASS_THRU_BITS + 9))
              begin
                 $display("ERROR: CG_AVALON_S_ADDR_WIDTH (%d) != log2(CB_A2P_ADDR_MAP_NUM_ENTRIES (%d)) + CB_A2P_ADDR_MAP_PASS_THRU_BITS (%d)",
                          CG_AVALON_S_ADDR_WIDTH, CB_A2P_ADDR_MAP_NUM_ENTRIES, CB_A2P_ADDR_MAP_PASS_THRU_BITS) ;
                 $stop ;
              end
            else if (CB_A2P_ADDR_MAP_IS_FIXED != 0)
              begin
                 $display("ERROR: CB_A2P_ADDR_MAP_NUM_ENTRIES (%d) must be 16 or less when CB_A2P_ADDR_MAP_IS_FIXED is 1.",
                          CB_A2P_ADDR_MAP_NUM_ENTRIES) ;
                 $stop ;
              end
          default :
            begin
                 $display("ERROR: CB_A2P_ADDR_MAP_NUM_ENTRIES (%d) must be a power of 2 in the range from 1 to 512.",
                          CB_A2P_ADDR_MAP_NUM_ENTRIES) ;
                 $stop ;
            end
        endcase // case(CB_A2P_ADDR_MAP_NUM_ENTRIES)
     end
   // synthesis translate_on

*/
   // Address space definitions
   localparam [1:0] ADSP_CONFIG = 2'b11 ;
   localparam [1:0] ADSP_IO =     2'b10 ;
   localparam [1:0] ADSP_MEM64 =  2'b01 ;
   localparam [1:0] ADSP_MEM32 =  2'b00 ;

   // Address that has been specifically indexed down to first enabled byte
   wire [CG_AVALON_S_ADDR_WIDTH-1:0]       ByteAddr ;
   
   // Address directly from the translation tables before being manipulated for 
   // I/O and Config space specifics
   

   // Function to create the byte specific address
   function [CG_AVALON_S_ADDR_WIDTH-1:0] ModifyByteAddr ;
      input [CG_AVALON_S_ADDR_WIDTH-1:0] PbaAddress ;
      input [(CG_PCI_DATA_WIDTH/8)-1:0] PbaByteEnable ;
      reg [7:0] FullBE ;
      begin
         ModifyByteAddr[CG_AVALON_S_ADDR_WIDTH-1:3] = PbaAddress[CG_AVALON_S_ADDR_WIDTH-1:3] ;
         if (CG_PCI_DATA_WIDTH == 64)
           FullBE = PbaByteEnable ;
         else
           FullBE = {4'b0000,PbaByteEnable} ;
         casez (FullBE)
           8'b???????1 :
             ModifyByteAddr[2:0] = {PbaAddress[2],2'b00} ;
           8'b??????10 :
             ModifyByteAddr[2:0] = {PbaAddress[2],2'b01} ;
           8'b?????100 :
             ModifyByteAddr[2:0] = {PbaAddress[2],2'b10} ;
           8'b????1000 :
             ModifyByteAddr[2:0] = {PbaAddress[2],2'b11} ;
           8'b???10000 :
             ModifyByteAddr[2:0] = 3'b100 ;
           8'b??100000 :
             ModifyByteAddr[2:0] = 3'b101 ;
           8'b?1000000 :
             ModifyByteAddr[2:0] = 3'b110 ;
           8'b10000000 :
             ModifyByteAddr[2:0] = 3'b111 ;
           default :
             ModifyByteAddr[2:0] = PbaAddress[2:0] ;
         endcase // casez(FullBE)
      end
   endfunction // ModifyByteAddr
   
   
   // Function to modify the address as needed for Config and I/O Space
   function [CG_PCI_ADDR_WIDTH-1:0] ModifyCfgIO ;
      input [CG_PCI_ADDR_WIDTH-1:0] RawAddr ;
      input [1:0] AddrSpace ;
      begin
         ModifyCfgIO = {CG_PCI_ADDR_WIDTH{1'b0}} ;
         case (AddrSpace)
           ADSP_CONFIG :
             begin
                // For Config Space we need to determine if it is type 0 or type 1
                // If the bus number is 0, assume type 0, else type 1
                if (RawAddr[23:16] == 8'h00)
                  begin
                     // Type 0 - Pass through Function Number and Register Number
                     // Downstream logic only wants a QWORD address in 64-bit mode
                     // otherwise DWORD address in 32-bit mode
                     if (CG_PCI_DATA_WIDTH == 64)
                       ModifyCfgIO[10:3] = RawAddr[10:3] ;
                     else
                       ModifyCfgIO[10:2] = RawAddr[10:2] ;
                     // Type 0 - One Hot Encode Device Number 
                     if (RawAddr[15:11] < 21)
                       begin
                          ModifyCfgIO[RawAddr[15:11]+11] = 1'b1 ;
                       end
                     else
                       begin
                       	 ModifyCfgIO[10:3] = 8'h0;
                          // synthesis translate_off
                          
                          $display("ERROR: Attempt to issue a Type 0 Cfg transaction to a device number that can't be One-Hot encoded in bits 31:11") ;
                          $stop ;
                          // synthesis translate_on
                       end // else: !if(RawAddr[15:11] < 20)
                  end // if (RawAddr[23:16] == 8'h00)
                else
                  begin
                     // Type 1 - Set Type 1 bit
                     ModifyCfgIO[0] = 1'b1 ;
                     // Type 1 - Pass Through Bus Num, Device Num, Func Num, and Reg Num
                     // Downstream logic only wants a QWORD address in 64-bit mode
                     // otherwise DWORD address in 32-bit mode
                     if (CG_PCI_DATA_WIDTH == 64)
                       ModifyCfgIO[23:3] = RawAddr[23:3] ;
                     else
                       ModifyCfgIO[23:2] = RawAddr[23:2] ;
                  end // else: !if(RawAddr[23:16] == 8'h00)
             end // case: ADSP_CONFIG
           ADSP_IO :
             begin
                // The Byte enables have already been encoded pass them through
                ModifyCfgIO = RawAddr ;
             end
           default :
             begin
                // Memory Space, Pass the address through, but clear the byte specific
                // In 64-bit mode the memory space address should only be a QWORD
                // address, in 32-bit mode it should be a DWORD address
                if (CG_PCI_DATA_WIDTH == 64)
                  ModifyCfgIO[CG_PCI_ADDR_WIDTH-1:3] = RawAddr[CG_PCI_ADDR_WIDTH-1:3] ;
                else
                  ModifyCfgIO[CG_PCI_ADDR_WIDTH-1:2] = RawAddr[CG_PCI_ADDR_WIDTH-1:2] ;
             end
         endcase // case(AddrSpace)
      end
   endfunction
         
   assign ByteAddr = ModifyByteAddr(PbaAddress_i,PbaByteEnable_i) ;
             
   generate
      if (CB_A2P_ADDR_MAP_IS_FIXED == 0)
        begin
          altpciexpav_stif_a2p_vartrans  
            #(.CB_A2P_ADDR_MAP_NUM_ENTRIES(CB_A2P_ADDR_MAP_NUM_ENTRIES),
              .CB_A2P_ADDR_MAP_PASS_THRU_BITS(CB_A2P_ADDR_MAP_PASS_THRU_BITS),
              .CG_AVALON_S_ADDR_WIDTH(CG_AVALON_S_ADDR_WIDTH),
              .CG_PCI_ADDR_WIDTH(CG_PCI_ADDR_WIDTH),
              .INTENDED_DEVICE_FAMILY(INTENDED_DEVICE_FAMILY),
              .A2P_ADDR_TRANS_TR_OUTREG(A2P_ADDR_TRANS_TR_OUTREG),
              .A2P_ADDR_TRANS_RA_OUTREG(A2P_ADDR_TRANS_RA_OUTREG)
              )
              vartrans
              (
               .PbaClk_i(PbaClk_i),
               .PbaRstn_i(PbaRstn_i),
               .PbaAddress_i(ByteAddr),
               .PbaAddrVld_i(PbaAddrVld_i),
               .PciAddr_o(RawAddr_d),
               .PciAddrSpace_o(pci_address_space_d),
               .PciAddrVld_o(pci_address_valid_d),
               .CraClk_i(CraClk_i),
               .CraRstn_i(CraRstn_i),
               .AdTrAddress_i(AdTrAddress_i),
               .AdTrByteEnable_i(AdTrByteEnable_i),
               .AdTrWriteVld_i(AdTrWriteVld_i),
               .AdTrWriteData_i(AdTrWriteData_i),
               .AdTrReadVld_i(AdTrReadVld_i),
               .AdTrReadData_o(AdTrReadData_o),
               .AdTrReadVld_o(AdTrReadVld_o)
               ) ;   
        end // if (CB_A2P_ADDR_MAP_IS_FIXED == 0)
      else
        begin
          altpciexpav_stif_a2p_fixtrans  
            #(.CB_A2P_ADDR_MAP_NUM_ENTRIES(CB_A2P_ADDR_MAP_NUM_ENTRIES),
              .CB_A2P_ADDR_MAP_PASS_THRU_BITS(CB_A2P_ADDR_MAP_PASS_THRU_BITS),
              .CG_AVALON_S_ADDR_WIDTH(CG_AVALON_S_ADDR_WIDTH),
              .CG_PCI_ADDR_WIDTH(CG_PCI_ADDR_WIDTH),
              .CB_A2P_ADDR_MAP_FIXED_TABLE(CB_A2P_ADDR_MAP_FIXED_TABLE)
              )
              fixtrans
              (
               .PbaAddress_i(ByteAddr),
               .PbaAddrVld_i(PbaAddrVld_i),
               .PciAddr_o(RawAddr_d),
               .PciAddrSpace_o(pci_address_space_d),
               .PciAddrVld_o(pci_address_valid_d),
               .AdTrAddress_i(AdTrAddress_i),
               .AdTrReadVld_i(AdTrReadVld_i),
               .AdTrReadData_o(AdTrReadData_o),
               .AdTrReadVld_o(AdTrReadVld_o)
               ) ;   
        end // else: !if(CB_A2P_ADDR_MAP_IS_FIXED == 0)
   endgenerate

   assign pci_address = ModifyCfgIO(RawAddr,pci_address_space) ;
   
   
always @(posedge CraClk_i or negedge CraRstn_i)
  begin
     if(~CraRstn_i)
       begin
         PciAddr_o <= 0;
         PciAddrSpace_o <= 0;
         PciAddrVld_o   <= 0;
       end
     else
       begin
          PciAddr_o <= pci_address; 
          PciAddrSpace_o <= pci_address_space;    
          PciAddrVld_o   <= pci_address_valid;
       end
  end
endmodule // altpciav_a2p_addrtrans

