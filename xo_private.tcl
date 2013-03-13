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
package require xo::actor
package require xo::config

# # ## ### ##### ######## ############# #####################
## Definition - Single purpose command.

oo::class create ::xo::private {
    superclass ::xo::actor
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
	set myconfig [xo::config create config [self] $myarguments]
	return
    }

    # # ## ### ##### ######## #############

    method do {args} {
	my Setup

	config parse {*}$args

	# XXX not implemented yet.
	if {[config mustinteract]} {
	    config interact
	}

	# Forcibly define the value of all parameters requesting such.
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
	if {![my documented]} { return {} }
	return [dict create $prefix [config help]]
    }

    # Redirect anything not known to the parameter collection.
    method unknown {m args} {
	config $m {*}$args
    }

    # # ## ### ##### ######## #############
    ## Command completion. This is the entry point for recursion from
    ## the higher level officers.

    ## Note that command completion for the REPL of the private is
    ## handled by the internal xo::config instance, which also manages
    ## the REPL itself.

    method complete-words {parse} {
	# No completions. Yet.
	return {}
    }

    # # ## ### ##### ######## #############

    variable myarguments mycmd myinit myconfig

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::private 0.1
