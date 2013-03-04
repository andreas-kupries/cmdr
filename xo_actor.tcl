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

    constructor {} {
	set myname        {}
	set mydescription {}
	set mysuper       {}
	set mystore       {}
	return
    }

    # # ## ### ##### ######## #############
    ## Public API: Common actor attributes and behaviour
    ## - Name.
    ## - Description (help information).
    ## - Chain of command.
    ## - Associative data store

    method name {} {
	return $myname
    }

    method name: {thename} {
	set myname $thename
	return
    }

    method description {} {
	my Setup ; # Calls into the derived class
	return $mydescription
    }

    method description: {thedescription} {
	set mydescription $thedescription
	return
    }

    method super {} {
	return $mysuper
    }

    method super: {thesuper} {
	set mysuper $thesuper
	return
    }

    method keys {} {
	my Setup
	return [dict keys $mystore]
    }

    method get {key} {
	my Setup ; # Call into derived class.

	# Satisfy from local store first ...
	if {[dict exists $mystore $key]} {
	    return [dict get $mystore $key]
	}
	# ... then ask in the chain of command ...
	if {$super ne {}} {
	    return [$super get $key]
	}
	# ... and fail if we are at the top.
	return -code error -errorcode {XO STORE UNKNOWN} \
	    "Expected known key for get, got \"$key\""
    }

    method set {key data} {
	dict set mystore $key $data
	return
    }

    # # ## ### ##### ######## #############
    ## Public APIs:
    ## Overridden by sub-classes.

    # - Perform an action.
    # - Return help information about the action.

    method do   {args} {}
    method help {}     {}

    ##
    # # ## ### ##### ######## #############

    variable myname mydescription mysuper mystore

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::actor 0.1
