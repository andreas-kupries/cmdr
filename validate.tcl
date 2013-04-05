## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate - Definition of core validation classes.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require debug
package require debug::caller

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export validate
    namespace ensemble create
}

namespace eval ::cmdr::validate {
    namespace export boolean integer identity \
	fail complete-enum config
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate
debug level  cmdr/validate
debug prefix cmdr/validate {[debug caller] | }

# # ## ### ##### ######## ############# #####################

proc ::cmdr::validate::fail {code type x} {
    debug.cmdr/validate {}
    return -code error -errorcode [list CMDR VALIDATE {*}$code] \
	"Expected $type, got \"$x\""
}

proc ::cmdr::validate::complete-enum {choices nocase buffer} {
    # As a helper function for command completion printing anything
    # here would mix with the output of linenoise. Do that only on
    # explicit request (level 10).
    debug.cmdr/validate {} 10

    if {$buffer eq {}} {
	return $choices
    }

    if {$nocase} {
	set buffer [string tolower $buffer]
    }

    set candidates {}
    foreach c $choices {
	if {![string match ${buffer}* $c]} continue
	lappend candidates $c
    }

    debug.cmdr/validate {= [join $candidates "\n= "]} 10
    return $candidates
}

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::validate::boolean {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::fail
    namespace import ::cmdr::validate::complete-enum
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

namespace eval ::cmdr::validate::integer {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::fail
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

namespace eval ::cmdr::validate::identity {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::identity::release  {x} { return }
proc ::cmdr::validate::identity::default  {}  { debug.cmdr/validate {}    ; return {} }
proc ::cmdr::validate::identity::complete {x} { debug.cmdr/validate {} 10 ; return {} }
proc ::cmdr::validate::identity::validate {x} { debug.cmdr/validate {}    ; return $x }

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::validate::pass {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::pass::release  {x} { return }
proc ::cmdr::validate::pass::default  {}  {debug.cmdr/validate {}    ; return {} }
proc ::cmdr::validate::pass::complete {x} {debug.cmdr/validate {} 10 ; return {} }
proc ::cmdr::validate::pass::validate {x} {debug.cmdr/validate {}    ; return $x }

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::validate::str {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::str::release  {x} { return }
proc ::cmdr::validate::str::default  {}  { debug.cmdr/validate {}    ; return {} }
proc ::cmdr::validate::str::complete {x} { debug.cmdr/validate {} 10 ; return {} }
proc ::cmdr::validate::str::validate {x} { debug.cmdr/validate {}    ; return $x }

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate 0.1
return
