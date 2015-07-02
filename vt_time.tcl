## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate::Time - Supporting validation type - iso times.

# @@ Meta Begin
# Package cmdr::validate::time 1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard parameter validation type for times (down to seconds)
# Meta description Standard parameter validation type for times (down to seconds)
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require {cmdr::validate::common 1.2}
# Meta require debug
# Meta require debug::caller
# Meta require try
# Meta require clock::iso8601
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::validate::common 1.2
package require debug
package require debug::caller

package require clock::iso8601
package require try

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export validate
    namespace ensemble create
}
namespace eval ::cmdr::validate {
    namespace export time
    namespace ensemble create
}
namespace eval ::cmdr::validate::time {
    namespace export default validate complete release 2external
    namespace ensemble create

    namespace import ::cmdr::validate::common::fail
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate/time
debug level  cmdr/validate/time
debug prefix cmdr/validate/time {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## Times as parsed by clock::iso86

proc ::cmdr::validate::time::2external {x}  {
    debug.cmdr/validate/time {}
    return [clock format $x -format {%H:%M:%S}]
}

proc ::cmdr::validate::time::release  {p x} { return }
proc ::cmdr::validate::time::default  {p}  {
    debug.cmdr/validate/time {}
    # Today.
    return [clock seconds]
}
proc ::cmdr::validate::time::complete {p x} {
    debug.cmdr/validate/time {} 10
    # No completion.
    return {}
}
proc ::cmdr::validate::time::validate {p x} {
    debug.cmdr/validate/time {}
    try {
	# TODO: error code in clock::iso8601.
	set epoch [clock::iso8601 parse_time $x]
    } on error {e o} {
	fail $p TIME "an ISO8601 time" $x
    } 
    return $epoch
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::time 1
return
