if {$argc < 1} {
    puts stderr "usage: run_post_impl.tcl <project.xpr> ?--plusarg-value name value|--plusarg-flag name ...?"
    exit 2
}

set project_file [file normalize [lindex $argv 0]]
set encoded_args [lrange $argv 1 end]
set plusargs [list]
set index 0
while {$index < [llength $encoded_args]} {
    set kind [lindex $encoded_args $index]
    incr index
    if {$kind eq "--plusarg-value"} {
        if {$index + 1 >= [llength $encoded_args]} {
            puts stderr "incomplete --plusarg-value"
            exit 2
        }
        set name [lindex $encoded_args $index]
        set value [lindex $encoded_args [expr {$index + 1}]]
        incr index 2
        lappend plusargs "$name=$value"
    } elseif {$kind eq "--plusarg-flag"} {
        if {$index >= [llength $encoded_args]} {
            puts stderr "incomplete --plusarg-flag"
            exit 2
        }
        lappend plusargs [lindex $encoded_args $index]
        incr index
    } else {
        puts stderr "unknown encoded argument: $kind"
        exit 2
    }
}

if {![file exists $project_file]} {
    puts stderr "Vivado project not found: $project_file"
    exit 2
}

open_project $project_file

# Ensure the post-implementation testbench is in the project fileset
set tb_path [file normalize ../sim/mycpu_tb_post_impl.v]
if {[catch {set current [get_files -of_objects [get_filesets sim_1] $tb_path]}] ||
    [llength $current] == 0} {
    add_files -fileset sim_1 $tb_path -quiet
    update_compile_order -fileset sim_1
}

# Switch to the post-implementation testbench (no XMR cross-module refs)
set_property -name "top" -value "tb_top_post_impl" -objects [get_filesets sim_1]

set options ""
foreach plusarg $plusargs {
    set escaped [string map [list "\\" "\\\\" "\"" "\\\""] $plusarg]
    append options " -testplusarg \"$escaped\""
}
set_property -name {xsim.simulate.xsim.more_options} \
    -value [string trim $options] -objects [get_filesets sim_1]

if {[catch {
    launch_simulation -simset sim_1 -mode post-implementation -type timing
    run all
} message]} {
    puts stderr $message
    catch {close_sim}
    close_project
    exit 1
}

if {[catch {get_value -radix unsigned /tb_top_post_impl/tb_status} tb_status] ||
    $tb_status ne "1"} {
    puts stderr "XSIM testbench did not pass (tb_status=$tb_status)"
    catch {close_sim}
    close_project
    exit 1
}

close_sim
close_project
exit 0
