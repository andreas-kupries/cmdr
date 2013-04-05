## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Util - General utilities

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require textutil::adjust
package require debug
package require debug::caller

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export util
    namespace ensemble create
}

namespace eval ::cmdr::util {
    namespace export padr
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/util
debug level  cmdr/util
debug prefix cmdr/util {[debug caller] | }

# # ## ### ##### ######## ############# #####################

proc ::cmdr::util::padr {list} {
    debug.cmdr/util {}
    if {[llength $list] <= 1} {
	return $list
    }
    set maxl 0
    foreach str $list {
	set l [string length $str]
	if {$l <= $maxl} continue
	set maxl $l
    }
    set res {}
    foreach str $list { lappend res [format "%-*s" $maxl $str] }
    return $res
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::util 0.1
