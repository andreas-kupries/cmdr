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

namespace eval ::cmdr {
    namespace export color
    namespace ensemble create
}

namespace eval ::cmdr::color {
    namespace export \
	activate active names get get-def define exists unset
    namespace ensemble create \
	-unknown [namespace current]::Unknown \
	-prefixes 0

    # Note, the -unknown option ensures that all unknown methods are
    # treated as (list of) color codes to apply to some text,
    # effectively creating the virtual command
    #
    #    ::cmdr::color <codelist> <text>
    #
    # The -prefix 0 option ensures that we canuse the 'name'
    # color-code, without it will go to 'names' and then fail with
    # wrong#args due to the different expected syntax.
    ##

    namespace import ::cmdr::tty
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/color
debug level  cmdr/color
debug prefix cmdr/color {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## TODO multi-def aka bulk-def aka load
## TODO officer and private for std commands (show, define).

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

proc ::cmdr::color::names {} {
    debug.cmdr/color {}
    variable def
    return [dict keys $def]
}

proc ::cmdr::color::unset {name} {
    debug.cmdr/color {}
    variable def
    if {![dict exists $def $name]} {
	return -code error \
	    -errorcode [list CMDR COLOR BAD $name] \
	    "Expected a color name, got \"$name\""
    }

    variable char
    dict unset def  $name
    dict unset char $name
    return
}

proc ::cmdr::color::get {name} {
    debug.cmdr/color {}
    variable def
    if {![dict exists $def $name]} {
	return -code error \
	    -errorcode [list CMDR COLOR BAD $name] \
	    "Expected a color name, got \"$name\""
    }
    variable char
    return [dict get $char $name]
}

proc ::cmdr::color::get-def {name} {
    debug.cmdr/color {}
    variable def
    if {![dict exists $def $name]} {
	return -code error \
	    -errorcode [list CMDR COLOR BAD $name] \
	    "Expected a color name, got \"$name\""
    }
    return [dict get $def $name]
}

proc ::cmdr::color::exists {name} {
    debug.cmdr/color {}
    variable def
    return [dict exists $def $name]
}

proc ::cmdr::color::define {name spec} {
    debug.cmdr/color {}
    variable def
    variable char

    # The spec may be
    # (1) A reference to other color name.
    # (2) An RGB spec.
    # (3) A raw control sequence.

    # Syntax:
    # (1) ref := =<name>
    # (2) rgb := %<r>,<g>,<b>
    # (3) esc := [Ee]<code>(,...)?
    # (4) raw := anything else

    if {[regexp {^=(.*)$} $spec -> ref]} {
	if {$ref eq $name} {
	    return -code error \
		-errorcode [list CMDR COLOR CIRCLE $name] \
		"Rejected self-referential definition of \"$name\""
	} elseif {![dict exists $def $ref]} {
	    return -code error \
		-errorcode [list CMDR COLOR BAD $ref] \
		"Expected a color name, got \"$ref\""
	} else {
	    set raw [dict get $char $ref]
	    debug.cmdr/color {reference, resolved => [Quote $raw]}
	    dict set def  $name $spec
	    dict set char $name $raw
	    return
	}
    }

    if {[regexp {^[eE](.*)$} $spec -> codes]} {
	if {![regexp {^(\d+)(,\d+)*$} $codes]} {
	    return -code error \
		-errorcode [list CMDR COLOR BAD-ESCAPE SYNTAX $rgb] \
		"Expected a comma-separated list of codes, got \"$spec\""
	}
	set codes [Code {*}[split $codes ,]]
	debug.cmdr/color {ESC encoded => [Quote $codes]}
	dict set def  $name $spec
	dict set char $name $codes
	return
    }

    if {[regexp {^%(.*)$} $spec -> rgb]} {
	if {![regexp {^(\d+),(\d+),(\d+)$} $rgb -> r g b]} {
	    return -code error \
		-errorcode [list CMDR COLOR BAD-RGB SYNTAX $rgb] \
		"Expected an RGB tuple, got \"$rgb\""
	} {
	    # R, G, B all in range 0..5
	    Clamp R $r
	    Clamp G $g
	    Clamp B $b
	    # 256-color mapping
	    # code = 16 + 36R + 6G + B --> [16..236]
	    set point [expr {16 + 36*$r + 6*$g + $b}]
	    set code [Code $point]
	    debug.cmdr/color {RGB encoded => [Quote $code]}
	    dict set def  $name $spec
	    dict set char $name $code
	    return

	    # Legacy mapping
	    # R,G,B mapping 0,1 --> 0, 2,3 --> 1, 4,5 --> 2
	    # bold mapping: 0,1,2 --> 0,1,1 (set if any of R, G, B)
	    # code = 8bold + R + 2G + 4B
	    #      = 8, for R==G==B != 0, special case.
	}
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
	if {![dict exists $char $c]} {
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

proc ::cmdr::color::Quote {text} {
    # quote all non-printable characters (< space, > ~)
    variable smap
    return [string map $smap $text]
}

proc ::cmdr::color::Code {args} {
    return \033\[[join $args \;]m
}

proc ::cmdr::color::Clamp {label x} {
    if {($x >= 0) && ($x <= 5)} { return $x }
    return -code error \
	-errorcode [list CMDR COLOR BAD-RGB RANGE $x] \
	"RGB channel $label out of range, got $x"
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
    define  black        e30  ; # Black  
    define  red          e31  ; # Red    
    define  green        e32  ; # Green  
    define  yellow       e33  ; # Yellow 
    define  blue         e34  ; # Blue   
    define  magenta      e35  ; # Magenta
    define  cyan         e36  ; # Cyan   
    define  white        e37  ; # White  
    define  default      e39  ; # Default (Black)

    # Colors. Background.
    define  bg-black     e40  ; # Black  
    define  bg-red       e41  ; # Red    
    define  bg-green     e42  ; # Green  
    define  bg-yellow    e43  ; # Yellow 
    define  bg-blue      e44  ; # Blue   
    define  bg-magenta   e45  ; # Magenta
    define  bg-cyan      e46  ; # Cyan   
    define  bg-white     e47  ; # White  
    define  bg-default   e49  ; # Default (Transparent)

    # Non-color attributes. Activation.
    define  bold         e1   ; # Bold  
    define  dim          e2   ; # Dim
    define  italic       e3   ; # Italics      
    define  underline    e4   ; # Underscore   
    define  blink        e5   ; # Blink
    define  revers       e7   ; # Reverse      
    define  hidden       e8   ; # Hidden
    define  strike       e9   ; # StrikeThrough

    # Non-color attributes. Deactivation.
    define  no-bold      e21  ; # Bold  
    define  no-dim       e22  ; # Dim
    define  no-italic    e23  ; # Italics      
    define  no-underline e24  ; # Underscore   
    define  no-blink     e25  ; # Blink
    define  no-revers    e27  ; # Reverse      
    define  no-hidden    e28  ; # Hidden
    define  no-strike    e29  ; # StrikeThrough

    # Remainder
    define  reset        e 0  ; # Reset

    # And now the standard symbolic names
    define  advisory =yellow
    define  bad      =red
    define  confirm  =red
    define  error    =magenta
    define  good     =green
    define  name     =blue
    define  neutral  =blue
    define  no       =red
    define  note     =blue
    define  number   =green
    define  prompt   =blue
    define  unknown  =cyan
    define  warning  =yellow
    define  yes      =green

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
} ::cmdr::color}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::color 0
