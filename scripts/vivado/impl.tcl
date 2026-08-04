# Implementation + timing reports for the 100MHz push.
# Run inside the Vivado docker container with the repo root mounted at
# /workspace (see scripts/vivado/run_vivado.sh).  The synth run must be
# complete (synth.tcl) first.
open_project /workspace/run_vivado/project/thinpad_top.xpr
set impl_run [get_runs impl_1]
reset_run $impl_run
launch_runs $impl_run -jobs 8
wait_on_run $impl_run
set progress [get_property PROGRESS $impl_run]
set status [get_property STATUS $impl_run]
puts "IMPL_DONE progress=$progress status=$status"
if {$progress ne "100%"} {
    close_project
    exit 1
}
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained -file /workspace/run_vivado/project/impl_timing_summary.rpt
report_timing -max_paths 20 -nworst 10 -file /workspace/run_vivado/project/impl_critical_paths.rpt
report_utilization -file /workspace/run_vivado/project/impl_utilization.rpt
close_project
exit 0
