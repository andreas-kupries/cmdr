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
    namespace export new create interactive interactive?
    namespace ensemble create

    # Generally interaction is possible.
    variable interactive 1
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
## Global interactivity configuration.

proc ::xo::interactive {{enable 1}} {
    variable interactive $enable
    return
}

proc ::xo::interactive? {} {
    variable interactive
    return  $interactive
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo 0.1
