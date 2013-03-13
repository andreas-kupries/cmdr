## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Officer - Command execution. Dispatcher.
##                An actor.

## - Officers can learn to do many things, by delegating things to the
##   privates actually able to perform it.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO
package require oo::util 1.2 ;# link helper.
package require string::token::shell 1.1
package require try
package require xo::actor
package require xo::private
package require linenoise::facade

# # ## ### ##### ######## ############# #####################
## Definition - Single purpose command.

# # ## ### ##### ######## ############# #####################
## Definition

oo::class create ::xo::officer {
    superclass ::xo::actor
    # # ## ### ##### ######## #############
    ## Lifecycle.

    # action specification.
    # declares a hierarchy of sub-ordinate officers and privates.

    # Specification commands.
    #
    # private $name $arguments $cmdprefix --> sub-ordinate private for the action.
    # officer $name $actions              --> sub-ordinate officer with more actions.
    # default $name                       --> default action

    constructor {super name actions} {
	next

	my super: $super
	my name:  $name

	set myactions   $actions ; # Action spec for future initialization
	set myinit      no       ; # Dispatch map will be initialized lazily
	set mymap       {}       ; # Action map starts knowing nothing
	set mycommands  {}       ; # Ditto
	set myccommands exit     ; # Completion knows 'exit' command.
	set mychildren  {}       ; # List of created subordinates.
	return
    }

    # # ## ### ##### ######## #############
    ## Public API. (Introspection, mostly).
    ## - Determine set of known actions.
    ## - Determine default action.
    ## - Determine handler for an action.

    method known {} {
	my Setup
	set result {}
	dict for {k v} $mymap {
	    if {![string match a,* $k]} continue
	    lappend result [string range $k 2 end]
	}	
	return $result
    }

    method hasdefault {} {
	my Setup
	return [dict exists $mymap default]
    }

    method default {} {
	my Setup
	return [dict get $mymap default]
    }

    method lookup {name} {
	my Setup
	if {![dict exists $mymap a,$name]} {
	    return -code error -errorcode {XO ACTION UNKNOWN} \
		"Expected action name, got \"$name\""
	}
	return [dict get $mymap a,$name]
    }

    method children {} {
	my Setup
	return $mychildren
    }

    # # ## ### ##### ######## #############
    ## Internal. Dispatcher setup. Defered until required.
    ## Core setup code runs only once.

    method Setup {} {
	# Process the action specification only once.
	if {$myinit} return
	set myinit 1

	# Make the DSL commands directly available. Note that
	# "description:" and "common" are superclass methods, and
	# renamed to their DSL counterparts. The others are unexported
	# instance methods of this class.

	link \
	    {private     Private} \
	    {officer     Officer} \
	    {default     Default} \
	    {alias       Alias} \
	    {description description:} \
	    undocumented \
	    {common      set}
	eval $myactions

	# Postprocessing.
	set mycommands  [lsort -dict $mycommands]
	set myccommands [lsort -unique [lsort -dict $myccommands]]
	return
    }

    # # ## ### ##### ######## #############
    ## Implementation of the action specification language.

    # common      => set          (super xo::actor)
    # description => description: (super xo::actor)

    forward Private my DefineAction private
    forward Officer my DefineAction officer

    method Default {{name {}}} {
	if {[llength [info level 0]] == 2} {
	    set name [my Last]
	} elseif {![dict exists $mymap a,$name]} {
	    return -code error -errorcode {XO ACTION UNKNOWN} \
		"Unable to set default, expected action, got \"$name\""
	}
	dict set mymap default $name
	return
    }

    method Alias {name args} {
	set n [llength $args]
	if {($n == 1) || (($n > 1) && ([lindex $args 0] ne "="))} {
	    return -code error \
		"wrong\#args: should be \"name ?= cmd ?word...??\""
	}
	my ValidateAsUnknown $name

	if {$n == 0} {
	    # Simple alias, to preceding action.
	    set handler [my lookup [my Last]]
	} else {
	    # Track the chain of words through the existing hierarchy
	    # of actions to locate the final handler.
	    set handler [self]
	    foreach word [lassign $args _dummy_] {
		set handler [$handler lookup $word]
	    }
	}

	# Essentially copy the definition of the command the alias
	# refers to.
	dict set mymap a,$name $handler
	return
    }

    # Internal. Common code to declare actions and their handlers.
    method DefineAction {what name args} {
	my ValidateAsUnknown $name

	# Note: By placing the subordinate objects into the officer's
	# namespace they will be automatically destroyed with the
	# officer itself. No special code for cleanup required.

	set handler [self namespace]::${what}_$name
	xo::$what create $handler [self] $name {*}$args

	lappend mychildren $handler

	# ... then make it known to the dispatcher.
	dict set mymap last $name
	dict set mymap a,$name $handler
	lappend mycommands  $name
	lappend myccommands $name
	return
    }

    method ValidateAsUnknown {name} {
	if {![dict exists $mymap a,$name]} return
	return -code error -errorcode {XO ACTION KNOWN} \
	    "Unable to learn $name, already specified."
    }

    method Last {} {
	if {![dict exists $mymap last]} {
	    return -code error -errorcode {XO ACTION NO-LAST} \
		"Cannot be used as first command"
	}
	return [dict get $mymap last]
    }

    method Known {name} {
	return [dict exists $mymap a,$name]
    }

    # # ## ### ##### ######## #############
    ## Command dispatcher. Choose the subordinate and delegate.

    method do {args} {
	my Setup

	# No command specified.
	if {![llength $args]} {
	    # Drop into a shell where the user can enter her commands
	    # interactively.

	    set shell [linenoise::facade new [self]]
	    set myreplexit 0 ; # Initialize stop signal, no stopping
	    $shell history 1
	    $shell repl
	    $shell destroy
	    return
	}

	my Do {*}$args
	return
    }

    # Internal. Actual dispatch. Shared by main entry and shell.
    method Do {args} {
	# Empty command. Delegate to the default, if we have any.
	# Otherwise fail.
	if {![llength $args]} {
	    if {[my hasdefault]} {
		return [[my lookup [my default]] do]
	    }
	    return -code error -errorcode {XO DO EMPTY} \
		"No command found."
	}

	# Split into command and arguments
	set remainder [lassign $args cmd]

	# Delegate to the handler for a known command.
	if {[my Known $cmd]} {
	    [my lookup $cmd] do {*}$remainder
	    return
	}

	# The command word is not known. Delegate the full command to
	# the default, if we have any. Otherwise fail.

	if {[my hasdefault]} {
	    return [[my lookup [my default]] do {*}$args]
	}

	return -code error -errorcode {XO DO UNKNOWN} \
	    "No command found, have \"$cmd\""
    }

    # # ## ### ##### ######## #############
    ## Shell hook methods called by the linenoise::facade.

    method prompt1  {} { return "[my fullname]> " }
    method prompt2  {} { error {Continuation lines are not supported} }
    method continued {line} { return 0 }

    method dispatch {cmd} {
	if {$cmd eq "exit"} {
	    set myreplexit 1 ; return
	}
	my Do {*}[string token shell $cmd]
    }

    method report {what data} {
	switch -exact -- $what {
	    ok {
		if {$data eq {}} return
		puts stdout $data
	    }
	    fail {
		puts stderr $data
	    }
	    default {
		return -code error \
		    "Internal error, bad result type \"$what\", expected ok, or fail"
	    }
	}
    }

    method exit {} { return $myreplexit }

    # # ## ### ##### ######## #############
    # Shell hook method - Command line completion.

    method complete {line} {
	#puts stderr ////////$line
	try {
	    set completions [my complete-words [my ParseLine $line]]
	} on error {e o} {
	    #puts stderr "ERROR: $e"
	    #puts stderr $::errorInfo
	    set completions {}
	}
	#puts stderr =($completions)
	return $completions
    }

    method complete-words {parse} {
	#puts stderr [my fullname]/[self]/$parse/
	# Note: This method has to entry-points.
	# (1) Above in 'complete', for command completion from self's REPL.
	# (2) Below, as part of recursion from a higher officer while
	#     following the chain of words to the actor responsible
	#     for handling the last word.

	my Setup

	# Unfold the parse state
	dict with parse {} ;# --> line ok words at nwords doexit
	# ok     - boolean flag, syntax ok ? yes/no
	# line   - string, the raw command line with quotes, escapes, etc.
	# nwords - number of words found in the -> line
	# words  - list of words found in the -> line.
	# at     - index of the current word to process.
	# doexit - boolean flag, pseudo-command 'exit' active ? yes/no
	#
	# words = list (tuple), where tuple = (type startoff endoff string)
	# doexit - True only for entry point (1), false for all of (2) and down.

	# Parse error, bad syntax. No completions.

	if {!$ok} {
	    #puts stderr \tBAD
	    return {}
	}

	# Empty line. All our commands are completions, plus the
	# special 'exit' command to stop the REPL. Thus using
	# my<c>commands instead of mycommands.

	if {$line eq {}} {
	    #puts stderr \tALL
	    set completions $myccommands
	    if {[my hasdefault]} {
		dict set parse doexit 0
		lappend completions {*}[[my lookup [my default]] complete-words $parse]
	    }
	    return [lsort -unique [lsort -dict $completions]]
	}

	# Beyond the end of the line. No completions.

	if {$at == $nwords} {
	    #puts stderr \tBEYOND
	    return {}
	}

	# Extract the text of the current word. The type and offset
	# parts are irrelevant at the moment.
	set current [lindex $words $at end]

	if {$at < ($nwords - 1)} {
	    # This officer has to handle a word in the middle of the
	    # command line. This is done by delegating to the
	    # subordinate associated with the current word and letting
	    # it handle the remainder.

	    #puts stderr \tRECURSE
	    return [my CompleteRecurse $current $parse]
	}

	# This officer is responsible for handling the last word on
	# the command line. We do this by computing the set of
	# matching commands from the set the officer knows and
	# providing them as completions. One tricky thing: If we have
	# a default we ask it as well, and merge its completions to
	# ours. Lastly, we may have to add the 'exit' pseudo-command
	# as well.

	#puts stderr \tMATCH\ ($current)
	set completions {}
	dict for {k v} $mymap {
	    if {![string match a,* $k]} continue
	    set name [lindex [split $k ,] 1]
	    if {![string match ${current}* $name]} continue
	    my AddResult $name ; # imports completions, line, words
	}

	if {$doexit && [string match ${current}* exit]} {
	    my AddResult exit ; # imports completions, line, words
	}

	if {[my hasdefault]} {
	    dict set parse doexit 0
	    lappend completions {*}[[my lookup [my default]] complete-words $parse]
	}

	#puts stderr \tC($completions)
	return [lsort -unique [lsort -dict $completions]]
    }

    method AddResult {cmd} {
	upvar 1 completions completions line line words words

	# The -> cmd is a valid completion of the line.  The actual
	# completion is the line itself, plus the command.  We have
	# however have to chop off the incomplete part of cmd to make
	# things right.
	#
	# Example:
	# line       = "foo b"
	# cmd            = "bar"
	# completion = "foo bar"

	if {[string first { } $cmd] >= 0} {
	    # Command has spaces, insert as single-quoted word.
	    # TODO: We have to handle command names containing double- and single-quotes also!
	    set cmd '$cmd'
	}

	# Determine the chop point: Just before the first character of the last word.
	set  start [lindex $words end 1]
	incr start -1

	# Chop and complete.
	lappend completions [string range $line 0 $start]$cmd
	return
    }

    method ParseLine {line} {
	set ok    1
	set words {}

	try {
	    set words [string token shell -partial -indices $line]
	} trap {STRING TOKEN SHELL BAD} {e o} {
	    set ok 0
	}

	set len [string length $line]

	if {$ok} {
	    # last word, end index
	    set lwe [lindex $words end 2]
	    # last word ends before end of line -> trailing whitespace
	    # add the implied empty word for the completion processing.
	    if {$lwe < ($len-1)} {
		lappend words [list PLAIN $len $len {}]
	    }
	}
	set parse [dict create \
		       doexit 1 \
		       at     0 \
		       line   $line \
		       ok     $ok \
		       words  $words \
		       nwords [llength $words]]

	return $parse
    }

    method CompleteRecurse {current parse} {
	# Inside the command line. Find the relevant subordinate based
	# on the current word and let it handle everything.

	# The 'exit' pseudo-command of the subordinate is irrelevant
	# during recursion from the current or higher REPL, suppress
	# it. The pseudo-command is only relevant to the officers
	# actually in their REPL.
	dict set parse doexit 0

	set handlers {}
	dict for {k v} $mymap {
	    if {![string match a,* $k]} continue
	    set name [lindex [split $k ,] 1]
	    if {![string match ${current}* $name]} continue
	    lappend handlers $v
	}

	if {[llength $handlers] == 1} {
	    # Proper subordinate found. Delegate. Note: Step to next
	    # word, we have processed the current one.
	    dict incr parse at
	    return [[lindex $handlers 0] complete-words $parse]
	}

	# The search was inconclusive. Try the default, if we have any.
	if {[my hasdefault]} {
	    return [[my lookup [my default]] complete-words $parse]
	}

	# No default, no completions.
	return {}
    }

    # # ## ### ##### ######## #############

    method help {{prefix {}}} {
	my Setup
	# Query each subordinate for their help and use it to piece ours together.
	# Note: Result is not finally formatted text, but nested dict structure.
	# Same is expected from the sub-ordinates

	# help = dict (name -> command)
	if {![my documented]} { return {} }
	set help {}
	foreach c [my known] {
	    set cname [list {*}$prefix $c]
	    set actor [my lookup $c]
	    set help [dict merge $help [$actor help $cname]]
	}
	return $help
    }

    # # ## ### ##### ######## #############

    variable myinit myactions mymap mycommands myccommands mychildren myreplexit

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::officer 0.1
