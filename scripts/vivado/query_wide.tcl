open_project /workspace/run_vivado/project/thinpad_top.xpr
open_run impl_1
report_timing -max_paths 400 -nworst 1 -file /workspace/run_vivado/project/wide_paths.rpt
report_timing_summary -file /workspace/run_vivado/project/wide_summary.rpt
close_project
exit
