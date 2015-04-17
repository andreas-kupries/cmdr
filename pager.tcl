## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Pager - Auto-page large output
##                Common use case is help.

# @@ Meta Begin
# Package cmdr::pager 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Utilities for interfacing with pager applications like less and more.
# Meta description Utilities for interfacing with pager applications like less and more.
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require debug
# Meta require debug::caller
# Meta require linenoise
# Meta require cmdr::tty
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require debug
package require debug::caller
package require linenoise
package require cmdr::tty

# # ## ### ##### ######## ############# #####################

debug define cmdr/pager
debug level  cmdr/pager
debug prefix cmdr/pager {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export pager
    namespace ensemble create
}

namespace eval ::cmdr::pager {
    namespace import ::cmdr::tty
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::pager {text} {
    debug.cmdr/pager {}

    set pager [pager::Locate $text]

    debug.cmdr/pager {pager = ($pager)}
    if {[llength $pager]} {
	set    pipe [open "|$pager" w]
	puts  $pipe $text
	# This waits until the pager exits.
	close $pipe

    } else {
	# Paging not available, disabled, etc.
	puts stdout $text
    }

    debug.cmdr/pager {/done}
    return
}

proc ::cmdr::pager::Locate {text} {
    debug.cmdr/pager {}

    # Not in a terminal, no paging
    if {![tty stdout]} {
	debug.cmdr/pager {==> (), not in a tty - disabled}
	return {}
    }

    # Does line noise support querying terminal height ?  If not we go
    # with a default value.
    if {[catch {
	set height [linenoise lines]
	debug.cmdr/pager {terminal height $height /linenoise}
    }]} {
	set height 25
	debug.cmdr/pager {terminal height $height /default}
    }

    # Does the text fits into the terminal as is ? If yes, paging is
    # not required.
    set lines [llength [split $text \n]]
    if {$lines <= $height} {
	debug.cmdr/pager {==> (), text fits - disabled}
	return {}
    }

    # We want paging. Find the external command to use for this. This
    # can still disable paging, when nothing is found. We look for the
    # user's choice first.

    global env
    if {[info exists env(PAGER)]} {
	lappend pager $env(PAGER)
    }
    lappend pager less
    lappend pager more

    foreach p $pager {
	debug.cmdr/pager {Looking for cmd ($p)}
	set cmd [auto_execok $p]
	if {[llength $cmd]} break
    }

    debug.cmdr/pager {==> ($cmd)}
    return $cmd
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::pager 1
