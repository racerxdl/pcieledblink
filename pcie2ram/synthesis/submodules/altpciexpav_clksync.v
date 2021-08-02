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
// $Id: //acds/main/ip/pci_express/src/rtl/lib/avalon/altpciexpav_clksync.v#8 $
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// This module contains the clock synchronization logic for  a signal from clock
// domain 1 to clock domain 2.
// if the cg_common_clock_mode_i is active, signal1 will be passed through to 
// signal 2 with a direct connection


module altpciexpav_clksync ( cg_common_clock_mode_i, 
                       Clk1_i, 
                       Clk2_i, 
                       Clk1Rstn_i, 
                       Clk2Rstn_i, 
                       Sig1_i, 
                       Sig2_o,
                       SyncPending_o,
                       Ack_o);

input cg_common_clock_mode_i;
input Clk1_i;
input Clk2_i;
input Clk1Rstn_i;
input Clk2Rstn_i;
input Sig1_i;
output Sig2_o;
output Ack_o;
output SyncPending_o;

wire input_rise;
reg input_sig_reg;
(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) reg output1_reg;
(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) reg output2_reg;
reg output3_reg;
reg sig2_o_reg;
reg req_reg;
reg ack_reg;
(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) reg ack1_reg;
(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) reg ack2_reg;
reg ack3_reg;
reg pending_reg;

always @(posedge Clk1_i or negedge Clk1Rstn_i)
  begin
    if(~Clk1Rstn_i)
      input_sig_reg <= 1'b0;
    else
      input_sig_reg <= Sig1_i;
  end
// detect the rising edge of the input signal to be transfer to clock domain 2
assign input_rise = ~input_sig_reg & Sig1_i;

// input signal toggles req_reg flop. The other clock domain asserts single cycle pulse
// on edge detection

always @(posedge Clk1_i or negedge Clk1Rstn_i)
  begin
    if(~Clk1Rstn_i)
      begin
      req_reg <= 1'b0;
      pending_reg <= 1'b0;
      end
    else 
      begin
      if(input_rise)
	req_reg <= ~req_reg;

      if (input_rise)
	pending_reg <= 1'b1;
      else if (ack3_reg^ack2_reg)
	pending_reg <= 1'b0;
      
      end
  end
  
 // forward synch reg with double registers
always @(posedge Clk2_i or negedge Clk2Rstn_i)
  begin
    if(~Clk2Rstn_i)
      begin
      output1_reg <= 1'b0;
      output2_reg <= 1'b0;
      output3_reg <= 1'b0;
      sig2_o_reg <= 1'b0;
      ack_reg <= 1'b0;
      end
    else
      begin
      output1_reg <= req_reg;
      output2_reg <= output1_reg;
      output3_reg <= output2_reg;

      // self clear
      if (output3_reg^output2_reg) 
	sig2_o_reg <= 1'b1;
      else
	sig2_o_reg <= 1'b0;

      if (output3_reg^output2_reg)
	ack_reg <= ~ack_reg;

      end
  end
 
 
// backward synch reg. double register sync the ack signal from clock domain2
always @(posedge Clk1_i or negedge Clk1Rstn_i)
  begin
    if(~Clk1Rstn_i)
      begin
      ack1_reg <= 1'b0;
      ack2_reg <= 1'b0;
      ack3_reg <= 1'b0;
      end
    else
      begin
      ack1_reg <= ack_reg;
      ack2_reg <= ack1_reg;
      ack3_reg <= ack2_reg;
      end
  end


// Muxing the output based on the parameter cg_common_clock_mode_i
// the entire sync logic will be synthesized away if the same clock domain
// is used.

assign Sig2_o = (cg_common_clock_mode_i == 0) ? sig2_o_reg : input_sig_reg;

// Ackknowlege out
assign Ack_o = ack2_reg;

/// sync is pending
assign SyncPending_o = (cg_common_clock_mode_i == 0) ? pending_reg : 1'b0;
endmodule


