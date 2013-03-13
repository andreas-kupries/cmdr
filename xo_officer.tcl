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

	set myactions  $actions ; # Action spec for future initialization
	set myinit     no       ; # Dispatch map will be initialized lazily
	set mymap      {}       ; # Action map starts knowing nothing
	set mycommands {}       ; # Ditto
	set mychildren {}       ; # List of created subordinates.
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
	set mycommands [lsort -dict $mycommands]
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
	lappend mycommands $name
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

    method prompt1  {} { return "[my name]> " }
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
	return [my complete-words [my ParseLine $line]]
    }

    method complete-words {parse} {
	# Note: This may be invoked from a higher-level officer doing
	# command completion.
	my Setup

    }

    method ParseLine {line} {
	set hasspace [string match {*[ 	]} $line]
	set ok 1
	set words {}
	try {
	    set words [string token shell -partial -indices $line]
	} trap {STRING TOKEN SHELL BAD} {e o} {
	    set ok 0
	}
	return [dict create line $line ok $ok eos $hasspace words $words ]
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

    variable myinit myactions mymap mycommands mychildren myreplexit

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::officer 0.1
