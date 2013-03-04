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

	# Create the instance to hold the arguments.
	set myconfig [xo::config create config]

	# Make the DSL commands directly available.
	# Note that "description:" is a superclass method, and renamed
	# to its DSL counterpart. With the exception of "use"
	# everything else goes to the internal configuration instance.

	link \
	    {description: description} use input \
	    optional splat flag invisible alias

	eval $myarguments

	config complete
	return
    }

    # # ## ### ##### ######## #############
    ## Commands of the specification language.

    forward flag      config add flag
    forward input     config add input
    forward invisible config add invisible
    forward optional  config add optional
    forward splat     config add splat
    forward alias     config alias

    method use {name} {
	# Pull code fragment out of the data store and run.
	uplevel 1 [my get $name]
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

	# Call actual command, hand it the filled configuration.
	$mycmd $myconfig 
    }

    method help {} {
	my Setup
	return
    }

    # # ## ### ##### ######## #############

    variable myarguments mycmd myinit myconfig

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::private 0.1
