## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate - Common utility commands.

# @@ Meta Begin
# Package cmdr::validate::common 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Utilities for validation types.
# Meta description Utilities for validation types.
# Meta subject {command line} {parameter validation}
# Meta subject {validation type} {type checking}
# Meta require {Tcl 8.5-}
# Meta require debug
# Meta require debug::caller
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require debug
package require debug::caller

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export validate
    namespace ensemble create
}

namespace eval ::cmdr::validate {
    namespace export common
    namespace ensemble create
}

namespace eval ::cmdr::validate::common {
    namespace export fail complete-enum config
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate/common
debug level  cmdr/validate/common
debug prefix cmdr/validate/common {[debug caller] | }

# # ## ### ##### ######## ############# #####################

proc ::cmdr::validate::common::fail {code type x} {
    debug.cmdr/validate/common {}
    return -code error -errorcode [list CMDR VALIDATE {*}$code] \
	"Expected $type, got \"$x\""
}

proc ::cmdr::validate::common::complete-enum {choices nocase buffer} {
    # As a helper function for command completion printing anything
    # here would mix with the output of linenoise. Do that only on
    # explicit request (level 10).
    debug.cmdr/validate/common {} 10

    if {$buffer eq {}} {
	return $choices
    }

    if {$nocase} {
	set buffer [string tolower $buffer]
    }

    set candidates {}
    foreach c $choices {
	if {![string match ${buffer}* $c]} continue
	lappend candidates $c
    }

    debug.cmdr/validate/common {= [join $candidates "\n= "]} 10
    return $candidates
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::common 0.1
return
