## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate::Weekday - Supporting validation type - iso weekdays.

# @@ Meta Begin
# Package cmdr::validate::weekday 1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard parameter validation type for weekdays
# Meta description Standard parameter validation type for weekdays
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require {cmdr::validate::common 1.2}
# Meta require debug
# Meta require debug::caller
# Meta require try
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::validate::common 1.2
package require debug
package require debug::caller
package require try

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export validate
    namespace ensemble create
}
namespace eval ::cmdr::validate {
    namespace export weekday
    namespace ensemble create
}
namespace eval ::cmdr::validate::weekday {
    namespace export default validate complete release 2external
    namespace ensemble create

    namespace import ::cmdr::validate::common::fail
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate/weekday
debug level  cmdr/validate/weekday
debug prefix cmdr/validate/weekday {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## Weekdays as parsed by clock::iso86

proc ::cmdr::validate::weekday::2external {x}  {
    debug.cmdr/validate/weekday {}
    return [clock format [clock scan $x -format %u] -format {%A}]
}

proc ::cmdr::validate::weekday::release  {p x} { return }
proc ::cmdr::validate::weekday::default  {p}  {
    debug.cmdr/validate/weekday {}
    # Weekday of today.
    return [clock format [clock seconds] -format %u]
}
proc ::cmdr::validate::weekday::complete {p x} {
    debug.cmdr/validate/weekday {} 10
    # No completion (too many possible inputs (across the locales))
    return {}
}
proc ::cmdr::validate::weekday::validate {p x} {
    debug.cmdr/validate/weekday {}
    # Accept short and long weekday names, and weekday numbers 0-7.
    # Sunday can be either 0, or 7.

    set xa [string tolower $x]
    foreach pattern {%A %a %u %w} {
	try {
	    set epoch [clock scan $xa -format $pattern]
	} trap {CLOCK badDayOfWeek} {e o} {
	    continue
	} trap {CLOCK badInputString} {e o} {
	    continue
	} on ok {e o} {
	    # We have an epoch value.
	    # Format it back to a numeric weekday (1->monday, 7->sunday).
	    # (iso8601)
	    return [clock format $epoch -format %u]
	}
    }
    fail $p WEEKDAY "a weekday" $x
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::weekday 1
return
