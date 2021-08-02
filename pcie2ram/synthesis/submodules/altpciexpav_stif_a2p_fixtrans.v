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
//     Description:  Avalon to PCI Fixed Address Translation Table   
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
// $Id: //acds/main/ip/pci_express/src/rtl/lib/avalon/altpciexpav_a2p_fixtrans.v#5 $
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module altpciexpav_stif_a2p_fixtrans
  #(parameter CB_A2P_ADDR_MAP_NUM_ENTRIES = 16 ,
    parameter CB_A2P_ADDR_MAP_PASS_THRU_BITS = 12 ,
    parameter CG_AVALON_S_ADDR_WIDTH = 32 ,
    parameter CG_PCI_ADDR_WIDTH = 32 ,
    parameter [1023:0] CB_A2P_ADDR_MAP_FIXED_TABLE = 0 
    )
  (
   input [CG_AVALON_S_ADDR_WIDTH-1:0] PbaAddress_i,   // Must be a byte address
   input                              PbaAddrVld_i,   // Valid indication in 
   output reg [CG_PCI_ADDR_WIDTH-1:0] PciAddr_o,      // Is a byte address
   output reg [1:0]                   PciAddrSpace_o,   // DAC Needed 
   output reg                         PciAddrVld_o,   // Valid out (piped)
   input [11:2]                       AdTrAddress_i,  // Is a (DWORD) address 
   input                              AdTrReadVld_i,  // Read Valid in
   output reg [31:0]                  AdTrReadData_o, // DWORD specific
   output reg                         AdTrReadVld_o   // Read Valid out (piped) 
   ) ;
   
   reg [3:0]                           table_index ;
   reg [3:0]                          entry_index;                            
   reg [63:0]                         table_addr ;
   reg [63:0]                         table_read ;

   // Address space definitions
   localparam [1:0] ADSP_CONFIG = 2'b11 ;
   localparam [1:0] ADSP_IO =     2'b10 ;
   localparam [1:0] ADSP_MEM64 =  2'b01 ;
   localparam [1:0] ADSP_MEM32 =  2'b00 ;

   // This function ensures that the selected table entry is formatted
   // correctly. It performs the following basic functions:
   // case (fixed_map_table address space) 
   //   Config : zero upper 40 bits
   //   IO     : zero upper 32 bits
   //   Memory :
   //      if 32bit PCI Addressing, Zero upper 32-bits    
   //      if >32bit PCI Addressing, Zero upper n-bits
   function [63:0] validate_entry ;
      input [3:0] index ;
      reg [63:0] valid_entry ;
      reg [63:0] table_entry ;
      begin
         if ((|index) !== 1'bX)
           begin
              valid_entry = 64'h0000000000000000 ;
              table_entry = CB_A2P_ADDR_MAP_FIXED_TABLE[(((index+1)*64)-1)-:64] ;
              valid_entry[(CG_PCI_ADDR_WIDTH-1):CB_A2P_ADDR_MAP_PASS_THRU_BITS]
                = table_entry[(CG_PCI_ADDR_WIDTH-1):CB_A2P_ADDR_MAP_PASS_THRU_BITS] ;
              case (table_entry[1:0])
                ADSP_CONFIG : // Config space (Upper 40 bits zero)
                  begin
                     valid_entry[1:0]   = ADSP_CONFIG ;
                     valid_entry[63:24] = 40'h0000000000 ;
                  end
                ADSP_IO : // I/O space (Upper 32 bits zero)
                  begin
                     valid_entry[1:0]   = ADSP_IO ;
                     valid_entry[63:32] = 32'h00000000 ;
                  end
                ADSP_MEM64, ADSP_MEM32 :
                  begin
                     if (CG_PCI_ADDR_WIDTH > 32)
                       begin
                          // In 64-bit mode, calculate the correct space
                          if (|valid_entry[63:32] == 1'b1)
                            valid_entry[1:0]   = ADSP_MEM64 ;
                          else
                            valid_entry[1:0]   = ADSP_MEM32 ;
                          // synthesis translate_off
                          if  ( (valid_entry[1:0] == ADSP_MEM64) && (table_entry[1:0] != ADSP_MEM64) )
                          $display("WARNING: CB_A2P_ADDR_MAP_FIXED_TABLE specified 32 bit memory space, but upper bits were non zero, assuming 64 bit memory space") ;
                          else if  ( (valid_entry[1:0] == ADSP_MEM32) && (table_entry[1:0] != ADSP_MEM32) )
                          $display("WARNING: CB_A2P_ADDR_MAP_FIXED_TABLE specified 64 bit memory space, but upper bits were zero, assuming 32 bit memory space") ;
                          // synthesis translate_on
                       end
                     else
                       begin
                          // In 32-bit mode, force 32-bit space
                          valid_entry[1:0]   = ADSP_MEM32 ;
                          valid_entry[63:32] = 32'h00000000 ;
                          // synthesis translate_off
                          if (table_entry[0] == 1'b1)
                          $display("WARNING: CB_A2P_ADDR_MAP_FIXED_TABLE specified 64 bit memory space, but CG_PCI_ADDR_WIDTH is 32 bits, forcing 32 bit memory space") ;
                          // synthesis translate_on
                       end // else: !if(CG_PCI_ADDR_WIDTH > 32)
                  end // case: 2'b00, 2'b01
                default :
                  begin
                  	 valid_entry[63:32] = 32'h00000000 ;
                     // synthesis translate_off
                     $display("ERROR: MetaCharacters in Address Space (bits[1:0]) field of CB_A2P_ADDR_MAP_FIXED_TABLE") ;
                     $stop ;
                     // synthesis translate_on
                  end
              endcase // case(table_entry[1:0])
              validate_entry = valid_entry ;
           end // if (|index != 1'bx)
         else
           begin
              validate_entry = {64{1'b0}} ;
           end // else: !if(|index != 1'bx)
      end 
   endfunction // validate_table

   // Need a temp parameter to get around fatal sim errors that occur when there is only
   // 1 table entry and  CG_AVALON_S_ADDR_WIDTH  is equal to CB_A2P_ADDR_MAP_PASS_THRU_BITS
   localparam TABLE_INDEX_LSB = (CG_AVALON_S_ADDR_WIDTH > CB_A2P_ADDR_MAP_PASS_THRU_BITS) ?
                                CB_A2P_ADDR_MAP_PASS_THRU_BITS : CG_AVALON_S_ADDR_WIDTH-1 ;

   // This section of the code uses the upper bits of the Avalon address input
   // to select an entry from the fixed mapping table. The upper bits from the 
   // mapping table are combined with the lower bits of the Avalon address to 
   // form the PCI Address output.   
   always @(PbaAddress_i or PbaAddrVld_i)
     begin
         table_index = PbaAddress_i[CG_AVALON_S_ADDR_WIDTH-1:
                                   TABLE_INDEX_LSB] % 
                      CB_A2P_ADDR_MAP_NUM_ENTRIES ;
        table_addr = validate_entry(table_index) ;
        PciAddrSpace_o = table_addr[1:0] ;
        table_addr[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0] 
          = PbaAddress_i[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0] ;
        PciAddr_o  = table_addr[CG_PCI_ADDR_WIDTH-1:0] ;
        PciAddrVld_o = PbaAddrVld_i ;
     end // always @ (PbaAddress_i or PbaAddrVld_i)

   // This section selects a 32-bit section of the fixed mapping table to
   // be used as a possible read back for the Control Register Access port
   
   always @*
    begin
    	 entry_index = ((AdTrAddress_i >> 1) % 
                           CB_A2P_ADDR_MAP_NUM_ENTRIES) ;
    end
     
   always @*
     begin
        table_read 
          = validate_entry(entry_index) ;
        if (AdTrAddress_i[2] == 1'b1)
          AdTrReadData_o = table_read[63:32] ;
        else
          AdTrReadData_o = table_read[31:0] ;
        AdTrReadVld_o = AdTrReadVld_i ; 
     end

endmodule // altpciav_a2p_fixtrans


 
		      

