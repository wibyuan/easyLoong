cd [file normalize [file join [file dirname [info script]] ..]]

# Generate bitstream after implementation. Timing violations are reported separately.
open_project project/thinpad_top.xpr

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

set impl_run [get_runs impl_1]
set impl_progress [get_property PROGRESS $impl_run]
set impl_status [get_property STATUS $impl_run]
puts "impl_1 progress: $impl_progress"
puts "impl_1 status: $impl_status"

if {$impl_progress ne "100%"} {
    puts "ERROR: Bitstream generation did not complete."
    close_project
    exit 1
}

if {[string first "ERROR" $impl_status] >= 0} {
    puts "ERROR: Bitstream generation failed: $impl_status"
    close_project
    exit 1
}

if {[string first "Failed Timing" $impl_status] >= 0} {
    puts "WARNING: Bitstream generation completed with timing violations."
} elseif {[string first "Failed" $impl_status] >= 0} {
    puts "ERROR: Bitstream generation failed: $impl_status"
    close_project
    exit 1
}

set bit_files [glob -nocomplain project/thinpad_top.runs/impl_1/*.bit]
if {[llength $bit_files] == 0} {
    puts "ERROR: Bitstream file was not generated."
    close_project
    exit 1
}

puts "Generated bitstream files:"
foreach bit_file $bit_files {
    puts "  $bit_file"
}

close_project
exit 0
