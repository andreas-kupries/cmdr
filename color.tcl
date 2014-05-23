## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Convenience commands for colored text in terminals.

# @@ Meta Begin
# Package cmdr::color 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Text colorization for terminal output
# Meta description Commands to manage colored text in terminal
# Meta description output
# Meta subject {command line} terminal color {text colors}
# Meta require {Tcl 8.5-}
# Meta require debug
# Meta require debug::caller
# Meta require cmdr::tty
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require debug
package require debug::caller
package require cmdr::tty

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::color {
    namespace export activate active define
    namespace ensemble create \
	-unknown [namespace current]::Unknown
    # Note, the option ensures that all unknown methods are treated as
    # (list of) color codes to apply to some text, effectively
    # creating the virtual command
    #
    #    ::cmdr::color <codelist> <text>
    ##

    namespace import ::cmdr::tty
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/color
debug level  cmdr/color
debug prefix cmdr/color {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## TODO undef?
## TODO multi-def (load)
## TODO get (display)
## officer and private for std commands (show, define).

proc ::cmdr::color::activate {{flag 1}} {
    debug.cmdr/color {}
    variable active $flag
    return
}

proc ::cmdr::color::active {} {
    debug.cmdr/color {}
    variable active
    return  $active
}

proc ::cmdr::color::define {name spec} {
    debug.cmdr/color {}
    variable def
    variable char
    # TODO: spec may be
    # => reference to other color name, or
    # => raw control sequence, or
    # => RGB spec.

    # Syntax:
    # ref = anything already found as key in the database.
    # rgb = 
    # raw = 

    if {[dict exists $def $spec]} {
	if {$spec eq $name} {
	    return -code error \
		-errorcode [list CMDR COLOR CIRCLE $name] \
		"Rejected self-referential definition of \"$name\""
	}
	debug.cmdr/color {reference, resolved => [S [dict get $char $spec]]}
	dict set def  $name $spec
	dict set char $name [dict get $char $spec]
	return
    }

    if {[regexp {^%(\d+),(\d+),(\d+)$} $spec -> r g b]} {
	# R, G, B all in range 0..5
	set r [Clamp $r]
	set g [Clamp $g]
	set b [Clamp $b]
	# 256 mapping
	# code = 16 + 36R + 6G + B --> [16..236]
	set code [expr {16 + 36*$r + 6*$g + $b}]
	debug.cmdr/color {RGB encoded => [S [C $code]]}
	dict set def  $name $spec
	dict set char $name [C $code]
	return

	# Legacy mapping
	# R,G,B mapping 0,1 --> 0, 2,3 --> 1, 4,5 --> 2
	# bold mapping: 0,1,2 --> 0,1,1 (set if any of R, G, B)
	# code = 8bold + R + 2G + 4B
	#      = 8, for R==G==B != 0, special case.
    }

    # Raw control sequence, simply save
    dict set def  $name $spec
    dict set char $name $spec
    return
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::color::Unknown {cmd codes text} {
    list [namespace current]::Apply $codes
}

proc ::cmdr::color::Apply {codes text} {
    debug.cmdr/color {}

    variable active
    if {!$active} {
	debug.cmdr/color {not active}
	return $text
    }

    variable char
    foreach c $codes {
	if {[dict exists $char $c]} {
	    return -code error \
		-errorcode [list CMDR COLOR UNKNOWN $c] \
		"Expected a color name, got \"$c\""
	}
	append r [dict get $char $c]
    }
    append r $text
    append r [dict get $char reset]

    debug.cmdr/color {/done}
    return $r
}

proc ::cmdr::color::S {text} {
    # quote all non-printable characters (< space, > ~)
    variable smap
    return [string map $smap $text]
}

proc ::cmdr::color::C {args} {
    return \033\[[join $args \;]m
}

proc ::cmdr::color::Clamp {x} {
    if {$x < 0} { return 0 }
    if {$x > 5} { return 5 }
    return $x
}

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::color {
    # Boolean flag controlling use of color sequences.
    # Default based on tty-ness of stdout. Active if yes.
    variable active [tty stdout]

    # Database (dictionary) of standard colors and associated codes.
    # Based on the standard ANSI colors (16-color terminal). The two
    # dictionaries hold the user-level specification and the
    # full-resolved character sequence.

    variable def  {}
    variable char {}

    # Colors. Foreground/Text.
    define  black        [C 30]  ; # Black  
    define  red          [C 31]  ; # Red    
    define  green        [C 32]  ; # Green  
    define  yellow       [C 33]  ; # Yellow 
    define  blue         [C 34]  ; # Blue   
    define  magenta      [C 35]  ; # Magenta
    define  cyan         [C 36]  ; # Cyan   
    define  white        [C 37]  ; # White  
    define  default      [C 39]  ; # Default (Black)

    # Colors. Background.
    define  bg-black     [C 40]  ; # Black  
    define  bg-red       [C 41]  ; # Red    
    define  bg-green     [C 42]  ; # Green  
    define  bg-yellow    [C 43]  ; # Yellow 
    define  bg-blue      [C 44]  ; # Blue   
    define  bg-magenta   [C 45]  ; # Magenta
    define  bg-cyan      [C 46]  ; # Cyan   
    define  bg-white     [C 47]  ; # White  
    define  bg-default   [C 49]  ; # Default (Transparent)

    # Non-color attributes. Activation.
    define  bold         [C  1]  ; # Bold  
    define  dim          [C  2]  ; # Dim
    define  italic       [C  3]  ; # Italics      
    define  underline    [C  4]  ; # Underscore   
    define  blink        [C  5]  ; # Blink
    define  revers       [C  7]  ; # Reverse      
    define  hidden       [C  8]  ; # Hidden
    define  strike       [C  9]  ; # StrikeThrough

    # Non-color attributes. Deactivation.
    define  no-bold      [C 22]  ; # Bold  
    define  no-dim       [C __]  ; # Dim
    define  no-italic    [C 23]  ; # Italics      
    define  no-underline [C 24]  ; # Underscore   
    define  no-blink     [C 25]  ; # Blink
    define  no-revers    [C 27]  ; # Reverse      
    define  no-hidden    [C 28]  ; # Hidden
    define  no-strike    [C 29]  ; # StrikeThrough

    # Remainder
    define  reset        [C  0]  ; # Reset

    # And now the standard symbolic names

    define  confirm red
    define  error   red
    define  warning yellow
    define  note    blue
    define  good    green
    define  name    blue

    # header command stopped advisory crashed failure success name prompt table warning
    # bl/whi bl/yel  bl/grey bl/yel   bl/red  bl/red  bl/gre  bl/cy bl/cy bl/cy bl/mag
    # stdout - white, stderr - red
    # app-header sys-header
    # bl/yel     bl/cy

    # others ...
    # name	<>	blue,
    # neutral	<>	blue,
    # good	<>	green,
    # bad	<>	red,
    # error	<>	magenta,
    # unknown	<>	cyan,
    # warning	<>	yellow,
    # instance<>	yellow,
    # number	<>	green,
    # prompt	<>	blue,
    # yes	<>	green,
    # no	<>	red

    variable smap {}
}

apply {{} {
    variable smap
    for {set i 0} {$i < 32} {incr i} {
	set c [format %c $i]
	set o \\[format %03o $i] 
	lappend smap $c $o
    }
    lappend smap \127 \\127
}} ::cmdr::color

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::color 0
