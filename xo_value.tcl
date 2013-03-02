## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Value - Definition of a single command argument (for a private).

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO
package require ooutil 1.2    ;# link helper

# # ## ### ##### ######## ############# #####################
## Definition

oo::class create ::xo::value {
    # # ## ### ##### ######## #############
    ## Lifecycle.

    constructor {theconfig name valuespec} {
	# The valuespec is parsed immediately.  In contrast to actors,
	# which defer until they are required.  As arguments are
	# required when the using private is required further delay is
	# nonsense.

	set myname $name

	# Value's configuration from spec.
	set mydescription {} ;# no description
	set myhidden      no ;# visible to help
	set myinteractive no ;# no interactive query of value
	set myprompt      {} ;# no prompt for interaction
	set mydefault     {} ;# default value - raw
	set myhasdefault  no ;# flag for default existence
	set mygenerate    {} ;# generator command
	set myvalidate    {} ;# validation command
	set myon          {} ;# action-on-definition command

	# Translate the specification.
	link description hidden interactive default generate validate on
	eval $valuespec
	my FinalizeSpec

	my reset

	# Make the whole collection of arguments this one is a part of
	# available in our namespace as fixed command "config", for
	# the various command prefixes (which will be run in that
	# namespace context).
	set myconfig $theconfig
	interp alias {} [self namespace]::config {} $theconfig
	return
    }

    # # ## ### ##### ######## #############
    ## API for value specification DSL.
    ## The derived classes may override one or more of these
    ## to customize the DSL for their situation.

    method description {text} {
	set mydescription $text
	return
    }

    method hidden {} {
	set myhidden yes
	return
    }

    method interactive {{prompt {}}} {
	if {$prompt eq {}} { set prompt "Enter ${myname}:" }
	set myinteractive yes
	set myprompt {}
	return
    }

    method default {value} {
	set myhasdefault yes
	set mydefault    $value
	return
    }

    method generate {cmd} {
	set mygenerate $cmd
	return
    }

    method validate {cmd} {
	set words [lassign $cmd cmd]

	# Allow FOO shorthand for xo::validate::FOO
	if {![llength [info commands $cmd]] &&
	    [llength [info commands xo::validate::$cmd]]} {
	    set cmd xo::validate::$cmd
	}
	set cmd [list $cmd {*}$words]
	set myvalidate $cmd
	return
    }

    method on {cmd} {
	set myon $cmd
	return
    }

    # # ## ### ##### ######## #############
    ## Must be defined by derived classes.

    method FinalizeSpec {} {
	if {$myvalidate eq {}} {
	    # No validator specified. Try to deduce something from the
	    # default value if there is any. If there is not, go with
	    # boolean.

	    if {!$myhasdefault} {
		set myvalidate xo::validate::boolean
	    } elseif {[string is boolean -strict $mydefault]} {
		set myvalidate xo::validate::boolean
	    } elseif {[string is integer -strict $mydefault]} {
		set myvalidate xo::validate::integer
	    } else {
		# unable to deduce a type from the default.
		# assume identity.
		set myvalidate xo::validate::identity
	    }
	}

	if {!$myhasdefault} {
	    # Without a default determine one from the chosen
	    # validator.

	    if {$myvalidate eq "xo::validate::boolean"} {
		my default no
	    } elseif {$myvalidate eq "xo::validate::integer"} {
		my default 0
	    } elseif {$myvalidate eq "xo::validate::identity"} {
		my default {}
	    }
	}
	return
    }

    # # ## ### ##### ######## #############
    ## API for management by xo::config

    method reset {} {
	# Runtime configuration, initial state

	set myhasstring 0
	set mystring {}
	set myhasvalue 0
	set myvalue  {}
	return
    }

    # # ## ### ##### ######## #############
    ## API for management by xo::config.
    ## Implemented in the derived classes.

    method flags     {}        { return -code error "Undefined. Extend the sub-class" }
    method arguments {}        { return -code error "Undefined. Extend the sub-class" }
    method process   {n queue} { return -code error "Undefined. Extend the sub-class" }

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

    method get {} {
	# compute argument value if any, cache result.
	error NYI
    }

    method defined? {} {
	# determine if we have an argument value, may compute it.
	error NYI
    }

    # # ## ### ##### ######## #############

    variable myconfig myname mydescription myhidden myinteractive \
	myprompt mydefault myhasdefault myon mygenerate \
	myvalidate myhasstring mystring myhasvalue myvalue

    # # ## ### ##### ######## #############

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Derived classes for the different kinds of arguments.

# # ## ### ##### ######## ############# #####################

oo::class create ::xo::flag {
    # DSL overrides.

    method interactive {} {
	return -code error "Flag cannot be interactive"
    }

    # API overrides.

    method flags {} {
	lappend res [my Option $myname]
	if {$myvalidate eq "xo::validate::boolean"} {
	    lappend res --no-$myname
	}
	return $res
    }

    method arguments {} { return {} }

    method process {n queue} {
	# XXX Note: Can stuff like this put into the validation class?

	if {$myvalidate eq "xo::validate::boolean"} {
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
}

# # ## ### ##### ######## ############# #####################

oo::class create ::xo::input {
    # No DSL overrides

    # API overrides
    # No flags. XXX Maybe: --ask-FOO in the future ?
    method flags {} { return {} }

    method arguments {} { return [list $myname] }

    method process {n queue} {
	# pull value. validation comes later, when the value of this
	# argument is actually requested somewhere.
	set mystring    [$queue get]
	set myhasstring 1
	return
    }
}

# # ## ### ##### ######## ############# #####################

oo::class create ::xo::invisible {
    # DSL overrides

    # Ignore description of invisible (state-only) argument.
    method description {text} {}

    # Ignore hidden setting. Implied in class.
    method hidden {} {}

    method interactive {} {
	return -code error "Invisible (state-only) argument cannot be interactive"
    }

    method FinalizeSpec {} {
	# Invisible argument does not go into help.
	set myhidden yes

	if {![llength $mygenerate] && !$myhasdefault} {
	    return -code error \
		"Invisible argument must have a generator or a default"
	}
	return
    }

    # API overrides

    method flags     {} { return {} }
    method arguments {} { return {} }

    method process   {n queue} {
	return -code error "Illegal command line input for state-only data"
    }
}

# # ## ### ##### ######## ############# #####################

oo::class create ::xo::optional {
    # No DSL overrides

    # API overrides

    # Same as input. Maybe an intermediate base class for these two?
    # No flags. XXX Maybe: --ask-FOO in the future ?
    method flags {} { return {} }
    method arguments {} { return [list $myname] }

    method process {n queue} {
	# How to choose whether to pull value from queue or not?!

	# XXX (a) Peek, run through validation, pass if it fails to validate.
	# XXX (b) Counting - How many arguments are in the queue,
	# versus how many are needed least/most by the following
	# arguments ? If taking teh value leaves the remainder
	# unsatisfied, pass on it.

	error NYI

	set myhasstring 1
	set mystring    [$queue get]
	return
    }
}

# # ## ### ##### ######## ############# #####################

oo::class create ::xo::splat {
    # Note: xo::config (add) makes sure that splat is the last
    # argument in argument specifications.

    # DSL overrides

    method interactive {} {
	return -code error "Collection argument cannot be interactive"
    }

    method default {value} {
	return -code error "Collection argument cannot have a default"
    }

    method generate {value} {
	return -code error "Collection argument cannot have a generator"
    }

    # API overrides

    # Same as input. Maybe an intermediate base class for these two?
    # No flags. XXX Maybe: --ask-FOO in the future ?
    method flags {} { return {} }
    method arguments {} { return [list $myname] }

    method process {n queue} {
	# Pull the remaining words for our value.
	set mystring    [$queue get [$queue size]]
	set myhasstring 1
	return
    }
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::value 0.1
