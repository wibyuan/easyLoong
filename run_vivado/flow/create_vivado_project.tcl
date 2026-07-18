cd [file normalize [file join [file dirname [info script]] ..]]

# Project settings
set  project_name thinpad_top
set  project_path ./project
set  project_part xc7a200tfbg676-2

# Recreate project
file delete -force $project_path

create_project -force $project_name $project_path -part $project_part

# Add RTL sources
add_files -scan_for_includes [glob -nocomplain ../src/soc]

# Add IPs
set ip_files [concat \
    [glob -nocomplain ../src/soc/xilinx_ip/*/*.xci] \
    [glob -nocomplain ../src/soc/xilinx_ip/*/*.xcix]]
if {[llength $ip_files] > 0} {
    add_files -quiet $ip_files
}

# Add simulation files
#add_files -fileset sim_1 ./simulation

# Add constraints
add_files -fileset constrs_1 -quiet ./constraints

# Upgrade IPs
set ips [get_ips -quiet]
if {[llength $ips] > 0} {
    upgrade_ip -quiet $ips
}

set_property top thinpad_top [current_fileset]
# set_property -name "top" -value "tb_top" -objects  [get_filesets sim_1]
# set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
# set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
# set_property strategy Performance_Explore [get_runs impl_1]
# set_property -name "top" -value "tb_top" -objects  [get_filesets sim_1]
# set_property -name "xsim.simulate.log_all_signals" -value "1" -objects [get_filesets sim_1]

update_compile_order -fileset sources_1