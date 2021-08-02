module PCIeLedBlink (
  input   clkin, 			//	2.5V
  output  [7:0] LED, 	//	2.5V
  
  // PCI Express
  input         	pcie_rx_p, 		 //	1.5-V PCML
  output      		pcie_tx_p, 		 //	1.5-V PCML
  input           pcie_refclk_p,  //	HCSL
  input           pcie_perst      //	2.5V AB28
);

wire clk;

// self-reset w/ self-detect logic
// self-reset just start w/ a value and decrement it until zero; at same time, sample the
// default external reset value at startup, supposing that you are not pressing the button
// at the programming moment! supposed to work in *any* board!

reg [3:0] reset_counter = 15; // self-reset
reg reset  = 1; // global reset
reg extrst = 1; // external reset default value (sampled at startup)
reg rst = 1;

always@(posedge clk)
begin
    reset_counter <= reset_counter ? reset_counter-1 : // while(reset_counter--);
                     extrst!=rst ? 13 : 0; // rst != extrst -> restart counter
    reset <= reset_counter ? 1 : 0; // while not zero, reset = 1, after that use extrst
    extrst <= (reset_counter==14) ? rst : extrst; // sample the reset button and store the value when not in reset
end

reg 		[25:0] 	counter;
reg		[8:0]		onchip_memory_s2_address;
reg					onchip_memory_s2_chipselect;
reg					onchip_memory_s2_clken;
reg					onchip_memory_s2_write;
wire		[63:0]	onchip_memory_s2_readdata;
reg		[63:0]	onchip_memory_s2_writedata;
reg		[7:0]		onchip_memory_s2_byteenable;


always @(posedge clk)
begin
	if (reset)
	begin
		counter 						 		<= 0;
		onchip_memory_s2_address 		<= 0;
		onchip_memory_s2_byteenable 	<= 255;
		onchip_memory_s2_writedata		<= 0;
		onchip_memory_s2_clken			<= 1;
		onchip_memory_s2_chipselect	<= 1;
		onchip_memory_s2_write			<= 0;
	end
	else
	begin
	  counter <= counter + 1;
	end
end

assign LED = onchip_memory_s2_readdata[63] ? onchip_memory_s2_readdata[7:0] : counter[25:18];

//
// PCI Express
//
wire [31:0] pcie_test_in;
assign pcie_test_in[0] = 1'b0;
assign pcie_test_in[4:1] = 4'b1000;
assign pcie_test_in[5] = 1'b0;
assign pcie_test_in[31:6] = 26'h2;

pcie2ram mypci (
    .clk_clk                   (clkin),
    .clk_125_clk               (clk),
    .hip_ctrl_test_in          (pcie_test_in),
    .hip_ctrl_simu_mode_pipe   (),
    .hip_npor_npor             (1'b1),
    .hip_npor_pin_perst        (pcie_perst),
    .hip_refclk_clk            (pcie_refclk_p),

	 .hip_serial_rx_in0       (pcie_rx_p),
	 .hip_serial_tx_out0      (pcie_tx_p),
	 
    .pcie_ram_bus_address      (onchip_memory_s2_address),
    .pcie_ram_bus_chipselect   (onchip_memory_s2_chipselect),
    .pcie_ram_bus_clken        (onchip_memory_s2_clken),
    .pcie_ram_bus_write        (onchip_memory_s2_write),
    .pcie_ram_bus_readdata     (onchip_memory_s2_readdata),
    .pcie_ram_bus_writedata    (onchip_memory_s2_writedata),
    .pcie_ram_bus_byteenable   (onchip_memory_s2_byteenable),
    .pcie_ram_clk_clk          (clk),
    .pcie_ram_reset_reset      (1'b0),
    .reset_reset_n             (1'b1),
);

endmodule
