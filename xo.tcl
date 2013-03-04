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

proc ::xo::new {name spec} {
    return [xo::officer new {} $name $spec]
}

proc ::xo::create {obj name spec} {
    # Uplevel to ensure proper namespace for the 'obj'.
    return [uplevel 1 [list xo::officer create $obj {} $name $spec]]
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo 0.1
