set project_file [file normalize ./project/Loongson_Soc.xpr]

if {![file exists $project_file]} {
    puts stderr "Vivado project not found: $project_file"
    puts stderr "Run: vivado -mode batch -source create_project.tcl"
    exit 2
}

open_project $project_file
update_compile_order -fileset sources_1

proc require_run_complete {run_name phase} {
    set run [get_runs $run_name]
    set progress [get_property PROGRESS $run]
    set status [get_property STATUS $run]
    if {$progress ne "100%" || ![string match "*Complete*" $status]} {
        puts stderr "$phase failed: $status (progress $progress)"
        close_project
        exit 1
    }
}

reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
require_run_complete synth_1 Synthesis

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
require_run_complete impl_1 Implementation

set bit_files [glob -nocomplain ./project/Loongson_Soc.runs/impl_1/*.bit]
if {[llength $bit_files] == 0} {
    puts stderr "Implementation completed without a bitstream"
    close_project
    exit 1
}
foreach bit_file $bit_files {
    puts "BITSTREAM: [file normalize $bit_file]"
}

close_project
exit 0
