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

module altpciexpav_stif_cfg_status
  (
   input             CraClk_i,           // Clock for register access port
   input             CraRstn_i,          // Reset signal  
   // Broadcast Avalon signals
   input [13:0]      IcrAddress_i,       // Address 
   
   input              CfgReadReqVld_i,
   output reg [31:0]  CfgReadData_o,
   output reg         CfgReadDataVld_o,
   input  [3:0]       CfgAddr_i,
   input  [31:0]      CfgCtl_i,
   input  [4:0]       Ltssm_i,
   input  [1:0]       CurrentSpeed_i,
   input  [3:0]       LaneAct_i
   
   
   ) ;
      
reg  [31:0]             cfg_dev_ctrl;
reg  [31:0]             cfg_slot_ctrl;
reg  [31:0]             cfg_link_ctrl;
reg  [31:0]             cfg_prm_root_ctrl;
reg  [31:0]             cfg_sec_bus;
reg  [31:0]             cfg_msi_addr_iobase;
reg  [31:0]             cfg_msi_addr_iolim;
reg  [31:0]             cfg_np_base_lim;
reg  [31:0]             cfg_pr_base;
reg  [31:0]             cfg_msi_add_pr_base;
reg  [31:0]             cfg_pr_lim;
reg  [31:0]             cfg_msi_addr_prlim;
reg  [31:0]             cfg_pm_csr;
reg  [31:0]             cfg_msix_msi_csr;
reg  [31:0]             cfg_ecrc_tcvc_map;
reg  [31:0]             cfg_msi_data_busdev;   
 
wire [31:0]             cfg_dev_ctrl_reg;     
wire [31:0]             cfg_dev_ctrl2_reg;    
wire [31:0]             cfg_link_ctrl_reg;    
wire [31:0]             cfg_link_ctrl2_reg;   
wire [31:0]             cfg_prm_cmd_reg;      
wire [31:0]             cfg_root_ctrl_reg;    
wire [31:0]             cfg_sec_ctrl_reg;     
wire [31:0]             cfg_secbus_reg;       
wire [31:0]             cfg_subbus_reg;       
wire [31:0]             cfg_msi_addr_low_reg; 
wire [31:0]             cfg_msi_addr_hi_reg;  
wire [31:0]             cfg_io_bas_reg;       
wire [31:0]             cfg_io_lim_reg;       
wire [31:0]             cfg_np_bas_reg;       
wire [31:0]             cfg_np_lim_reg;       
wire [31:0]             cfg_pr_bas_low_reg;   
wire [31:0]             cfg_pr_bas_hi_reg;    
wire [31:0]             cfg_pr_lim_low_reg;   
wire [31:0]             cfg_pr_lim_hi_reg;    
wire [31:0]             cfg_pmcsr_reg;        
wire [31:0]             cfg_msixcsr_reg;      
wire [31:0]             cfg_msicsr_reg;       
wire [31:0]             cfg_tcvcmap_reg;      
wire [31:0]             cfg_msi_data_reg;     
wire [31:0]             cfg_busdev_reg;       
reg                     rstn_r; 
wire                    rstn_reg; 
reg                     rstn_rr;         

wire [31:0]              ltssm_reg;         
wire [31:0]              current_speed_reg; 
wire [31:0]              lane_act_reg;      
reg  [2:0]               cvp_done_reg;
wire                     out_of_cvp;
reg                      cvp_done_stat_reg;

always @(posedge CraClk_i or negedge CraRstn_i)
  begin
  	if(~CraRstn_i)
  	  begin
        rstn_r <= 1'b0; 
        rstn_rr <= 1'b0;
       end
    else
       begin
       	  rstn_r <= 1'b1;
          rstn_rr <= rstn_r;
       end
  end
 
 assign rstn_reg = rstn_rr;

/// CVP Done logic

always @(posedge CraClk_i)
       begin
          cvp_done_reg[0] <= 1'b1;
          cvp_done_reg[1] <=  cvp_done_reg[0];
          cvp_done_reg[2] <=  cvp_done_reg[1];
       end

assign out_of_cvp = ~cvp_done_reg[2] & cvp_done_reg[1];
// CVP Done status bit

always @(posedge CraClk_i or negedge CraRstn_i)
  begin
  	 if(~CraRstn_i)
          cvp_done_stat_reg  <= 1'b0;
     else if(out_of_cvp )        // rising edge of CVP done
          cvp_done_stat_reg <= 1'b1;
     else if(IcrAddress_i[13:0] &  CfgReadReqVld_i)  // read clear
           cvp_done_stat_reg <= 1'b0;
       end



    //Configuration Demux logic 
    always @(posedge CraClk_i or negedge rstn_reg) 
     begin
        if (rstn_reg == 0)
          begin
             cfg_dev_ctrl <= 32'h0;
             cfg_slot_ctrl <= 32'h0;
             cfg_link_ctrl <= 32'h0;
             cfg_prm_root_ctrl <= 32'h0;
             cfg_sec_bus <= 32'h0;
             cfg_msi_addr_iobase <= 32'h0;
             cfg_msi_addr_iolim <= 32'h0;
             cfg_np_base_lim <= 32'h0;
             cfg_pr_base <= 32'h0;
             cfg_msi_add_pr_base <= 32'h0;
             cfg_pr_lim <= 32'h0;
             cfg_msi_addr_prlim <= 32'h0;
             cfg_pm_csr <= 32'h0;
             cfg_msix_msi_csr <= 32'h0;
             cfg_ecrc_tcvc_map <= 32'h0;
             cfg_msi_data_busdev <= 32'h0;
          end
        else
          begin  /// dump the table
             cfg_dev_ctrl           <= (CfgAddr_i[3:0] == 4'h0) ? CfgCtl_i[31 : 0]  : cfg_dev_ctrl;
             cfg_slot_ctrl          <= (CfgAddr_i[3:0] == 4'h1) ? CfgCtl_i[31 : 0]  : cfg_slot_ctrl;
             cfg_link_ctrl          <= (CfgAddr_i[3:0] == 4'h2) ? CfgCtl_i[31 : 0]  : cfg_link_ctrl;
             cfg_prm_root_ctrl      <= (CfgAddr_i[3:0] == 4'h3) ? CfgCtl_i[31 : 0]  : cfg_prm_root_ctrl;
             cfg_sec_bus            <= (CfgAddr_i[3:0] == 4'h4) ? CfgCtl_i[31 : 0]  : cfg_sec_bus;
             cfg_msi_addr_iobase    <= (CfgAddr_i[3:0] == 4'h5) ? CfgCtl_i[31 : 0]  : cfg_msi_addr_iobase;
             cfg_msi_addr_iolim     <= (CfgAddr_i[3:0] == 4'h6) ? CfgCtl_i[31 : 0]  : cfg_msi_addr_iolim;
             cfg_np_base_lim        <= (CfgAddr_i[3:0] == 4'h7) ? CfgCtl_i[31 : 0]  : cfg_np_base_lim;
             cfg_pr_base            <= (CfgAddr_i[3:0] == 4'h8) ? CfgCtl_i[31 : 0]  : cfg_pr_base;
             cfg_msi_add_pr_base    <= (CfgAddr_i[3:0] == 4'h9) ? CfgCtl_i[31 : 0]  : cfg_msi_add_pr_base;
             cfg_pr_lim             <= (CfgAddr_i[3:0] == 4'hA) ? CfgCtl_i[31 : 0]  : cfg_pr_lim;
             cfg_msi_addr_prlim     <= (CfgAddr_i[3:0] == 4'hB) ? CfgCtl_i[31 : 0]  : cfg_msi_addr_prlim;
             cfg_pm_csr             <= (CfgAddr_i[3:0] == 4'hC) ? CfgCtl_i[31 : 0]  : cfg_pm_csr;
             cfg_msix_msi_csr       <= (CfgAddr_i[3:0] == 4'hD) ? CfgCtl_i[31 : 0]  : cfg_msix_msi_csr;
             cfg_ecrc_tcvc_map      <= (CfgAddr_i[3:0] == 4'hE) ? CfgCtl_i[31 : 0]  : cfg_ecrc_tcvc_map;
             cfg_msi_data_busdev    <= (CfgAddr_i[3:0] == 4'hF) ? CfgCtl_i[31 : 0]  : cfg_msi_data_busdev;
          end
     end          
 
/// Remap the table
    assign cfg_dev_ctrl_reg          = {16'h0, cfg_dev_ctrl[31:16]};
    assign cfg_dev_ctrl2_reg         = {16'h0, cfg_slot_ctrl[15:0]};
    assign cfg_link_ctrl_reg         = {16'h0, cfg_link_ctrl[31:16]};
    assign cfg_link_ctrl2_reg        = {16'h0, cfg_link_ctrl[15:0]};  
    assign cfg_prm_cmd_reg           = {16'h0, cfg_prm_root_ctrl[23:8]};
    assign cfg_root_ctrl_reg         = {24'h0, cfg_prm_root_ctrl[7:0]};
    assign cfg_sec_ctrl_reg          = {16'h0, cfg_sec_bus[31:16]};
    assign cfg_secbus_reg            = {24'h0, cfg_sec_ctrl_reg[23:8]};
    assign cfg_subbus_reg            = {24'h0, cfg_sec_ctrl_reg[7:0]};
    assign cfg_msi_addr_low_reg      = {cfg_msi_add_pr_base[31:12], cfg_msi_addr_iobase[31:20]}; 
    assign cfg_msi_addr_hi_reg       = {cfg_msi_addr_prlim[31:12] ,cfg_msi_addr_iolim[31:20]};
    assign cfg_io_bas_reg            = {12'h0, cfg_msi_addr_iobase[19:0]};
    assign cfg_io_lim_reg            = {12'h0, cfg_msi_addr_iolim[19:0]};
    assign cfg_np_bas_reg            =  {20'h0, cfg_np_base_lim[23:12]};
    assign cfg_np_lim_reg            =  {20'h0, cfg_np_base_lim[11:0]};  
    assign cfg_pr_bas_low_reg        =  cfg_pr_base;
    assign cfg_pr_bas_hi_reg         =  {20'h0, cfg_msi_add_pr_base[11:0]};
    assign cfg_pr_lim_low_reg        =  cfg_pr_lim;
    assign cfg_pr_lim_hi_reg         =  {20'h0, cfg_msi_addr_prlim[11:0]};
    assign cfg_pmcsr_reg             = cfg_pm_csr ;     
    assign cfg_msixcsr_reg           = {16'h0, cfg_msix_msi_csr[31:16]};
    assign cfg_msicsr_reg            = {16'h0, cfg_msix_msi_csr[15:0]};  
    assign cfg_tcvcmap_reg           = {8'h0, cfg_ecrc_tcvc_map[23:0]};
    assign cfg_msi_data_reg          = {16'h0, cfg_msi_data_busdev[31:16]};
    assign cfg_busdev_reg            = {19'h0, cfg_msi_data_busdev[12:0]};      
    assign ltssm_reg                 = {27'h0, Ltssm_i};
    assign current_speed_reg         = {30'h0, CurrentSpeed_i};
    assign lane_act_reg              = {28'h0, LaneAct_i};
    
     
always @*                     
  begin               
    case(IcrAddress_i[13:0])
       14'h3C00 :  CfgReadData_o =  cfg_dev_ctrl_reg     ;
       14'h3C04 :  CfgReadData_o =  cfg_dev_ctrl2_reg    ;
       14'h3C08 :  CfgReadData_o =  cfg_link_ctrl_reg    ;
       14'h3C0C :  CfgReadData_o =  cfg_link_ctrl2_reg   ;
       14'h3C10 :  CfgReadData_o =  cfg_prm_cmd_reg      ;   
       14'h3C14 :  CfgReadData_o =  cfg_root_ctrl_reg    ;
       14'h3C18 :  CfgReadData_o =  cfg_sec_ctrl_reg     ;
       14'h3C1C :  CfgReadData_o =  cfg_secbus_reg       ;
       14'h3C20 :  CfgReadData_o =  cfg_subbus_reg       ;
       14'h3C24 :  CfgReadData_o =  cfg_msi_addr_low_reg ;
       14'h3C28 :  CfgReadData_o =  cfg_msi_addr_hi_reg  ;
       14'h3C2C :  CfgReadData_o =  cfg_io_bas_reg       ;
       14'h3C30 :  CfgReadData_o =  cfg_io_lim_reg       ;
       14'h3C34 :  CfgReadData_o =  cfg_np_bas_reg       ;
       14'h3C38 :  CfgReadData_o =  cfg_np_lim_reg       ;
       14'h3C3C :  CfgReadData_o =  cfg_pr_bas_low_reg   ;
       14'h3C40 :  CfgReadData_o =  cfg_pr_bas_hi_reg    ;
       14'h3C44 :  CfgReadData_o =  cfg_pr_lim_low_reg   ;
       14'h3C48 :  CfgReadData_o =  cfg_pr_lim_hi_reg    ;
       14'h3C4C :  CfgReadData_o =  cfg_pmcsr_reg        ;
       14'h3C50 :  CfgReadData_o =  cfg_msixcsr_reg      ;           
       14'h3C54 :  CfgReadData_o =  cfg_msicsr_reg       ;           
       14'h3C58 :  CfgReadData_o =  cfg_tcvcmap_reg      ;           
       14'h3C5C :  CfgReadData_o =  cfg_msi_data_reg     ;           
       14'h3C60 :  CfgReadData_o =  cfg_busdev_reg       ;    
       14'h3C64 :  CfgReadData_o =  ltssm_reg            ;      
       14'h3C68 :  CfgReadData_o =  current_speed_reg    ;  
       14'h3C6C :  CfgReadData_o =  lane_act_reg         ;
       14'h3C70 :  CfgReadData_o =  {31'h0,cvp_done_stat_reg};
       default  :  CfgReadData_o =   32'h0;
    endcase       
  end    	
    
   always @(posedge CraClk_i or negedge CraRstn_i)    
     begin                                            
       if(~CraRstn_i)                                 
     	   CfgReadDataVld_o <= 1'b0;                     
     	 else                                           
     	   CfgReadDataVld_o <= CfgReadReqVld_i;           
     end                                              

endmodule 

   

