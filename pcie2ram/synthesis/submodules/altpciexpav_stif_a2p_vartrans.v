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
//     Description:  Avalon to PCI Variable Address Translation Table   
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
// $Id: //acds/main/ip/pci_express/src/rtl/lib/avalon/altpciexpav_a2p_vartrans.v#5 $
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module altpciexpav_stif_a2p_vartrans
  #(
    parameter CB_A2P_ADDR_MAP_NUM_ENTRIES = 16 ,
    parameter CB_A2P_ADDR_MAP_PASS_THRU_BITS = 12 , 
    parameter CG_AVALON_S_ADDR_WIDTH = 32 ,
    parameter CG_PCI_ADDR_WIDTH = 32 ,
    parameter INTENDED_DEVICE_FAMILY = "Stratix" ,
    parameter A2P_ADDR_TRANS_TR_OUTREG = 1,
    parameter A2P_ADDR_TRANS_RA_OUTREG = 1
    )
  (
   input                              PbaClk_i,        // Clock for a2p Trans
   input                              PbaRstn_i,       // Reset signal  
   input [CG_AVALON_S_ADDR_WIDTH-1:0] PbaAddress_i,    // Byte specific address
   input                              PbaAddrVld_i,    // Valid indication in 
   output reg [CG_PCI_ADDR_WIDTH-1:0] PciAddr_o,       // Byte specific address
   output reg [1:0]                   PciAddrSpace_o,    // DAC Needed 
   output reg                         PciAddrVld_o,    // Valid indication out
   input                              CraClk_i,        // Clock for access port
   input                              CraRstn_i,       // Reset signal  
   input [11:2]                       AdTrAddress_i,   // DWORD specific address
   input [3:0]                        AdTrByteEnable_i,// Register Byte Enables
   input                              AdTrWriteVld_i,  // Valid Write Cycle in  
   input [31:0]                       AdTrWriteData_i, // Write Data in 
   input                              AdTrReadVld_i,   // Read Valid in
   output reg [31:0]                  AdTrReadData_o,  // Read Data out
   output reg                         AdTrReadVld_o    // Read Valid out (piped) 
   ) ;

   // Address space definitions 
   localparam [1:0] ADSP_CONFIG = 2'b11 ;
   localparam [1:0] ADSP_IO =     2'b10 ;
   localparam [1:0] ADSP_MEM64 =  2'b01 ;
   localparam [1:0] ADSP_MEM32 =  2'b00 ;

   //define the clogb2 constant function
   function integer clogb2;
      input [31:0] depth;
      begin
         depth = depth - 1 ;
         for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1)
           depth = depth >> 1 ;       
      end
   endfunction // clogb2

   localparam TABLE_ADDR_WIDTH = clogb2(CB_A2P_ADDR_MAP_NUM_ENTRIES) ;

   // Quartus can't handle the range specification on parameters SPR160299
   // so we need to leave that off for now. 
   // localparam [(13*8)-1:0] OUTREG_A_CLK = A2P_ADDR_TRANS_TR_OUTREG == 1 ?
   localparam OUTREG_A_CLK = A2P_ADDR_TRANS_TR_OUTREG == 1 ?
                                          "CLOCK0" : "UNREGISTERED" ;
   // localparam [(13*8)-1:0] OUTREG_B_CLK = A2P_ADDR_TRANS_RA_OUTREG == 1 ?
   localparam OUTREG_B_CLK = A2P_ADDR_TRANS_RA_OUTREG == 1 ?
                                          "CLOCK1" : "UNREGISTERED" ;

   // The following parameter is used to avoid a fatal modelsim error on code 
   // that won't actually get executed when CG_PCI_ADDR_WIDTH is 32.
   //  
   localparam UPPER_PCI_ADDR_BIT_WIDTH 
     = CG_PCI_ADDR_WIDTH > 32 ? CG_PCI_ADDR_WIDTH : 64 ; 
 
   reg [(TABLE_ADDR_WIDTH-1):0]       table_trans_index ;                            
   reg [63:0]                         table_write_data ;
   reg [7:0]                          table_write_byteena ;
   reg [(TABLE_ADDR_WIDTH-1):0]       table_cra_addr ;
   wire [63:0]                        table_trans_data ;
   wire [63:0]                        table_read_data ;

   reg                                AdTrReadVld_q1 ;
   reg                                AdTrReadVld_q2 ;
   reg                                AdTrAddr2_q1 ;
   reg                                AdTrAddr2_q2 ;
   reg                                PbaAddrVld_q1 ;
   reg                                PbaAddrVld_q2 ;
   reg [CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0] PbaAddress_q1 ;
   reg [CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0] PbaAddress_q2 ;
   
   // Calculate the index into the table from the incoming address
   always @(PbaAddress_i)
     begin
        table_trans_index = PbaAddress_i[CG_AVALON_S_ADDR_WIDTH-1:
                                         CB_A2P_ADDR_MAP_PASS_THRU_BITS] % 
                            CB_A2P_ADDR_MAP_NUM_ENTRIES ;
     end

   // Calculate the Write Port Parameters
   always @(AdTrAddress_i or AdTrByteEnable_i or AdTrWriteData_i)
     begin
        table_write_data = 64'h0000000000000000 ;
        table_cra_addr = AdTrAddress_i[TABLE_ADDR_WIDTH+2:3] ;
        if (AdTrAddress_i[2] == 1'b1)
          begin
             table_write_byteena = {AdTrByteEnable_i,4'b0000} ;
             if (CG_PCI_ADDR_WIDTH > 32)
               // Need a special value here even when CG_PCI_ADDR_WIDTH = 32
               table_write_data[UPPER_PCI_ADDR_BIT_WIDTH-1:32] 
               = AdTrWriteData_i[UPPER_PCI_ADDR_BIT_WIDTH-33:0] ;
          end
        else
          begin
             table_write_byteena = {4'b0000,AdTrByteEnable_i} ;
             table_write_data[31:CB_A2P_ADDR_MAP_PASS_THRU_BITS] 
               = AdTrWriteData_i[31:CB_A2P_ADDR_MAP_PASS_THRU_BITS] ;
             if ( (CG_PCI_ADDR_WIDTH < 33) && (AdTrWriteData_i[1:0] == ADSP_MEM64) )
               begin
                  // synthesis translate_off
                  if ( (AdTrByteEnable_i[0] == 1'b1) && (AdTrWriteVld_i == 1'b1) ) 
                  $display("WARNING: Attempt to write 64-bit Memory space in 32-bit mode, 32-bit forced.") ;
                  // synthesis translate_on
                  table_write_data[1:0] = ADSP_MEM32 ;
               end
             else
               begin
                  table_write_data[1:0] = AdTrWriteData_i[1:0] ;
               end
          end // else: !if(AdTrAddress_i[2] == 1'b1)
     end // always @ (AdTrAddress_i or AdTrByteEnable_i)

   // Pipeline the Valid signal and the DWORD select bit
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             AdTrReadVld_q1 <= 1'b0 ;
             AdTrReadVld_q2 <= 1'b0 ;
             AdTrAddr2_q1 <= 1'b0 ;
             AdTrAddr2_q2 <= 1'b0 ;
          end
        else
          begin
             AdTrReadVld_q2 <= AdTrReadVld_q1 ;
             AdTrReadVld_q1 <= AdTrReadVld_i ;
             AdTrAddr2_q2   <= AdTrAddr2_q1 ;
             AdTrAddr2_q1   <= AdTrAddress_i[2] ;
          end // else: !if(CraRstn_i == 1'b0)
     end // always @ (posedge CraClk_i or negedge CraRstn_i)

   // Pipeline the Translation Address Valid signal
   always @(posedge PbaClk_i or negedge PbaRstn_i)
     begin
        if (PbaRstn_i == 1'b0)
          begin
             PbaAddrVld_q1 <= 1'b0 ;
             PbaAddrVld_q2 <= 1'b0 ;
             PbaAddress_q1 <= 0 ;
             PbaAddress_q2 <= 0 ;
          end
        else
          begin
             PbaAddrVld_q2 <= PbaAddrVld_q1 ;
             PbaAddrVld_q1 <= PbaAddrVld_i ;
             PbaAddress_q2 <= PbaAddress_q1 ;
             PbaAddress_q1 <= PbaAddress_i[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0] ;  
          end
     end

   // Calculate the final PCI Address and the valid signal
   always @(PbaAddress_q2 or PbaAddress_q1 or table_trans_data or PbaAddrVld_q1 or PbaAddrVld_q2)
     begin
        if (A2P_ADDR_TRANS_TR_OUTREG == 1)
          begin
             PciAddrVld_o = PbaAddrVld_q2 ;
             PciAddr_o = {table_trans_data[63:CB_A2P_ADDR_MAP_PASS_THRU_BITS],
                           PbaAddress_q2[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0]} ;
          end
        else
          begin
             PciAddrVld_o = PbaAddrVld_q1 ;
             PciAddr_o = {table_trans_data[63:CB_A2P_ADDR_MAP_PASS_THRU_BITS],
                           PbaAddress_q1[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0]} ;
          end // else: !if(A2P_ADDR_TRANS_TR_OUTREG == 1)
        PciAddrSpace_o = table_trans_data[1:0] ;
     end

   // Calculate the Final Register Read Data and the valid signal
   always @(AdTrAddr2_q1 or AdTrAddr2_q2 or AdTrReadVld_q1 or AdTrReadVld_q2 or table_read_data)
     begin
        if (A2P_ADDR_TRANS_RA_OUTREG == 1)
          begin
             AdTrReadVld_o = AdTrReadVld_q2 ;
             if (AdTrAddr2_q2 == 1'b0)
               AdTrReadData_o = table_read_data[31:0] ;
             else
               AdTrReadData_o = table_read_data[63:32] ;
          end
        else
          begin
             AdTrReadVld_o = AdTrReadVld_q1 ;
             if (AdTrAddr2_q1 == 1'b0)
               AdTrReadData_o = table_read_data[31:0] ;
             else
               AdTrReadData_o = table_read_data[63:32] ;
          end
     end

   // The actual translation table 
   altsyncram 
     #(
       .intended_device_family(INTENDED_DEVICE_FAMILY),
       .operation_mode("BIDIR_DUAL_PORT"),
       .width_a(64),
       .widthad_a(TABLE_ADDR_WIDTH),
       .numwords_a(CB_A2P_ADDR_MAP_NUM_ENTRIES),
       .width_b(64),
       .widthad_b(TABLE_ADDR_WIDTH),
       .numwords_b(CB_A2P_ADDR_MAP_NUM_ENTRIES),
       .lpm_type("altsyncram"),
       .width_byteena_a(1),
       .width_byteena_b(8),
       .byte_size(8),
       .indata_aclr_a("CLEAR0"),
       .wrcontrol_aclr_a("CLEAR0"),
       .address_aclr_a("CLEAR0"),
       .indata_reg_b("CLOCK1"),
       .address_reg_b("CLOCK1"),
       .wrcontrol_wraddress_reg_b("CLOCK1"),
       .indata_aclr_b("CLEAR1"),
       .wrcontrol_aclr_b("CLEAR1"),
       .address_aclr_b("CLEAR1"),
       .byteena_reg_b("CLOCK1"),
       .byteena_aclr_b("CLEAR1"),
       .outdata_reg_a(OUTREG_A_CLK),
//       .outdata_aclr_a("CLEAR0"),
       .outdata_reg_b(OUTREG_B_CLK)
//       .outdata_aclr_b("CLEAR1")
       )
     altsyncram_component 
     (
      .wren_a (1'b0),
      .clock0 (PbaClk_i),
      .wren_b (AdTrWriteVld_i),
      .clock1 (CraClk_i),
      .byteena_b (table_write_byteena),
      .address_a (table_trans_index),
      .address_b (table_cra_addr),
      .data_a (64'h0000000000000000),
      .data_b (table_write_data),
      .q_a (table_trans_data),
      .q_b (table_read_data)
      // synopsys translate_off
      ,
      .byteena_a (),
      .rden_b (),
      .clocken0 (),
      .clocken1 (),
      .addressstall_a (),
      .addressstall_b ()
      // synopsys translate_on
      );

endmodule // altpa_a2p_vartrans

