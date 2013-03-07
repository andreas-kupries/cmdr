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

	set splat no ;# Updated in my DefineParameter

	eval $spec

	# Postprocessing

	my SetThresholds
	my UniquePrefixes

	set mypq [struct::queue P] ;# actual parameters
	if {[llength $myargs]} {
	    set myaq [struct::queue A] ;# formal argument parameters
	}
	return
    }

    method eoptions  {} { return $myfullopt }
    method names     {} { return [dict keys $mymap] }
    method arguments {} { return $myargs }
    method options   {} { return [dict keys $myoption] }

    method lookup {name} {
	if {![dict exists $mymap $name]} {
	    return -code error -errorcode {XO CONFIG PARAMETER UNKNOWN} \
		"Expected parameter name, got \"$name\""
	}
	return [dict get $mymap $name]
    }

    method lookup-option {name} {
	if {![dict exists $myoption $name]} {
	    return -code error -errorcode {XO CONFIG PARAMETER UNKNOWN} \
		"Expected option name, got \"$name\""
	}
	return [dict get $myoption $name]
    }

    # # ## ### ##### ######## #############

    method SetThresholds {} {
	# Compute the threshold needed by optional arguments to decide
	# when they can take an argument.

	# The threshold is the number of actual parameters required to
	# satisfy all _required_ arguments coming after the current
	# argument. Computed from back to front, starting with 0 (none
	# required after the last argument), this value increments for
	# each required argument found. Optional arguments do not count.

	set required 0
	#set rlist {} ; # Debugging aid

	foreach a [lreverse $myargs] {
	    set para [dict get $mymap $a]
	    $para threshold: $required
	    #lappend rlist $required
	    if {[$para required]} {
		incr required
	    }
	}

	# Debug, show mapping.
	#puts A|$myargs|
	#puts T|[lreverse $rlist]|

	return
    }

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
	upvar 1 splat splat
	if {$splat && $order} {
	    return -code error -errorcode {XO CONFIG SPLAT ORDER} \
		"A splat must be the last argument in the specification"
	}
	my ValidateAsUnknown $name

	# Create and initialize handler.
	set para [xo::parameter create param_$name [self] \
		      $order $cmdline $required \
		      $name $desc $spec]

	# Map parameter name to handler object.
	dict set mymap $name $para

	if {$order} {
	    # Arguments, keep names, in order of definition.
	    lappend myargs $name
	    set splat [$para list]
	} else {
	    # Keep map of options to their handlers.
	    foreach option [$para options] {
		dict set myoption $option $para
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

	# Nothing to process.
	if {![P size]} return

	# Unshift the front value under consideration by
	# 'xo::parameter Take'.

	lappend arguments [P get]

	# Process the remainder for options and their values.
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
	if {![llength $arguments]} return
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

	P clear
	if {[llength $args]} { P put {*}$args }

	if {![llength $myargs]} {
	    # The command has no arguments. It may accept options.

	    while {[P size]} {
		set word [P peek]
		if {![string match -* $word]} {
		    # Error. No regular arguments to accept.
		    my tooMany
		}
		my ProcessOption
	    }
	    return
	}

	# Process commands and flags, in order.

	A clear
	A put {*}$myargs

	#puts /[A size]|[P size]
	while {[A size]} {
	    # Option ... Leaves A unchanged.
	    if {[P size]} {
		set word [P peek]
		if {[string match -* $word]} {
		    my ProcessOption
		    continue
		}
	    }

	    # Note: The parameter instance is responsible for
	    # retrieving its value from the parameter queue.  It may
	    # pass on this. This also checks if there is enough in the
	    # P queue, aborting if not.

	    set argname [A get]
	    #puts [A size]|$argname|[P size]
	    [dict get $mymap $argname] process $argname $mypq
	    #puts \t==>[P size]
	}

	#puts "a[A size] p[P size]"

	# End conditions:
	# P left, A empty. - wrong#args, too many.
	# A left, P empty. - wrong#args, not enough.
	# A, P empty.      - OK

	# Note that 'not enough' should not be reached here, but in
	# the parameter instances. I.e. early.

	if {![A size] && [P size]} { my tooMany   }
	if {![P size] && [A size]} { my notEnough }

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

    method tooMany {} {
	return -code error \
	    -errorcode {XO CONFIG WRONG-ARGS TOO-MANY} \
	    "wrong#args, too many"
    }

    method notEnough {} {
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
