## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Convenience commands for terminal-based user interaction.

# @@ Meta Begin
# Package cmdr::ask 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Terminal-based user interaction commands.
# Meta description Commands to interact with the user in various
# Meta description simple ways, for a terminal.
# Meta subject {command line} tty interaction terminal
# Meta require {Tcl 8.5-}
# Meta require debug
# Meta require debug::caller
# Meta require cmdr::color
# Meta require try
# Meta require linenoise
# Meta require struct::matrix
# Meta require textutil::adjust
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::color
package require debug
package require debug::caller
package require linenoise
package require try
package require struct::matrix
package require textutil::adjust

namespace eval ::cmdr {
    namespace export ask
}
namespace eval ::cmdr::ask {
    namespace export string string/extended string* yn choose menu
    namespace ensemble create

    namespace import ::cmdr::color
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/ask
debug level  cmdr/ask
debug prefix cmdr/ask {[debug caller] | }

# # ## ### ##### ######## ############# #####################

proc ::cmdr::ask::string {query {default {}}} {
    debug.cmdr/ask {}

    Chop query {: }
    if {$default ne {}} {
	append query " \[[color good $default]\]"
    }
    # TODO: allow customization (string prompt string)
    append query {: }

    try {
	set response [Interact {*}[Fit $query 10]]
    } on error {e o} {
	if {$e eq "aborted"} {
	    error Interrupted error SIGTERM
	}
	return {*}${o} $e
    }
    if {($response eq {}) && ($default ne {})} {
	set response $default
    }
    return $response
}

proc ::cmdr::ask::string/extended {query args} {
    debug.cmdr/ask {}
    # accept  -history, -hidden, -complete
    # plus    -default
    # but not -prompt

    # for history ... integrate history load/save from file here?
    # -history is then not boolean, but path to history file.

    Ensure query :   ;# TODO: allow customization (string prompt string)
    append query { }

    set default {}
    set config {}
    foreach {o v} $args {
	switch -exact -- $o {
	    -history -
	    -hidden -
	    -complete {
		lappend config $o $v
	    }
	    -default {
		set default $v
	    }
	    default {
		return -code error "Bad option \"$o\", expected one of -history, -hidden, -prompt, or -default"
	    }
	}
    }
    try {
	set response [Interact {*}[Fit $query 10] {*}$config]
    } on error {e o} {
	if {$e eq "aborted"} {
	    error Interrupted error SIGTERM
	}
	return {*}${o} $e
    }
    if {($response eq {}) && ($default ne {})} {
	set response $default
    }
    return $response
}

proc ::cmdr::ask::string* {query} {
    debug.cmdr/ask {}

    Chop   query {: }
    append query {: }   ;# TODO: allow customization (string prompt string)

    try {
	set response [Interact {*}[Fit $query 10] -hidden 1]
    } on error {e o} {
	if {$e eq "aborted"} {
	    error Interrupted error SIGTERM
	}
	return {*}${o} $e
    }
    return $response
}

proc ::cmdr::ask::yn {query {default yes}} {
    debug.cmdr/ask {}

    Chop query {: }
    append query [expr {$default
			? " \[[color yes Y]n\]"
			: " \[y[color no N]\]"}]
    # TODO: allow customization (bool prompt string)
    append query {: }

    lassign [Fit $query 5] header prompt
    while {1} {
	try {
	    set response \
		[Interact $header $prompt \
		     -complete [namespace code {Complete {yes no false true on off 0 1} 1}]]
		     
	} on error {e o} {
	    if {$e eq "aborted"} {
		error Interrupted error SIGTERM
	    }
	    return {*}${o} $e
	}
	if {$response eq {}} { set response $default }
	if {[::string is bool $response]} break
	puts stdout [Wrap "You must choose \"yes\" or \"no\""]
    }

    return $response
}

proc ::cmdr::ask::choose {query choices {default {}}} {
    debug.cmdr/ask {}

    set hasdefault [expr {$default in $choices}]

    set lc [linsert [join $choices {, }] end-1 or]
    if {$hasdefault} {
	lappend map $default [color good $default]
	set lc [::string map $map $lc]
    }

    Chop   query {: }
    append query " ($lc)"
    # TODO: allow customization (choose prompt string)
    append query {: }

    lassign [Fit $query 5] header prompt

    while {1} {
	try {
	    set response \
		[Interact $header $prompt \
		     -complete [namespace code [list Complete $choices 0]]]
	} on error {e o} {
	    if {$e eq "aborted"} {
		error Interrupted error SIGTERM
	    }
	    return {*}${o} $e
	}
	if {($response eq {}) && $hasdefault} {
	    set response $default
	}
	if {$response in $choices} break
	puts stdout [Wrap "You must choose one of $lc"]
    }

    return $response
}

proc ::cmdr::ask::menu {header prompt choices {default {}}} {
    debug.cmdr/ask {}

    Chop   prompt {? }
    # TODO: allow customization (menu prompt string)
    append prompt {? }

    set hasdefault [expr {$default in $choices}]

    # Full list of choices is the choicces themselves, plus the numeric
    # indices we can address them by. This is for the prompt
    # completion callback below.
    set fullchoices $choices

    # Build table (2-column matrix)
    struct::matrix [namespace current]::M
    M add columns 2
    set n 1
    foreach c $choices {
	if {$default eq $c} {
	    set c [color good $c]
	}

	M add row [list ${n}. $c]
	lappend fullchoices $n
	incr n
    }
    set Mstr [M format 2string]
    M destroy

    # Format the prompt
    lassign [Fit $prompt 5] pheader prompt

    # Interaction loop
    while {1} {
	if {$header ne {}} {puts stdout $header}
	puts stdout $Mstr

	try {
	    set response \
		[Interact $pheader $prompt \
		     -complete [namespace code [list Complete $fullchoices 0]]]
	} on error {e o} {
	    if {$e eq "aborted"} {
		error Interrupted error SIGTERM
	    }
	    return {*}${o} $e
	}
	if {($response eq {}) && $hasdefault} {
	    set response $default
	}

	if {$response in $choices} break

	if {[::string is int $response]} {
	    # Inserting a dummy to handle indexing from 1...
	    set response [lindex [linsert $choices 0 {}] $response]
	    if {$response in $choices} break
	}

	puts stdout [Wrap "You must choose one of the above"]
    }

    return $response
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::ask::Complete {choices nocase buffer} {
    debug.cmdr/ask {}

    if {$buffer eq {}} {
	return $choices
    }

    if {$nocase} {
	set buffer [::string tolower $buffer]
    }

    set candidates {}
    foreach c $choices {
	if {![::string match ${buffer}* $c]} continue
	lappend candidates $c
    }
    return $candidates
}

proc ::cmdr::ask::Interact {header prompt args} {
    debug.cmdr/ask {}
    if {$header ne {}} { puts $header }
    return [linenoise prompt {*}$args -prompt $prompt]
}

proc ::cmdr::ask::Wrap {text {down 0}} {
    debug.cmdr/ask {}
    global env
    if {[info exists env(CMDR_NO_WRAP)]} {
	return $text
    }
    set c [expr {[linenoise columns]-$down}]
    return [textutil::adjust::adjust $text -length $c -strictlength 1]
}

proc ::cmdr::ask::Fit {prompt space} {
    debug.cmdr/ask {}
    # Similar to Wrap, except with a split following.
    global env
    if {[info exists env(CMDR_NO_WRAP)]} {
	return [list {} $prompt]
    }

    set w [expr {[linenoise columns] - $space }]
    # we leave space for some characters to be entered.

    if {[::string length $prompt] < $w} {
	return [list {} $prompt]
    }

    set prompt [textutil::adjust::adjust $prompt -length $w -strictlength 1]
    set prompt [split $prompt \n]
    set header [join [lrange $prompt 0 end-1] \n]
    set prompt [lindex $prompt end]
    # Alternate code for the last 3 lines, more cryptic.
    # set header [join [lreverse [lassign [lreverse [split $prompt \n]] prompt]] \n]
    append prompt { }

    return [list $header $prompt]
}

proc ::cmdr::ask::Chop {var charset} {
    debug.cmdr/ask {}
    upvar 1 $var text
    set text [::string trimright $text $charset]

    debug.cmdr/ask {/done ==> ($text)}
    return
}

proc ::cmdr::ask::Ensure {var char} {
    debug.cmdr/ask {}
    upvar 1 $var text
    if {[::string index $text end] eq $char} {
	debug.cmdr/ask {/done, no change}
	return
    }
    append text $char

    debug.cmdr/ask {/done ==> ($text)}
    return
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::ask 1
