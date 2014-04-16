## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate - Common utility commands.

# @@ Meta Begin
# Package cmdr::validate::common 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Utilities for validation types.
# Meta description Utilities for validation types.
# Meta subject {command line} {parameter validation}
# Meta subject {validation type} {type checking}
# Meta require {Tcl 8.5-}
# Meta require debug
# Meta require debug::caller
# @@ Meta End

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
    namespace export common
    namespace ensemble create
}

namespace eval ::cmdr::validate::common {
    namespace export \
	complete-enum complete-glob \
	fail fail-unknown-thing fail-known-thing \
	p-name lead-in
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate/common
debug level  cmdr/validate/common
debug prefix cmdr/validate/common {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## Different forms of validation failure messages

proc ::cmdr::validate::common::fail {p code type x {context {}}} {
    # Generic failure: "Expected foo, got x".
    debug.cmdr/validate/common {}

    append msg "Expected $type for [$p type] \"[p-name $p]\"$context,"
    append msg " got \"$x\""

    return -code error -errorcode [list CMDR VALIDATE {*}$code] $msg
}

proc ::cmdr::validate::common::fail-unknown-thing {p code type x {context {}}} {
    # Specific failure for a named thing: Expected existence, found it missing.
    debug.cmdr/validate/common {}

    append msg "Found a problem with [$p type] \"[p-name $p]\":"
    append msg " [lead-in $type] \"$x\" does not exist$context."
    append msg " Please use a different value."

    return -code error -errorcode [list CMDR VALIDATE {*}$code] $msg
}

proc ::cmdr::validate::common::fail-known-thing {p code type x {context {}}} {
    # Specific failure for a named thing: Expected non-existence, found a definition.
    debug.cmdr/validate/common {}

    append msg "Found a problem with [$p type] \"[p-name $p]\":"
    append msg " [lead-in $type] named \"$x\" already exists$context."
    append msg " Please use a different name."

    return -code error -errorcode [list CMDR VALIDATE {*}$code] $msg
}

# # ## ### ##### ######## ############# #####################
## Support commands for construction of messages.

proc ::cmdr::validate::common::lead-in {type} {
    if {[string match {A *}  $type] ||
	[string match {An *} $type]} {
	set lead {}
    } elseif {[string match {[aeiouAEIOU]*} $type]} {
	set lead {An }
    } else {
	set lead {A }
    }
    return $lead$type
}

proc ::cmdr::validate::common::p-name {p} {
    if {[$p type] eq "option"} {
	return [$p flag]
    } else {
	return [$p label]
    }
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::validate::common::complete-enum {choices nocase buffer} {
    # As a helper function for command completion printing anything
    # here would mix with the output of linenoise. Do that only on
    # explicit request (level 10).
    debug.cmdr/validate/common {} 10

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

    debug.cmdr/validate/common {= [join $candidates "\n= "]} 10
    return $candidates
}

proc ::cmdr::validate::common::complete-glob {filter buffer} {
    debug.cmdr/validate/common {} 10

    # Treat everything in the buffer as literal prefix.
    # Disable all glob special characters.
    regsub -all {(.)} $buffer {\\\1} buffer

    set candidates {}
    foreach path [glob -nocomplain ${buffer}*] {
	if {![{*}$filter $path]} continue
	lappend candidates $path
    }

    debug.cmdr/validate/common {= [join $candidates "\n= "]} 10
    return $candidates
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::common 1.2
return
