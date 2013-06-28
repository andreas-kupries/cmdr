## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate - Definition of core validation classes.

# @@ Meta Begin
# Package cmdr::validate 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard validation types for parameters.
# Meta description Standard validation types for parameters.
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require debug
# Meta require debug::caller
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::validate::common
package require debug
package require debug::caller

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export validate
    namespace ensemble create
}

namespace eval ::cmdr::validate {
    namespace export boolean integer identity
    #namespace ensemble create

    # For external v-types relying on them here.
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-enum
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate
debug level  cmdr/validate
debug prefix cmdr/validate {[debug caller] | }

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::validate::boolean {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-enum
}

proc ::cmdr::validate::boolean::release  {x} { return }
proc ::cmdr::validate::boolean::default  {}  {
    debug.cmdr/validate {}
    return no
}

proc ::cmdr::validate::boolean::complete {x} {
    debug.cmdr/validate {} 10
    return [complete-enum {yes no false true on off 0 1} 1 $x]
}

proc ::cmdr::validate::boolean::validate {x} {
    debug.cmdr/validate {}
    if {[string is boolean -strict $x]} { return $x }
    fail BOOLEAN "a boolean" $x
}

# # ## ### ##### ######## ############# #####################
## Any integer

namespace eval ::cmdr::validate::integer {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
}

proc ::cmdr::validate::integer::release  {x} { return }
proc ::cmdr::validate::integer::default  {}  {
    debug.cmdr/validate {}
    return 0
}
proc ::cmdr::validate::integer::complete {x} {
    debug.cmdr/validate {} 10
    return {}
}
proc ::cmdr::validate::integer::validate {x} {
    debug.cmdr/validate {}
    if {[string is integer -strict $x]} { return $x }
    fail INTEGER "an integer" $x
}

# # ## ### ##### ######## ############# #####################
## Any string

namespace eval ::cmdr::validate::identity {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::identity::release  {x} { return }
proc ::cmdr::validate::identity::default  {}  { debug.cmdr/validate {}    ; return {} }
proc ::cmdr::validate::identity::complete {x} { debug.cmdr/validate {} 10 ; return {} }
proc ::cmdr::validate::identity::validate {x} { debug.cmdr/validate {}    ; return $x }

# # ## ### ##### ######## ############# #####################
## Any string, alternate name

namespace eval ::cmdr::validate::pass {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::pass::release  {x} { return }
proc ::cmdr::validate::pass::default  {}  {debug.cmdr/validate {}    ; return {} }
proc ::cmdr::validate::pass::complete {x} {debug.cmdr/validate {} 10 ; return {} }
proc ::cmdr::validate::pass::validate {x} {debug.cmdr/validate {}    ; return $x }

# # ## ### ##### ######## ############# #####################
## Any string, alternate name, the second

namespace eval ::cmdr::validate::str {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::str::release  {x} { return }
proc ::cmdr::validate::str::default  {}  { debug.cmdr/validate {}    ; return {} }
proc ::cmdr::validate::str::complete {x} { debug.cmdr/validate {} 10 ; return {} }
proc ::cmdr::validate::str::validate {x} { debug.cmdr/validate {}    ; return $x }

# # ## ### ##### ######## ############# #####################
## File, existing and readable

namespace eval ::cmdr::validate::rfile {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
}

proc ::cmdr::validate::rfile::release  {x} { return }
proc ::cmdr::validate::rfile::default  {}  { debug.cmdr/validate {} ; error {No default} }
proc ::cmdr::validate::rfile::complete {x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rfile::Ok $x
}
proc ::cmdr::validate::rfile::validate {x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail RFILE "an existing readable file" $x
}

proc ::cmdr::validate::rfile::Ok {path} {
    if {![file exists   $path]} {return 0}
    if {![file isfile   $path]} {return 0}
    if {![file readable $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## File, existing and read/writable

namespace eval ::cmdr::validate::rwfile {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
}

proc ::cmdr::validate::rwfile::release  {x} { return }
proc ::cmdr::validate::rwfile::default  {}  { debug.cmdr/validate {} ; error {No default} }
proc ::cmdr::validate::rwfile::complete {x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rwfile::Ok $x
}
proc ::cmdr::validate::rwfile::validate {x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail RWFILE "an existing read/writable file" $x
}

proc ::cmdr::validate::rwfile::Ok {path} {
    if {![file exists   $path]} {return 0}
    if {![file isfile   $path]} {return 0}
    if {![file readable $path]} {return 0}
    if {![file writable $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Directory, existing and readable.

namespace eval ::cmdr::validate::rdirectory {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
}

proc ::cmdr::validate::rdirectory::default  {}  { error {No default} }
proc ::cmdr::validate::rdirectory::release  {x} { return }
proc ::cmdr::validate::rdirectory::complete {x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rdirectory::Ok $x
}

proc ::cmdr::validate::rdirectory::validate {x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail RDIRECTORY "an existing readable directory" $x
}

proc ::cmdr::validate::rdirectory::Ok {path} {
    if {![file exists      $path]} {return 0}
    if {![file isdirectory $path]} {return 0}
    if {![file readable    $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Directory, existing and read/writable.

namespace eval ::cmdr::validate::rwdirectory {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
}

proc ::cmdr::validate::rwdirectory::default  {}  { error {No default} }
proc ::cmdr::validate::rwdirectory::release  {x} { return }
proc ::cmdr::validate::rwdirectory::complete {x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rwdirectory::Ok $x
}

proc ::cmdr::validate::rwdirectory::validate {x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail RWDIRECTORY "an existing read/writeable directory" $x
}

proc ::cmdr::validate::rwdirectory::Ok {path} {
    if {![file exists      $path]} {return 0}
    if {![file isdirectory $path]} {return 0}
    if {![file readable    $path]} {return 0}
    if {![file writable    $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Any path, existing and readable.

namespace eval ::cmdr::validate::rpath {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
}

proc ::cmdr::validate::rpath::default  {}  { error {No default} }
proc ::cmdr::validate::rpath::release  {x} { return }
proc ::cmdr::validate::rpath::complete {x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rpath::Ok $x
}

proc ::cmdr::validate::rpath::validate {x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail RPATH "an existing readable path" $x
}

proc ::cmdr::validate::rpath::Ok {path} {
    if {![file exists      $path]} {return 0}
    if {![file isdirectory $path]} {return 0}
    if {![file readable    $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Any path, existing and read/writable.

namespace eval ::cmdr::validate::rwpath {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
}

proc ::cmdr::validate::rwpath::default  {}  { error {No default} }
proc ::cmdr::validate::rwpath::release  {x} { return }
proc ::cmdr::validate::rwpath::complete {x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rwpath::Ok $x
}

proc ::cmdr::validate::rwpath::validate {x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail RWPATH "an existing read/writeable path" $x
}

proc ::cmdr::validate::rwpath::Ok {path} {
    if {![file exists      $path]} {return 0}
    if {![file readable    $path]} {return 0}
    if {![file writable    $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate 0.1
return
