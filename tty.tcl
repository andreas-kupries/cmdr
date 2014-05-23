## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - TTY. Convenience command for checking if stdout is a tty.

# @@ Meta Begin
# Package cmdr::tty 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Check if stdout is a TTY.
# Meta description 
# Meta subject {command line} tty
# Meta require {Tcl 8.5-}
# Meta require Tclx
# Meta require debug
# Meta require debug::caller
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require Tclx
package require debug
package require debug::caller

# # ## ### ##### ######## #############

namespace eval ::cmdr {
    namespace export tty
    namespace ensemble create
}

namespace eval ::cmdr::tty {
    namespace export stdout
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/tty
debug level  cmdr/tty
debug prefix cmdr/tty {[debug caller] | }

# # ## ### ##### ######## #############

if {$::tcl_platform(platform) eq "windows"} {
    proc ::cmdr::tty::stdout {} {
	debug.cmdr/tty {-- windows --}
	return 0
    }
} else {
    proc ::cmdr::tty::stdout {} {
	debug.cmdr/tty {-- unix/osx --}
	fstat stdout tty
    }
}

# # ## ### ##### ######## #############
package provide tty 0
