# vp/vn need analog setting
set_property IOSTANDARD ANALOG [get_ports VP]
set_property IOSTANDARD ANALOG [get_ports VN]
# don't think clocks need iostandards? maybe?
set_property PACKAGE_PIN AF5 [get_ports ADC0_CLK_P]
set_property PACKAGE_PIN AF4 [get_ports ADC0_CLK_N]

set_property PACKAGE_PIN AD5 [get_ports ADC2_CLK_P]
set_property PACKAGE_PIN AD4 [get_ports ADC2_CLK_N]

set_property PACKAGE_PIN AB5 [get_ports ADC4_CLK_P]
set_property PACKAGE_PIN AB4 [get_ports ADC4_CLK_N]

set_property PACKAGE_PIN Y5 [get_ports ADC6_CLK_P]
set_property PACKAGE_PIN Y4 [get_ports ADC6_CLK_N]

set_property PACKAGE_PIN R5 [get_ports DAC0_CLK_P]
set_property PACKAGE_PIN R4 [get_ports DAC0_CLK_N]

set_property PACKAGE_PIN U2 [get_ports DAC0_VOUT_P]
set_property PACKAGE_PIN U1 [get_ports DAC0_VOUT_N]

# maybe these don't even need anything?
set_property -dict { PACKAGE_PIN AP2 } [get_ports ADC0_VIN_P]
set_property -dict { PACKAGE_PIN AP1 } [get_ports ADC0_VIN_N]
set_property -dict { PACKAGE_PIN AM2 } [get_ports ADC1_VIN_P]
set_property -dict { PACKAGE_PIN AM1 } [get_ports ADC1_VIN_N]

set_property -dict { PACKAGE_PIN AK2 } [get_ports ADC2_VIN_P]
set_property -dict { PACKAGE_PIN AK1 } [get_ports ADC2_VIN_N]
set_property -dict { PACKAGE_PIN AH2 } [get_ports ADC3_VIN_P]
set_property -dict { PACKAGE_PIN AH1 } [get_ports ADC3_VIN_N]

set_property -dict { PACKAGE_PIN AF2 } [get_ports ADC4_VIN_P]
set_property -dict { PACKAGE_PIN AF1 } [get_ports ADC4_VIN_N]
set_property -dict { PACKAGE_PIN AD2 } [get_ports ADC5_VIN_P]
set_property -dict { PACKAGE_PIN AD1 } [get_ports ADC5_VIN_N]

set_property -dict { PACKAGE_PIN AB2 } [get_ports ADC6_VIN_P]
set_property -dict { PACKAGE_PIN AB1 } [get_ports ADC6_VIN_N]
set_property -dict { PACKAGE_PIN  Y2 } [get_ports ADC7_VIN_P]
set_property -dict { PACKAGE_PIN  Y1 } [get_ports ADC7_VIN_N]

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
