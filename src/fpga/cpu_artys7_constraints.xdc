set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_IBUF]
# set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets seconds_ones_OBUF[0]]

set_property -dict { PACKAGE_PIN F14    IOSTANDARD LVCMOS33 } [get_ports { clk }];

set_property PACKAGE_PIN G15 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { select_hhmmss_button }];
set_property -dict { PACKAGE_PIN J16   IOSTANDARD LVCMOS33 } [get_ports { select_yymmdd_button }];
set_property -dict { PACKAGE_PIN H13   IOSTANDARD LVCMOS33 } [get_ports { select_yyyymm_button }];

set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports turbo];

set_property PACKAGE_PIN U15 [get_ports {display0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display0[0]}]
set_property PACKAGE_PIN V16 [get_ports {display0[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display0[1]}]
set_property PACKAGE_PIN P13 [get_ports {display0[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display0[2]}]
set_property PACKAGE_PIN R13 [get_ports {display0[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display0[3]}]
set_property PACKAGE_PIN V14 [get_ports {display0[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display0[4]}]
set_property PACKAGE_PIN V15 [get_ports {display0[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display0[5]}]
set_property PACKAGE_PIN U12 [get_ports {display0[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display0[6]}]

set_property PACKAGE_PIN V13 [get_ports {display1[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display1[0]}]
set_property PACKAGE_PIN T12 [get_ports {display1[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display1[1]}]
set_property PACKAGE_PIN T13 [get_ports {display1[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display1[2]}]
set_property PACKAGE_PIN R11 [get_ports {display1[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display1[3]}]
set_property PACKAGE_PIN T11 [get_ports {display1[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display1[4]}]
set_property PACKAGE_PIN U11 [get_ports {display1[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display1[5]}]

set_property PACKAGE_PIN G16 [get_ports {display2[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display2[0]}]
set_property PACKAGE_PIN K14 [get_ports {display2[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display2[1]}]
set_property PACKAGE_PIN H17 [get_ports {display2[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display2[2]}]
set_property PACKAGE_PIN H16 [get_ports {display2[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display2[3]}]
set_property PACKAGE_PIN T15 [get_ports {display2[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display2[4]}]
set_property PACKAGE_PIN R15 [get_ports {display2[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display2[5]}]
set_property PACKAGE_PIN V17 [get_ports {display2[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display2[6]}]

set_property PACKAGE_PIN R17 [get_ports {display3[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display3[0]}]
set_property PACKAGE_PIN R16 [get_ports {display3[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display3[1]}]
set_property PACKAGE_PIN T14 [get_ports {display3[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display3[2]}]
set_property PACKAGE_PIN R14 [get_ports {display3[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display3[3]}]
set_property PACKAGE_PIN L16 [get_ports {display3[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display3[4]}]
set_property PACKAGE_PIN N13 [get_ports {display3[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display3[5]}]
set_property PACKAGE_PIN L13 [get_ports {display3[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display3[6]}]

set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { display4[0] }];
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { display4[1] }];
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { display4[2] }];
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { display4[3] }];
set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { display4[4] }];
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { display4[5] }];
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { display4[6] }];

set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { display5[0] }];
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { display5[1] }];
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { display5[2] }];
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { display5[3] }];
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { display5[4] }];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { display5[5] }];
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { display5[6] }];