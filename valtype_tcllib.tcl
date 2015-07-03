## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Support for wrapping Tcllib valtypes for use in cmdr.

# @@ Meta Begin
# Package cmdr::validate::valtype-support 1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Support for wrapping Tcllib valtypes into Cmdr validation typs.
# Meta description Support for wrapping Tcllib valtypes into Cmdr validation typs.
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require {cmdr::validate::common 1.2}
# Meta require debug
# Meta require debug::caller
# Meta require try
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::validate::common 1.2
package require debug
package require debug::caller
package require try

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export validate
    namespace ensemble create
}
namespace eval ::cmdr::validate {
    namespace export valtype-support
    namespace ensemble create
}
namespace eval ::cmdr::validate::valtype-support {
    namespace export default wrap
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate/valtype-support
debug level  cmdr/validate/valtype-support
debug prefix cmdr/validate/valtype-support {[debug caller] | }

# # ## ### ##### ######## ############# #####################
##

proc ::cmdr::validate::valtype-support::wrap {valtype} {
    debug.cmdr/validate/valtype-support {}

    lappend map @@@@ $valtype
    lappend map @@^^ [regsub {::} $valtype /]

    namespace eval ::cmdr {
	namespace export validate
	namespace ensemble create
    }
    namespace eval ::cmdr::validate {
	namespace export valtype
	namespace ensemble create
    }

    if {![string match *::* $valtype]} {
	# Simple.
	namespace eval ::cmdr::validate::valtype [string map $map {
	    namespace export @@@@
	    namespace ensemble create
	}]
    } else {
	# Namespaces. Split into parts and generate a chain of namespace ensembles.

	set spaces [split [regsub {::} $valtype {:}] :]

	foreach pre [lrange $spaces 0 end-1] post [lrange $spaces 1 end-1] {
	    append prefix ::$pre
	    namespace eval ::cmdr::validate::valtype$prefix [string map [list @@@@ $post] {
		namespace export @@@@
		namespace ensemble create
	    }]
	}
    }

    namespace eval ::cmdr::validate::valtype::${valtype} {
	namespace export default release default complete validate
	namespace ensemble create
    }

    uplevel \#0 [string map $map {
	package require valtype::@@@@
	package require debug
	package require debug::caller

	debug define cmdr/validate/valtype/@@^^
	debug level  cmdr/validate/valtype/@@^^
	debug prefix cmdr/validate/valtype/@@^^ {[debug caller] | }

	proc ::cmdr::validate::valtype::@@@@::release  {p x} { return }
	proc ::cmdr::validate::valtype::@@@@::default  {p}   { return {} }
	proc ::cmdr::validate::valtype::@@@@::complete {p x} {
	    debug.cmdr/validate/valtype/@@^^ {} 10
	    # No completion
	    return {}
	}
	proc ::cmdr::validate::valtype::@@@@::validate {p x} {
	    debug.cmdr/validate/valtype/@@^^ {}
	    return [::valtype::@@@@ validate $x]
	}
    }]

    debug.cmdr/validate/valtype-support {/done}
    return
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::valtype-support 1
return
