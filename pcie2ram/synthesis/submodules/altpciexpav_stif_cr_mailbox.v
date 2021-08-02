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
//     Description:  Control Register Mailbox Module  
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
// $Id: //acds/main/ip/pci_express/src/rtl/lib/avalon/altpciexpav_cr_mailbox.v#5 $
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// This module implements the Mailboxes for communication between PCI and
// Local processors.
// If there is 1 Mailbox it is implemented in registers
// If there is more than 1 Mailbox it is implemented in a RAM.
//
// The logic here simply implements both the single register implementation
// and the RAM implementation. Synthesis should be able to prune out the one
// that is not used when the number implemented input is driven by a constant
// If 0 mailboxes are implemented:
//    The single register is never written
//    The RAM implementation is never written
//    0's always returned for read data
//    Read Data Valid Out always Read Data Valid In
// If 1 mailbox is implemented:
//    The single register written when WriteValid and address == 0.
//    The RAM implementation is never written
//    Mailbox register returned for the read data
//    Read Data Valid Out always Read Data Valid In
// If greater the 1 mailbox is implemented:
//    The single register is never written
//    The RAM implementation is written when WriteValid and address in range
//    Ram data out returned for the read data
//    Read Data Valid Out delayed version of Read Data Valid In
//    

// Note the CG_NUM_MAILBOX parameter was added at the last minute to
// address an issue. It is redundant with the cg_num_mailbox_i
// they should always be the same but that is not verified here.

module altpciexpav_stif_cr_mailbox
  #(
    parameter INTENDED_DEVICE_FAMILY = "Stratix",
    parameter CG_NUM_MAILBOX = 8
    )
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
   input             MbWriteReqVld_i,    // Valid Write Cycle in 
   input             MbReadReqVld_i,     // Read Valid in  
   output reg [31:0] MbReadData_o,       // Read Data out
   output reg        MbReadDataVld_o,    // Read Valid out
   // Mailbox specific Interrupt Request pulses
   output reg [7:0]  MbRuptReq_o,        // Mailbox Interrupt Requests
   // Number of Mailboxes to actually implement (Max of 8)
   input [3:0]       cg_num_mailbox_i   
   ) ;
   
   reg [31:0]        mailbox1_reg ;
   reg               mailbox1_rupt_reg ;
   reg [7:0]         ram_rupt_reg ;
   reg               reg1_write ;
   reg               ram_write ;
   reg [4:2]         qual_address ;

   wire [31:0]       ram_read_data ;
   reg               read_vld_q1 ;
   reg               read_vld_q2 ;
   
   // Create qualified write enables and addresses
   always @*
     begin
        // If address bit 8 is on, that means we are using a
        // Read Only address and so we should turn off the write.
        // If any other address bits in the 7:5 range are
        // enabled we should turn off the write enable.
        // Finally if the address is above the number of Mailboxes
        // implemented we should tuyrn off the write enable.
        // Address bits above 8 may be on, depending on which
        // actual mailbox instance is used, we have to trust
        // the main decode logic to have done the right thing
        if ( (|IcrAddress_i[8:5] == 1'b1) ||
             (IcrAddress_i[4:2] >= cg_num_mailbox_i) )
          begin
             reg1_write = 1'b0 ;
             ram_write = 1'b0 ;
          end
        else
          begin
             if (cg_num_mailbox_i == 4'h1)
               begin
                  reg1_write = MbWriteReqVld_i ;
                  ram_write = 1'b0 ;
               end
             else
               begin        
                  reg1_write = 1'b0 ;
                  ram_write = MbWriteReqVld_i ;
               end
          end // else: !if( (|IcrAddress_i[8:5] == 1'b1) ||...
        // Force address bits to be 0 if not needed for the
        // implemented number of mailboxes. This will reduce
        // the RAM requirements if MbNumberImpl driven to a 1.
        case (cg_num_mailbox_i)
          4'h0 : 
            qual_address = 3'b000 ;
          4'h1, 4'h2 :
            qual_address = {2'b00,IcrAddress_i[2]} ;
          4'h3, 4'h4 :
            qual_address = {1'b0,IcrAddress_i[3:2]} ;
          default :
            qual_address = IcrAddress_i[4:2] ;
        endcase // case(cg_num_mailbox_i)
     end // always @ (IcrAddress_i or MbWriteReqVld_i or cg_num_mailbox_i)

   generate
      // This generate was added at the last minute due to an issue with 
      // Quartus not being able to handle the dynamic selection of
      // altsyncram when compiling for Max II 
      if (CG_NUM_MAILBOX <= 1)
        begin
        	 assign ram_read_data = 32'h0;
           // Implement the single register implementation
           always @(posedge CraClk_i or negedge CraRstn_i)
             begin
                if (CraRstn_i == 1'b0)
                  begin
                     mailbox1_reg <= 32'h00000000 ;
                  end
                else
                  begin
                     if (reg1_write & IcrByteEnable_i[3])
                       mailbox1_reg[31:24] <= IcrWriteData_i[31:24] ;
                     else
                       mailbox1_reg[31:24] <= mailbox1_reg[31:24] ;
                     if (reg1_write & IcrByteEnable_i[2])
                       mailbox1_reg[23:16] <= IcrWriteData_i[23:16] ;
                     else
                       mailbox1_reg[23:16] <= mailbox1_reg[23:16] ;
                     if (reg1_write & IcrByteEnable_i[1])
                       mailbox1_reg[15:8] <= IcrWriteData_i[15:8] ;
                     else
                       mailbox1_reg[15:8] <= mailbox1_reg[15:8] ;
                     if (reg1_write & IcrByteEnable_i[0])
                       mailbox1_reg[7:0] <= IcrWriteData_i[7:0] ;
                     else
                       mailbox1_reg[7:0] <= mailbox1_reg[7:0] ;
                  end // else: !if(CraRstn_i == 1'b0)
             end // always @ (posedge CraClk_i or negedge CraRstn_i)
         end // if (CG_NUM_MAILBOX == 1)
      else
        begin
        	
         always @(posedge CraClk_i or negedge CraRstn_i)
             begin
                if (CraRstn_i == 1'b0)
                     mailbox1_reg <= 32'h00000000 ;
                else
                     mailbox1_reg <= 32'h00000000 ;
             end
                  	
        	
           // Implement the ram based implementation
           altsyncram 
             #(
               .intended_device_family(INTENDED_DEVICE_FAMILY),
               .operation_mode("SINGLE_PORT"),
               .width_a(32),
               .widthad_a(3),
               .numwords_a(8),
               .outdata_reg_a("CLOCK0"),
               .indata_aclr_a("CLEAR0"),
               .wrcontrol_aclr_a("CLEAR0"),
               .address_aclr_a("CLEAR0"),
               .outdata_aclr_a("CLEAR0"),
               .width_byteena_a(4),
               .byte_size(8),
               .byteena_aclr_b("CLEAR0"),
	           .lpm_hint("ENABLE_RUNTIME_MOD=NO"),
               .lpm_type("altsyncram")
               )
               altsyncram_component 
                                       (
                                        .wren_a (ram_write),
                                        .aclr0 (~CraRstn_i),
                                        .clock0 (CraClk_i),
                                        .byteena_a (IcrByteEnable_i),
                                        .address_a (qual_address),
                                        .data_a (IcrWriteData_i),
                                        .q_a (ram_read_data)
                                        // synopsys translate_off
                                        ,
	                                    .aclr1 (),
	                                    .byteena_b (),
	                                    .rden_b (),
	                                    .clock1 (),
	                                    .data_b (),
	                                    .wren_b (),
	                                    .q_b (),
	                                    .clocken0 (),
	                                    .clocken1 (),
	                                    .address_b (),
	                                    .addressstall_a (),
	                                    .addressstall_b ()
                                        // synopsys translate_on
                                        );
        end // else: !if(CG_NUM_MAILBOX == 1)
   endgenerate
   
   // Pipeline the valid indications
   always @(posedge CraClk_i or negedge CraRstn_i)
     begin
        if (CraRstn_i == 1'b0)
          begin
             read_vld_q2 <= 1'b0 ;
             read_vld_q1 <= 1'b0 ;
          end
        else
          begin
             read_vld_q2 <= read_vld_q1 ;
             read_vld_q1 <= MbReadReqVld_i ;
          end
     end // always @ (posedge CraClk_i or negedge CraRstn_i)

   // Now create the final mux for sending the data back
   always @(MbReadReqVld_i or read_vld_q2 or
            ram_read_data or mailbox1_reg or
            cg_num_mailbox_i)
     begin
        case(cg_num_mailbox_i)
          4'h0 :
            begin
               MbReadDataVld_o <= MbReadReqVld_i ;
               MbReadData_o <= 32'h00000000 ;
            end
          4'h1 :
            begin
               MbReadDataVld_o <= MbReadReqVld_i ;
               MbReadData_o <= mailbox1_reg ;
            end
          default :
            begin
               MbReadDataVld_o <= read_vld_q2 ;
               MbReadData_o <= ram_read_data ;
            end
        endcase // case(cg_num_mailbox_i)
     end // always @ (MbReadReqVld_i or read_vld_q2 or...

   // Now generate the interrupt request signals
   // The address qualification should force unused mailbox 
   // rupt requests to always be 0
   always @(reg1_write or ram_write or IcrByteEnable_i or 
            qual_address)
     begin
        MbRuptReq_o = 8'b0 ;
        if ( (reg1_write | ram_write) & (|IcrByteEnable_i) )
          MbRuptReq_o[qual_address] = 1'b1 ;
     end
             
endmodule // altpciav_cr_mailbox

   

