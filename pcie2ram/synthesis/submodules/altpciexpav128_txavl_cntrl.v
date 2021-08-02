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


// altera message_off 10230 10036
// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on
module altpciexpav128_txavl_cntrl

# (
    parameter CG_AVALON_S_ADDR_WIDTH = 20,
    parameter CB_PCIE_MODE = 0,
    parameter CG_RXM_IRQ_NUM = 1,
    parameter CB_A2P_ADDR_MAP_PASS_THRU_BITS = 24,
    parameter CB_PCIE_RX_LITE = 0,
    parameter BYPASSS_A2P_TRANSLATION = 0,
    parameter AVALON_ADDR_WIDTH = 32

   )
    
( input                                AvlClk_i,     // Avalon clock
  input                                Rstn_i,    // Avalon reset
                                       
  // Avalon master port                
  input                                TxChipSelect_i,  // avalon chip sel
  input                                TxRead_i,        // avalon read
  input                                TxWrite_i,       // avalon write
  input  [5:0]                         TxBurstCount_i,    // busrt count
  input  [CG_AVALON_S_ADDR_WIDTH-1:0]  TxAddress_i, // word address
  input  [15:0] TxByteEnable_i,    // read enable
  output                               TxWaitRequest_o,
  
  
  // Address translation interface
  output                               AvlAddrVld_o,
  output [CG_AVALON_S_ADDR_WIDTH-1:0]  AvlAddr_o, // byte address 
  input                                AddrTransDone_i,     
  input  [63:0]                        PCIeAddr_i,
  input  [1:0]                         PCIeAddrSpace_i,
  
  // Command/Data buffer interface
  output                               CmdFifoWrReq_o,
  output      [98:0]                   TxReqHeader_o,
  input       [3:0]                    CmdFifoUsedW_i,
  
  // Tx Resp interface
  output                               CmdFifoBusy_o,
  
  input        [5:0]                   WrDatFifoUsedW_i,
  output                               WrDatFifoWrReq_o,
  output                               WrDatFifoEop_o,
  
  // cfg signals
  input      [31:0]                    DevCsr_i,             
  input      [12:0]                    BusDev_i,    
  input                                MasterEnable_i,
  input      [15:0]                    MsiCsr_i,
  input      [63:0]                    MsiAddr_i,
  input      [15:0]                    MsiData_i,
  input      [31:0]                    PCIeIrqEna_i,
  input      [11:0]                    A2PMbWrAddr_i,
  input                                A2PMbWrReq_i,
  
  input                                TxsReadDataValid_i,
  
  input     [CG_RXM_IRQ_NUM-1 : 0]     RxmIrq_i
);

localparam      TXAVL_IDLE          = 10'h000;
localparam      TXAVL_WAIT_WRADDR   = 10'h003;
localparam      TXAVL_BURST_DATA    = 10'h005;
localparam      TXAVL_WRHEADER      = 10'h009;
localparam      TXAVL_WR_HOLD       = 10'h011;
localparam      TXAVL_WAIT_RDADDR   = 10'h021;
localparam      TXAVL_RDHEADER      = 10'h041;
localparam      TXAVL_RDPIPE        = 10'h081;
localparam      TXAVL_WRPIPE        = 10'h101;
localparam      TXAVL_MSI           = 10'h201;


localparam      TX_PNDGRD_IDLE     = 3'h0;
localparam      TX_PNDGRD_LATCH    = 3'h3;
localparam      TX_PNDGRD_CHECK    = 3'h5;





wire          wr_fifos_ok; 
wire          pcie_boundary;
wire          maxpayload_reached;
wire          last_rd_segment; 
wire [12:0]   bytes_to_4KB;
wire [12:0]   unadjusted_bytes_to_4KB;
wire [12:0]   wr_bytes_to_4KB;
wire          wr_bytes_to_4KB_lte_16;
wire          to_4KB_sel;
wire          remain_bytes_sel;

wire          sm_idle;    
reg           sm_idle_reg;
wire          sm_msi;
wire          sm_wait_wraddr;  
wire          sm_burst_data;   
wire          sm_wrheader;     
wire          sm_wr_hold;      
wire          sm_wait_rdaddr;  
wire          sm_rdheader;
wire [8:0]    rd_dw_len;
wire [8:0]    wr_dw_len;
wire          txready;
wire          rx_only;
wire reads_up;  
wire reads_down;
wire cmd_fifo_ok;
wire wrdat_fifo_ok;
wire bypass_trans;
wire pcie_space_64;

   

wire [15:0] requestor_id;
reg [3:0] fbe;
reg [3:0] lbe;
wire [CG_RXM_IRQ_NUM-1:0]  generate_irq;

reg [9:0]                         txavl_state;
reg [9:0]                         txavl_nxt_state;
reg [9:0]                         burst_counter;
reg [CG_AVALON_S_ADDR_WIDTH-1:0]  wr_addr_reg;
reg [CG_AVALON_S_ADDR_WIDTH-1:0]  avl_wr_addr_cntr;
reg [12:0]                        payload_byte_cntr;
reg [CG_AVALON_S_ADDR_WIDTH-1:0]  rd_addr_reg;
reg [9:0]                        rd_size;
reg [9:0]                        unadjusted_rd_size;
reg [9:0]                        remain_rdbytecnt_reg;
reg [9:0]                        unadjusted_remain_rdbytecnt_reg;
reg [11:0]                        max_rd_size;
reg [11:0]                        max_payload_size;
reg [3:0]                         tag_cntr;
reg [1:0]                         rdsize_sel_reg;
reg [3:0]                         adjusted_dw_reg;
reg [15:0]                         first_avlbe_reg;
reg [15:0]                         last_avlbe_reg;


reg [12:0]                       bytes_to_4KB_reg;
reg [12:0]                       unadjusted_bytes_to_4KB_reg;
wire [1:0]                       rdsize_sel;
wire [8:0]                       dw_size;    
reg  [8:0]                       dw_size_reg;            
wire [8:0]                       tlp_len;

wire is_rd32;
wire is_rd64;
wire is_wr32;
wire is_wr64;
wire sm_wr_pipe;
wire byte_eq_maxpayload;

reg [4:0] reads_cntr;                     

reg [2:0]  pendingrd_state;
reg [2:0]  pendingrd_nxt_state;
wire       pendingrd_fifo_wrreq;
wire       pendingrd_fifo_rdreq;
wire       pendingrd_fifo_rdempty;
wire   [9:0] pendingrd_fifo_q;
reg    [9:0] read_valid_counter;
wire         pendingrd_check_state;
wire         terminal_count;
reg          terminal_count_reg;
wire         pendingrd_fifo_latch;
reg  [9:0]     pendingrd_fifo_q_reg;
reg          rxm_irq_reg;
wire        rxm_irq_rise;
reg         rxm_irq_sreg  /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL =D101" */;   
reg [9:0]  rd_byte_count;                        
reg [9:0]  adjusted_rd_byte_count;
reg [CG_AVALON_S_ADDR_WIDTH-1:0] tx_byte_address;
reg [1:0]  adjusted_dw_non_burst;
reg [3:0]  adjusted_dw_burst;
reg [3:0]  fbe_nibble_sel;
reg [3:0]  lbe_nibble_sel;
reg [63:CB_A2P_ADDR_MAP_PASS_THRU_BITS]   translated_address_upper_reg;
reg [1:0]  address_space_reg;
reg [CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0] translated_address_cntr;
reg         addr_trans_done_reg;
wire        addr_trans_done_rise;
wire [63:0]  pcie_address;
reg  [5:0]   tx_burst_cnt_reg;
reg [CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0]  wr_addr_counter;
reg  [3:0]  addr_lsb;
wire        one_dw_read;      
wire        one_dw_write;
wire        one_dw;
reg         tx_single_qw_reg;
reg         wr_split_pending;
wire   [63:0] pci_exp_address;
wire   [1:0] pcie_address_space;
wire         trans_ready;


generate if(CB_PCIE_MODE == 1)
  assign rx_only = 1'b1;
else
  assign rx_only = 1'b0;
endgenerate

generate if (AVALON_ADDR_WIDTH == 64)
		begin
			assign bypass_trans = 1'b1;
		end
	else
		begin
			assign bypass_trans = 1'b0;
		end
endgenerate
			assign AvlAddrVld_o = sm_wait_rdaddr | sm_wait_wraddr;
assign AvlAddr_o = (sm_wait_rdaddr | sm_rdheader)? rd_addr_reg : wr_addr_reg;
assign pcie_address_space = bypass_trans? 2'b01 : PCIeAddrSpace_i;
assign pci_exp_address  = bypass_trans? {{(64-CG_AVALON_S_ADDR_WIDTH){1'b0}}, AvlAddr_o} : PCIeAddr_i[63:0];
assign trans_ready   = AddrTransDone_i;

assign wrdat_fifo_ok = (WrDatFifoUsedW_i <= 32);
assign cmd_fifo_ok = (CmdFifoUsedW_i <= 8);


/// Tx control state machine

always @(posedge AvlClk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      txavl_state <= TXAVL_IDLE;
    else
      txavl_state <= txavl_nxt_state;
  end

// state machine next state gen


always @*  
  begin
    case(txavl_state)
      TXAVL_IDLE :
        if(rxm_irq_sreg & cmd_fifo_ok & MasterEnable_i)
          txavl_nxt_state <= TXAVL_MSI;
       else if((TxChipSelect_i & TxWrite_i & wr_fifos_ok & ~rx_only  & ~rxm_irq_sreg & MasterEnable_i & ~trans_ready))        // write cycle detected and fifo ok (cmd and wr_dat fifo)
          txavl_nxt_state <= TXAVL_WAIT_WRADDR;       
        else if(TxChipSelect_i & TxRead_i & ~rx_only & reads_cntr < 16  & ~rxm_irq_sreg & MasterEnable_i & ~trans_ready)   // read cycle
          txavl_nxt_state <= TXAVL_WAIT_RDADDR;            
        else
          txavl_nxt_state <= TXAVL_IDLE;
        
      TXAVL_WAIT_WRADDR :   // wait for address translation done 
        if(trans_ready & wrdat_fifo_ok  & TxWrite_i & TxChipSelect_i) // address translation done signaled
          txavl_nxt_state <= TXAVL_BURST_DATA;
        else
          txavl_nxt_state <= TXAVL_WAIT_WRADDR;
          
      TXAVL_BURST_DATA:  // burst data to the FIFO untill fifo is full or done
        if( (pcie_boundary == 1 | burst_counter == 1 | maxpayload_reached) & TxChipSelect_i & TxWrite_i) // at the end of 4-KB boundary or the last data
          txavl_nxt_state <= TXAVL_WRPIPE;
        else if(~wrdat_fifo_ok)
          txavl_nxt_state <= TXAVL_WR_HOLD;  // hold off busrting
        else
          txavl_nxt_state <= TXAVL_BURST_DATA; // keep bursting
          
      TXAVL_WRPIPE:
        if(cmd_fifo_ok)
         txavl_nxt_state <= TXAVL_WRHEADER;
        else
         txavl_nxt_state <= TXAVL_WRPIPE;
      
      TXAVL_WRHEADER:
        if(burst_counter == 0)
          txavl_nxt_state <= TXAVL_IDLE; // done w/ current write
        else if (wr_addr_counter[11:0] == 12'h000)  
           txavl_nxt_state <= TXAVL_WAIT_WRADDR;
        else
          txavl_nxt_state <= TXAVL_BURST_DATA;
          
      TXAVL_WR_HOLD:
        if(wrdat_fifo_ok)
          txavl_nxt_state <= TXAVL_BURST_DATA;
        else
          txavl_nxt_state <= TXAVL_WR_HOLD;
      
      TXAVL_WAIT_RDADDR:
         if(trans_ready & cmd_fifo_ok) // addr translaled and fifo is ok
          txavl_nxt_state <= TXAVL_RDHEADER;
        else
          txavl_nxt_state <= TXAVL_WAIT_RDADDR;
          
      TXAVL_RDHEADER:
        if(last_rd_segment)
          txavl_nxt_state <= TXAVL_IDLE;
        else
          txavl_nxt_state <= TXAVL_RDPIPE; // piping state (doing nothing except that)
      
      TXAVL_RDPIPE:
        if(~trans_ready)
          txavl_nxt_state <= TXAVL_WAIT_RDADDR;
        else
          txavl_nxt_state <= TXAVL_RDPIPE;
      
      TXAVL_MSI:
          txavl_nxt_state <= TXAVL_IDLE;
      
     default :
         txavl_nxt_state <= TXAVL_IDLE;
         
    endcase
 end
 
 
 
 
 /// assign sm outputs
wire last_sub_read; 

assign  sm_idle         = ~txavl_state[0];    
assign  sm_wait_wraddr  = txavl_state[1] ;  
assign  sm_burst_data   = txavl_state[2];    
assign  sm_wrheader     = txavl_state[3];      
assign  sm_wr_hold      = txavl_state[4];       
assign  sm_wait_rdaddr  = txavl_state[5];   
assign  sm_rdheader     = txavl_state[6]; 
assign  sm_wr_pipe      = txavl_state[8];
assign  sm_msi          = txavl_state[9];

assign last_sub_read = sm_rdheader & last_rd_segment;

assign WrDatFifoWrReq_o = sm_burst_data & TxWrite_i & TxChipSelect_i;
assign WrDatFifoEop_o   = sm_burst_data & ( (pcie_boundary == 1 | burst_counter == 1 | maxpayload_reached) & TxChipSelect_i & TxWrite_i);
/// //////////////////state machine supporting signals //////////////////


assign txready = sm_burst_data | (sm_idle & TxChipSelect_i & TxRead_i & reads_cntr < 16 & ~rxm_irq_sreg & MasterEnable_i & ~trans_ready) ; // do not assert ready when IRQ pending
                          
assign TxWaitRequest_o  = ~txready;                     
// write fifo ok
assign wr_fifos_ok = cmd_fifo_ok & wrdat_fifo_ok;

// PCI Express address boundary (4-KB)
/// write address counter with 128-bit granuality
  always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      wr_addr_counter <= 0;
    else if(addr_trans_done_rise)
      wr_addr_counter <= {pci_exp_address[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:4], 4'b0000};
    else if(sm_burst_data &  TxWrite_i & TxChipSelect_i)
      wr_addr_counter <= wr_addr_counter + 16;
  end
  
  always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      avl_wr_addr_cntr <= 0;
    else if(sm_idle)
      avl_wr_addr_cntr <= tx_byte_address;
    else if(sm_burst_data &  TxWrite_i & TxChipSelect_i)
      avl_wr_addr_cntr <= avl_wr_addr_cntr + 16;
  end
  // hold the address for address translation
   // adjust the address based on Byte enable. Shoud use casez to maske don't care upper bits
  always @*
    begin
       case(TxByteEnable_i[15:0])
         16'hFFF0 : tx_byte_address = {TxAddress_i[CG_AVALON_S_ADDR_WIDTH-1:4], 4'h4};
         16'hFF00 : tx_byte_address = {TxAddress_i[CG_AVALON_S_ADDR_WIDTH-1:4], 4'h8};
         16'hF000 : tx_byte_address = {TxAddress_i[CG_AVALON_S_ADDR_WIDTH-1:4], 4'hC};
         default  : tx_byte_address = {TxAddress_i[CG_AVALON_S_ADDR_WIDTH-1:4], 4'h0};
       endcase
    end
  
 always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     begin
      tx_single_qw_reg <= 1'b0;
     end
    else if(sm_idle)
     begin
      tx_single_qw_reg <= (TxBurstCount_i == 1);
     end
  end
 
 always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      wr_split_pending <= 1'b0;
    else if(sm_wrheader)
      wr_split_pending <= 1'b1;
    else if(sm_idle)
      wr_split_pending <= 1'b0;
  end
 
  always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      wr_addr_reg <= 0;
    else if(sm_idle)
      wr_addr_reg <= tx_byte_address;
    else if(sm_wrheader)
       wr_addr_reg <= avl_wr_addr_cntr;
  end
 
 
 
  always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
     begin
      dw_size_reg      <= 0;
     end
    else
     begin
       dw_size_reg      <= dw_size;
     end
  end
 
 
  assign pcie_boundary = (wr_addr_counter[11:4] == 8'hFF); // 4-KB boundary reached
  
  /// burst counter to keep count of the remaining write data for the current write
  // packet
  
  always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      burst_counter <= 10'h0;
    else if(sm_idle)
      burst_counter <= {4'b0000, TxBurstCount_i[5:0]};
    else if(sm_burst_data &  TxWrite_i & TxChipSelect_i)
      burst_counter <= burst_counter - 1'b1;
  end
  
//Max payload reached
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      payload_byte_cntr <= 13'h000; // in byte
    else if(sm_wrheader)
      payload_byte_cntr <= 13'h000;
    else if(sm_burst_data & TxWrite_i & TxChipSelect_i)
      payload_byte_cntr <= payload_byte_cntr + 16;
  end

assign maxpayload_reached = (payload_byte_cntr == (max_payload_size-16)) & TxChipSelect_i & TxWrite_i;

// decode the max payload size


always @*
  begin
    case(DevCsr_i[7:5])
      3'b000 : max_payload_size = 128;
      default : max_payload_size = 256; // if >= 256 set to 256
    endcase
  end

/////// calculate the split address and byte count for the reads
// based on the:
// # of bytes to 4KB boundary
// remianing byte count of the current read
// and the max read request size

// cacalculate the number of byte count to 4KB boudary based on the address
// and the burst count


// decode the max read size

always @*
  begin
    case(DevCsr_i[14:12])
      3'b000 : max_rd_size = 128;
      3'b001 : max_rd_size = 256;
      default : max_rd_size = 512;
    endcase
  end


// read address reg increments byte the amount of byte in each read header
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      rd_addr_reg <= 0;
    else if(sm_idle)
      rd_addr_reg <= tx_byte_address;
    else if(sm_rdheader)
      rd_addr_reg <= rd_addr_reg + rd_size;
  end
  
  /// the reaming byte count after a read header is written into the Command FIFO   
  /// since the address is adjusted based on the byte enables, the byte count also needs to be calculated from byte enables
  /// We may need to add support for the starting BE at any byte position and with any contiguous bytes within a word.
  
  
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      tx_burst_cnt_reg <= 6'h0;
    else if(TxChipSelect_i & ~TxWaitRequest_o) 
      tx_burst_cnt_reg <= TxBurstCount_i;
  end  
  
// Since the read with burst count > 1 must have all byte enable asserted
// it might not make sense to use the   tx_burst_cnt_reg in the logic
// below. We could hard code to 4, 8, 12, or 16 ???  
always @*
  begin
    case (first_avlbe_reg[15:0])
    //  16'h000F, 16'h00F0, 16'h0F00, 16'hF000 : rd_byte_count = 4;        
    //  16'hFFF0, 16'h0FFF                     : rd_byte_count = {tx_burst_cnt_reg[5:1], 4'b1100}; // + 12;
    //  16'hFF00, 16'h0FF0, 16'h00FF           : rd_byte_count = {tx_burst_cnt_reg[5:1], 4'b1000}; // + 8;
    //  16'hF000                               : rd_byte_count = {tx_burst_cnt_reg[5:1], 4'b0100}; // + 4;        
    16'h000F, 16'h00F0, 16'h0F00, 16'hF000 :  rd_byte_count = 16;                                         
    16'hFFF0, 16'h0FFF                     :  rd_byte_count = 16; 
    16'hFF00, 16'h0FF0, 16'h00FF           :  rd_byte_count = 16;  
    default                                : rd_byte_count = {tx_burst_cnt_reg[5:0], 4'b0000};
    endcase
  end  
  
always @*
  begin
    case (first_avlbe_reg[15:0])
    16'h000F, 16'h00F0, 16'h0F00, 16'hF000 : adjusted_rd_byte_count = 4;        
    16'hFFF0, 16'h0FFF                     : adjusted_rd_byte_count = {tx_burst_cnt_reg[5:1], 4'b1100}; // + 12;
    16'hFF00, 16'h0FF0, 16'h00FF           : adjusted_rd_byte_count = {tx_burst_cnt_reg[5:1], 4'b1000}; // + 8;
//    16'hF000                               : adjusted_rd_byte_count = {tx_burst_cnt_reg[5:1], 4'b0100}; // + 4;        
    default                                : adjusted_rd_byte_count = {tx_burst_cnt_reg[5:0], 4'b0000};
    endcase
  end    
  
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      sm_idle_reg <= 1'b0;
    else 
      sm_idle_reg <= sm_idle;
  end  
  
  
  
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      remain_rdbytecnt_reg <= 10'h0;
    else if(sm_idle_reg )
      remain_rdbytecnt_reg <= adjusted_rd_byte_count;
    else if(sm_rdheader)
      remain_rdbytecnt_reg <= remain_rdbytecnt_reg - rd_size;
  end
  
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      unadjusted_remain_rdbytecnt_reg <= 10'h0;
    else if(sm_idle_reg )
      unadjusted_remain_rdbytecnt_reg <= rd_byte_count;
    else if(sm_rdheader)
      unadjusted_remain_rdbytecnt_reg <= unadjusted_remain_rdbytecnt_reg - rd_size;
  end

  // bytes to 4KB boundary
  assign bytes_to_4KB = 13'h1000 - rd_addr_reg[11:0];
  assign unadjusted_bytes_to_4KB = 13'h1000 - {rd_addr_reg[11:4], 4'h0};
  
  // pipeline for fmax
  always @(posedge AvlClk_i or negedge Rstn_i)
    begin
      if(~Rstn_i)
       begin
        bytes_to_4KB_reg <= 12'h0;
        unadjusted_bytes_to_4KB_reg <= 12'h0;
       end
      else 
       begin
        bytes_to_4KB_reg <= bytes_to_4KB;
        unadjusted_bytes_to_4KB_reg <= unadjusted_bytes_to_4KB;
       end
    end 
  
  
  // decode the mux select between remain bytes, bytes to 4KB, or max read size
  assign to_4KB_sel = (max_rd_size >= bytes_to_4KB) & (remain_rdbytecnt_reg > bytes_to_4KB);
  assign  remain_bytes_sel = (remain_rdbytecnt_reg <= max_rd_size) & (remain_rdbytecnt_reg <= bytes_to_4KB);
  
  
  assign rdsize_sel = {to_4KB_sel,remain_bytes_sel};
  // pipeline the select for better fmax
  always @(posedge AvlClk_i or negedge Rstn_i)
    begin
      if(~Rstn_i)
        rdsize_sel_reg <= 2'b00;
      else 
        rdsize_sel_reg <= {to_4KB_sel,remain_bytes_sel};
    end
    
  // mux logic
  always @(rdsize_sel_reg, remain_rdbytecnt_reg, bytes_to_4KB_reg, max_rd_size)
    begin
      case(rdsize_sel_reg)
        2'b01 : rd_size = remain_rdbytecnt_reg;
        2'b10 : rd_size = bytes_to_4KB_reg;
        default : rd_size = max_rd_size;
      endcase
    end

  always @*
    begin
      case(rdsize_sel_reg)
        2'b01 : unadjusted_rd_size = unadjusted_remain_rdbytecnt_reg;
        2'b10 : unadjusted_rd_size = unadjusted_bytes_to_4KB_reg;
        default : unadjusted_rd_size = max_rd_size;
      endcase
    end


                        
assign one_dw =        ((first_avlbe_reg == 16'h000F |
                        first_avlbe_reg == 16'h00F0 |
                        first_avlbe_reg == 16'h0F00 | 
                        first_avlbe_reg == 16'hF000 ) & (tx_single_qw_reg)) |
                        
                        ((last_avlbe_reg == 16'h000F |
                        last_avlbe_reg == 16'h00F0 |
                        last_avlbe_reg == 16'h0F00 | 
                        last_avlbe_reg == 16'hF000 ) & (dw_size_reg == 4)) ; 
    
    
assign rd_dw_len[8:0] = {1'b0, unadjusted_rd_size[9:2]};
 
  assign last_rd_segment = (rdsize_sel == 2'b01);


/// tag generation counter
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      tag_cntr <= 4'b000;
    else if(sm_rdheader)  // config / IO writes and all reads
      tag_cntr <= tag_cntr + 1;
  end  
  

/// calculate byte enable

assign wr_bytes_to_4KB = 13'h1000 - wr_addr_reg[11:0];
assign wr_bytes_to_4KB_lte_16 = (wr_bytes_to_4KB <= 16) ;


  assign byte_eq_maxpayload = (payload_byte_cntr == max_payload_size);
  
 always @*
  begin
    case(first_avlbe_reg[15:0])
      16'h000F    : adjusted_dw_non_burst[1:0] = 2'd3;
      16'h00F0    : adjusted_dw_non_burst[1:0] = 2'd3;
      16'h0F00    : adjusted_dw_non_burst[1:0] = 2'd3;
      16'hF000    : adjusted_dw_non_burst[1:0] = 2'd3;
      16'h00FF    : adjusted_dw_non_burst[1:0] = 2'd2;
      16'h0FFF    : adjusted_dw_non_burst[1:0] = 2'd1;
      16'hFFFF    : adjusted_dw_non_burst[1:0] = 2'd0;
      16'h0FF0    : adjusted_dw_non_burst[1:0] = 2'd2;
      16'hFFF0    : adjusted_dw_non_burst[1:0] = 2'd1;
      16'hFF00    : adjusted_dw_non_burst[1:0] = 2'd2;
      default     : adjusted_dw_non_burst[1:0] = 2'd0;
    endcase
  end
  
  
always @*
  begin
    case({last_avlbe_reg[15:0], first_avlbe_reg[15:0]})                              
      32'h000F_FFFF    : adjusted_dw_burst[3:0] = 4'd3;       
      32'h00FF_FFFF    : adjusted_dw_burst[3:0] = 4'd2;
      32'h0FFF_FFFF    : adjusted_dw_burst[3:0] = 4'd1;
      
      32'h000F_FFF0    : adjusted_dw_burst[3:0] = 4'd4;       
      32'h00FF_FFF0    : adjusted_dw_burst[3:0] = 4'd3;
      32'h0FFF_FFF0    : adjusted_dw_burst[3:0] = 4'd2;
      32'hFFFF_FFF0    : adjusted_dw_burst[3:0] = 4'd1;
                                     
      32'h000F_FF00    : adjusted_dw_burst[3:0] = 4'd5; 
      32'h00FF_FF00    : adjusted_dw_burst[3:0] = 4'd4;                                      
      32'h0FFF_FF00    : adjusted_dw_burst[3:0] = 4'd3;       
      32'hFFFF_FF00    : adjusted_dw_burst[3:0] = 4'd2;  
      
      32'h000F_F000    : adjusted_dw_burst[3:0] = 4'd6; 
      32'h00FF_F000    : adjusted_dw_burst[3:0] = 4'd5;                                      
      32'h0FFF_F000    : adjusted_dw_burst[3:0] = 4'd4;       
      32'hFFFF_F000    : adjusted_dw_burst[3:0] = 4'd3;
         
      default          : adjusted_dw_burst[3:0] = 4'd0;                                   
    endcase                                                                          
end

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      adjusted_dw_reg <= 0;
   // else if ((sm_wr_pipe | sm_wait_rdaddr) & dw_size == 4)
     else if (((sm_wr_pipe | sm_wait_rdaddr) & tx_single_qw_reg) | (sm_wr_pipe & wr_bytes_to_4KB_lte_16 & wr_addr_counter[11:0] == 0 & ~wr_split_pending)) // burst count =1 or cross boundary and less than or equal 4dw
      adjusted_dw_reg <= adjusted_dw_non_burst;
    else
      adjusted_dw_reg <= adjusted_dw_burst;
  end 

  
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      first_avlbe_reg <= 16'h0;                  
    else if(sm_wrheader)       // after crossing MAX payload or 4KB
      first_avlbe_reg <= 16'hFFFF;
    else if(sm_idle | (TxChipSelect_i & TxRead_i & sm_idle))  // latch byte enable when transfering the first data word
      first_avlbe_reg <= TxByteEnable_i[15:0];
  end 
  
always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      last_avlbe_reg <= 8'hFF;
    else if(sm_burst_data | TxChipSelect_i & TxRead_i & sm_idle)  /// keep latching last byte enable until the last data transfer of a segment 
      last_avlbe_reg <= TxByteEnable_i[15:0];
  end   
  

always @*
  begin
    case(first_avlbe_reg[15:0])
      16'h000F    : fbe_nibble_sel[3:0] = 4'b0001;
      16'h00F0    : fbe_nibble_sel[3:0] = 4'b0010;
      16'h0F00    : fbe_nibble_sel[3:0] = 4'b0100;
      16'hF000    : fbe_nibble_sel[3:0] = 4'b1000;
      16'h00FF    : fbe_nibble_sel[3:0] = 4'b0001;
      16'h0FFF    : fbe_nibble_sel[3:0] = 4'b0101;
      16'hFFFF    : fbe_nibble_sel[3:0] = 4'b1001;
      16'h0FF0    : fbe_nibble_sel[3:0] = 4'b0100;
      16'hFFF0    : fbe_nibble_sel[3:0] = 4'b0010;
      16'hFF00    : fbe_nibble_sel[3:0] = 4'b0100;
      default     : fbe_nibble_sel[3:0] = 4'b0001;
    endcase
  end

always @*
  begin
    case(last_avlbe_reg[15:0])
      16'h00FF    : lbe_nibble_sel[3:0] = 4'b0010;
      16'h0FFF    : lbe_nibble_sel[3:0] = 4'b0100;
      16'hFFFF    : lbe_nibble_sel[3:0] = 4'b1000;
      16'h0FF0    : lbe_nibble_sel[3:0] = 4'b0100;
      16'hFFF0    : lbe_nibble_sel[3:0] = 4'b1000;
      16'hFF00    : lbe_nibble_sel[3:0] = 4'b1000;
      default     : lbe_nibble_sel[3:0] = 4'b0001;  
    endcase
  end
  

always @*
  begin
     case({fbe_nibble_sel[3:0]})  // first BE
       4'b0010 : fbe[3:0] = first_avlbe_reg[7:4];
       4'b0100 : fbe[3:0] = first_avlbe_reg[11:8];
       4'b1000 : fbe[3:0] = first_avlbe_reg[15:12];
       default : fbe[3:0] = first_avlbe_reg[3:0];
     endcase
  end    



always @*
  begin
     case({one_dw, lbe_nibble_sel[3:0]})  // Last BE
       5'b0_0001 : lbe[3:0] = last_avlbe_reg[3:0]; 
       5'b0_0010 : lbe[3:0] = last_avlbe_reg[7:4];
       5'b0_0100 : lbe[3:0] = last_avlbe_reg[11:8];
       5'b0_1000 : lbe[3:0] = last_avlbe_reg[15:12];
       default   : lbe[3:0] = 4'b0000;
     endcase
  end    





 /// command fifo interface
    assign CmdFifoWrReq_o = sm_wrheader | sm_rdheader | sm_msi;
 // write header format
   // config write (always 32-bit in length)
      // if the first dw is not enable, then the second dw is
      always @*
         begin
           case (first_avlbe_reg[15:0])
             16'h00F0, 16'hFFF0, 16'h0FF0           : addr_lsb[3:0] = 4'h4;
             16'h0F00, 16'hFF00                     : addr_lsb[3:0] = 4'h8;
             16'hF000                               : addr_lsb[3:0] = 4'hC;
             default                                : addr_lsb[3:0] = 4'h0;
           endcase
         end  
      
                            
      assign wr_dw_len    = payload_byte_cntr[10:2];  
      assign dw_size[8:0] = (sm_rdheader | sm_wait_rdaddr)? rd_dw_len[8:0] : wr_dw_len[8:0];      

      assign is_rd32 =  sm_rdheader & (~address_space_reg[0] | pcie_address[63:32] == 32'h0);
      assign is_rd64 =  sm_rdheader & (address_space_reg[0] & pcie_address[63:32] != 32'h0);
      
      
      assign is_wr32 =  (sm_wrheader & (~address_space_reg[0] | pcie_address[63:32] == 32'h0)) | (sm_msi & MsiAddr_i[63:32] == 32'h0) ;
      assign is_wr64 =  (sm_wrheader & (address_space_reg[0] & pcie_address[63:32] != 32'h0)) |  (sm_msi & MsiAddr_i[63:32] != 32'h0);
      
      assign tlp_len[8:0] = ({dw_size[8:2], 2'b00} - adjusted_dw_reg);

    assign TxReqHeader_o[98:0] = { last_sub_read ,lbe[3:0], tlp_len[8:0] ,3'b000, sm_msi, 3'b000, tag_cntr[3:0], fbe[3:0], 2'b00, is_wr64, is_wr32, is_rd64, is_rd32, pcie_address[63:32], pcie_address[31:0] };
    

always @(posedge AvlClk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      addr_trans_done_reg <= 1'b0;
    else
      addr_trans_done_reg <= trans_ready;
  end

assign addr_trans_done_rise = ~addr_trans_done_reg & trans_ready;

 // latch the translated address
 always @(posedge AvlClk_i or negedge Rstn_i) 
  begin
    if(~Rstn_i)
       begin
          translated_address_upper_reg[63:CB_A2P_ADDR_MAP_PASS_THRU_BITS] <= 0;
          address_space_reg[1:0] <= 2'b00;
       end
    else if(addr_trans_done_rise)
       begin    
          translated_address_upper_reg[63:CB_A2P_ADDR_MAP_PASS_THRU_BITS] <= pci_exp_address[63:CB_A2P_ADDR_MAP_PASS_THRU_BITS];
          address_space_reg[1:0] <= pcie_address_space[1:0];
      end
 end
 
 always @(posedge AvlClk_i or negedge Rstn_i)  
  begin
    if(~Rstn_i)
          translated_address_cntr[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0] <= 0;
    else if(addr_trans_done_rise)
          translated_address_cntr[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0] <= {pci_exp_address[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:4], addr_lsb[3:0]};
    else if(sm_rdheader)
          translated_address_cntr[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0] <= translated_address_cntr + rd_size;
    else if (sm_wrheader)
          translated_address_cntr[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0] <= {wr_addr_counter[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:4], 4'b000}; // wraddress_cntr is 16-byte unit
  end
  
assign pcie_address[63:0] = {translated_address_upper_reg[63:CB_A2P_ADDR_MAP_PASS_THRU_BITS], translated_address_cntr[CB_A2P_ADDR_MAP_PASS_THRU_BITS-1:0]};

assign CmdFifoBusy_o = sm_burst_data | sm_wait_rdaddr | sm_wr_pipe | sm_wr_hold | sm_wait_wraddr | sm_wrheader | rxm_irq_sreg; //  indicate busy one clock before accessing it

// Logic to keep track of the numbers of outstanding reads

always @(posedge AvlClk_i or negedge Rstn_i)  // state machine registers
  begin
    if(~Rstn_i)
      pendingrd_state <= TX_PNDGRD_IDLE;
    else
      pendingrd_state <= pendingrd_nxt_state;
  end


always @ *
  begin
    case(pendingrd_state)
      TX_PNDGRD_IDLE :
        if(~pendingrd_fifo_rdempty)     
          pendingrd_nxt_state <= TX_PNDGRD_LATCH;            
        else
          pendingrd_nxt_state <= TX_PNDGRD_IDLE;    
                  
      TX_PNDGRD_LATCH:
          pendingrd_nxt_state <= TX_PNDGRD_CHECK;
          
      TX_PNDGRD_CHECK:
          if((read_valid_counter == pendingrd_fifo_q_reg) & pendingrd_fifo_rdempty)
            pendingrd_nxt_state <= TX_PNDGRD_IDLE;
          else if((read_valid_counter == pendingrd_fifo_q_reg) & ~pendingrd_fifo_rdempty)
            pendingrd_nxt_state <= TX_PNDGRD_LATCH;
          else
            pendingrd_nxt_state <= TX_PNDGRD_CHECK;
            
     default :
         pendingrd_nxt_state <= TXAVL_IDLE;
         
    endcase
 end



assign pendingrd_fifo_wrreq = (sm_idle & TxChipSelect_i & TxRead_i & ~TxWaitRequest_o & reads_cntr < 16 & ~rxm_irq_sreg & ~trans_ready); // no read accepted when IRQ pending
assign pendingrd_fifo_rdreq = (!pendingrd_state[0] & !pendingrd_fifo_rdempty) | (pendingrd_check_state & ~pendingrd_fifo_rdempty & (read_valid_counter == pendingrd_fifo_q_reg));
assign pendingrd_check_state = pendingrd_state[2];
assign pendingrd_fifo_latch  = pendingrd_state[1];

	scfifo	pendingrd_fifo (                                          
				.rdreq (pendingrd_fifo_rdreq),               
				.clock (AvlClk_i),                          
				.wrreq (pendingrd_fifo_wrreq),               
				.data ({4'b0000, TxBurstCount_i[5:0]}),               
				.usedw (),             
				.empty (pendingrd_fifo_rdempty),             
				.q (pendingrd_fifo_q),                 
				.full ()   ,                              
				.aclr (~Rstn_i),                         
				.almost_empty (),                        
				.almost_full (),                         
				.sclr ()                                 
				);                                       
	defparam                                                         
		pendingrd_fifo.add_ram_output_register = "ON",            
		pendingrd_fifo.intended_device_family = "Stratix IV",     
		pendingrd_fifo.lpm_numwords = 16,                         
		pendingrd_fifo.lpm_showahead = "OFF",                     
		pendingrd_fifo.lpm_type = "scfifo",                       
		pendingrd_fifo.lpm_width = 10,                            
		pendingrd_fifo.lpm_widthu = 4,                            
		pendingrd_fifo.overflow_checking = "ON",                  
		pendingrd_fifo.underflow_checking = "ON",                 
		pendingrd_fifo.use_eab = "ON";         

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      read_valid_counter <= 10'h0;
    else if(pendingrd_fifo_rdreq)
      read_valid_counter <= 10'h0;
    else if(TxsReadDataValid_i)
       read_valid_counter <= read_valid_counter + 1;
  end


always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      pendingrd_fifo_q_reg <= 10'h3FF;
    else if(pendingrd_fifo_latch)
      pendingrd_fifo_q_reg <= pendingrd_fifo_q;
  end

assign reads_up       = (sm_idle & TxChipSelect_i & TxRead_i &  ~TxWaitRequest_o & reads_cntr < 16 & ~rxm_irq_sreg & ~trans_ready); // no read accepted when IRQ pending
assign terminal_count = (read_valid_counter == pendingrd_fifo_q_reg);

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      terminal_count_reg <= 1'b0;
    else
       terminal_count_reg <= terminal_count;
  end


assign reads_down = !terminal_count_reg & terminal_count; // rise edge

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
      reads_cntr <= 5'h0;
    else if(reads_up & ~reads_down)
      reads_cntr <= reads_cntr + 1'b1;
    else if(reads_down & ~reads_up)
       reads_cntr <= reads_cntr - 1'b1;
  end

// MSI insertion to the command FIFO when the Rxm Irq is asserted
// this mechanism is to maintain the "write" ordering between MSI and upstream writes


generate
  genvar i;
     for(i=0; i<CG_RXM_IRQ_NUM; i=i+1)
        begin: irq_gen
              assign generate_irq[i] = (RxmIrq_i[i] & PCIeIrqEna_i[i]);
        end
endgenerate

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
       rxm_irq_reg <= 1'b0;
   else 
       rxm_irq_reg <= |generate_irq;
  end
  
assign rxm_irq_rise = |generate_irq & ~rxm_irq_reg;


wire   rxm_irq_set;
assign rxm_irq_set  =( rxm_irq_rise| 
                     (A2PMbWrReq_i & A2PMbWrAddr_i[2:0] == 3'b000 & PCIeIrqEna_i[16])|
                     (A2PMbWrReq_i & A2PMbWrAddr_i[2:0] == 3'b001 & PCIeIrqEna_i[17])|
                     (A2PMbWrReq_i & A2PMbWrAddr_i[2:0] == 3'b010 & PCIeIrqEna_i[18])|
                     (A2PMbWrReq_i & A2PMbWrAddr_i[2:0] == 3'b011 & PCIeIrqEna_i[19])|
                     (A2PMbWrReq_i & A2PMbWrAddr_i[2:0] == 3'b100 & PCIeIrqEna_i[20])|
                     (A2PMbWrReq_i & A2PMbWrAddr_i[2:0] == 3'b101 & PCIeIrqEna_i[21])|
                     (A2PMbWrReq_i & A2PMbWrAddr_i[2:0] == 3'b110 & PCIeIrqEna_i[22])|
                     (A2PMbWrReq_i & A2PMbWrAddr_i[2:0] == 3'b111 & PCIeIrqEna_i[23])
                     ) 
                     & MsiCsr_i[0];  //  Msi go through Cmd FiFO
                      

always @(posedge AvlClk_i or negedge Rstn_i)
  begin
    if(~Rstn_i)
       rxm_irq_sreg <= 1'b0;
   else if(rxm_irq_set)
       rxm_irq_sreg <= 1'b1;
   else if(sm_msi)
       rxm_irq_sreg <= 1'b0;
  end


endmodule

