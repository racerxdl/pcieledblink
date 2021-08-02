	pcie2ram u0 (
		.clk_clk                 (<connected-to-clk_clk>),                 //            clk.clk
		.clk_125_clk             (<connected-to-clk_125_clk>),             //        clk_125.clk
		.hip_ctrl_test_in        (<connected-to-hip_ctrl_test_in>),        //       hip_ctrl.test_in
		.hip_ctrl_simu_mode_pipe (<connected-to-hip_ctrl_simu_mode_pipe>), //               .simu_mode_pipe
		.hip_npor_npor           (<connected-to-hip_npor_npor>),           //       hip_npor.npor
		.hip_npor_pin_perst      (<connected-to-hip_npor_pin_perst>),      //               .pin_perst
		.hip_refclk_clk          (<connected-to-hip_refclk_clk>),          //     hip_refclk.clk
		.hip_serial_rx_in0       (<connected-to-hip_serial_rx_in0>),       //     hip_serial.rx_in0
		.hip_serial_tx_out0      (<connected-to-hip_serial_tx_out0>),      //               .tx_out0
		.pcie_ram_bus_address    (<connected-to-pcie_ram_bus_address>),    //   pcie_ram_bus.address
		.pcie_ram_bus_chipselect (<connected-to-pcie_ram_bus_chipselect>), //               .chipselect
		.pcie_ram_bus_clken      (<connected-to-pcie_ram_bus_clken>),      //               .clken
		.pcie_ram_bus_write      (<connected-to-pcie_ram_bus_write>),      //               .write
		.pcie_ram_bus_readdata   (<connected-to-pcie_ram_bus_readdata>),   //               .readdata
		.pcie_ram_bus_writedata  (<connected-to-pcie_ram_bus_writedata>),  //               .writedata
		.pcie_ram_bus_byteenable (<connected-to-pcie_ram_bus_byteenable>), //               .byteenable
		.pcie_ram_clk_clk        (<connected-to-pcie_ram_clk_clk>),        //   pcie_ram_clk.clk
		.pcie_ram_reset_reset    (<connected-to-pcie_ram_reset_reset>),    // pcie_ram_reset.reset
		.reset_reset_n           (<connected-to-reset_reset_n>)            //          reset.reset_n
	);

