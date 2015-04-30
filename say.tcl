## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Convenience commands for terminal manipulation and output

# @@ Meta Begin
# Package cmdr::say 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Terminal manipulation and output.
# Meta description Commands to generate terminal output, to control
# Meta description the terminal, and print text
# Meta subject {command line} tty interaction terminal
# Meta require {Tcl 8.5-}
# Meta require debug
# Meta require debug::caller
# Meta require cmdr::color
# Meta require linenoise
# Meta require TclOO
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::color
package require debug
package require debug::caller
package require linenoise
package require TclOO
package require try

namespace eval ::cmdr {
    namespace export say
}
namespace eval ::cmdr::say {
    namespace export \
	up down forw back \
	erase-screen erase-up erase-down \
	erase-line erase-back erase-forw \
	goto home line add line rewind lock-prefix clear-prefix \
	next next* animate barberpole percent progress-counter progress \
	ping pulse turn operation \
	\
	auto-width barber-phases progress-phases larson-phases \
	slider-phases pulse-phases turn-phases \
	\
	to

    namespace ensemble create
    namespace import ::cmdr::color

    # State for "add", "lock-prefix", "clear-prefix", and "rewind"
    variable prefix {}
    variable pre    {}

    # Channel to write to. Default is stdout. Mainly to allow
    # redirection during testing.
    variable to
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/say
debug level  cmdr/say
debug prefix cmdr/say {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## output redirection

proc ::cmdr::say::to {{chan {}}} {
    debug.cmdr/say {}
    variable to
    if {[llength [info level 0]] == 1} {
	return $chan
    }
    set to $chan
    return
}

# # ## ### ##### ######## ############# #####################
## cursor movement

proc ::cmdr::say::up {{n 1}} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[${n}A
    flush           stdout
    return
}

proc ::cmdr::say::down {{n 1}} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[${n}B
    flush           stdout
    return
}

proc ::cmdr::say::forw {{n 1}} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[${n}C
    flush           stdout
    return
}

proc ::cmdr::say::back {{n 1}} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[${n}D
    flush           stdout
    return
}

# # ## ### ##### ######## ############# #####################
## (partial) screen erasure

proc ::cmdr::say::erase-screen {{suffix {}}} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[2J$suffix
    flush           stdout
    return
}

proc ::cmdr::say::erase-up {{suffix {}}} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[1J$suffix
    flush           stdout
    return
}

proc ::cmdr::say::erase-down {{suffix {}}} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[0J$suffix
    flush           stdout
    return
}

# # ## ### ##### ######## ############# #####################
## (partial) line erasure

proc ::cmdr::say::erase-line {{suffix {}}} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[2K$suffix
    flush           stdout
    return
}

proc ::cmdr::say::erase-back {{suffix {}}} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[1K$suffix
    flush           stdout
    return
}

proc ::cmdr::say::erase-forw {{suffix {}}} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[0K$suffix
    flush           stdout
    return
}

# # ## ### ##### ######## ############# #####################
## absolute cursor movement

proc ::cmdr::say::goto {x y} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[${y};${x}f
    flush           stdout
    return
}

proc ::cmdr::say::home {} {
    debug.cmdr/say {}
    puts -nonewline stdout \033\[H
    flush           stdout
    return
}

# # ## ### ##### ######## ############# #####################
## bottom level line output and animation control

proc ::cmdr::say::add {text} {
    debug.cmdr/say {}
    variable pre
    append   pre $text
    puts -nonewline stdout $text
    flush           stdout
    return
}

proc ::cmdr::say::line {text} {
    debug.cmdr/say {}
    variable pre    {}
    variable prefix {}
    puts  stdout $text
    flush stdout
    return
}

proc ::cmdr::say::rewind {} {
    debug.cmdr/say {}
    variable prefix
    erase-line \r$prefix
    return
}

proc ::cmdr::say::lock-prefix {} {
    debug.cmdr/say {}
    variable pre
    variable prefix $pre
    return
}

proc ::cmdr::say::clear-prefix {} {
    debug.cmdr/say {}
    variable prefix {}
    return
}

proc ::cmdr::say::next {} {
    debug.cmdr/say {}
    clear-prefix
    puts  stdout ""
    flush stdout
    return
}

proc ::cmdr::say::next* {} {
    debug.cmdr/say {}
    puts  stdout ""
    flush stdout
    return
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::say::operation {lead script args} {
    debug.cmdr/say {}

    set cmd {}
    set delay 100
    while {1} {
	set o [lindex $args 0]
	switch -glob -- $o {
	    -every {
		set delay [lindex $args 1]
		set args  [lrange $args 2 end]
	    }
	    -play {
		set cmd  [lindex $args 1]
		set args [lrange $args 2 end]
	    }
	    -* {
		return -code error \
		    -errorcode {CMD SAY BAD-OPTION} \
		    "Unknown option $o, expected -a, or -d"
	    }
	    default break
	}
    }

    add $lead
    lock-prefix

    if {[llength $cmd]} {
	set animation [uplevel 1 $cmd]
	$animation run $delay
    }

    try {
	uplevel 1 $script
    } {*}$args on error {e o} {
	# General error => close line, and pass.
	line ""
	return {*}$o $e
    } on ok {e o} {
	rewind ; # remove animation output, leave only the lead
	line [color good OK]
    } finally {
	# Stop ongoing animation, if any
	if {[llength $cmd]} {
	    $animation done
	}
    }
    return $e
}

# # ## ### ##### ######## ############# #####################
## Animation helper class (timer driven auto-step).

oo::class create ::cmdr::say::Auto {
    variable mytimer

    method run {delay} {
	debug.cmdr/say {}
	my stop ;# Kill a running timer, this allows us to call sequences of runs without worrying about the system state.

	cmdr say rewind
	my step

	set mytimer [after $delay [info level 0]]
	return
    }

    method stop {} {
	debug.cmdr/say {}
	catch {
	    after cancel $mytimer
	}
	set mytimer {}
	return
    }

    destructor {
	debug.cmdr/say {}
	my stop
    }
}

# # ## ### ##### ######## ############# #####################
## general animation command and class

proc ::cmdr::say::animate {args} {
    debug.cmdr/say {}
    array set config $args
    Require config -phases
    return [animate::Im new -phases [Fill $config(-phases)]]
}

oo::class create ::cmdr::say::animate::Im {
    superclass ::cmdr::say::Auto
    variable myphases myphase mywidth

    constructor {args} {
	debug.cmdr/say {}
	my configure {*}$args
	return
    }

    method configure {args} {
	array set config $args
	::cmdr::say::Require config -phases

	set myphases $config(-phases)
	set myphase  0
	set mywidth  [string length [lindex $myphases 0]]
	return
    }

    method width {} {
	debug.cmdr/say {}
	return $mywidth
    }

    method step {} {
	debug.cmdr/say {}
	cmdr say add [lindex $myphases $myphase]
	incr myphase
	if {$myphase == [llength $myphases]} { set myphase 0 }
	return
    }

    method goto {phase} {
	debug.cmdr/say {}
	set myphase $phase
	cmdr say add [lindex $myphases $myphase]
	return
    }

    method done {} {
	debug.cmdr/say {}
	my destroy
    }
}

# # ## ### ##### ######## ############# #####################
## barberpole animation

proc ::cmdr::say::barberpole {args} {
    debug.cmdr/say {}

    array set config {
	-width   {}
	-pattern {**  }
    }
    array set config $args

    set phases [barber-phases \
		    [auto-width $config(-width)] \
		    $config(-pattern)]

    # Run the animation via the general class.
    return [animate::Im new -phases $phases]
}

# # ## ### ##### ######## ############# #####################
## pulse animation

proc ::cmdr::say::pulse {args} {
    debug.cmdr/say {}

    array set config {
	-width   {}
	-stem    .
    }
    array set config $args

    set phases [pulse-phases \
		    [auto-width $config(-width)] \
		    $config(-stem)]

    # Run the animation via the general class.
    return [animate::Im new -phases $phases]
}

# # ## ### ##### ######## ############# #####################
## turn animation

proc ::cmdr::say::turn {} {
    debug.cmdr/say {}
    set phases [turn-phases]
    # Run the animation via the general class.
    return [animate::Im new -phases $phases]
}

# # ## ### ##### ######## ############# #####################
## progress counter, n of max.

proc ::cmdr::say::progress-counter {max} {
    debug.cmdr/say {}
    return [progress-counter::Im new $max]
}

oo::class create ::cmdr::say::progress-counter::Im {
    superclass ::cmdr::say::Auto
    variable mywidth myformat mymax

    constructor {max} {
	debug.cmdr/say {}
	set n [string length $max]
	set mymax    $max
	set mywidth  [expr {1+2*$n}]
	set myformat %${n}d/%d
	return
    }

    method width {} {
	debug.cmdr/say {}
	return $mywidth
    }

    method step {at} {
	debug.cmdr/say {}
	cmdr say add [format $myformat $at $mymax]
	return
    }

    method done {} {
	debug.cmdr/say {}
	my destroy
    }
}

# # ## ### ##### ######## ############# #####################
## progress counter, in percent.

proc ::cmdr::say::percent {args} {
    debug.cmdr/say {}

    array set config {
	-max    100
	-digits 2
    }
    array set config $args

    return [percent::Im new $config(-max) $config(-digits)]
}

oo::class create ::cmdr::say::percent::Im {
    superclass ::cmdr::say::Auto
    variable mywidth myformat mymax

    constructor {max digits} {
	debug.cmdr/say {}
	set mymax $max

	set mywidth 3
	if {$digits} {
	    incr mywidth ;# .
	    incr mywidth $digits
	}
	set myformat %${mywidth}.${digits}f
	return
    }

    method width {} {
	debug.cmdr/say {}
	return $mywidth
    }

    method step {at} {
	debug.cmdr/say {}
	set percent [expr {100*double($at)/double($mymax)}]
	cmdr say add [format $myformat $percent]%
	return
    }

    method done {} {
	debug.cmdr/say {}
	my destroy
    }
}

# # ## ### ##### ######## ############# #####################
## progress-bar

proc ::cmdr::say::progress {args} {
    debug.cmdr/say {}

    array set config {
	-max    100
	-width  {}
	-stem   =
	-head   >
    }
    array set config $args

    set phases [progress-phases \
		    [auto-width $config(-width)] \
		    $config(-stem) \
		    $config(-head)]

    return [progress::Im new $config(-max) $phases]
}

oo::class create ::cmdr::say::progress::Im {
    variable mymax myphases

    constructor {max phases} {
	debug.cmdr/say {}
	# Inner object, general animation, container for our phases.
	cmdr::say::animate::Im create A -phases $phases
	set mymax    $max
	set myphases [llength $phases]
	return
    }

    forward width \
	A width

    method step {at} {
	debug.cmdr/say {}
	set phase [expr {int($myphases * (double($at)/double($mymax)))}]
	if {$phase >= $myphases} { set phase end }
	A goto $phase
	return
    }

    method done {} {
	debug.cmdr/say {}
	my destroy
    }
}


# # ## ### ##### ######## ############# #####################
## ping

proc ::cmdr::say::ping {args} {
    debug.cmdr/say {}

    # Options
    # -head  string - Show in front of the ping characters.
    # -map   dict   - Map moduli to characters, when reached.
    #                 Order relevant, largest moduli first.
    #                 End with modulus 1, always matching!
    #                 (System will internally add such to close the map).
    # -width int    - Amount of space to use for the moving ping+head
    # -wrap  bool   - Wrapping keeps the moving part within the current line.
    #                 Without wrap a wrap goes to the next line using next*.

    array set config {
	-wrap 0
	-head &
	-map {
	    100000 @
	    10000  \#
	    1000   %
	    100    |
	    10     *
	    1      .
	}
	-width {}
    }
    array set config $args

    return [ping::Im new \
		$config(-wrap) \
		$config(-head) \
		$config(-map) \
		[auto-width $config(-width)]]
}

oo::class create ::cmdr::say::ping::Im {
    superclass ::cmdr::say::Auto
    variable mywrap myhead mymap mywidth myphase mybuffer myewidth mytrail

    constructor {wrap head map width} {
	debug.cmdr/say {}

	# close map, if user forgot. No-op if user closed it.
	lappend map 1 _ ;# default char configurable ?

	set mywrap   $wrap
	set myhead   $head
	set mymap    $map
	set mywidth  $width
	set myewidth [expr {$mywidth - [string length $head]}] ;# effective width.
	set myphase  0
	set mybuffer ""
	if {$mywrap} {
	    set mytrail [string repeat { } $myewidth]
	} else {
	    set mytrail {}
	}
	return
    }

    method width {} { return $mywidth }

    method step {} {
	debug.cmdr/say {}

	set ch [my Next]

	# Create a buffer to print, from the previous state.
	# First attempt. Without a head leading the pings.

	append  mybuffer $ch
	set str $mybuffer

	if {$mywrap} {
	    set mytrail [string range $mytrail 1 end]
	}

	if {[string length $str] < $myewidth} {
	    # Still fits. Simply print.
	    cmdr say add $str$myhead$mytrail
	} else {
	    # Too long. Split into a fitting piece and overshot.
	    set fit  [string range $str 0          ${myewidth}-1]
	    set over [string range $str ${myewidth} end]

	    # Print the fitting piece first to complete the line,
	    # then move to the next line and print the overshot.
	    cmdr say add $fit

	    if {!$mywrap} {
		cmdr say next*      ;# no-wrap: next line, keep current prefix.
	    } else {
		cmdr say rewind     ;# wrap:    rewind/clear line and continue
	    }
	    cmdr say add $over$myhead$mytrail

	    # Set state for next call.
	    set mybuffer $over
	    if {$mywrap} {
		set mytrail $fit
	    }
	}
	return
    }

    method done {} {
	debug.cmdr/say {}
	my destroy
    }

    method Next {} {
	incr myphase
	foreach {mod char} $mymap {
	    if {($myphase % $mod) != 0} continue
	    return $char
	}
	return -code error -errorcode ... ""
    }
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::say::auto-width {width} {
    debug.cmdr/say {}

    if {$width eq {}} {
	# Nothing defined, adapt to terminal width
	set width [linenoise columns]
    } elseif {$width < 0} {
	# Adapt to terminal width, with some space reserved.
	set width [expr {[linenoise columns] + $width}]
    }
    return $width
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::say::barber-phases {width pattern} {
    debug.cmdr/say {}

    # Repeat the base pattern as necessary to fill the requested
    # width. We use a count which gives us something which might be a
    # bit over, so after replication the resulting string is cut down
    # to the exact size.
    set n    [expr {int(0.5+ceil($width / double([string length $pattern])))}]
    set base [string range [string repeat $pattern $n] 0 ${width}-1]

    # Example for standard pattern '**  ', widths 16, and 17.
    # |**  **  **  **  |
    # | **  **  **  ** |
    # |  **  **  **  **|
    # |*  **  **  **  *|

    # |**  **  **  **  *| Note how the odd length yields one larger
    # |***  **  **  **  | band (***) in the pattern, which ripples
    # | ***  **  **  ** | across, and multiplies the number of phases
    # |  ***  **  **  **| before reaching the origin again.
    # |*  ***  **  **  *|
    # |**  ***  **  **  | Similar effects will be had for for any width
    # | **  ***  **  ** | which W != 0 mod (length pattern).
    # |  **  ***  **  **|
    # |*  **  ***  **  *|
    # |**  **  ***  **  |
    # | **  **  ***  ** |
    # |  **  **  ***  **|
    # |*  **  **  ***  *|
    # |**  **  **  ***  |
    # | **  **  **  *** |
    # |  **  **  **  ***|
    # |*  **  **  **  **|

    lappend phases $base
    # rotate the base through all configurations until we reach it again.
    set next $base
    while {1} {
	set next [string range $next 1 end][string index $next 0]
	if {$next eq $base} break
	lappend phases $next
    }

    return $phases
}

proc ::cmdr::say::progress-phases {width stem head} {
    debug.cmdr/say {}

    # compute phases.
    set h [string length $head]
    set phases {}
    for {set i 0} {$i < ($width - $h)} {incr i} {
	lappend phases [string repeat $stem $i]$head
	# >, =>, ==>, ...
    }

    return [Fill $phases]
}

proc ::cmdr::say::larson-phases {width pattern} {
    debug.cmdr/say {}

    set n [string length $pattern]
    if {$n > $width} {
	return [list $pattern]
    }

    set spaces [expr {$width - $n}]

    # round 1: slide right
    for {
	set pre  0
	set post $spaces
    } { $post > 0 } {
	incr pre
	incr post -1
    } {
	lappend phases [string repeat { } $pre]${pattern}[string repeat { } $post]
    }

    # round 2: slide left
    for {
	set pre  $spaces
	set post 0
    } { $pre > 0 } {
	incr pre  -1
	incr post
    } {
	lappend phases [string repeat { } $pre]${pattern}[string repeat { } $post]
    }

    return $phases
}

proc ::cmdr::say::slider-phases {width pattern} {
    debug.cmdr/say {}

    set n [string length $pattern]
    if {$n > $width} {
	return [list $pattern]
    }

    # round 1: slide pattern in.
    lappend phases {}
    for {set k 0} {$k < $n} {incr k} {
	lappend phases [string range $pattern end-$k end]
    }

    # round 2: slide pattern right.
    set spaces [expr {$width - $n}]
    for {
	set pre  0
	set post $spaces
    } { $post > 0 } {
	incr pre
	incr post -1
    } {
	lappend phases [string repeat { } $pre]${pattern}[string repeat { } $post]
    }

    # round 3: slide pattern out.
    for {set k 0} {$k < $n} {incr k} {
	lappend phases [string repeat { } $pre][string range $pattern 0 end-$k]
	incr pre
    }

    return $phases
}

proc ::cmdr::say::pulse-phases {width stem} {
    debug.cmdr/say {}

    # compute phases.
    set phases {}
    for {set i 0} {$i <= $width} {incr i} {
	lappend phases [string repeat $stem $i]
    }
    return [Fill $phases]
}

proc ::cmdr::say::turn-phases {} {
    return [list | / - \\]
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::say::Require {cv option} {
    debug.cmdr/say {}
    upvar 1 $cv config
    if {[info exists config($option)]} return
    return -code error \
	-errorCode [list CMDR SAY OPTION MISSING $option] \
	"Missing required option \"$option\""
}

proc ::cmdr::say::Fill {phases} {
    # compute max length of phase strings
    set max [string length [lindex $phases 0]]
    foreach p [lrange $phases 1 end] {
	# Look for ANSI color control sequences and remove them. Avoid
	# counting their characters as such sequences as a whole
	# represent a state change, and are logically of zero/no
	# width.
	regsub -all "\033\\\[\[0-9;\]*m" $p {} p
	set n [string length $p]
	if {$n < $max} continue
	set max $n
    }

    # then pad all other strings which do not reach that length with
    # spaces at the end.
    set tmp {}
    foreach p $phases {
	# Look for ANSI color control sequences and discount
	# them. Avoid counting their characters as such sequences as a
	# whole represent a state change, and are logically of zero/no
	# width.
	regsub -all "\033\\\[\[0-9;\]*m" $p {} px
	set n [string length $px]
	if {$n < $max} {
	    append p [string repeat { } [expr {$max - $n}]]
	}
	lappend tmp $p
    }

    return $tmp
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::say 1
