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
package require string::token::shell
package require try
package require xo::actor
package require xo::private

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

    method Alias {altname args} {
	set n [llength $args]
	if {($n == 1) || (($n > 1) && ([lindex $args 0] ne "="))} {
	    return -code error \
		"wrong\#args: should be \"name ?= cmd ?word...??\""
	}
	my ValidateAsUnknown $altname

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
	dict set mymap a,$altname $handler
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
	    error "REPL NYI" ; # XXX completion...
	    set shell [linenoise::facade new [self]]
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
	my Setup

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
		if {![dict exists $mymap default]} {
		    # No default: no completion.
		    return {}
		}
		# Default: Recurse to its handler with an empty line
		# and use its results as our own.
		dict set config line {}
		return [[my lookup [my default]] complete-words $config]
	    }

	    # Some words.
	    set c [lindex $words 0]



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
	my Setup
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
