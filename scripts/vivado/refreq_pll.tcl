#!/usr/bin/env tclsh
# refreq_pll.tcl — re-customize the clk_pll clocking-wizard IP at a new
# cpu_clk frequency, headlessly, inside the vivado:2019.2 docker container.
#
# Usage (inside the container):
#   vivado -mode batch -source /workspace/scripts/vivado/refreq_pll.tcl -tclargs <freq_mhz>
#
# The IP is copied into a scratch project under /tmp, the CLKOUT1 (cpu_clk,
# wizard output #1 = PLLE2 CLKOUT0) requested frequency is set to <freq_mhz>,
# CLKOUT2 (sys_clk, wizard output #2 = CLKOUT1) is pinned back to 25 MHz,
# the IP is regenerated (the wizard recomputes VCO / dividers / actual
# frequencies), and the regenerated .xci is written back over
# /workspace/src/soc/xilinx_ip/clk_pll/clk_pll.xci.
set freq [lindex $argv 0]
if {[string equal $freq ""]} {
    puts "ERROR: missing frequency argument"
    exit 1
}

set ip_dir    /workspace/src/soc/xilinx_ip/clk_pll
set scratch   /tmp/pllrefreq
set xci_src   ${ip_dir}/clk_pll.xci
set xci_gen   ${scratch}/pllrefreq.srcs/sources_1/ip/clk_pll/clk_pll.xci

file delete -force $scratch
create_project pllrefreq $scratch -part xc7a200tfbg676-2 -force
read_ip $xci_src
set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $freq [get_ips clk_pll]
set_property CONFIG.CLKOUT2_REQUESTED_OUT_FREQ 25 [get_ips clk_pll]
generate_target all [get_ips clk_pll]
close_project

file copy -force $xci_gen $xci_src
puts "REGENERATED: $xci_src"
puts "REQUESTED:   cpu_clk=$freq MHz, sys_clk=25 MHz"
