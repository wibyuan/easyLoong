if {$argc < 1} {
    puts stderr "usage: run.tcl <project.xpr> ?--plusarg-value name value|--plusarg-flag name ...?"
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
set options ""
foreach plusarg $plusargs {
    set escaped [string map [list "\\" "\\\\" "\"" "\\\""] $plusarg]
    append options " -testplusarg \"$escaped\""
}
set_property -name {xsim.simulate.xsim.more_options} \
    -value [string trim $options] -objects [get_filesets sim_1]

if {[catch {
    launch_simulation -simset sim_1 -mode behavioral
    run all
} message]} {
    puts stderr $message
    catch {close_sim}
    close_project
    exit 1
}

if {[catch {get_value -radix unsigned /tb_top/tb_status} tb_status] ||
    $tb_status ne "1"} {
    puts stderr "XSIM testbench did not pass (tb_status=$tb_status)"
    catch {close_sim}
    close_project
    exit 1
}

close_sim
close_project
exit 0
