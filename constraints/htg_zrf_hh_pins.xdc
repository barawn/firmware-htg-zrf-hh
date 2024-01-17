# vp/vn need analog setting
set_property IOSTANDARD ANALOG [get_ports VP]
set_property IOSTANDARD ANALOG [get_ports VN]
# don't think clocks need iostandards? maybe?
set_property PACKAGE_PIN AF5 [get_ports ADC0_CLK_P]
set_property PACKAGE_PIN AF4 [get_ports ADC0_CLK_N]
# maybe these don't even need anything?
set_property -dict { PACKAGE_PIN AP2 } [get_ports ADC0_VIN_P]
set_property -dict { PACKAGE_PIN AP1 } [get_ports ADC0_VIN_N]
# does sysref need a constraint?

# REFCLK/SYSREF are SWAPPED compared to the HTG-ZRF-HH schematic/pin list because they are idiots
# AT7/AT6 go to HD pins, so they're very difficult to use as a clock source. SYSREF is a low-frequency
# capture so there's no reason you can't just splat it into an HD path.
set_property -dict { IOSTANDARD LVDS_25 PACKAGE_PIN AT7 } [get_ports SYSREF_FPGA_P]
set_property -dict { IOSTANDARD LVDS_25 PACKAGE_PIN AT6 } [get_ports SYSREF_FPGA_N]

set_property -dict { IOSTANDARD LVDS DIFF_TERM TRUE PACKAGE_PIN AL16 } [get_ports FPGA_REFCLK_IN_P]
set_property -dict { IOSTANDARD LVDS DIFF_TERM TRUE PACKAGE_PIN AL15 } [get_ports FPGA_REFCLK_IN_N]

set_property -dict { IOSTANDARD LVCMOS33 PACKAGE_PIN A9 } [get_ports {PL_USER_LED[0]}]
set_property -dict { IOSTANDARD LVCMOS33 PACKAGE_PIN B8 } [get_ports {PL_USER_LED[1]}]
