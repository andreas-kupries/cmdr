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
package require xo::flag      ;# option argument
package require xo::input     ;# regular argument
package require xo::invisible ;# internal state
package require xo::optional  ;# optional argument, but not option
package require xo::splat     ;# list of args
package require ooutil 1.2    ;# link helper
package require struct::queue

# # ## ### ##### ######## ############# #####################
## Definition - Single purpose command.

oo::class create ::xo::config {
    # # ## ### ##### ######## #############
    ## Lifecycle.

    constructor {} {
	set mypq [struct::queue P] ;# actual parameters
	set myaq [struct::queue A] ;# arguments

	set myargs  {} ;# map regular arg name to value object
	set myflags {} ;# map flag             to value object
	set mymap   {} ;# map arg names        to value object
	return
    }

    # # ## ### ##### ######## #############
    ## API for xo::private argument specification DSL.

    method complete {} {
	# Finalize the argument setup.
	# - ex: unique option prefixes.
	error "NYI [info level 0]"
	return
    }

    method add {class name valuespec} {
	my ValidateAsUnknown $name

	#package require xo::$class
	set a [xo::$class create $name $valuespec]

	# Stash into name -> arg map
	# Stash into lists, separate flags|arguments

	dict set mymap $name $a
	foreach n [$a flags] {
	    dict set myflag $n $a
	}
	foreach n [$a arguments] {
	    dict set myargs $n $a
	}
	return
    }

    method alias {name} {
	error NYI
    }

    # # ## ### ##### ######## #############
    ## API for xo::private use of the arguments.

    method parse {args} {
	# XXX TODO XXX
	# - reset the arguments (we might be in interactive shell, multiple commands).
	# - stash args into a queue for processing.
	# - stash non-option args into second queue.
	# - operate on args queue until empty, dispatching
	#   to arguments per flag vs regular.

	dict for $mymap {name a} { $a reset }
	P clear
	A clear

	P put {*}$args
	A put {*}$myargs

	# XXX special case: command only has options, and no regular arguments at all.

	while {[P size] && [A size]} {
	    set word [P peek]
	    if {[string match -* $word]} {
		# flag.
		my ProcessFlag
	    } else {
		# regular argument.
		# XXX error if config has no regular arguments.

		# Note: that the value object is responsible for
		# pulling the value out of the queue. Or not, may pass
		# it!
		[A get] process $mypq
	    }
	}

	# End conditions:
	# P left, A empty. - wrong#args, too many.
	# A left, P empty. - wrong#args, not enough.
	# A, P empty.      - OK

	return
    }

    method mustinteract {} {
	error "REPL NYI - wrong\#args"
    }

    method interact {} {
	# compare xo::officer REPL.
	error "REPL NYI"
    }

    # # ## ### ##### ######## #############

    method ProcessFlag {} {
	# Get flag. Do special handling.
	# Non special flag gets dispatched to handler (value object).
	# Handler is responsible for pulling its value.
	set flag [P get]


    }

    # # ## ### ##### ######## #############

    variable mymap myflags myargs myaq mypq

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::config 0.1
