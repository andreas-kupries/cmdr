## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Config - Collection of argument values for a private.

## - The config manages the argument values, and can parse
##   a command line against the definition, filling values,
##   issuing errors on mismatches, etc.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO
package require xo::value

package require xo::flag      ;# option argument
package require xo::input     ;# regular argument
package require xo::invisible ;# internal state
package require xo::optional  ;# optional argument, but not option
package require xo::splat     ;# list of args
package require ooutil 1.2    ;# link helper
package require struct::queue

# # ## ### ##### ######## ############# #####################
## Definition

oo::class create ::xo::config {
    # # ## ### ##### ######## #############
    ## Lifecycle.

    constructor {} {
	set mypq [struct::queue P] ;# actual parameters
	set myaq [struct::queue A] ;# arguments

	set myargs  {} ;# map regular arg name to value object
	set myflags {} ;# map flag             to value object
	set mymap   {} ;# map arg names        to value object
	set mysplat no
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
	if {$mysplat} {
	    return -code error -errorcode {XO CONFIG SPLAT ORDER} \
		"splat must be last command in argument specification"
	}

	my ValidateAsUnknown $name

	# Create and fill argument|flag container
	set a [xo::$class create [self] $name $valuespec]
	if {$class eq "splat"} {
	    set mysplat true
	}

	# Remember various mappings for the runtime argument parser.

	dict set mymap $name $a
	foreach n [$a flags]     { dict set myflag $n $a }
	foreach n [$a arguments] { dict set myargs $n $a }
	return
    }

    method alias {name} {
	error NYI
    }

    # # ## ### ##### ######## #############
    ## API for xo::private use of the arguments.

    method parse {args} {
	# - Reset the state values (we might be in interactive shell, multiple commands).
	# - Stash the parameters into a queue for processing.
	# - Stash the non-option args into second queue.
	# - Operate on parameter and arg queues until empty,
	#   dispatching the parameters to args and flags.

	dict for $mymap {name a} { $a reset }
	P clear
	A clear

	P put {*}$args
	A put {*}$myargs

	if {![llength $myargs]} {
	    # The command has no arguments. It may accept flags.

	    while {[P size]} {
		set word [P peek]
		if {![string match -* $word]} {
		    # Error. No regular arguments to accept.
		    my TooMany
		}
		my ProcessFlag
	    }

	    return
	}

	# Process commands and flags, in order.

	while {[P size] && [A size]} {
	    # This loop will terminate.
	    # Each round removes either at least one parameter,
	    # or one argument handler.

	    set word [P peek]
	    if {[string match -* $word]} {
		my ProcessFlag
		continue
	    }

	    # Note: The value instance is responsible for
	    # retrieving its value from the parameter queue.
	    # It may pass on this (xo::optional).
	    [A get] process $word $mypq
	}

	# End conditions:
	# P left, A empty. - wrong#args, too many.
	# A left, P empty. - wrong#args, not enough.
	# A, P empty.      - OK

	if {![A size] && [P size]} { my TooMany   }
	if {![P size] && [A size]} { my NotEnough }


	# XXX Go through the regular arguments and validate them?
	# XXX Or can we assume that things will work simply through
	# XXX access by the command ?
	return
    }

    method mustinteract {} {
	return 0
	# config has regular arguments, none are defined by the user
	# (!mustinteract <=> no arguments specified, and config allows that).

	error "REPL NYI - wrong\#args"
    }

    method interact {} {
	# compare xo::officer REPL.
	error "REPL NYI"
    }

    # # ## ### ##### ######## #############
    ## API for use by the actual command run by the private, and by
    ## the values in the config (which may request other values for
    ## their validation, generation, etc.). Access to argument values by name.

    method unkown {m args} {
	if {![regexp {^@(.*)$} $m -> mraw]} { next $m {*}$args ; return }
	# @name ... => handlerof(name) ...
	if {![llength $args]} { lappend args get }
	return [[dict get $mymap $name] {*}$args]
    }

    # # ## ### ##### ######## #############

    method ProcessFlag {} {
	# Get flag. Do special handling.
	# Non special flag gets dispatched to handler (value object).
	# Handler is responsible for pulling its value.
	set flag [P get]

	# Handle general special forms:
	#
	# --foo=bar ==> --foo bar
	# -f=bar    ==> -f bar

	if {[regexp {^(-[^=]+)=(.*)$} $flag --> flag value]} {
	    P unget $value
	}

	# Validate existence of flag itself
	if {![dict exists $myflags $flag]} {
	    return -code error \
		-errorcode {XO CONFIG BAD FLAG} \
		"Unknown flag $flag"
	}

	# Now map the flag name to its handler and let it deal with
	# the rest, including pulling the flag argument (if any),
	# validation, etc.

	[dict get $myflags $flag] process $flag $mypq
	return
    }

    method TooMany {} {
	return -code error \
	    -errorcode {XO CONFIG WRONG-ARGS TOO-MANY} \
	    "wrong#args, too many"
    }

    method TooMany {} {
	return -code error \
	    -errorcode {XO CONFIG WRONG-ARGS NOT-ENOUGH} \
	    "wrong#args, not enough"
    }

    # # ## ### ##### ######## #############

    variable mymap myflags myargs myaq mypq mysplat

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::config 0.1
