## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate::Year - Supporting validation type - iso years.

# @@ Meta Begin
# Package cmdr::validate::year 1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard parameter validation type for years
# Meta description Standard parameter validation type for years
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
    namespace export year
    namespace ensemble create
}
namespace eval ::cmdr::validate::year {
    namespace export default validate complete release
    namespace ensemble create

    namespace import ::cmdr::validate::common::fail
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate/year
debug level  cmdr/validate/year
debug prefix cmdr/validate/year {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## Years as parsed by clock::iso86

proc ::cmdr::validate::year::release  {p x} { return }
proc ::cmdr::validate::year::default  {p}  {
    debug.cmdr/validate/year {}
    # Year of today.
    return [clock format [clock seconds] -format %Y]
}
proc ::cmdr::validate::year::complete {p x} {
    debug.cmdr/validate/year {} 10
    # No completion (too many possible inputs (across the locales))
    return {}
}
proc ::cmdr::validate::year::validate {p x} {
    debug.cmdr/validate/year {}
    # Accept short and long year numbers

    set xa [string tolower $x]
    foreach pattern {%Y-%m-%d %y-%m-%d} {
	try {
	    # Note how we add fake month and day to both input and
	    # pattern (see above) to ensure proper behaviour from
	    # 'clock scan'.
	    set epoch [clock scan ${xa}-01-01 -format $pattern]
	} trap {CLOCK badInputString} {e o} {
	    continue
	} on ok {e o} {
	    # We have an epoch value.
	    # Format it back to a full numeric year
	    set y [clock format $epoch -format %Y]
	    debug.cmdr/validate/year {($xa) $pattern ==> ($epoch) ==> $y}
	    return $y
	}
    }
    fail $p YEAR "a year" $x
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::year 1
return
