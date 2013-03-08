## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Validate - Definition of core validation classes.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::xo {
    namespace export validate
    namespace ensemble create
}

namespace eval ::xo::validate {
    namespace export boolean integer identity Fail
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

proc ::xo::validate::Fail {code type x} {
    return -code error -errorcode [list XO VALIDATE {*}$code] \
	"Expected $type, got \"$x\""
}

# # ## ### ##### ######## ############# #####################

namespace eval ::xo::validate::boolean {
    namespace export default validate
    namespace ensemble create
    namespace import ::xo::validate::Fail
}

proc ::xo::validate::boolean::default {} { return no }

proc ::xo::validate::boolean::validate {x} {
    if {[string is integer -strict $x]} { return $x }
    Fail BOOLEAN "a boolean" $x
}

# # ## ### ##### ######## ############# #####################

namespace eval ::xo::validate::integer {
    namespace export default validate
    namespace ensemble create
    namespace import ::xo::validate::Fail
}

proc ::xo::validate::integer::default {} { return 0 }

proc ::xo::validate::integer::validate {x} {
    if {[string is integer -strict $x]} { return $x }
    Fail INTEGER "an integer" $x
}

# # ## ### ##### ######## ############# #####################

namespace eval ::xo::validate::identity {
    namespace export default validate
    namespace ensemble create
}

proc ::xo::validate::identity::default {} { return {} }
proc ::xo::validate::identity::validate {x} { return $x }

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::validate 0.1
