## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Validate - Definition of core validation classes.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5

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

proc ::cmdr::validate::fail {code type x} {
    return -code error -errorcode [list XO VALIDATE {*}$code] \
	"Expected $type, got \"$x\""
}

proc ::cmdr::validate::complete-enum {choices nocase buffer} {
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

namespace eval ::cmdr::validate::boolean {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::fail
    namespace import ::cmdr::validate::complete-enum
}

proc ::cmdr::validate::boolean::default  {}  { return no }
proc ::cmdr::validate::boolean::release  {x} { return }

proc ::cmdr::validate::boolean::complete {x} {
    return [complete-enum {yes no false true on off 0 1} 1 $x]
}

proc ::cmdr::validate::boolean::validate {x} {
    if {[string is boolean -strict $x]} { return $x }
    fail BOOLEAN "a boolean" $x
}


# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::validate::integer {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::fail
}

proc ::cmdr::validate::integer::default  {}  { return 0 }
proc ::cmdr::validate::integer::release  {x} { return }
proc ::cmdr::validate::integer::complete {x} { return {} }
proc ::cmdr::validate::integer::validate {x} {
    if {[string is integer -strict $x]} { return $x }
    fail INTEGER "an integer" $x
}

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::validate::identity {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::identity::default  {}  { return {} }
proc ::cmdr::validate::identity::release  {x} { return }
proc ::cmdr::validate::identity::complete {x} { return {} }
proc ::cmdr::validate::identity::validate {x} { return $x }

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::validate::pass {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::pass::default  {}  { return {} }
proc ::cmdr::validate::pass::release  {x} { return }
proc ::cmdr::validate::pass::complete {x} { return {} }
proc ::cmdr::validate::pass::validate {x} { return $x }

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::validate::str {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::str::default  {}  { return {} }
proc ::cmdr::validate::str::release  {x} { return }
proc ::cmdr::validate::str::complete {x} { return {} }
proc ::cmdr::validate::str::validate {x} { return $x }

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate 0.1
