cd [file normalize [file join [file dirname [info script]] ..]]

# Run implementation and emit reports.
open_project project/thinpad_top.xpr

set impl_run [get_runs impl_1]
reset_run $impl_run

launch_runs impl_1
wait_on_run impl_1

set impl_progress [get_property PROGRESS $impl_run]
set impl_status [get_property STATUS $impl_run]
puts "impl_1 progress: $impl_progress"
puts "impl_1 status: $impl_status"

if {$impl_progress ne "100%"} {
    puts "ERROR: Implementation did not complete."
    close_project
    exit 1
}

if {[string first "ERROR" $impl_status] >= 0} {
    puts "ERROR: Implementation failed: $impl_status"
    close_project
    exit 1
}

if {[string first "Failed Timing" $impl_status] >= 0} {
    puts "WARNING: Implementation completed with timing violations. Reports will be generated before timing check fails the job."
} elseif {[string first "Failed" $impl_status] >= 0} {
    puts "ERROR: Implementation failed: $impl_status"
    close_project
    exit 1
}

open_run impl_1
report_utilization -file project/thinpad_top.runs/impl_1/utilization.rpt -pb project/thinpad_top.runs/impl_1/utilization.pb
report_timing_summary -delay_type min_max -report_unconstrained \
    -file project/thinpad_top.runs/impl_1/timing_summary.rpt

close_project
exit 0
