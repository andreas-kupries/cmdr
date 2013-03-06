## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Value - Definition of a single command argument (for a private).

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO
package require oo::util 1.2    ;# link helper

# # ## ### ##### ######## ############# #####################
## Definition

oo::class create ::xo::value {
    # # ## ### ##### ######## #############
    ## Lifecycle.

    constructor {theconfig order hide list required name desc valuespec} {
	# The valuespec is parsed immediately.  In contrast to actors,
	# which defer until they are required.  As arguments are
	# required when the using private is required further delay is
	# nonsense.

	set myname        $name
	set mydescription $desc

	set myisordered   $order
	set myishidden    $hide
	set myislist      $list
	set myisrequired  $required

	set myinteractive no ;# no interactive query of value
	set myprompt      {} ;# no prompt for interaction
	set myhasdefault  no ;# flag for default existence
	set mydefault     {} ;# default value - raw
	set mygenerate    {} ;# generator command
	set myvalidate    {} ;# validation command
	set myon          {} ;# action-on-definition command
	set mythreshold   {} ;# threshold for optional arguments
	set myflags       {} ;# Flags to recognize for options.

	# Import the DSL commands to translate the specification.
	link \
	    {alias    Alias} \
	    {test     Test} \
	    {optional Optional} \
	    {interact Interact} \
	    {default  Default} \
	    {generate Generate} \
	    {validate Validate} \
	    {on       On}
	eval $valuespec

	# Postprocessing ... Fill in validation and other defaults

	my ValidationDefault
	my DefaultDefault
	my Flags
	set myflags [lsort -dict $myflags]

	# Check constraints.

	my Assert {$myisordered||$myhasdefault||[llength $mygenerate]||$myinteractive} \
	    "Unordered parameter $myname must have default, generator, or interaction"
	my Assert {$myisrequired||$myhasdefault||[llength $mygenerate]||$myinteractive} \
	    "Optional parameter $myname must have default, generator, or interaction"
	my Assert {!$myhasdefault||![llength $mygenerate]} \
	    "Parameter $myname cannot have both default and generator"
	my Assert {!$myinteractive||($myprompt ne {})} \
	    "Interactive parameter $myname must have a prompt"
	my Assert {!$myislist||$myisordered} \
	    "List parameter $myname must be an argument"
	my Assert {!$myishidden||(!$myinteractive && !$myisordered)} \
	    "Hidden parameter must be non-interactive option"

	# Import the whole collection of parameters this one is a part
	# of into our namespace, as the fixed command "config", for
	# use by the various command prefixes (generate, validate,
	# on), all of which will be run in our namespace context.

	set myconfig $theconfig
	interp alias {} [self namespace]::config {} $theconfig

	# Start with a proper runtime state
	my reset
	return
    }

    # Add context name into it?
    method name        {} { return $myname }
    method description {} { return $mydescription }

    # Accessors for parameter configuration
    method ordered     {} { return $myisordered }
    method required    {} { return $myisrequired }
    method hidden      {} { return $myishidden }
    method list        {} { return $myislist }
    method interactive {} { return $myinteractive }
    method prompt      {} { return $myprompt }
    method generator   {} { return $mygenerate }
    method validator   {} { return $myvalidate }
    method on          {} { return $myon }
    method hasdefault  {} { return $myhasdefault }
    method default     {} { return $mydefault }
    method threshold   {} { return $mythreshold }

    method threshold: {n} {
	# Ignore when parameter is required.
	if {$myisrequired} return
	# Ignore when parameter is in test-mode.
	if {$mythreshold ne {}} return
	set mythreshold $n
	return
    }

    # # ## ### ##### ######## #############
    ## API for value specification DSL.

    method Alias {name} {
	my Assert {!$myisordered} "Argument $myname cannot have aliases"
	my Assert {!$myishidden}  "Hidden parameter $myname cannot have aliases"
	lappend myflags [my Option $name]
	return
    }

    method Optional {} {
	set myisrequired no
	return
    }

    method Interact {{prompt {}}} {
	# (c6)
	my Assert {!$myishidden} "Hidden parameter $myname cannot be set by the user"
	if {$prompt eq {}} { set prompt "Enter ${myname}:" }
	set myinteractive yes
	set myprompt $prompt
	return
    }

    method Default {value} {
	# (c3)
	my Assert {![llength $mygenerate]} "Parameter $myname default conflicts with generate command"
	set myhasdefault yes
	set mydefault    $value
	return
    }

    method Generate {cmd} {
	# (c3)
	my Assert {!$myhasdefault} "Parameter $myname generat commands conflicts with default value"
	set mygenerate $cmd
	return
    }

    method Validate {cmd} {
	set words [lassign $cmd cmd]

	# Allow FOO shorthand for xo::validate::FOO
	if {![llength [info commands $cmd]] &&
	    [llength [info commands ::xo::validate::$cmd]]} {
	    set cmd xo::validate::$cmd
	}
	set cmd [list $cmd {*}$words]
	set myvalidate $cmd
	return
    }

    method On {cmd} {
	set myon $cmd
	return
    }

    method Test {} {
	my Assert {!$myishidden} \
	    "Hidden parameter $myname cannot change test-mode for optional argument"
	my Assert {$myisordered} \
	    "Option $myname cannot change test-mode for optional argument"
	my Assert {!$myisrequired} \
	    "Required argument $myname cannot change test-mode for optional argument"
	# Switch the mode of the optional argument from testing by
	# argument counting to peeking at the queue and validating.
	set mythreshold -1
	return
    }

    # # ## ### ##### ######## #############

    method Assert {expr msg} {
	if {[uplevel 1 [list expr $expr]]} return
	return -code error -errorcode {XO PARAMETER FAIL} $msg
    }

    method ValidationDefault {} {
	if {[llength $myvalidate]} return

	# The parameter has no user-specified validator. Try to deduce
	# something from the default value if there is any. If there
	# is not, go with boolean. Exception: For a generator command
	# always go with identity. The constraints ensure that we have
	# no default in that case.

	if {[llength $mygenerate]} {
	    set myvalidate xo::validate::identity
	} elseif {!$myhasdefault} {
	    set myvalidate xo::validate::boolean
	} elseif {[string is boolean -strict $mydefault]} {
	    set myvalidate xo::validate::boolean
	} elseif {[string is integer -strict $mydefault]} {
	    set myvalidate xo::validate::integer
	} else {
	    # Unable to deduce a type from the default.
	    # assume identity.
	    set myvalidate xo::validate::identity
	}
	return
    }

    method DefaultDefault {} {
	# Ignore this when a generator command is specified.
	if {[llength $mygenerate]} return

	# Ditto if the user specified something.
	if {$myhasdefault} return

	if {$myislist} {
	    # A list parameter defaults to empty, regardless of validator.
	    my Default {}
	} else {
	    # Ask the chosen validator for a default value.
	    my Default [$myvalidate default]
	}
	return
    }

    method Flags {} {
	# Ordered and hidden parameters have no flags.
	# NOTE: Ordered may change in future (--ask-FOO)
	if {$myisordered} return
	if {$myishidden} return
	lappend myflags [my Option $myname]

	# Special flags for boolean options
	# XXX Consider pushing this into the validators.
	if {$myvalidate ne "xo::validate::boolean"} return
	lappend myflags --no-$myname
	return
    }

    method Option {name} {
	if {[string length $name] == 1} {
	    return "-$name"
	}
	return "--$name"
    }

    # # ## ### ##### ######## #############
    ## API for management by xo::config

    method reset {} {
	# Runtime configuration, initial state
	set myhasstring no
	set mystring    {}
	set myhasvalue  no
	set myvalue     {}
	return
    }

    # # ## ### ##### ######## #############
    ## API for management by xo::config.

    method options {} {
	return $myflags
    }

    method process {n queue} {
	my Assert {!$myishidden} "Illegal command line input for hidden parameter"

	if {$myisordered} {
	    my ProcessArgument $queue
	    return
	}

	# Option parameters.
	my ProcessOption $queue
	return
    }

    method Take {queue} {
	if {$mythreshold >= 0} {

	    # Choose by checking argument count against a threshold.
	    # For this to work correctly we now have to process all
	    # the remaining options first.

	    config parse-options
	    if {[$queue size] < $mythreshold} { return 0 }
	} else {
	    # Choose by peeking and validating the front value.
	    try {
		$myvalidate validate [$queue peek]
	    } trap {XO VALIDATE} {e o} {
		return 0
	    }
	}
	return 1
    }

    method ProcessArgument {queue} {
	# Argument parameters.

	if {$myisrequired} {
	    # Required arguments. Unconditionally retrieve their parameter value.
	    if {$myislist} {
		my Assert {[$queue size]} \
		    "Required list argument $myname cannot be empty"
		set mystring [$queue get [$queue size]]
	    } else {
		set mystring [$queue get]
	    }
	    set myhasstring 1
	    return
	}

	# Optional argument. Conditionally retrieve the parameter
	# value based on argument count and threshold or validation of
	# the value. For the count+threshold method to work we have to
	# process (i.e. remove) all the options first.

	# Note also the possibility of the argument being a list.

	if {![my Take $queue]} return
	set mystring [$queue get]
	set myhasstring 1
	return
    }

    method ProcessOption {queue} {
	if {$myvalidate eq "xo::validate::boolean"} {
	    # XXX Consider a way of pushing this into the validator classes.

	    # Look for and process boolean special forms.

	    # Insert implied boolean flag value.
	    #
	    # --foo    non-boolean-value ==> --foo YES non-boolean-value
	    # --no-foo non-boolean-value ==> --foo NO  non-boolean-value

	    # Invert meaning of option.
	    # --no-foo YES ==> --foo NO
	    # --no-foo NO  ==> --foo YES

	    # Take implied or explicit value.
	    if {![string is boolean -strict [$queue peek]]} {
		set value yes
	    } else {
		set value [$queue get]
	    }

	    # Invert meaning, if so requested.
	    if {[string match --no-* $n]} {
		set value [expr {!$value}]
	    }
	} else {
	    # Everything else has no special forms.
	    set value [$queue get]
	}

	set mystring    $value
	set myhasstring 1
	return
    }

    # # ## ### ##### ######## #############
    ## APIs for use in the actual command called by the private
    ## containing the xo::config holding this value.
    #
    # - retrieve user string
    # - retrieve validated value, internal representation.
    # - query if a value is defined.

    method string {} {
	if {!$myhasstring} { return -code error Undefined }
	return $mystring
    }

    method string? {} {
	return $myhasstring
    }

    method get {} {
	# compute argument value if any, cache result.
	#error NYI

	# Calculate value, from most prefered to least
	#
	# (1) User entered value ?
	#     => Validate, transforms.
	#
	# (2) Generation command ?
	#     => Run
	#
	# (3) Default value ?
	#     => Validate, transforms
	#
	# (4) Interactive entry possible ? (general config, plus per value)
	#     Enter, validate, transforms
	#     - mini shell - ^C abort
	#     - completion => Validator API
	#
	# (5) Optional ?
	#     => It is ok to not have the value.
	#
	# (6) FAIL. 


    }

    method defined? {} {
	# determine if we have an argument value, may compute it.
	#error NYI

	# Test if we have a value
	# Similar to 'get' above, no validation, no transforms

	return 0
    }

    # # ## ### ##### ######## #############

    variable myconfig myname mydescription \
	myisordered myishidden myislist myisrequired \
	myinteractive myprompt mydefault myhasdefault \
	myflags myon mygenerate myvalidate mythreshold \
	myhasstring mystring myhasvalue myvalue

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::value 0.1
