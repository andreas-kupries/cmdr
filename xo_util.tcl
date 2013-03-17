## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Util - General utilities

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require textutil::adjust

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::xo {
    namespace export util
    namespace ensemble create
}

namespace eval ::xo::util {
    namespace export padr
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

proc ::xo::util::padr {list} {
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
package provide xo::util 0.1
