# vivado_multi_synth.tcl
# Usage examples:
#   vivado -mode batch -source vivado_multi_synth.tcl -tclargs \
#     -proj_name myproj -part xc7a200tfbg484-2 -top top \
#     -proj_dir ./build/myproj -src_dir ./rtl -xdc ./constraints/top.xdc \
#     -runs synth_small
#
#   vivado -mode batch -source vivado_multi_synth.tcl -tclargs -runs all
#   vivado -mode batch -source vivado_multi_synth.tcl -tclargs -runs synth_small,synth_full

proc usage {} {
  puts "ERROR: bad arguments"
  puts "Args:"
  puts "  -proj_name <name>"
  puts "  -proj_dir  <dir>"
  puts "  -part      <part>"
  puts "  -top       <top_module_or_entity>"
  puts "  -src_dir   <rtl_dir>          "
  puts "  -xdc       <constraints.xdc>  (optional; can be comma-separated)"
  puts "  -runs      <all|synth_small|synth_medium|synth_full|comma-list>"
  exit 2
}

# -------------------------
# Arg parsing
# -------------------------
array set OPT {
  proj_name "aoc_chal8"
  proj_dir  "build"
  part      "xcku035-fbva676-3-e"
  top       "top"
  src_dir   "../src"
  xdc       "constraints.xdc"
  runs      "synth_small"
}

set argcnt [llength $argv]
for {set i 0} {$i < $argcnt} {incr i} {
  set a [lindex $argv $i]
  switch -- $a {
    -proj_name { incr i; set OPT(proj_name) [lindex $argv $i] }
    -proj_dir  { incr i; set OPT(proj_dir)  [lindex $argv $i] }
    -part      { incr i; set OPT(part)      [lindex $argv $i] }
    -top       { incr i; set OPT(top)       [lindex $argv $i] }
    -src_dir   { incr i; set OPT(src_dir)   [lindex $argv $i] }
    -xdc       { incr i; set OPT(xdc)       [lindex $argv $i] }
    -runs      { incr i; set OPT(runs)      [lindex $argv $i] }
    default    { usage }
  }
}

if {$OPT(src_dir) eq ""} {
  puts "ERROR: Provide -src_dir"
  usage
}

# Normalize and create project directory
set proj_dir [file normalize $OPT(proj_dir)]
if {![file exists $proj_dir]} {
  file mkdir $proj_dir
} else {
    puts "Deleting old $proj_dir directory"
    file delete -force $proj_dir
    file mkdir $proj_dir
}

# -------------------------
# Project creation
# -------------------------
if {[file exists [file join $proj_dir "$OPT(proj_name).xpr"]]} {
  puts "INFO: Project exists, opening: $proj_dir/$OPT(proj_name).xpr"
  open_project [file join $proj_dir "$OPT(proj_name).xpr"]
} else {
  puts "INFO: Creating new project: $OPT(proj_name)"
  create_project $OPT(proj_name) $proj_dir -part $OPT(part) -force
}

set_property top $OPT(top) [current_fileset]

set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# -------------------------
# Add sources
# -------------------------
proc add_rtl_sources {dirs} {
    foreach dir $dirs {
        set rtl_files {}
        set include_files {}

        set d [file normalize $dir]
        if {![file isdirectory $d]} {
        error "src_dir not a directory: $d"
        }

        # Collect RTL sources
        set rtl_files [concat \
        [glob -nocomplain -directory $d *.v] \
        [glob -nocomplain -directory $d *.sv] \
        [glob -nocomplain -directory $d *.vhd] \
        [glob -nocomplain -directory $d *.vhdl] \
        ]

        # Collect include files
        set include_files [concat \
        [glob -nocomplain -directory $d *.vh] \
        [glob -nocomplain -directory $d *.svh] \
        ]

        # Add RTL files
        if {[llength $rtl_files] > 0} {
            add_files -norecurse $rtl_files
        }

        # Add include files and mark as global includes
        if {[llength $include_files] > 0} {
            add_files -norecurse $include_files
            foreach f $include_files {
            set_property IS_GLOBAL_INCLUDE true [get_files $f]
            }
        }
    }
}

add_rtl_sources "$OPT(src_dir) [pwd]"

# -------------------------
# Add constraints
# -------------------------
if {$OPT(xdc) ne ""} {
  set xlist [split $OPT(xdc) ","]
  foreach x $xlist {
    set xf [file normalize $x]
    if {![file exists $xf]} { error "XDC not found: $xf" }
    add_files -fileset constrs_1 -norecurse $xf
  }
}

# -------------------------
# Synthesis run creation/config
# -------------------------
proc ensure_synth_run {run_name flow} {
  if {[lsearch -exact [get_runs -quiet] $run_name] < 0} {
    create_run $run_name -flow $flow -strategy "Vivado Synthesis Defaults" -constrset constrs_1
  }
}

proc set_run_defines {run_name defines_list} {
  set r [get_runs $run_name]

  # Pull any existing MORE_OPTIONS so we can merge rather than clobber
  set cur [get_property  {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS}  [get_runs $r] ]
  if {$cur eq ""} {
    set cur {}
  }

  # Remove any existing -verilog_define chunk from MORE_OPTIONS (best-effort)
  # This keeps repeated script runs from accumulating conflicting options.
  set new {}
  set skip 0
  foreach tok $cur {
    if {$skip} {
      # Skip the list argument to -verilog_define
      set skip 0
      continue
    }
    if {$tok eq "-verilog_define"} {
      set skip 1
      continue
    }
    lappend new $tok
  }

  # Append the defines
  lappend new -verilog_define $defines_list

  set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value "$new" -objects [get_runs $r]
}

proc set_run_extra_synth_args {run_name args_list} {
  # args_list example: {-flatten_hierarchy rebuilt -fsm_extraction one_hot}
  set r [get_runs $run_name]
  set_property STEPS.SYNTH_DESIGN.ARGS.MORE_OPTIONS $args_list $r
}

# Use the default Vivado synthesis flow
set synth_flow "Vivado Synthesis 2025"

# Create runs
ensure_synth_run "synth_small"  $synth_flow
ensure_synth_run "synth_medium" $synth_flow
ensure_synth_run "synth_full"   $synth_flow

#Delete default
if {[get_runs synth_1] ne ""} {
    delete_runs synth_1
}


# Common run settings (optional)
foreach r {synth_small synth_medium synth_full} {
  set rr [get_runs $r]
  set_property PART $OPT(part) $rr
  set_property NEEDS_REFRESH true $rr
}

# Per-run parameters
set_run_defines synth_small  {DIM_W=17 NUM_POINTS=20 NUM_CONNS=10 NUM_NTWRKS=3}
set_run_defines synth_medium {DIM_W=17 NUM_POINTS=100 NUM_CONNS=100 NUM_NTWRKS=3}
set_run_defines synth_full   {DIM_W=17 NUM_POINTS=1000 NUM_CONNS=1000 NUM_NTWRKS=3}

#Additional options
foreach r {synth_small synth_medium synth_full} {
    set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs $r]
    set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION one_hot [get_runs $r]
    set_property STEPS.SYNTH_DESIGN.ARGS.NO_SRLEXTRACT true     [get_runs $r]
}

# -------------------------
# Run launching helpers
# -------------------------
proc normalize_run_list {runs_arg} {
  if {$runs_arg eq "" || $runs_arg eq "all"} {
    return {synth_small synth_medium synth_full}
  }
  # Allow comma-separated list
  if {[string first "," $runs_arg] >= 0} {
    return [split $runs_arg ","]
  }
  return [list $runs_arg]
}

proc launch_synth_runs {runs_arg {jobs 4}} {
  set runs [normalize_run_list $runs_arg]
  foreach r $runs {
    if {[lsearch -exact {synth_small synth_medium synth_full} $r] < 0} {
      error "Unknown run requested: $r (valid: synth_small,synth_medium,synth_full,all)"
    }
    puts "INFO: Launching run: $r"
    launch_runs $r -jobs $jobs
  }
}

proc wait_on_synth_runs {runs_arg} {
  set runs [normalize_run_list $runs_arg]
  foreach r $runs {
    puts "INFO: Waiting on run: $r"
    wait_on_run $r
  }
}

# -------------------------
# Main execution
# -------------------------
puts "INFO: Project: [current_project]"
puts "INFO: Top:     $OPT(top)"
puts "INFO: Part:    $OPT(part)"

# Launch requested runs and wait for completion
launch_synth_runs $OPT(runs) 4
wait_on_synth_runs $OPT(runs)

# Report status
foreach r {synth_small synth_medium synth_full} {
  set s [get_property STATUS [get_runs $r]]
  puts "INFO: Run $r status: $s"
  if {$s eq "synth_design Complete!"} {
    puts "Generating timing and utilization for $r"
    open_run $r
    report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -max_paths 100 -input_pins -routable_nets -file $proj_dir/${r}_timing_summary.txt
    puts "INFO: Timing report for $r saved to $proj_dir/${r}_timing_summary.txt"
    report_utilization -hierarchical -file $proj_dir/${r}_utilization.txt
    puts "INFO: Utilization report for $r saved to $proj_dir/${r}_utilization.txt"
    close_design
  }
}

puts "INFO: Done."
exit 0
