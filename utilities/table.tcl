# -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## Easy table generation

# TODO: control colorization a bit more - Allow for global and
# per-table suppression.

# @@ Meta Begin
# Package cmdr::table 0.3
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform    tcl
# Meta summary Easy generation of tables
# Meta description Easy generation of tables
# Meta subject {command line} table matrix report
# Meta require {Tcl 8.5-}
# Meta require TclOO
# Meta require cmdr::color
# Meta require debug
# Meta require debug::caller
# Meta require report
# Meta require struct::matrix
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
    variable borders yes  ;# Global style setting (use borders: yes/no)
    variable showcmd puts ;# Global print setting (command prefix)

    namespace export general dict borders show
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################
## API

proc ::cmdr::table::borders {{enable {}}} {
    debug.cmdr/table {}
    variable borders
    if {[llength [info level 0]] > 1} {
	CheckBool $enable
	set borders $enable
    }
    return $borders
}

proc ::cmdr::table::show {args} {
    debug.cmdr/table {}
    variable showcmd
    if {[llength $args]} {
	set showcmd $args
    }
    return $showcmd
}

proc ::cmdr::table::general {v headings script} {
    debug.cmdr/table {}

    variable borders
    upvar 1 $v t
    set t [uplevel 1 [list ::cmdr::table::Impl::general new {*}$headings]]
    if {!$borders} { $t borders no }
    uplevel 1 $script
    return $t
}

proc ::cmdr::table::dict {v script} {
    debug.cmdr/table {}

    upvar 1 $v t
    variable borders
    set t [uplevel 1 [list ::cmdr::table::Impl::dict new]]
    if {!$borders} { $t borders no }
    uplevel 1 $script
    return $t
}

proc ::cmdr::table::CheckBool {v} {
    debug.cmdr/table {}
    if {[string is boolean -strict $v]} return
    return -code error -errorcode {CMDR TABLE NOT-A-BOOLEAN} \
	"Expected boolean, got \"$v\""
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
	set myborders 1
	set myheaders 1
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

    method borders {{enable {}}} {
	debug.cmdr/table {}
	if {[llength [info level 0]] > 2} {
	    ::cmdr::table::CheckBool $enable
	    set myborders $enable
	}
	return $myborders
    }

    method headers {{enable {}}} {
	debug.cmdr/table {}
	if {[llength [info level 0]] > 2} {
	    ::cmdr::table::CheckBool $enable
	    set myheaders $enable
	}
	return $myheaders
    }

    method style {{style {}}} {
	debug.cmdr/table {}
	if {[llength [info level 0]] > 2} {
	    set mystyle $style
	}
	return [my Style]
    }

    method Style {} {
	debug.cmdr/table {}
	# Determine and return style (user-specified, borders y/n, header y/n)
	if {$mystyle ne {}} {
	    set thestyle $mystyle
	} elseif {$myborders} {
	    if {$myheaders} {
		set thestyle cmdr/table/borders
	    } else {
		set thestyle cmdr/table/borders/nohdr
	    }
	} elseif {$myheaders} {
	    set thestyle cmdr/table/plain
	} else {
	    set thestyle cmdr/table/plain/nohdr
	}

	debug.cmdr/table {==> ($thestyle)}
	return $thestyle
    }

    method String {} {
	debug.cmdr/table {}

	if {!$myheaders} {
	    # Remove the header row pushed by the constructor.
	    M delete row 0
	}
	
	set r [report::report [self namespace]::R [M columns] style [my Style]]
	set str [M format 2string $r]
	$r destroy

	set tmp {}
	foreach line [split $str \n] {
	    lappend tmp [string trimright $line]
	}
	set str [join $tmp \n]
	
	return [string trimright $str]
    }

    # # ## ### ##### ######## #############
    ## Internal commands.

    # # ## ### ##### ######## #############
    ## State

    variable myborders myheaders mystyle

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################

oo::class create ::cmdr::table::Impl::dict {
    # # ## ### ##### ######## #############
    superclass ::cmdr::table::Impl::general

    constructor {} {
	debug.cmdr/table {}
	next Key Value
	my headers no ;# suppress header row.
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
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::table 0.3
