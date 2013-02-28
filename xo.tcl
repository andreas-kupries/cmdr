## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## Command dispatcher framework.
## Knows about officers and privates.
## Encapsulates the creation of command hierachies.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO
package require xo::officer

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::xo {
    namespace export new create
    namespace ensemble create
}

# # ## ### ##### ######## #############

proc ::xo::new {spec} {
    return [xo::officer new $spec]
}

proc ::xo::create {obj spec} {
    return [xo::officer create $obj $spec]
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo 0.1
