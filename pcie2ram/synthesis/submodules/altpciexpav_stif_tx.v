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
module altpciexpav_stif_tx

#(   parameter              INTENDED_DEVICE_FAMILY = "Stratix",  
     parameter              CG_AVALON_S_ADDR_WIDTH = 24,
     parameter              CG_COMMON_CLOCK_MODE   = 0,  
     parameter              CB_PCIE_MODE = 0,   
     parameter              CB_A2P_PERF_PROFILE    = 3,
     parameter              CB_P2A_PERF_PROFILE    = 3,
     parameter              CB_A2P_ADDR_MAP_IS_FIXED = 1,
     parameter  [1023:0]    CB_A2P_ADDR_MAP_FIXED_TABLE = 0,
     parameter              CB_A2P_ADDR_MAP_NUM_ENTRIES = 1,
     parameter              CB_A2P_ADDR_MAP_PASS_THRU_BITS = 24,
     parameter              EXTERNAL_A2P_TRANS =0,
     parameter              CG_RXM_IRQ_NUM = 16,
     parameter              CB_PCIE_RX_LITE = 0,
     parameter              CB_RXM_DATA_WIDTH = 64,
     parameter              port_type_hwtcl   = "Native endpoint",
     parameter              deviceFamily = "Arria V",
     parameter 							BYPASSS_A2P_TRANSLATION = 0 ,
     parameter              AVALON_ADDR_WIDTH = 32,
     parameter              in_cvp_mode_hwtcl = 0 
  )

  ( 
    input                                  Clk_i,
    input                                  Rstn_i,
    /// Avalon interface                   
    input                                  AvlClk_i,
    input                                  TxsRstn_i,
    input                                  TxChipSelect_i,
    input                                  TxRead_i,
    input                                  TxWrite_i,
    input   [63:0]                         TxWriteData_i,
    input   [6:0]                          TxBurstCount_i,
    input   [CG_AVALON_S_ADDR_WIDTH-1:0]   TxAddress_i,
    input   [7:0]                          TxByteEnable_i,
    input                                  TxReadDataValid_i,
    input   [CB_RXM_DATA_WIDTH-1:0]        TxReadData_i,
    output                                 TxWaitRequest_o,            
    input  [CG_RXM_IRQ_NUM-1 : 0]          RxmIrq_i,  
    input                                  MasterEnable_i,
                                           
    /// PCIe Core interface                
     input                                 TxStReady_i  ,
     output   [63:0]                       TxStData_o   ,
     output   [31:0]                       TxStParity_o ,
     output                                TxStErr_o    ,
     output                                TxStSop_o    ,
     output                                TxStEop_o    ,
     output   [1:0]                        TxStEmpty_o  ,
     output                                TxStValid_o  ,
     input                                 TxAdapterFifoEmpty_i,
     input  [31:0]                         DevCsr_i, 
     input  [12:0]                         BusDev_i, 
     output                                CplPending_o,
          
       
     /// Tx Credit interface
     input   [5 : 0]                      TxCredHipCons_i,
     input   [5 : 0]                      TxCredInfinit_i,
     input   [7 : 0]                      TxCredNpHdrLimit_i,
     input   [7:0]                        ko_cpl_spc_header,
     input   [11:0]                       ko_cpl_spc_data,
     
     input    [35:0]                        TxCredit_i,
     input                                  TxNpCredOne_i,
                                           
    // Rx Control interface                
     input                                 RxPndgRdFifoEmpty_i,
     input  [56:0]                         RxPndgRdFifoDato_i,
                                           
                                           
     output                                RxPndgRdFifoRdReq_o,
                                           
     output                                TxCplSent_o,
     output [9:0]                          TxCplDwSent_o,
     input                                 CplTagRelease_i,
    
    // Control reg interface for address translation table read and write
    input   [11:2]                         AdTrAddress_i,    /// Trans table address
    input   [3:0]                          AdTrByteEnable_i, // write byte enable
    input                                  AdTrWriteVld_i,  // write enable
    input   [31:0]                         AdTrWriteData_i, // write data
    input                                  AdTrReadVld_i,   // read request qualifies the AdTrAddress_i
    output  [31:0]                         AdTrReadData_o,  // read data
    output                                 AdTrReadVld_o,    // read data valid
   output                                 MsiReq_o,  
  input                                  MsiAck_i,  
  output                               IntxReq_o,
  input                                IntxAck_i,
  
  input      [15:0]                    MsiCsr_i,
  input      [63:0]                    MsiAddr_i,
  input      [15:0]                    MsiData_i,
  input      [31:0]                    PCIeIrqEna_i,
  input      [11:0]                    A2PMbWrAddr_i,
  input                                A2PMbWrReq_i,
  input                                TxsReadDataValid_i,
  
  output                               TxRespIdle_o,
  
  output                               TxRpFifoRdReq_o,
  input      [65:0]                    TxRpFifoData_i,  
  input                                RpTLPReady_i,
  output                               RpTLPAck_o,
  input                                pld_clk_inuse,
  output                               tx_cons_cred_sel,
  output                               TxBufferEmpty_o 
  
    
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

/// detect the fixed translation table for 32-bit addressing only
function integer address_32_only;
      input [1023:0] map_table;
      integer n;
      begin
            if ( (map_table[(0*64) + 63 :  (0*64) + 32] != 32'h0) |
                 (map_table[(1*64) + 63 :  (1*64) + 32] != 32'h0) |
                 (map_table[(2*64) + 63 :  (2*64) + 32] != 32'h0) |
                 (map_table[(3*64) + 63 :  (3*64) + 32] != 32'h0) |
                 (map_table[(4*64) + 63 :  (4*64) + 32] != 32'h0) |
                 (map_table[(5*64) + 63 :  (5*64) + 32] != 32'h0) |
                 (map_table[(6*64) + 63 :  (6*64) + 32] != 32'h0) |
                 (map_table[(7*64) + 63 :  (7*64) + 32] != 32'h0) |
                 (map_table[(8*64) + 63 :  (8*64) + 32] != 32'h0) |
                 (map_table[(9*64) + 63 : (9*64) + 32] != 32'h0) |
                 (map_table[(10*64) + 63 : (10*64) + 32] != 32'h0) |
                 (map_table[(11*64) + 63 : (11*64) + 32] != 32'h0) |
                 (map_table[(12*64) + 63 : (12*64) + 32] != 32'h0) |
                 (map_table[(13*64) + 63 : (13*64) + 32] != 32'h0) |
                 (map_table[(14*64) + 63 : (14*64) + 32] != 32'h0) |
                 (map_table[(15*64) + 63 : (15*64) + 32] != 32'h0) 
                 )
              address_32_only = 0;
            else
              address_32_only = 1;
      end
   endfunction 


localparam     ADDRESS_32BIT = (CB_A2P_ADDR_MAP_IS_FIXED == 1 & address_32_only(CB_A2P_ADDR_MAP_FIXED_TABLE));
localparam     CB_TX_CPL_BUFFER_DEPTH  = 128;
localparam     CB_TX_WR_BUFFER_DEPTH  = (CB_A2P_PERF_PROFILE == 2)? 64 : 128;
localparam     WR_BUFF_ADDR_WIDTH     = clogb2(CB_TX_WR_BUFFER_DEPTH) ;
localparam     TXCPL_BUFF_ADDR_WIDTH     = clogb2(CB_TX_CPL_BUFFER_DEPTH) ;



wire                          avl_addr_vld;
wire [CG_AVALON_S_ADDR_WIDTH-1:0]         avl_addr;
wire                          a2ptrans_done;
wire [63:0]                   pcie_addr;
wire [1:0]                    pcie_addr_space;
wire                          rdwr_header_wrreq;
wire [98:0]                   rd_wr_header;
wire                          cmd_fifo_full;
wire [3:0]                    cmd_fifo_usedw;
wire                          wrdat_fifo_wrreq;
wire [8:0]                    cplbuff_wraddr;
wire [98:0]                  cpl_header;
wire                          cpl_header_wrreq;
wire                          cmd_fifo_busy;
wire                          cmdfifo_wrreq;
reg                           cmdfifo_wrreq_reg;
wire                          cmdfifo_rdreq;
wire [98:0]                  cmdfifo_datain;
reg [98:0]                  cmdfifo_datain_reg;
wire                          cmd_fifo_empty;
wire  [98:0]                 cmdfifo_dato;
wire                          wrdat_fifo_rdreq;
wire [63:0]                   wr_datout;
wire  [4:0]                   txrd_tagram_wraddr;
wire                          txrd_tagram_wrena;
wire  [22:0]                  txrd_tagram_wrdat;
wire  [63:0]                  cpl_datout;
wire                          rd_bpfifo_empty;
wire  [6:0]                   rd_bpfifo_usedw;
wire                          rd_bpfifo_full;
wire  [98:0]                 rd_bpfifo_dat;
wire                          rd_bpfifo_wrreq;
wire                          rd_bpfifo_rdreq;
wire [8:0]                    cplbuff_rdaddr;
reg  [63:0]                   cpldat_out_reg;
wire [5 : 0] wrdat_fifo_usedw;
wire [22:0]  tag_ram_q;
reg  [31:0]  cpl_data_reg;


  
///// avalon tx control
altpciexpav_stif_txavl_cntrl
# (
   .CG_AVALON_S_ADDR_WIDTH(CG_AVALON_S_ADDR_WIDTH),
   .CB_PCIE_MODE(CB_PCIE_MODE),
   .CG_RXM_IRQ_NUM(CG_RXM_IRQ_NUM),
   .CB_PCIE_RX_LITE(CB_PCIE_RX_LITE),
   .INTENDED_DEVICE_FAMILY(INTENDED_DEVICE_FAMILY),
   .port_type_hwtcl(port_type_hwtcl),
   .BYPASSS_A2P_TRANSLATION								(BYPASSS_A2P_TRANSLATION),
   .AVALON_ADDR_WIDTH(AVALON_ADDR_WIDTH)
  
   )
   
txavl
    
(      .AvlClk_i(AvlClk_i),     // Avalon clock
       .Rstn_i(TxsRstn_i),    // Avalon reset
       .TxChipSelect_i(TxChipSelect_i),  // avalon chip sel
       .TxRead_i(TxRead_i),        // avalon read
       .TxWrite_i(TxWrite_i),       // avalon write
       .TxBurstCount_i(TxBurstCount_i),    // busrt count
       .TxAddress_i(TxAddress_i), // word address
       .TxByteEnable_i(TxByteEnable_i),   
       .TxWaitRequest_o(TxWaitRequest_o),
       .RxmIrq_i(RxmIrq_i),   
       .MasterEnable_i(MasterEnable_i),
       .AvlAddrVld_o(avl_addr_vld),
       .AvlAddr_o(avl_addr), // byte address 
       .AddrTransDone_i(a2ptrans_done),     
       .PCIeAddr_i(pcie_addr),
       .PCIeAddrSpace_i(pcie_addr_space),
       .CmdFifoWrReq_o(rdwr_header_wrreq),
       .CmdFifoBusy_o(cmd_fifo_busy),
       .TxReqHeader_o(rd_wr_header),
       .CmdFifoUsedW_i(cmd_fifo_usedw),
       .WrDatFifoUsedW_i(wrdat_fifo_usedw),
       .WrDatFifoWrReq_o(wrdat_fifo_wrreq),
       .DevCsr_i(DevCsr_i),             
       .BusDev_i(BusDev_i),
       .MsiCsr_i(MsiCsr_i),  
       .MsiAddr_i(MsiAddr_i),     
       .PCIeIrqEna_i(PCIeIrqEna_i),   
       .A2PMbWrAddr_i(A2PMbWrAddr_i),  
       .A2PMbWrReq_i(A2PMbWrReq_i),
       .TxsReadDataValid_i(TxsReadDataValid_i)

       
       
       
       
       
);     
       
//// Address translation (A2P)
//// instantiation of the address translation module


 altpciexpav_stif_a2p_addrtrans 
 
  #(
    .CB_A2P_ADDR_MAP_IS_FIXED(CB_A2P_ADDR_MAP_IS_FIXED) ,
    .CB_A2P_ADDR_MAP_NUM_ENTRIES(CB_A2P_ADDR_MAP_NUM_ENTRIES),
    .CB_A2P_ADDR_MAP_PASS_THRU_BITS(CB_A2P_ADDR_MAP_PASS_THRU_BITS), 
    .CG_AVALON_S_ADDR_WIDTH(CG_AVALON_S_ADDR_WIDTH),
    .CB_A2P_ADDR_MAP_FIXED_TABLE(CB_A2P_ADDR_MAP_FIXED_TABLE),
    .INTENDED_DEVICE_FAMILY(INTENDED_DEVICE_FAMILY)
    ) 
 
a2p_addr_trans
  (
    .PbaClk_i(AvlClk_i),        // Clock For Avalon to PCI Trans
    .PbaRstn_i(TxsRstn_i),       // Reset signal  
    .PbaAddress_i(avl_addr),    // Must be a byte specific address
    .PbaByteEnable_i(TxByteEnable_i),
    .PbaAddrVld_i(avl_addr_vld),    // Valid indication in 
    .PciAddr_o(pcie_addr),       // Is a byte specific address
    .PciAddrSpace_o(pcie_addr_space),  // DAC Needed 
    .PciAddrVld_o(a2ptrans_done),    // Valid indication out (piped)
    .CraClk_i(AvlClk_i),        // Clock for register access port
    .CraRstn_i(TxsRstn_i),       // Reset signal  
    .AdTrAddress_i(AdTrAddress_i),   // Register (DWORD) specific address from control reg module [11:2]
    .AdTrByteEnable_i(AdTrByteEnable_i),// Register Byte Enables
    .AdTrWriteVld_i(AdTrWriteVld_i),  // Valid Write Cycle in  
    .AdTrWriteData_i(AdTrWriteData_i), // Write Data in 
    .AdTrReadVld_i(AdTrReadVld_i),   // Read request valid from control reg indicating the address of the table is valid
    .AdTrReadData_o(AdTrReadData_o),  // Read Data out
    .AdTrReadVld_o(AdTrReadVld_o)  // Read Valid out (piped) 
  );

///// Avalon read response control
altpciexpav_stif_txresp_cntrl 
 #( .TXCPL_BUFF_ADDR_WIDTH(TXCPL_BUFF_ADDR_WIDTH),
    .CB_PCIE_RX_LITE(CB_PCIE_RX_LITE)
   )
txresp
(      .AvlClk_i(AvlClk_i),     // Avalon clock
       .Rstn_i(TxsRstn_i),    // Avalon reset
       .RxPndgRdFifoEmpty_i(RxPndgRdFifoEmpty_i),
       .RxPndgRdFifoDato_i(RxPndgRdFifoDato_i),
       .RxPndgRdFifoRdReq_o(RxPndgRdFifoRdReq_o),
       .TxReadDataValid_i(TxReadDataValid_i),
       .CplRamWrAddr_o(cplbuff_wraddr),
       .CmdFifoDatin_o(cpl_header),
       .CmdFifoWrReq_o(cpl_header_wrreq),
       .CmdFifoBusy_i(cmd_fifo_busy),        // being access by the main control
       .CmdFifoUsedw_i(cmd_fifo_usedw),
       .DevCsr_i(DevCsr_i),             
       .BusDev_i(BusDev_i),
       .TxRespIdle_o(TxRespIdle_o)
);



	scfifo	txcmd_fifo (
				.rdreq (cmdfifo_rdreq),
				.clock (Clk_i),
				.wrreq (cmdfifo_wrreq_reg),
				.data (cmdfifo_datain_reg),
				.usedw (cmd_fifo_usedw),
				.empty (cmd_fifo_empty),
				.q (cmdfifo_dato),
				.full (cmd_fifo_full) ,
				.aclr (~Rstn_i),
				.almost_empty (),
				.almost_full (),
				.sclr ()
				);
	defparam
		txcmd_fifo.add_ram_output_register = "ON",
		txcmd_fifo.intended_device_family = "Stratix IV",
		txcmd_fifo.lpm_numwords = 16,
		txcmd_fifo.lpm_showahead = "OFF",
		txcmd_fifo.lpm_type = "scfifo",
		txcmd_fifo.lpm_width = 99,
		txcmd_fifo.lpm_widthu = 4,
		txcmd_fifo.overflow_checking = "ON",
		txcmd_fifo.underflow_checking = "ON",
		txcmd_fifo.use_eab = "ON";


// mux to select between wr/read and completion header
assign cmdfifo_datain =  cpl_header_wrreq? cpl_header : rd_wr_header;
assign cmdfifo_wrreq  =  cpl_header_wrreq? cpl_header_wrreq : rdwr_header_wrreq;    
assign TxBufferEmpty_o = cmd_fifo_empty;

 always @(posedge AvlClk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
     begin
      cmdfifo_datain_reg <= 0;
      cmdfifo_wrreq_reg <= 0;
    end
    else
      begin
       cmdfifo_datain_reg <= cmdfifo_datain;
      cmdfifo_wrreq_reg <= cmdfifo_wrreq;
      end
  end
//// Write Data FIFO to hold the write data

generate if(CB_PCIE_MODE == 0)
begin
     
	scfifo	wrdat_fifo (
				.rdreq (wrdat_fifo_rdreq),
				.clock (Clk_i),
				.wrreq (wrdat_fifo_wrreq),
				.data (TxWriteData_i),
				.usedw (wrdat_fifo_usedw),
				.empty (),
				.q (wr_datout),
				.full () ,
				.aclr (~Rstn_i),
				.almost_empty (),
				.almost_full (),
				.sclr ()
				);
	defparam
		wrdat_fifo.add_ram_output_register = "ON",
		wrdat_fifo.intended_device_family = "Stratix IV",
		wrdat_fifo.lpm_numwords = 64,
		wrdat_fifo.lpm_showahead = "OFF",
		wrdat_fifo.lpm_type = "scfifo",
		wrdat_fifo.lpm_width = 64,
		wrdat_fifo.lpm_widthu = 6,
		wrdat_fifo.overflow_checking = "ON",
		wrdat_fifo.underflow_checking = "ON",
		wrdat_fifo.use_eab = "ON";

end
else
  begin
    assign wrdat_fifo_usedw = 0;
    assign wr_datout = 64'h0;
  end
endgenerate



/// Read Bypass FIFO

generate if(CB_PCIE_MODE == 0)

begin
	scfifo	rd_bypass_fifo (
				.rdreq (rd_bpfifo_rdreq),
				.clock (Clk_i),
				.wrreq (rd_bpfifo_wrreq),
				.data (cmdfifo_dato),
				.usedw (rd_bpfifo_usedw),
				.empty (rd_bpfifo_empty),
				.q (rd_bpfifo_dat),
				.full (rd_bpfifo_full) ,
				.aclr (~Rstn_i),
				.almost_empty (),
				.almost_full (),
				.sclr ()
				);
	defparam
		rd_bypass_fifo.add_ram_output_register = "ON",
		rd_bypass_fifo.intended_device_family = "Stratix IV",
		rd_bypass_fifo.lpm_numwords = 64,
		rd_bypass_fifo.lpm_showahead = "OFF",
		rd_bypass_fifo.lpm_type = "scfifo",
		rd_bypass_fifo.lpm_width = 99,
		rd_bypass_fifo.lpm_widthu = 6,
		rd_bypass_fifo.overflow_checking = "ON",
		rd_bypass_fifo.underflow_checking = "ON",
		rd_bypass_fifo.use_eab = "ON";

end

else
  begin
    assign rd_bpfifo_dat = 99'h0;
    assign rd_bpfifo_full = 1'b0;
    assign rd_bpfifo_empty = 1'b1;
  end
endgenerate

/// Tx Completion buffer
generate if (CB_PCIE_RX_LITE == 0)
 begin
altsyncram	
#(     
    .intended_device_family(INTENDED_DEVICE_FAMILY),
		.operation_mode("DUAL_PORT"),
		.width_a(64),
		.widthad_a(TXCPL_BUFF_ADDR_WIDTH),
		.numwords_a(CB_TX_CPL_BUFFER_DEPTH),
		.width_b(64),
		.widthad_b(TXCPL_BUFF_ADDR_WIDTH),
		.numwords_b(CB_TX_CPL_BUFFER_DEPTH),
		.lpm_type("altsyncram"),
		.width_byteena_a(1),
		.outdata_reg_b("UNREGISTERED"),
		.indata_aclr_a("NONE"),
		.wrcontrol_aclr_a("NONE"),
		.address_aclr_a("NONE"),
		.address_reg_b("CLOCK1"),
		.address_aclr_b("NONE"),
		.outdata_aclr_b("NONE"),
		.power_up_uninitialized("FALSE")
) 
  
  
tx_cpl_buff (
				.wren_a (TxReadDataValid_i),
				.clocken1 (),
				.clock0 (AvlClk_i),
				.clock1 (Clk_i),
				.address_a (cplbuff_wraddr),
				.address_b (cplbuff_rdaddr),
				.data_a (TxReadData_i),
				.q_b (cpl_datout),
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clocken0 (),
				.data_b (),
				.q_a (),
				.rden_b (),
				.wren_b ()
                );
end

else
  begin
  	always @(posedge Clk_i or negedge Rstn_i)
  	  begin
  	  	 if (~Rstn_i)
  	  	   cpl_data_reg <= 32'h0;
  	  	 else if (TxReadDataValid_i)
  	  	   cpl_data_reg <= TxReadData_i;
  	  end
  	
  	assign cpl_datout = {cpl_data_reg[31:0], cpl_data_reg[31:0]};
  end
endgenerate


//// PCIe Tx Control
altpciexpav_stif_tx_cntrl  
#(
.ADDRESS_32BIT(ADDRESS_32BIT),
.CB_PCIE_MODE(CB_PCIE_MODE),
.CG_COMMON_CLOCK_MODE(CG_COMMON_CLOCK_MODE),
.AST_WIDTH(64),
.deviceFamily(INTENDED_DEVICE_FAMILY),
.in_cvp_mode_hwtcl   (in_cvp_mode_hwtcl)
)
   
tx_cntrl 
( .Clk_i(Clk_i),     
  .Rstn_i(Rstn_i),     
  
  // PCIe core Tx interface
  .TxStReady_i  (TxStReady_i),
  .TxStData_o   (TxStData_o),
  .TxStParity_o (TxStParity_o),
  .TxStErr_o    (TxStErr_o),
  .TxStSop_o    (TxStSop_o),
  .TxStEop_o    (TxStEop_o),
  .TxStEmpty_o  (TxStEmpty_o),
  .TxStValid_o  (TxStValid_o),
  .TxAdapterFifoEmpty_i(TxAdapterFifoEmpty_i),
  // Command Fifo interface
  .CmdFifoDat_i(cmdfifo_dato),
  .CmdFifoEmpty_i(cmd_fifo_empty),
  .CmdFifoRdReq_o(cmdfifo_rdreq),
  .MsiAddr_i(MsiAddr_i),
  .MsiData_i(MsiData_i),
  
 .RdBypassFifoEmpty_i(rd_bpfifo_empty), 
 .RdBypassFifoFull_i(rd_bpfifo_full),   
 .RdBypassFifoUsedw_i(rd_bpfifo_usedw),
 .RdBypassFifoDat_i(rd_bpfifo_dat),     
 .RdBypassFifoWrReq_o(rd_bpfifo_wrreq), 
 .RdBypassFifoRdReq_o(rd_bpfifo_rdreq), 
 .RxCplBuffFree_i(CplTagRelease_i),

  
  
  
  // Completion buffer interface
  .CplBuffRdAddr_o(cplbuff_rdaddr),
  .TxCplDat_i(cpl_datout),
  
  // write data fifo interface
  .WrDatFifoRdReq_o(wrdat_fifo_rdreq),
  .TxWrDat_i(wr_datout),
  
  /// read tag ram interface
 // .TxRdTagRamWrAddr_o(txrd_tagram_wraddr),
 // .TxRdTagRamWrEna_o(txrd_tagram_wrena),
 // .TxRdTagRamDat_o(txrd_tagram_wrdat),
  
  // Rx Completion interface for buffer credit keeping
  .TxCplSent_o(TxCplSent_o),
  .TxCplDwSent_o(TxCplDwSent_o),
  .CplPending_o(CplPending_o),
  
  // cfg register
  .BusDev_i(BusDev_i),
  .MsiCsr_i(MsiCsr_i),
  .MsiReq_o(MsiReq_o), 
  .MsiAck_i(MsiAck_i),
  .IntxReq_o(IntxReq_o),
  .IntxAck_i(IntxAck_i),
  .TxCredHipCons_i(TxCredHipCons_i),    
  .TxCredInfinit_i(TxCredInfinit_i),    
  .TxCredNpHdrLimit_i(TxCredNpHdrLimit_i),
  .ko_cpl_spc_header(ko_cpl_spc_header),
  .ko_cpl_spc_data(ko_cpl_spc_data),
  
  .TxCredit_i(TxCredit_i),
  .TxNpCredOne_i(TxNpCredOne_i),
  
    // RP interface
  .TxRpFifoRdReq_o(TxRpFifoRdReq_o),  
  .TxRpFifoData_i(TxRpFifoData_i), 
  .RpTLPReady_i(RpTLPReady_i),
  .RpTLPAck_o(RpTLPAck_o),
   .pld_clk_inuse(pld_clk_inuse),
   .tx_cons_cred_sel(tx_cons_cred_sel)
  
);

endmodule
