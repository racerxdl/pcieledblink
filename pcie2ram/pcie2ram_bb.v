
module pcie2ram (
	clk_clk,
	clk_125_clk,
	hip_ctrl_test_in,
	hip_ctrl_simu_mode_pipe,
	hip_npor_npor,
	hip_npor_pin_perst,
	hip_refclk_clk,
	hip_serial_rx_in0,
	hip_serial_tx_out0,
	pcie_ram_bus_address,
	pcie_ram_bus_chipselect,
	pcie_ram_bus_clken,
	pcie_ram_bus_write,
	pcie_ram_bus_readdata,
	pcie_ram_bus_writedata,
	pcie_ram_bus_byteenable,
	pcie_ram_clk_clk,
	pcie_ram_reset_reset,
	reset_reset_n);	

	input		clk_clk;
	output		clk_125_clk;
	input	[31:0]	hip_ctrl_test_in;
	input		hip_ctrl_simu_mode_pipe;
	input		hip_npor_npor;
	input		hip_npor_pin_perst;
	input		hip_refclk_clk;
	input		hip_serial_rx_in0;
	output		hip_serial_tx_out0;
	input	[11:0]	pcie_ram_bus_address;
	input		pcie_ram_bus_chipselect;
	input		pcie_ram_bus_clken;
	input		pcie_ram_bus_write;
	output	[63:0]	pcie_ram_bus_readdata;
	input	[63:0]	pcie_ram_bus_writedata;
	input	[7:0]	pcie_ram_bus_byteenable;
	input		pcie_ram_clk_clk;
	input		pcie_ram_reset_reset;
	input		reset_reset_n;
endmodule
