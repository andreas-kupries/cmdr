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
package require oo::util 1.2    ;# link helper
package require struct::queue 1 ;#
package require xo::validate    ; # Core validator commands.
package require xo::parameter       ; # Parameters

# # ## ### ##### ######## ############# #####################
## Definition

oo::class create ::xo::config {
    # # ## ### ##### ######## #############
    ## Lifecycle.

    constructor {context spec} {
	# Import the context (xo::private).
	interp alias {} [self namespace]::context {} $context

	# Initialize collection state.
	set mymap     {} ;# parameter name -> object
	set myoption  {} ;# option         -> object
	set myfullopt {} ;# option prefix  -> option
	set myargs    {} ;# List of argument names.

	# Import the DSL commands.
	link \
	    {description Description} \
	    {use         Use} \
	    {input       Input} \
	    {option      Option} \
	    {state       State}

	set splat no
	set min 0 ; set minlist {}
	set max 0 ; set maxlist {}

	eval $spec

	foreach a [lreverse $myargs] min $minlist {
	    [dict get $mymap $a] threshold: $min
	}

	my UniquePrefixes

	set mypq [struct::queue P] ;# actual parameters
	if {[llength $myargs]} {
	    set myaq [struct::queue A] ;# formal argument parameters
	}
	return
    }

    method options {} { return $myfullopt }
    method names   {} { return [dict keys $mymap] }

    method lookup {name} {
	if {![dict exists $mymap $name]} {
	    return -code error -errorcode {XO CONFIG PARAMETER UNKNOWN} \
		"Expected parameter name, got \"$name\""
	}
	return [dict get $mymap $name]
    }

    # # ## ### ##### ######## #############

    method UniquePrefixes {} {
	dict for {k v} $myoption {
	    set prefix ""
	    foreach c [split $k {}] {
		append prefix $c
		if {$prefix in {- --}} continue
		if {[dict exists $myoption $prefix]} {
		    dict set myfullopt $prefix [list $k]
		} else {
		    dict lappend myfullopt $prefix $k
		}
	    }
	}

	#array set _o $myoption  ; parray _o ; unset _o
	#array set _f $myfullopt ; parray _f ; unset _f
	return
    }

    # # ## ### ##### ######## #############
    ## API for xo::private parameter specification DSL.

    # Description is for the context, i.e. the private.
    forward Description context description:

    # Bespoke 'source' command for common specification fragments.
    method Use {name} {
	# Pull code fragment out of the data store and run.
	uplevel 1 [context get $name]
	return
    }

    # Parameter definition itself.
    #       order, cmdline, required (O C R) name ?spec?
    forward Input  my DefineParameter 1 1 1
    forward Option my DefineParameter 0 1 0
    forward State  my DefineParameter 0 0 1

    method DefineParameter {
	    order cmdline required
	    name desc {spec {}}
    } {
	upvar 1 splat splat min min minlist minlist max max maxlist maxlist
	if {$splat && $order} {
	    return -code error -errorcode {XO CONFIG SPLAT ORDER} \
		"splat must be last command in argument specification"
	}
	my ValidateAsUnknown $name

	# Create and initialize handler.
	set a [xo::parameter create param_$name [self] \
		   $order $cmdline $required \
		   $name $desc $spec]

	# Map parameter name to handler object.
	dict set mymap $name $a

	if {$order} {
	    set splat [$a list]
	    if {$list} {
		set max Inf
	    } else {
		incr max
	    }
	    if {$required} { incr min }
	    lappend maxlist $max
	    lappend minlist $min
	    # Arguments, keep names, in order of definition.
	    lappend myargs $name
	} else {
	    # Keep map of options to their handlers.
	    foreach option [$a options] {
		dict set myoption $option $a
	    }
	}
	return
    }

    method ValidateAsUnknown {name} {
	if {![dict exists $mymap $name]} return
	return -code error -errorcode {XO CONFIG KNOWN} \
	    "Duplicate parameter $name, already specified."
    }

    # # ## ### ##### ######## #############
    ## API for xo::private use of the arguments.
    ## Runtime parsing of a command line, parameter extraction.

    method parse-options {} {
	# The P queue contains a mix of options and arguments.  An
	# optional argument was encountered and has called on this to
	# now process all options so that it can decode wether to take
	# the front value for itself or not. The front value is
	# definitely not an option.

	lappend arguments [P get]

	while {[P size]} {
	    set word [P peek]
	    if {[string match -* $word]} {
		my ProcessOption
		continue
	    }
	    lappend arguments [P get]
	}

	# Refill the queue with the arguments which remained after
	# option processing.
	P put {*}$arguments
	return
    }

    method parse {args} {
	# - Reset the state values (we might be in interactive shell, multiple commands).
	# - Stash the parameters into a queue for processing.
	# - Stash the (ordered) arguments into a second queue.
	# - Operate on parameter and arg queues until empty,
	#   dispatching the words to handlers as needed.

	dict for {name a} $mymap { $a reset }

	if {![llength $myargs]} {
	    # The command has no arguments. It may accept options.

	    P clear
	    P put {*}$args

	    while {[P size]} {
		set word [P peek]
		if {![string match -* $word]} {
		    # Error. No regular arguments to accept.
		    my TooMany
		}
		my ProcessOption
	    }
	    return
	}

	# Process commands and flags, in order.

	P clear
	A clear

	P put {*}$args
	A put {*}$myargs

	while {[P size] && [A size]} {
	    # This loop will terminate.
	    # Each round removes either at least one parameter,
	    # or one argument handler.

	    set word [P peek]
	    if {[string match -* $word]} {
		my ProcessOption
		continue
	    }

	    # Note: The parameter instance is responsible for
	    # retrieving its value from the parameter queue.
	    # It may pass on this.

	    [dict get $mymap [A get]] process $word $mypq
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

    method unknown {m args} {
	if {![regexp {^@(.*)$} $m -> mraw]} { next $m {*}$args ; return }
	# @name ... => handlerof(name) ...
	if {![llength $args]} { lappend args get }
	return [[my lookup $name] {*}$args]
    }

    # # ## ### ##### ######## #############

    method ProcessOption {} {
	# Get option. Do special handling.
	# Non special option gets dispatched to handler (xo::parameter instance).
	# The handler is responsible for retrieved the option's value.
	set option [P get]

	# Handle general special forms:
	#
	# --foo=bar ==> --foo bar
	# -f=bar    ==> -f bar

	if {[regexp {^(-[^=]+)=(.*)$} $option --> option value]} {
	    P unget $value
	}

	# Validate existence of the option
	if {![dict exists $myfullopt $option]} {
	    return -code error \
		-errorcode {XO CONFIG BAD OPTION} \
		"Unknown option $option"
	}

	# Map from option prefix to full option
	set options [dict get $myfullopt $option]
	if {[llength $options] > 1} {
	    return -code error \
		-errorcode {XO CONFIG AMBIGUOUS OPTION} \
		"Ambiguous option prefix $option, matching [join $options {, }]"
	}

	# Now map the fully expanded option name to its handler and
	# let it deal with the remaining things, including retrieval
	# of the option argument (if any), validation, etc.

	[dict get $myoption [lindex $options 0]] process $option $mypq
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

    variable mymap myoption myfullopt myargs myaq mypq

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::config 0.1
