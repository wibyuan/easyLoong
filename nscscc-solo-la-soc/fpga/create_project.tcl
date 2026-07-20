# SET PROJECT NAME
set  project_name Loongson_Soc
set  project_path ./project
set project_part xc7a200tfbg676-1
# CLEAR
file delete -force $project_path

create_project -force $project_name $project_path -part $project_part

proc collect_files {root extensions excluded_dirs} {
    set files [list]
    set root [file normalize $root]
    set excluded [list]
    foreach dir $excluded_dirs {
        lappend excluded [file normalize $dir]
    }

    foreach item [glob -nocomplain -directory $root *] {
        set item_norm [file normalize $item]
        set skip 0
        foreach dir $excluded {
            if {$item_norm eq $dir || [string match "$dir/*" $item_norm]} {
                set skip 1
                break
            }
        }
        if {$skip} {
            continue
        }

        if {[file isdirectory $item_norm]} {
            if {[file tail $item_norm] eq ".Xil"} {
                continue
            }
            set files [concat $files [collect_files $item_norm $extensions $excluded]]
        } elseif {[lsearch -exact $extensions [string tolower [file extension $item_norm]]] >= 0} {
            lappend files $item_norm
        }
    }
    return $files
}

# Add HDL sources only. The PLL directory is represented by its XCI file; its
# generated netlists and stubs must not be compiled as ordinary RTL.
set rtl_files [collect_files ../rtl [list .v .sv .vhd .vhdl] \
    [list ../rtl/ip/PLL_2019_2]]
add_files -scan_for_includes $rtl_files

# Add packaged Vivado IPs separately, including optional CPU-owned IPs.
set ip_files [collect_files ../rtl [list .xci .xcix] [list]]
if {[llength $ip_files] != 0} {
    add_files -norecurse $ip_files
}

# Add only HDL testbench sources. Scripts, scenarios, and backend-specific
# drivers under sim/ are orchestration files, not Vivado simulation sources.
set sim_files [concat \
    [glob -nocomplain ../sim/*.v] \
    [glob -nocomplain ../sim/*.sv]]
add_files -fileset sim_1 $sim_files

proc collect_dirs {root} {
    set dirs [list]
    if {![file isdirectory $root]} {
        return $dirs
    }
    lappend dirs $root
    foreach dir [glob -nocomplain -types d -directory $root *] {
        if {[file tail $dir] eq ".Xil"} {
            continue
        }
        set dirs [concat $dirs [collect_dirs $dir]]
    }
    return $dirs
}

set include_dirs [list ../rtl ../rtl/ip/APB_UART/URT]
set include_dirs [concat $include_dirs [collect_dirs ../rtl/ip/myCPU]]
set include_dirs [lsort -unique $include_dirs]
set_property include_dirs $include_dirs [get_filesets sources_1]
set_property include_dirs $include_dirs [get_filesets sim_1]

# Add constraints
add_files -fileset constrs_1 -quiet ./constraints

set_property top soc_top [current_fileset]
set_property -name "top" -value "tb_top" -objects  [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
