## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Value - Definition of command parameters (for a private).
## See "doc/notes_parameter.txt"

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO
package require oo::util 1.2    ;# link helper

# # ## ### ##### ######## ############# #####################
## Definition

oo::class create ::xo::parameter {
    # # ## ### ##### ######## #############
    ## Lifecycle.

    constructor {theconfig order cmdline required name desc valuespec} {
	# The valuespec is parsed immediately.  In contrast to actors,
	# which defer until they are required.  As arguments are
	# required when the using private is required further delay is
	# nonsense.

	set myname        $name		; # [R1]
	set mydescription $desc		; # [R2]

	set myisordered   $order	; # [R3,4,5,6]
	set myiscmdline   $cmdline	; # [R3,4,5,6]
	set myisrequired  $required	; # [R7,8,9,10]

	my C1_StateIsUnordered
	my C2_OptionIsOptional
	my C3_StateIsRequired

	set myislist      no ;# scalar vs list parameter

	set myhasdefault  no ;# flag for default existence
	set mydefault     {} ;# default value - raw
	set mygenerate    {} ;# generator command
	set myinteractive no ;# no interactive query of value
	set myprompt      {} ;# no prompt for interaction

	set myvalidate    {} ;# validation command
	set mywhendef     {} ;# action-on-definition command

	set mythreshold   {} ;# threshold for optional arguments

	my ExecuteSpecification $valuespec

	# Start with a proper runtime state
	my reset
	return
    }

    # # ## ### ##### ######## #############
    # Constraints.

    forward C1_StateIsUnordered \
	my Assert {$myiscmdline || $myisordered} \
	{State parameter "@" must be unordered}

    forward C2_OptionIsOptional \
	my Assert {!$myisrequired || !$myiscmdline || $myisordered} \
	{Option argument "@" must be optional}

    forward C3_StateIsRequired \
	my Assert {$myiscmdline || $myisrequired} \
	{State parameter "@" must be required}

    forward C5_OptionalHasAlternateInput \
	my Assert {$myisrequired||$myhasdefault||[llength $mygenerate]||$myinteractive} \
	{Optional parameter "@" must have default value, generator command, or interaction}

    forward C5_StateHasAlternateInput \
	my Assert {$myiscmdline||$myhasdefault||[llength $mygenerate]||$myinteractive} \
	"State parameter "@" must have default value, generator command, or interaction"

    forward C6_RequiredArgumentForbiddenDefault \
	my Assert {!$myhasdefault || !$myisrequired || !$myiscmdline} \
	{Required argument "@" must not have default value}

    forward C6_RequiredArgumentForbiddenGenerator \
	my Assert {![llength $mygenerate] || !$myisrequired || !$myiscmdline} \
	{Required argument "@" must not have generator command}

    forward C6_RequiredArgumentForbiddenInteract \
	my Assert {!$myinteractive || !$myisrequired || !$myiscmdline} \
	{Required argument "@" must not have user interaction}

    forward C7_DefaultGeneratorConflict \
	my Assert {!$myhasdefault || ![llength $mygenerate]} \
	{Default value and generator command for parameter "@" are in conflict}

    # # ## ### ##### ######## #############
    ## Syntax constraints.

    forward Alias_Option \
	my Assert {$myiscmdline && !$myisordered} \
	{Non-option parameter "@" cannot have alias}

    forward Optional_Option \
	my Assert {$myisordered} \
	{Option "@" is already optional}

    forward Optional_State \
	my Assert {$myiscmdline} \
	{State parameter "@" cannot be optional}

    forward Test_NotState \
	my Assert {$myiscmdline} \
	{State parameter "@" has no test-mode}

    forward Test_NotOption \
	my Assert {$myisordered} \
	{Option "@" has no test-mode}

    forward Test_NotRequired \
	my Assert {!$myisrequired} \
	{Required argument "@" has no test-mode}

    # # ## ### ##### ######## #############
    ## Public accessors...

    # Add context name into it?
    method name        {} { return $myname }
    method description {} { return $mydescription }

    # Accessors for the various properties
    method ordered      {} { return $myisordered }
    method cmdline      {} { return $myiscmdline }
    method required     {} { return $myisrequired }
    method list         {} { return $myislist }

    # - alternate input
    method hasdefault   {} { return $myhasdefault }
    method default      {} { return $mydefault }
    method generator    {} { return $mygenerate }
    method interactive  {} { return $myinteractive }
    method prompt       {} { return $myprompt }

    method validator    {} { return $myvalidate }
    method when-defined {} { return $mywhendef }

    # - test mode of optional arguments (not options)
    method threshold    {} { return $mythreshold }
    method threshold: {n} {
	# Ignore when parameter is required, or already set to mode peek+test
	if {$myisrequired || ($mythreshold ne {})} return
	set mythreshold $n
	return
    }

    # # ## ### ##### ######## #############
    ## API for value specification DSL.

    method ExecuteSpecification {valuespec} {
	set myflags {} ;# List of flags to recognize for an option.

	# Import the DSL commands to translate the specification.
	link \
	    {alias        Alias} \
	    {default      Default} \
	    {generate     Generate} \
	    {interact     Interact} \
	    {list         List} \
	    {optional     Optional} \
	    {test         Test} \
	    {validate     Validate} \
	    {when-defined WhenDefined}
	eval $valuespec

	# Postprocessing ... Fill in validation and other defaults

	my FillMissingValidation
	my FillMissingDefault
	my DefineStandardFlags
	set myflags [lsort -dict $myflags]

	# Check all constraints.

	my C1_StateIsUnordered
	my C2_OptionIsOptional
	my C3_StateIsRequired
	my C5_OptionalHasAlternateInput
	my C5_StateHasAlternateInput
	my C6_RequiredArgumentForbiddenDefault
	my C6_RequiredArgumentForbiddenGenerator
	my C6_RequiredArgumentForbiddenInteract
	my C7_DefaultGeneratorConflict

	# Import the whole collection of parameters this one is a part
	# of into our namespace, as the fixed command "config", for
	# use by the various command prefixes (generate, validate,
	# when-defined), all of which will be run in our namespace
	# context.

	set myconfig $theconfig
	interp alias {} [self namespace]::config {} $theconfig
	return
    }

    method List {} {
	set myislist yes
	return
    }

    method Alias {name} {
	my Alias_Option
	lappend myflags [my Option $name]
	return
    }

    method Optional {} {
	# Arguments only. Options are already optional, and state parameters must not be.
	my Optional_Option
	my Optional_State
	set myisrequired no
	return
    }

    method Interact {{prompt {}}} {
	# Check relevant constraint(s) after making the change. That
	# is easier than re-casting the expressions for the proposed
	# change.
	set myinteractive yes
	my C6_RequiredArgumentForbiddenInteract
	if {$prompt eq {}} { set prompt "Enter ${myname}:" }
	set myprompt $prompt
	return
    }

    method Default {value} {
	# Check relevant constraint(s) after making the change. That
	# is easier than re-casting the expressions for the proposed
	# change.
	set myhasdefault yes
	set mydefault    $value
	my C6_RequiredArgumentForbiddenDefault
	my C7_DefaultGeneratorConflict
	return
    }

    method Generate {cmd} {
	# Check relevant constraint(s) after making the change. That
	# is easier than re-casting the expressions for the proposed
	# change.
	set mygenerate $cmd
	my C6_RequiredArgumentForbiddenGenerator
	my C7_DefaultGeneratorConflict
	return
    }

    method Validate {cmd} {
	set words [lassign $cmd cmd]
	# Allow FOO shorthand for xo::validate::FOO
	if {![llength [info commands $cmd]] &&
	    [llength [info commands ::xo::validate::$cmd]]} {
	    set cmd ::xo::validate::$cmd
	}
	set cmd [list $cmd {*}$words]
	set myvalidate $cmd
	return
    }

    method WhenDefined {cmd} {
	set mywhendef $cmd
	return
    }

    method Test {} {
	my Test_NotState    ; # Order of tests is important, enabling us
	my Test_NotOption   ; # to simplify the guard conditions inside.
	my Test_NotRequired ; #
	# Switch the mode of the optional argument from testing by
	# argument counting to peeking at the queue and validating.
	set mythreshold -1
	return
    }

    # # ## ### ##### ######## #############
    ## DSL Helper commands.

    method Assert {expr msg} {
	if {[uplevel 1 [list expr $expr]]} return
	return -code error \
	    -errorcode {XO PARAMETER CONSTRAINT VIOLATION} \
	    [string map [list @ $myname] $msg]
    }

    method FillMissingValidation {} {
	# Ignore when the user specified a validation type
	if {[llength $myvalidate]} return

	# The parameter has no user-specified validation type. Deduce
	# a validation type from the default value, if there is
	# any. If there is not, go with "boolean". Exception: Go with
	# "identity" when a generator command is specified. Note that
	# the constraints ensured that we have no default value in
	# that case.

	if {[llength $mygenerate]} {
	    set myvalidate ::xo::validate::identity
	} elseif {!$myhasdefault} {
	    set myvalidate ::xo::validate::boolean
	} elseif {[string is boolean -strict $mydefault]} {
	    set myvalidate ::xo::validate::boolean
	} elseif {[string is integer -strict $mydefault]} {
	    set myvalidate ::xo::validate::integer
	} else {
	    set myvalidate ::xo::validate::identity
	}
	return
    }

    method FillMissingDefault {} {
	# Ignore when the user specified a default value.
	# Ditto when the user specified a generator command.
	# Ditto if the parameter is a required argument.
	if {$myhasdefault ||
	    [llength $mygenerate] ||
	    ($myiscmdline && $myisordered && $myisrequired)
	} return

	if {$myislist} {
	    # For a list parameter the default is the empty list,
	    # regardless of the validation type.
	    my Default {}
	} else {
	    # For non-list parameters ask the chosen validation type
	    # for a default value.
	    my Default [$myvalidate default]
	}
	return
    }

    method DefineStandardFlags {} {
	# Only options have flags, arguments and state don't.
	# NOTE: Arguments may change in the future (--ask-FOO)
	if {!$myiscmdline || $myisordered} return

	# Flag derived from option name.
	lappend myflags [my Option $myname]
	# Special flags for boolean options
	# XXX Consider pushing this into the validators.
	if {$myvalidate ne "::xo::validate::boolean"} return
	lappend myflags --no-$myname
	return
    }

    method Option {name} {
	# Short options (single character) get a single-dash '-'.
	# Long options use a double-dash '--'.
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

    method options {} { return $myflags }

    method process {n queue} {
	my Assert {!$myiscmdline} "Illegal command line input for state parameter"

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
	# Arguments.

	if {$myisrequired} {
	    # Required. Unconditionally retrieve its parameter value.
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

	# Optional. Conditionally retrieve the parameter value based
	# on argument count and threshold or validation of the
	# value. For the count+threshold method to work we have to
	# process (i.e. remove) all the options first.

	# Note also the possibility of the argument being a list.

	if {![my Take $queue]} return

	if {$myislist} {
	    set mystring [$queue get [$queue size]]
	} else {
	    set mystring [$queue get]
	}
	set myhasstring 1
	return
    }

    method ProcessOption {queue} {
	if {$myvalidate eq "::xo::validate::boolean"} {
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

	if {$myislist} {
	    lappend mystring $value
	} else {
	    set mystring $value
	}
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
	myisordered myiscmdline myislist myisrequired \
	myinteractive myprompt mydefault myhasdefault \
	myflags mywhendef mygenerate myvalidate mythreshold \
	myhasstring mystring myhasvalue myvalue

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::parameter 0.1
