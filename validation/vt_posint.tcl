## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate::Posint - Supporting validation type - positive integers (> 0)

# @@ Meta Begin
# Package cmdr::validate::posint 1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard parameter validation type for positive ints > 0
# Meta description Standard parameter validation type for positive ints > 0
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
    namespace export posint
    namespace ensemble create
}
namespace eval ::cmdr::validate::posint {
    namespace export default validate complete release
    namespace ensemble create

    namespace import ::cmdr::validate::common::fail
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate/posint
debug level  cmdr/validate/posint
debug prefix cmdr/validate/posint {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## Posints as parsed by clock::iso86

proc ::cmdr::validate::posint::release  {p x} { return }
proc ::cmdr::validate::posint::default  {p}  { return 1 }
proc ::cmdr::validate::posint::complete {p x} {
    debug.cmdr/validate/posint {} 10
    # No completion
    return {}
}
proc ::cmdr::validate::posint::validate {p x} {
    debug.cmdr/validate/posint {}
    # While we accept integers in octal and hex we convert them into
    # proper decimals for internal use, as our standard
    # representation.
    if {[string is integer -strict $x] && ($x > 0)} {
	return [format %d $x]
    }
    fail $p INTEGER "a positive integer" $x
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::posint 1
return
