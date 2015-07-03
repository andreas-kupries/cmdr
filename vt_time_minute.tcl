## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate::Time::Minute - Supporting validation type - iso times limited to minutes.

# @@ Meta Begin
# Package cmdr::validate::time::minute 1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard parameter validation type for times (down to minutes)
# Meta description Standard parameter validation type for times (down to minutes)
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
    namespace export minute
    namespace ensemble create
}
namespace eval ::cmdr::validate::time::minute {
    namespace export default validate complete release 2external
    namespace ensemble create

    namespace import ::cmdr::validate::common::fail
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate/time/minute
debug level  cmdr/validate/time/minute
debug prefix cmdr/validate/time/minute {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## Times as parsed by clock::iso86

proc ::cmdr::validate::time::minute::2external {x}  {
    debug.cmdr/validate/time/minute {}
    # x in [0..1440) => [0..86400) seconds.
    return [clock format [expr {$x * 60 + [DayBase]}] -format {%H:%M}]
}

proc ::cmdr::validate::time::minute::release  {p x} { return }
proc ::cmdr::validate::time::minute::default  {p}  {
    debug.cmdr/validate/time/minute {}
    # Today, limited to the minute from midnight
    return [expr {([clock seconds] / 60) % 1440}]
}
proc ::cmdr::validate::time::minute::complete {p x} {
    debug.cmdr/validate/time/minute {} 10
    # No completion.
    return {}
}
proc ::cmdr::validate::time::minute::validate {p x} {
    debug.cmdr/validate/time/minute {}
    try {
	if {[string is integer -strict $x] && ($x >= 0)} {
	    # Integer, direct offset from midnight, force range.
	    set minoffset [expr {$x % 1440}]
	} else {
	    # TODO: error code in clock::iso8601.
	    set minoffset [expr {(([clock::iso8601 parse_time ${x}:00] - [DayBase]) / 60) % 1440}]
	}
    } on error {e o} {
	fail $p TIME "a time to the minute" $x
    }
    return $minoffset
}

proc ::cmdr::validate::time::minute::DayBase {}  {
    clock::iso8601 parse_time 00:00:00
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::time::minute 1
return
