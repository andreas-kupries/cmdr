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
package require ooutil 1.2 ;# link helper.
package require xo::actor
package require xo::private
package require string::atoken::shell
package require try

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

    constructor {name actions} {
	next $name

	set myactions  $actions ; # Action spec for future initialization
	set myinit     no       ; # Dispatch map will be initialized lazily
	set mymap      {}       ; # Action map starts knowing nothing
	set mycommands {}       ; # Ditto

	link \
	    DefAction ValidateAsUnknown Setup \
	    Last Default Default? Handler
	# DecodeLine Default Complete
	return
    }

    # # ## ### ##### ######## #############
    ## Internal. Dispatcher setup. Defered until required.
    ## Core setup code runs only once.

    method Setup {} {
	if {$myinit} return
	# Process myactions, initialize our dispatcher.
	link private officer
	eval $myactions
	set mycommands [lsort -dict $mycommands]
	set myinit 1
	return
    }

    # # ## ### ##### ######## #############
    ## Commands of the specification language.

    method private {name arguments cmdprefix} {
	# Create actor which can perform a specific actions.
	DefAction private $name $arguments $cmdprefix
	return
    }

    method officer {name actions} {
	# Create actor which can perform multiple actions, ...
	DefAction officer $name $actions
	return
    }

    method default {name} {
	if {![dict exists $mymap a,$name]} {
	    return -code error -errorcode {XO ACTION UNKNOWN} \
		"Unable to set default, expected action, got \"$name\""
	}
	dict set mymap default $name
	return
    }

    method alias {altname} {
	ValidateAsUnknown $altname
	# Copy definition the alias is for.
	dict set mymap a,$altname [Handler [Last]]
	return
    }

    # Internal. Common code to declare actions and their handlers.
    method DefAction {what name args} {
	ValidateAsUnknown $name

	# Note: By placing the subordinate objects into the officer's
	# namespace they will be automatically destroyed with the
	# officer itself. No special code for cleanup required.

	set handler [self namespace]::${what}_$name
	xo::$what create $name $handler {*}$args

	# ... then make it known to the dispatcher.
	dict set mymap last $name
	dict set mymap a,$name $handler
	lappend mycommands $name
	return
    }

    method ValidateAsUnknown {name} {
	if {[dict exists mymap a,$name]} return
	return -code error -errorcode {XO ACTION KNOWN} \
	    "Unable to learn $name, already specified."
    }

    method Default? {} {
	return [dict exists $mymap default]
    }

    method Default {} {
	return [dict get $mymap default]
    }

    method Last {} {
	if {![dict exists $mymap last]} {
	    return code error -errorcode {XO ACTION NO-LAST} \
		"Cannot be used as first command"
	}
	return [dict get $mymap last]
    }

    method Known {name} {
	return [dict exists $mymap a,$name]
    }

    method Handler {name} {
	return [dict get $mymap a,$name]
    }


    # # ## ### ##### ######## #############
    ## Command dispatcher. Choose the subordinate and delegate.

    method do {args} {
	Setup

	# No command specified.
	if {![llength $args]} {
	    # Drop into a shell where the user can enter her commands
	    # interactively.
	    set shell [linenoise::facade new [self]]
	    $shell repl
	    $shell destroy
	    return
	}

	Do {*}$args
	return
    }

    # Internal. Actual dispatch. Shared by main entry and shell.
    method Do {args} {
	# Empty command. Delegate to the default, if we have any.
	# Otherwise fail.
	if {![llength $args]} {
	    if {[Default?]} {
		return [[Handler [Default]] do]
	    }
	    return -code error -errorcode {XO DO EMPTY} \
		"No command found."
	}

	# Split into command and arguments
	set remainder [lassign $args cmd]

	# Delegate to the handler for a known command.
	if {[Known $cmd]} {
	    [Handler $cmd] do {*}$remainder
	}

	# The command word is not known. Delegate the full command to
	# the default, if we have any. Otherwise fail.

	if {[Default?]} {
	    return [[Handler [Default]] do {*}$args]
	}

	return -code error -errorcode {XO DO UNKNOWN} \
	    "No command found, have \"$cmd\""
    }

    # # ## ### ##### ######## #############
    ## Shell hook methods called by the linenoise::facade.

    method prompt1  {} { my name }
    method prompt2  {} { error {Continuation lines are not supported} }
    method continued {line} { return 0 }

    method dispatch {cmd} {
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

    method exit {} { return 0 }

    # # ## ### ##### ######## #############
    # Shell hook method - Command line completion.

    method complete {line} {
	return {}
	# XXX TODO XXX
	return [complete-words [ParseLine $line]]
    }

    method complete-words {parse} {
	# Note: This may be invoked from a higher-level officer doing
	# command completion.
	Setup

	dict with $config {} ;# --> line ok words eos

	# Empty line. All our commands.
	if {$line eq {}} { return $mycommands }

	# trailing whitespace or not?
	# ok syntax for the line before trailing whitespace?
	# how many words?

	# Not ending in whitespace. 
	if {!$eos} {


	}

	# XXX XXX XXX later

	    # Bad syntax: no completion.
	    if {!$ok} { return {} }

	    # Good syntax
	    if {![llength $words]} {
		# No words
		if {![dict exists mymap default]} {
		    # No default: no completion.
		    return {}
		}
		# Default: Recurse to its handler with an empty line
		# and use its results as our own.
		dict set config line {}
		return [[Handler [Default]] complete-words $config]
	    }

	    # Some words.
	    set c [lindex $words 0]


	# No ending in whitespace.

	# 1. whitespace at the end of the line?
	#    string before should have good syntax.
	#    if not no completion.
	#    if yes, count words.
	#    one word, or more -> should be command.
	#                if not use default.
	#                no default -> no completion
	#       we have a command. trim it from the
	#       beginning of the line, and dispatch
	#       to the associated subordinate for
	#       completion of the truncated line.



    }

    method ParseLine {line} {
	set hasspace [string match {*[ 	]} $line]
	set ok 1
	set words {}
	try {
	    set words [string token shell $line]
	} trap {STRING TOKEN SHELL BAD} {e o} {
	    set ok 0
	}
	return [dict create line $line ok $ok eos $hasspace words $words ]
    }


    # # ## ### ##### ######## #############

    method help {} {
	Setup
	# Query each subordinate for their help and use it to piece ours together.
	# Note: Result is not finally formatted text, but nested dict structure.
	# Same is expected from the sub-ordinates
	# XXX spec the structure.
	return
    }

    # # ## ### ##### ######## #############

    variable myinit myactions mymap mycommands

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::officer 0.1
