## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## Command dispatcher framework.
## Knows about officers and privates.
## Encapsulates the creation of command hierachies.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO
package require cmdr::officer

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export new create interactive interactive?
    namespace ensemble create

    # Generally interaction is possible.
    variable interactive 1
}

# # ## ### ##### ######## #############

proc ::cmdr::new {name spec} {
    return [cmdr::officer new {} $name $spec]
}

proc ::cmdr::create {obj name spec} {
    # Uplevel to ensure proper namespace for the 'obj'.
    return [uplevel 1 [list cmdr::officer create $obj {} $name $spec]]
}

# # ## ### ##### ######## ############# #####################
## Global interactivity configuration.

proc ::cmdr::interactive {{enable 1}} {
    variable interactive $enable
    return
}

proc ::cmdr::interactive? {} {
    variable interactive
    return  $interactive
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr 0.1
