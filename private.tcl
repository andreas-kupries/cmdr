## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Private - Command execution. Simple case.
##                An actor.

## - Privates know to do one thing, exactly, and nothing more.
##   They can process their command line to extract/validate
##   the inputs they need for their action from the arguments.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO
package require oo::util 1.2 ;# link helper
package require cmdr::actor
package require cmdr::config

# # ## ### ##### ######## ############# #####################
## Definition - Single purpose command.

oo::class create ::cmdr::private {
    superclass ::cmdr::actor
    # # ## ### ##### ######## #############
    ## Lifecycle.

    # argument specification + callback performing the action.
    # callback takes dictionary containing the actual arguments
    constructor {super name arguments cmdprefix} {
	next

	my super: $super
	my name:  $name

	set myarguments $arguments
	set mycmd       $cmdprefix
	set myinit      0
	set myhandler   {}
	return
    }

    # # ## ### ##### ######## #############

    method ehandler {cmd} {
	set myhandler $cmd
	return
    }

    # # ## ### ##### ######## #############
    ## Internal. Argument processing. Defered until required.
    ## Core setup code runs only once.

    method Setup {} {
	# Process myarguments only once.
	if {$myinit} return
	set myinit 1

	# Create and fill the parameter collection
	set myconfig [cmdr::config create config [self] $myarguments]
	return
    }

    # # ## ### ##### ######## #############

    method do {args} {
	my Setup

	if {[llength $myhandler]} {
	    # The handler is expected to have a try/finally construct
	    # which captures all of interest.
	    {*}$myhandler {
		my Run $args
	    }
	} else {
	    my Run $args
	}
    }

    method Run {words} {
	try {
	    config parse {*}$words
	} trap {XO CONFIG WRONG-ARGS NOT-ENOUGH} {e o} {
	    # Prevent interaction if globally suppressed, or just for
	    # this actor.
	    if {![cmdr interactive?] ||
		![config interactive]} {
		return {*}$o $e
	    }
	    if {![config interact]} return
	}

	# Define all parameters now, resolving defaults, validating
	# the values, etc.
	config force

	# Call actual command, hand it the filled configuration.
	{*}$mycmd $myconfig 
    }

    method help {{prefix {}}} {
	my Setup
	# help    = dict (name -> command)
	# command = list ('desc'      -> description
	#                 'options'   -> options
	#                 'arguments' -> arguments)
	#if {![my documented]} { return {} }
	return [dict create $prefix [config help]]
    }

    method complete-words {parse} {
	my Setup
	return [my completions $parse [config complete-words $parse]]
    }

    # Redirect anything not known to the parameter collection.
    method unknown {m args} {
	my Setup
	config $m {*}$args
    }

    # # ## ### ##### ######## #############

    variable myarguments mycmd myinit myconfig myhandler

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::private 0.1
