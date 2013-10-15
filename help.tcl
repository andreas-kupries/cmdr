## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Help - Help support.

# @@ Meta Begin
# Package cmdr::help 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Internal. Utilities for help text formatting and setup.
# Meta description Internal. Utilities for help text formatting and setup.
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require debug
# Meta require debug::caller
# Meta require lambda
# Meta require linenoise
# Meta require textutil::adjust
# Meta require cmdr::util
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require debug
package require debug::caller
package require lambda
package require linenoise
package require textutil::adjust
package require cmdr::util

# # ## ### ##### ######## ############# #####################

debug define cmdr/help
debug level  cmdr/help
debug prefix cmdr/help {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export help
    namespace ensemble create
}

namespace eval ::cmdr::help {
    namespace export query format auto
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::help::query {actor words} {
    debug.cmdr/help {}
    # Resolve chain of words (command name path) to the actor
    # responsible for that command, starting from the specified actor.
    # This is very much a convenience command.

    set n -1
    foreach word $words {
	if {[info object class $actor] ne "::cmdr::officer"} {
	    # Privates do not have subordinates to look up.
	    # We now have a bad command name argument to help.

	    set prefix [lrange $words 0 $n]
	    return -code error \
		-errorcode [list CMDR ACTION BAD $word] \
		"The command \"$prefix\" has no sub-commands, unexpected word \"$word\""
	}

	set actor [$actor lookup $word]
	incr n
    }
    return [$actor help $words]
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::help::auto {actor} {
    debug.cmdr/help {}
    # Generate a standard help command for any actor, and add it dynamically.

    # Auto create options based on the help formats found installed
    foreach c [info commands {::cmdr::help::format::[a-z]*}] {
	set format [namespace tail $c]
	lappend formats --$format
	lappend options [string map [list @c@ $format] {
	    option @c@ {
		Activate @c@ form of the help.
	    } {
		presence
		when-set [lambda {p x} { $p config @format set @c@ }]
	    }}]
    }

    # Standard option for line width to format against.
    lappend options {
	option width {
	    The line width to format the help for.
	    Defaults to the terminal width, or 80 when
	    no terminal is available.
	} {
	    alias w
	    validate integer ;# better: integer > 0, or even > 10
	    generate [lambda {p} { linenoise columns }]
	}
    }
    lappend map @formats@ [linsert [join $formats {, }] end-1 and]
    lappend map @options@ [join $options \n]
    lappend map @actor@   $actor

    $actor learn [string map $map {private help {
	description {
	    Retrieve help for a command or command set.
	    Without arguments help for all commands is given.
	    The default format is --full.
	}
	@options@
	state format {
	    Format of the help to generate.
	    This field is fed by the options @formats@.
	} { default {} }
	input cmdname {
	    The entire command line, the name of the
	    command to get help for. This can be several
	    words.
	} { optional ; list }
    } {::cmdr::help::auto-help @actor@}}]
    return
}

proc ::cmdr::help::auto-help {actor config} {
    debug.cmdr/help {}

    set width  [$config @width]
    set words  [$config @cmdname]
    set format [$config @format]

    if {$format eq {}} {
	# Default depends on the presence of additional arguments, i.e. if a specific command is asked for, or not.
	if {[llength $words]} {
	    set format full
	} else {
	    set format list
	}
    }

    puts [format $format $width [DictSort [query $actor $words]]]
    return
}

proc ::cmdr::help::DictSort {dict} {
    set r {}
    foreach k [lsort -dict [dict keys $dict]] {
	lappend r $k [dict get $dict $k]
    }
    return $r
}

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::help::format {
    namespace export full list short
    namespace ensemble create
}

# Alternate formats:
# List
# Short
# ... entirely different formats (json, .rst, docopts, ...)
#

proc ::cmdr::help::format::full {width help} {
    debug.cmdr/help {}

    # help = dict (name -> command)
    set result {}
    dict for {cmd desc} $help {
	lappend result [Full $width $cmd $desc]
    }
    return [join $result \n]
}

proc ::cmdr::help::format::Full {width name command} {
    # Data structure: see config.tcl,  method 'help'.
    # Data structure: see private.tcl, method 'help'.

    dict with command {} ; # -> desc, options, arguments, parameters

    # Short line.
    lappend lines \
	[string trimright \
	     "[join $name] [HasOptions $options][Arguments $arguments $parameters]"]

    if {$desc ne {}} {
	# plus description
	set w [expr {$width - 5}]
	set w [expr {$w < 1 ? 1 : $w}]
	lappend lines [textutil::adjust::indent \
			   [textutil::adjust::adjust $desc \
				-length $w -strictlength 1] \
			   {    }]
    }

    # plus per-option descriptions (sort by flag name)
    if {[dict size $options]} {
	set onames {}
	set odefs  {}
	foreach {oname ohelp} [::cmdr::help::DictSort $options] {
	    lappend onames $oname
	    lappend odefs  $ohelp
	}
	DefList $width $onames $odefs
    }

    # plus per-argument descriptions (keep in cmdline order)
    if {[llength $arguments]} {
	set anames {}
	set adefs  {}
	foreach aname $arguments {
	    set v [dict get $parameters $aname]
	    dict with v {} ; # -> code, description, label
	    lappend anames $label
	    lappend adefs  $description
	}
	DefList $width $anames $adefs
    }
    lappend lines ""
    return [join $lines \n]
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::help::format::list {width help} {
    debug.cmdr/help {}

    # help = dict (name -> command)
    set result {}
    dict for {cmd desc} $help {
	lappend result [List $width $cmd $desc]
    }
    return [join $result \n]
}

proc ::cmdr::help::format::List {width name command} {
    # Data structure: see config.tcl,  method 'help'.
    # Data structure: see private.tcl, method 'help'.

    dict with command {} ; # -> desc, options, arguments, parameters

    # Short line.
    lappend lines \
	[string trimright \
	     "    [join $name] [HasOptions $options][Arguments $arguments $parameters]"]
    return [join $lines \n]
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::help::format::short {width help} {
    debug.cmdr/help {}

    # help = dict (name -> command)
    set result {}
    dict for {cmd desc} $help {
	lappend result [Short $width $cmd $desc]
    }
    return [join $result \n]
}

proc ::cmdr::help::format::Short {width name command} {
    # Data structure: see config.tcl,  method 'help'.
    # Data structure: see private.tcl, method 'help'.

    dict with command {} ; # -> desc, options, arguments, parameters

    # Short line.
    lappend lines \
	[string trimright \
	     "[join $name] [HasOptions $options][Arguments $arguments $parameters]"]

    if {$desc ne {}} {
	# plus description
	set w [expr {$width - 5}]
	set w [expr {$w < 1 ? 1 : $w}]
	lappend lines [textutil::adjust::indent \
			   [textutil::adjust::adjust $desc \
				-length $w -strictlength 1] \
			   {    }]
    }
    lappend lines ""
    return [join $lines \n]
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::help::format::DefList {width labels defs} {
    upvar 1 lines lines

    set labels [cmdr util padr $labels]

    set  nl [string length [lindex $labels 0]]
    incr nl 5
    set blank [string repeat { } $nl]

    lappend lines ""
    foreach l $labels def $defs {
	# FUTURE: Consider paragraph breaks in $def (\n\n),
	#         and format them separately.
	set w [expr {$width - $nl}]
	set w [expr {$w < 1 ? 1 : $w}]
	lappend lines "    $l [textutil::adjust::indent \
		       [textutil::adjust::adjust $def \
			    -length $w -strictlength 1] \
		       $blank 1]"
    }
    return
}

proc ::cmdr::help::format::Arguments {arguments parameters} {
    set result {}
    foreach a $arguments {
	set v [dict get $parameters $a]
	dict with v {} ; # -> code, desc, label
	switch -exact -- $code {
	    +  { set text "$label" }
	    ?  { set text "?${label}?" }
	    +* { set text "${label}..." }
	    ?* { set text "?${label}...?" }
	}
	lappend result $text
    }
    return [join $result]
}

proc ::cmdr::help::format::HasOptions {options} {
    if {[dict size $options]} {
	return "\[OPTIONS\] "
    } else {
	return {}
    }
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::help 0.4
