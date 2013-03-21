## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Validate - Definition of core validation classes.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::xo {
    namespace export validate
    namespace ensemble create
}

namespace eval ::xo::validate {
    namespace export boolean integer identity \
	fail complete-enum config
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

proc ::xo::validate::fail {code type x} {
    return -code error -errorcode [list XO VALIDATE {*}$code] \
	"Expected $type, got \"$x\""
}

proc ::xo::validate::complete-enum {choices nocase buffer} {
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
    return $candidates
}

# # ## ### ##### ######## ############# #####################

namespace eval ::xo::validate::boolean {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::xo::validate::fail
    namespace import ::xo::validate::complete-enum
}

proc ::xo::validate::boolean::default  {}  { return no }
proc ::xo::validate::boolean::release  {x} { return }

proc ::xo::validate::boolean::complete {x} {
    return [complete-enum {yes no false true on off 0 1} 1 $x]
}

proc ::xo::validate::boolean::validate {x} {
    if {[string is boolean -strict $x]} { return $x }
    fail BOOLEAN "a boolean" $x
}


# # ## ### ##### ######## ############# #####################

namespace eval ::xo::validate::integer {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::xo::validate::fail
}

proc ::xo::validate::integer::default  {}  { return 0 }
proc ::xo::validate::integer::release  {x} { return }
proc ::xo::validate::integer::complete {x} { return {} }
proc ::xo::validate::integer::validate {x} {
    if {[string is integer -strict $x]} { return $x }
    fail INTEGER "an integer" $x
}

# # ## ### ##### ######## ############# #####################

namespace eval ::xo::validate::identity {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::xo::validate::identity::default  {}  { return {} }
proc ::xo::validate::identity::release  {x} { return }
proc ::xo::validate::identity::complete {x} { return {} }
proc ::xo::validate::identity::validate {x} { return $x }

# # ## ### ##### ######## ############# #####################

namespace eval ::xo::validate::pass {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::xo::validate::pass::default  {}  { return {} }
proc ::xo::validate::pass::release  {x} { return }
proc ::xo::validate::pass::complete {x} { return {} }
proc ::xo::validate::pass::validate {x} { return $x }

# # ## ### ##### ######## ############# #####################

namespace eval ::xo::validate::str {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::xo::validate::str::default  {}  { return {} }
proc ::xo::validate::str::release  {x} { return }
proc ::xo::validate::str::complete {x} { return {} }
proc ::xo::validate::str::validate {x} { return $x }

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::validate 0.1
