# Synthesis + utilization + timing reports for the 100MHz push.
# Run inside the Vivado docker container with the repo root mounted at
# /workspace (see scripts/vivado/run_vivado.sh).
open_project /workspace/run_vivado/project/thinpad_top.xpr
set synth_run [get_runs synth_1]
reset_run $synth_run
launch_runs $synth_run -jobs 8
wait_on_run $synth_run
set progress [get_property PROGRESS $synth_run]
puts "SYNTH_DONE progress=$progress"
if {$progress ne "100%"} { close_project; exit 1 }
open_run synth_1
report_utilization -hierarchical -file /workspace/run_vivado/project/synth_util_hier.rpt
report_timing_summary -delay_type min_max -report_unconstrained -file /workspace/run_vivado/project/synth_timing_summary.rpt
report_timing -max_paths 20 -nworst 10 -file /workspace/run_vivado/project/synth_critical_paths.rpt
close_project
exit 0
