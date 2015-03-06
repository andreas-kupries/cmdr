## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate::Date - Supporting validation type - iso dates.

# @@ Meta Begin
# Package cmdr::validate::date 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard parameter validation type for dates
# Meta description Standard parameter validation type for dates
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require {cmdr::validate::common 1.2}
# Meta require debug
# Meta require debug::caller
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
    namespace export date
    namespace ensemble create
}
namespace eval ::cmdr::validate::date {
    namespace export default validate complete release
    namespace ensemble create

    namespace import ::cmdr::validate::common::fail
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate/date
debug level  cmdr/validate/date
debug prefix cmdr/validate/date {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## Dates as parsed by clock::iso86

proc ::cmdr::validate::date::release  {p x} { return }
proc ::cmdr::validate::date::default  {p}  {
    debug.cmdr/validate/date {}
    # Today.
    return [clock format [clock seconds] -format {%Y-%m-%d}]
}
proc ::cmdr::validate::date::complete {p x} {
    debug.cmdr/validate/date {} 10
    # No completion.
    return {}
}
proc ::cmdr::validate::date::validate {p x} {
    debug.cmdr/validate/date {}
    try {
	# TODO: error code in clock::iso8601.
	set epoch [clock::iso8601 parse_date $x]
    } on error {e o} {
	fail $p DATE "an ISO8601 date" $x
    } 
    return $epoch
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::date 1
return
