set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports rst]

set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports enable]

set_property -dict { PACKAGE_PIN A18  IOSTANDARD LVCMOS33 } [get_ports uart_out]

set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN V19  IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN U15  IOSTANDARD LVCMOS33 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN U14  IOSTANDARD LVCMOS33 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN V14  IOSTANDARD LVCMOS33 } [get_ports {led[7]}]

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical -filter {NAME =~ *u_ro3*}]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical -filter {NAME =~ *u_ro5*}]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical -filter {NAME =~ *u_ro*}]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical -filter {NAME =~ *u_firo*}]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical -filter {NAME =~ *raw_osc*}]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical -filter {NAME =~ *mux_raw*}]

set_false_path -through [get_nets -hierarchical -filter {NAME =~ *u_ro3*}]
set_false_path -through [get_nets -hierarchical -filter {NAME =~ *u_ro5*}]
set_false_path -through [get_nets -hierarchical -filter {NAME =~ *u_ro*}]
set_false_path -through [get_nets -hierarchical -filter {NAME =~ *u_firo*}]
set_false_path -through [get_nets -hierarchical -filter {NAME =~ *raw_osc*}]
set_false_path -through [get_nets -hierarchical -filter {NAME =~ *mux_raw*}]

set_property DONT_TOUCH TRUE [get_cells -hierarchical -filter {NAME =~ *u_ro3*}]
set_property DONT_TOUCH TRUE [get_cells -hierarchical -filter {NAME =~ *u_ro5*}]
set_property DONT_TOUCH TRUE [get_cells -hierarchical -filter {NAME =~ *u_ro*}]
set_property DONT_TOUCH TRUE [get_cells -hierarchical -filter {NAME =~ *u_firo*}]
set_property DONT_TOUCH TRUE [get_cells -hierarchical -filter {NAME =~ *u_sync*}]
set_property DONT_TOUCH TRUE [get_cells -hierarchical -filter {NAME =~ *u_dff_fb*}]
set_property DONT_TOUCH TRUE [get_cells -hierarchical -filter {NAME =~ *u_clfsr_4bit*}]
set_property DONT_TOUCH TRUE [get_cells -hierarchical -filter {NAME =~ *tff_state*}]
