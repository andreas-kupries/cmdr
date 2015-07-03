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
	complete-enum complete-glob complete-substr \
	ok-directory strip-lead-in lead-in fail \
	fail-unknown-thing fail-unknown-thing-msg fail-unknown-simple fail-unknown-simple-msg \
	fail-known-thing   fail-known-thing-msg   fail-known-simple   fail-known-simple-msg
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

    append msg "Expected $type for [$p type] \"[$p the-name]\"$context,"
    append msg " got \"$x\""

    return -code error -errorcode [list CMDR VALIDATE {*}$code] $msg
}

proc ::cmdr::validate::common::fail-unknown-thing {p code type x {context {}}} {
    # Specific failure for a named thing: Expected existence, found it missing.
    debug.cmdr/validate/common {}

    append msg "Found a problem with [$p type] \"[$p the-name]\":"
    append msg " [lead-in $type] \"$x\" does not exist$context."
    append msg " Please use a different value."

    return -code error -errorcode [list CMDR VALIDATE {*}$code] $msg
}

proc ::cmdr::validate::common::fail-unknown-thing-msg {usermsg p code type x {context {}}} {
    # Specific failure for a named thing: Expected existence, found it missing.
    # Takes a custom message to place into the error.
    debug.cmdr/validate/common {}

    append msg "Found a problem with [$p type] \"[$p the-name]\":"
    append msg " [lead-in $type] \"$x\" does not exist$context."
    append msg " " $usermsg "."

    return -code error -errorcode [list CMDR VALIDATE {*}$code] $msg
}

proc ::cmdr::validate::common::fail-unknown-simple {p code type x {context {}}} {
    # Specific failure for a named thing: Expected existence, found it missing.
    # Simplified intro, leaving out the parameter information (input|option, name)
    debug.cmdr/validate/common {}

    append msg "[string to-title [strip-lead-in $type]] \"$x\" does not exist$context."
    append msg " Please use a different value."

    return -code error -errorcode [list CMDR VALIDATE {*}$code] $msg
}

proc ::cmdr::validate::common::fail-unknown-simple-msg {usermsg p code type x {context {}}} {
    # Specific failure for a named thing: Expected existence, found it missing.
    # Takes a custom message to place into the error.
    # Simplified intro, leaving out the parameter information (input|option, name)
    debug.cmdr/validate/common {}

    append msg "[string totitle [strip-lead-in $type]] \"$x\" does not exist$context."
    append msg " " $usermsg "."

    return -code error -errorcode [list CMDR VALIDATE {*}$code] $msg
}

proc ::cmdr::validate::common::fail-known-thing {p code type x {context {}}} {
    # Specific failure for a named thing: Expected non-existence, found a definition.
    debug.cmdr/validate/common {}

    append msg "Found a problem with [$p type] \"[$p the-name]\":"
    append msg " [lead-in $type] named \"$x\" already exists$context."
    append msg " Please use a different name."

    return -code error -errorcode [list CMDR VALIDATE {*}$code] $msg
}

proc ::cmdr::validate::common::fail-known-thing-msg {usermsg p code type x {context {}}} {
    # Specific failure for a named thing: Expected non-existence, found a definition.
    debug.cmdr/validate/common {}

    append msg "Found a problem with [$p type] \"[$p the-name]\":"
    append msg " [lead-in $type] named \"$x\" already exists$context."
    append msg " " $usermsg "."

    return -code error -errorcode [list CMDR VALIDATE {*}$code] $msg
}

proc ::cmdr::validate::common::fail-known-simple {p code type x {context {}}} {
    # Specific failure for a named thing: Expected non-existence, found a definition.
    # Simplified intro, leaving out the parameter information (input|option, name)
    debug.cmdr/validate/common {}

    append msg " [string totitle [strip-lead-in $type]] named \"$x\" already exists$context."
    append msg " Please use a different name."

    return -code error -errorcode [list CMDR VALIDATE {*}$code] $msg
}

proc ::cmdr::validate::common::fail-known-simple-msg {usermsg p code type x {context {}}} {
    # Specific failure for a named thing: Expected non-existence, found a definition.
    # Simplified intro, leaving out the parameter information (input|option, name)
    debug.cmdr/validate/common {}

    append msg " [string totitle [strip-lead-in $type]] named \"$x\" already exists$context."
    append msg " " $usermsg "."

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

proc ::cmdr::validate::common::strip-lead-in {type} {
    if {[string match {A *} $type]} {
	return [string range $type 2 end]
    } elseif {[string match {An *} $type]} {
	return [string range $type 3 end]
    } else {
	return $type
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

    if {($nocase eq "nocase") || $nocase} {
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

proc ::cmdr::validate::common::complete-substr {choices nocase buffer} {
    # As a helper function for validation printing anything
    # here would mix with the output of linenoise. Do that only on
    # explicit request (level 10).
    debug.cmdr/validate/common {} 10

    if {$buffer eq {}} {
	return $choices
    }

    if {($nocase eq "nocase") || $nocase} {
	set buffer [string tolower $buffer]
    }

    set candidates {}
    foreach c $choices {
	if {![string match *${buffer}* $c]} continue
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

proc ::cmdr::validate::common::ok-directory {path} {
    if {![file exists $path]} {
	# The directory is allowed to not exist if its parent
	# directory exists and is writable.
	# Note: Prevent us from walking up the chain if the directory
	# has no parent.
	# Note 2: Switch to absolute notation if path is the relative
	# name of the CWD (i.e. ".").
	if {$path eq "."} {
	    set path [pwd]
	}
	set up [file dirname $path]
	if {$up eq $path} {
	    # Reached root (/, x:, x:/), found it missing, stop & fail.
	    return 0
	}
	return [ok-directory $up]
    }
    if {![file isdirectory $path]} {return 0}
    if {![file writable    $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::common 1.3
return
