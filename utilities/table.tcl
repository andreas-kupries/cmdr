# -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## Easy table generation

# @@ Meta Begin
# Package cmdr::table 0
# Meta author      ?
# Meta category    ?
# Meta description ?
# Meta location    http:/core.tcl.tk/akupries/cmdr
# Meta platform    tcl
# Meta require     ?
# Meta subject     ?
# Meta summary     ?
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requirements

package require Tcl 8.5
package require TclOO
package require cmdr::color
package require debug
package require debug::caller
package require report
package require struct::matrix

# # ## ### ##### ######## ############# ######################
## Debug narrative setup

debug level  cmdr/table
debug prefix cmdr/table {[debug caller] | }

# # ## ### ##### ######## ############# ######################
## Styles used in the table reports.

# Borders and header row.
::report::defstyle cmdr/table/borders {} {
    data	set [split "[string repeat "| "   [columns]]|"]
    top		set [split "[string repeat "+ - " [columns]]+"]
    bottom	set [top get]
    topdata	set [data get]
    topcapsep	set [top get]
    top		enable
    bottom	enable
    topcapsep	enable
    tcaption	1
    for {set i 0 ; set n [columns]} {$i < $n} {incr i} {
	pad $i both { }
    }
    return
}

# Borders, no header row.
::report::defstyle cmdr/table/borders/nohdr {} {
    data	set [split "[string repeat "| "   [columns]]|"]
    top		set [split "[string repeat "+ - " [columns]]+"]
    bottom	set [top get]
    top		enable
    bottom	enable
    for {set i 0 ; set n [columns]} {$i < $n} {incr i} {
	pad $i both { }
    }
    return
}

# No borders, with header row.
::report::defstyle cmdr/table/plain {} {
    tcaption	1
    for {set i 1 ; set n [columns]} {$i < $n} {incr i} {
	pad $i left { }
    }
    return
}

# No borders, no header row
::report::defstyle cmdr/table/plain/nohdr {} {
    for {set i 1 ; set n [columns]} {$i < $n} {incr i} {
	pad $i left { }
    }
    return
}

::report::defstyle cmdr/table/html {} {
    data	set [split "<tr><td> [string repeat "</td><td> " [expr {[columns]-1}]]</td></tr>"]
    #top		set <table>
    #bottom	set </table>
    #top		enable
    #bottom	enable
    return
}

# # ## ### ##### ######## ############# ######################

namespace eval ::cmdr {
    namespace export table
    namespace ensemble create
}
namespace eval ::cmdr::table {
    variable plain   no   ;# Global style setting (plain yes/no)
    variable showcmd puts ;# Global print setting (command prefix)

    namespace export general dict plain show
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################
## API

proc ::cmdr::table::plain {v} {
    debug.cmdr/table {}
    variable plain $v
    return
}

proc ::cmdr::table::show {args} {
    debug.cmdr/table {}
    variable showcmd $args
    return
}

proc ::cmdr::table::general {v headings script} {
    debug.cmdr/table {}

    variable plain
    upvar 1 $v t
    set t [uplevel 1 [list ::cmdr::table::Impl::general new {*}$headings]]
    if {$plain} { $t plain }
    uplevel 1 $script
    return $t
}

proc ::cmdr::table::dict {v script} {
    debug.cmdr/table {}

    upvar 1 $v t
    variable plain
    set t [uplevel 1 [list ::cmdr::table::Impl::dict new]]
    if {$plain} { $t plain }
    uplevel 1 $script
    return $t
}

# # ## ### ##### ######## ############# #####################
## Internal classes

oo::class create ::cmdr::table::Impl::general {
    # # ## ### ##### ######## #############

    constructor {args} {
	debug.cmdr/table {}
	namespace import ::cmdr::color
	# args = headings.

	struct::matrix [self namespace]::M
	M add columns [llength $args]

	set headings {}
	foreach w $args { lappend headings [color heading $w] }

	M add row $headings
	set myplain 0
	set myheader 1
	set mystyle {}
	return
    }

    destructor {}

    # # ## ### ##### ######## #############
    ## API

    method add {args} {
	M add row $args
	return
    }
    # Alternate names for creation of new rows.
    forward +  my add ; export +
    forward += my add ; export +=
    forward << my add ; export <<
    forward <= my add ; export <=

    method show {{cmd {}}} {
	if {[llength [info level 0]] == 2} {
	    variable ::cmdr::table::showcmd
	    set cmd $::cmdr::table::showcmd
	}
	uplevel #0 [list {*}$cmd [my String]]
	my destroy
	return
    }

    method show* {{cmd {}}} {
	if {[llength [info level 0]] == 2} {
	    variable ::cmdr::table::showcmd
	    set cmd $::cmdr::table::showcmd
	}
	uplevel #0 [list {*}$cmd [my String]]
	return
    }

    method plain {} {
	debug.cmdr/table {}
	set myplain 1
	return
    }

    method style {style} {
	debug.cmdr/table {}
	set mystyle $style
	return
    }

    method noheader {} {
	debug.cmdr/table {}
	if {!$myheader} return
	set myheader 0
	M delete row 0
	return
    }

    method String {} {
	debug.cmdr/table {}
	# Choose style (user-specified, plain y/n, header y/n)

	if {$mystyle ne {}} {
	    set thestyle $mystyle
	} elseif {$myplain} {
	    if {$myheader} {
		set thestyle cmdr/table/plain
	    } else {
		set thestyle cmdr/table/plain/nohdr
	    }
	} else {
	    if {$myheader} {
		set thestyle cmdr/table/borders
	    } else {
		set thestyle cmdr/table/borders/nohdr
	    }
	}

	set r [report::report [self namespace]::R [M columns] style $thestyle]
	set str [M format 2string $r]
	$r destroy

	return [string trimright $str]
    }

    # # ## ### ##### ######## #############
    ## Internal commands.

    # # ## ### ##### ######## #############
    ## State

    variable myplain myheader mystyle

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################

oo::class create ::cmdr::table::Impl::dict {
    # # ## ### ##### ######## #############
    superclass ::cmdr::table::Impl::general

    constructor {} {
	debug.cmdr/table {}
	next Key Value
	my noheader ;# suppress header row.
	# Keys are the headers (side ways table).
	return
    }

    destructor {}

    # # ## ### ##### ######## #############
    ## API

    # Specialized "add", applies colorization to keys.
    method add {key {value {}}} {
	# Note, we separate leading spaces and indentation from the
	# actual key.  The prefix will not be colored.  Note also that
	# key colorization done by the user will override the color
	# applied here.

	regexp {(^[- ]*)(.*)$} $key -> prefix thekey
	M add row [list $prefix[color heading $thekey] $value]
	return
    }

    # # ## ### ##### ######## #############
    ## Internal commands.

    # # ## ### ##### ######## #############
    ## State - None of its own.

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::table 0
