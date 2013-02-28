## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Actor - Command execution. Base.
##              Actors know how to do something.

## Two types:
## - Privates know to do one thing, exactly, and nothing more.
##   They can process their command line to extract/validate
##   the inputs they need for their action from the arguments.
#
## - Officers can learn to do many things, by delegating things to the
##   actors actually able to perform it.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO

# # ## ### ##### ######## ############# #####################
## Definition - Single purpose command.

oo::class create ::xo::actor {
    # # ## ### ##### ######## #############
    ## Lifecycle

    constructor {{thename {}}} {
	my name: $thename
	return
    }

    # # ## ### ##### ######## #############
    ## Public APIs:
    #
    # - Perform an action.
    # - Return help information about the action.
    # - Return actor name.
    #
    ## Overridden by sub-classes.

    method do   {args} {}
    method help {}     {}

    method name {} {
	return $myname
    }

    method name: {thename} {
	set myname $thename
    }

    ##
    # # ## ### ##### ######## #############

    variable myname

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::actor 0.1
