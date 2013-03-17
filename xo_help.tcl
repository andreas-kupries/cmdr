## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Help - Help support.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require textutil::adjust
package require xo::util

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::xo {
    namespace export help
    namespace ensemble create
}

namespace eval ::xo::help {
    namespace export query format
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

proc ::xo::help::query {actor words} {
    # Resolve chain of words (command name path) to the actor
    # responsible for that command, starting from the specified actor.
    # This is very much a convenience command.

    foreach word $words {
	set actor [$actor lookup $word]
    }
    return [$actor help $words]
}

# # ## ### ##### ######## ############# #####################

namespace eval ::xo::help::format {
    namespace export plain
    namespace ensemble create
}

# Alternate formats:
# List
# Short
# ... entirely different formats (json, .rst, docopts, ...)
#

proc ::xo::help::format::plain {width help} {
    # help = dict (name -> command)
    dict for {cmd desc} $help {
	lappend result [Plain $width $cmd $desc]
    }
    return [join $result \n]
}

proc ::xo::help::format::Plain {width name command} {
    # command = list ('desc'      -> description
    #                 'options'   -> options
    #                 'arguments' -> arguments)

    dict with command {} ; # -> desc, options, arguments

    # options   = list (option...)
    # option    = dict (name -> description)
    # arguments = dict (name -> argdesc)
    # argdesc   = dict ('code' -> code
    #                   'desc' -> description)
    # code in {
    #     +		<=> required
    #     ?		<=> optional
    #     +*	<=> required splat
    #     ?* 	<=> optional splat
    # }

    # Short line.
    lappend lines "[join $name] [HasOptions $options][Arguments $arguments]"

    # plus description
    lappend lines [textutil::adjust::indent \
		       [textutil::adjust::adjust $desc \
			    -length [expr {$width - 5}] \
			    -strictlength 1] \
		       {    }]

    # plus per-option descriptions
    if {[dict size $options]} {
	set onames {}
	set odefs {}
	dict for {oname ohelp} $options {
	    lappend onames $oname
	    lappend odefs $ohelp
	}
	DefList $width $onames $odefs
    }

    # plus per-argument descriptions
    if {[dict size $arguments]} {
	set anames {}
	set adefs  {}
	dict for {aname v} $arguments {
	    dict with v {} ; # -> code, desc
	    lappend anames $aname
	    lappend adefs  $desc
	}
	DefList $width $anames $adefs
    }
    lappend lines ""
    return [join $lines \n]
}

proc ::xo::help::format::DefList {width labels defs} {
    upvar 1 lines lines

    set labels [xo util padr $labels]

    set  nl [string length [lindex $labels 0]]
    incr nl 5
    set blank [string repeat { } $nl]

    lappend lines ""
    foreach l $labels def $defs {
	# FUTURE: Consider paragraph breaks in $def (\n\n),
	#         and format them separately.

	lappend lines "    $l [textutil::adjust::indent \
		       [textutil::adjust::adjust $def \
			    -length [expr {$width - $nl}] \
			    -strictlength 1] \
		       $blank 1]"
    }
    return
}

proc ::xo::help::format::Arguments {arguments} {
    set result {}
    foreach {a v} $arguments {
	dict with v {} ; # -> code, desc
	switch -exact -- $code {
	    +  { set text "$a" }
	    ?  { set text "?${a}?" }
	    +* { set text "${a}..." }
	    ?* { set text "?${a}...?" }
	}
	lappend result $text
    }
    return [join $result]
}

proc ::xo::help::format::HasOptions {options} {
    if {[dict size $options]} {
	return "\[OPTIONS\] "
    } else {
	return {}
    }
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::help 0.1
