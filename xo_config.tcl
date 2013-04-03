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
package require try
package require struct::queue 1 ; #
package require term::ansi::code::ctrl
package require linenoise::facade
package require xo::validate    ; # Core validator commands.
package require xo::parameter   ; # Parameter to collect
package require xo::util
package require xo::help

# # ## ### ##### ######## ############# #####################
## Definition

oo::class create ::xo::config {
    # # ## ### ##### ######## #############

    classmethod interactive {{value 1}} {
	variable ourinteractive $value
	return
    }

    # # ## ### ##### ######## #############
    ## Lifecycle.

    constructor {context spec} {
	classvariable ourinteractive
	if {![info exists ourinteractive]} { set ourinteractive 0 }

	my Colors

	# Import the context (xo::private).
	interp alias {} [self namespace]::context {} $context

	# Initialize collection state.
	set myinteractive $ourinteractive
	set mymap     {} ;# parameter name -> object
	set mypub     {} ;# parameter name -> object, non-state only, i.e. user visible
	set myoption  {} ;# option         -> object
	set myfullopt {} ;# option prefix  -> list of full options having that prefix.
	set myargs    {} ;# List of argument names.
	set myinforce no

	# Import the DSL commands.
	link \
	    {undocumented Undocumented} \
	    {description  Description} \
	    {use          Use} \
	    {input        Input} \
	    {interactive  Interactive} \
	    {option       Option} \
	    {state        State}

	# Updated in my DefineParameter, called from the $spec
	set splat no

	# Auto inherit common options, state, arguments.
	# May not be defined.
	catch { use *all* }
	eval $spec

	# Postprocessing

	my SetThresholds
	my UniquePrefixes
	my CompletionGraph

	set mypq [struct::queue P] ;# actual parameters
	if {[llength $myargs]} {
	    set myaq [struct::queue A] ;# formal argument parameters
	}
	return
    }

    method help {{mode public}} {
	# command   = dict ('desc'      -> description
	#                   'options'   -> options
	#                   'arguments' -> arguments)
	# options   = list (option...)
	# option    = dict (name -> description)
	# arguments = list (argument...)
	# argument  = dict (name -> argdesc)
	# argdesc   = dict ('code' -> code
	#                   'desc' -> description)
	# code in {
	#     +		<=> required
	#     ?		<=> optional
	#     +*	<=> required splat
	#     ?* 	<=> optional splat
	# }

	set options {}
	dict for {o para} $myoption {
	    # in interactive mode undocumented options can be shown in
	    # the help if they already have a value defined for them.
	    if {![$para documented] &&
		(($mode ne "interact") ||
		 ![$para defined?])} continue

	    # in interactive mode we skip all the aliases.
	    if {($mode eq "interact") &&
		![$para primary $o]} continue
	    dict set options $o [$para description $o]
	}

	set arguments {}
	foreach a $myargs {
	    set para [dict get $mymap $a]
	    dict set arguments $a \
		[dict create \
		     code [$para code] \
		     desc [$para description]]
	}

	return [dict create \
		    desc      [context description] \
		    options   $options \
		    arguments $arguments]
    }

    method interactive {} { return $myinteractive }
    method eoptions    {} { return $myfullopt }
    method names       {} { return [dict keys $mymap] }
    method public      {} { return [dict keys $mypub] }
    method arguments   {} { return $myargs }
    method options     {} { return [dict keys $myoption] }

    method lookup {name} {
	if {![dict exists $mymap $name]} {
	    set names [linsert [join [lsort -dict [my names]] {, }] end-1 or]
	    return -code error -errorcode {XO CONFIG PARAMETER UNKNOWN} \
		"Got \"$name\", expected parameter name, one of $names"
	}
	return [dict get $mymap $name]
    }

    method lookup-option {name} {
	if {![dict exists $myoption $name]} {
	    set names [linsert [join [lsort -dict [my options]] {, }] end-1 or]
	    return -code error -errorcode {XO CONFIG PARAMETER UNKNOWN} \
		"Got \"$name\", expected option name, one of $names"
	}
	return [dict get $myoption $name]
    }

    method force {} {
	# Define the values of all parameters.
	# Done in order of declaration.
	# Any dependencies between parameter can be handled by proper
	# declaration order.

	if {$myinforce} return
	set myinforce yes

	foreach name $mynames {
	    catch { [dict get $mymap $name] value }
	}

	set myinforce no
	return
    }

    method reset {} {
	dict for {name para} $mymap {
	    $para reset
	}
	return
    }

    method forget {} {
	if {$myinforce} return
	dict for {name para} $mymap {
	    $para forget
	}
	return
    }

    # # ## ### ##### ######## #############
    ## API for use by the actual command run by the private, and by
    ## the values in the config (which may request other values for
    ## their validation, generation, etc.). Access to argument values by name.

    method unknown {m args} {
	if {![regexp {^@(.*)$} $m -> mraw]} {
	    # Standard error message when not @name ...
	    next $m {*}$args
	    return
	}
	# @name ... => handlerof(name) ...
	if {![llength $args]} { lappend args value }
	return [[my lookup $mraw] {*}$args]
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

	# Sort the expansions, for the error messages.
	dict for {k v} $myfullopt {
	    if {[llength $v] == 1} continue
	    dict set myfullopt $k [lsort -dict $v]
	}

	#array set _o $myoption  ; parray _o ; unset _o
	#array set _f $myfullopt ; parray _f ; unset _f
	return
    }

    method CompletionGraph {} {
	set next {}
	set start .(start)
	set end   .(end)

	# Basic graph, linear chain of the arguments
	foreach from [linsert $myargs 0 $start] to [linsert $myargs end $end] {
	    dict lappend next $from $to
	    # Loop the chain for a list argument.
	    if {($from ne $start) && [[dict get $mymap $from] list]} {
		dict lappend next $from $from
	    }
	} ; #my SCG $start $next chain

	# Extend the graph, adding links bypassing the optional
	# arguments.  Essentially an iterative transitive closure
	# where the epsilon links are only implied.

	set changed 1
	set handled {} ;# Track processed epsilon links to not follow
			# them again.

	while {$changed} {
	    set changed 0
	    foreach a [linsert $myargs 0 $start] {
		foreach n [dict get $next $a] {
		    if {$n eq $end} continue
		    if {[[dict get $mymap $n] required]} continue
		    if {[dict exists $handled $a,$n]} continue
		    # make sucessors of a sucessor optional argument my sucessors, once
		    dict set handled $a,$n .
		    set changed 1
		    foreach c [dict get $next $n] {
			dict lappend next $a $c
		    }
		}
	    }
	} ; #my SCG $start $next closure

	# Convert the graph into a list of states, i.e. sets of
	# arguments (note that the underlying structure is still
	# essentially linear, which the DFA from the NFA now exposes
	# again).

	set mycchain {}
	foreach a [linsert $myargs 0 $start] {
	    # Tweaks: Ensure state uniqueness, and a canoninical order.
	    set state [lsort -unique [lsort -dict [dict get $next $a]]]
	    # Remove the end state
	    set pos [lsearch -exact $state $end]
	    if {$pos >= 0} { set state [lreplace $state $pos $pos] }

	    # Loop state, list argument last.
	    if {([llength $state] == 1) && $a eq [lindex $state 0]} {
		set state ... ; # marker for stepper in complete-words.
	    }
	    lappend mycchain $state
	}

	#puts stderr \t[join $mycchain \n\t]
	return
    }

    method SCG {start next label} {
	puts stderr \n/$label
	foreach a [linsert $myargs 0 $start] {
	    puts stderr "\t($a) => [dict get $next $a]"
	}
	return
    }

    # # ## ### ##### ######## #############
    ## API for xo::private parameter specification DSL.

    # Description is for the context, i.e. the private.
    forward Description  context description:
    forward Undocumented context undocumented

    # Bespoke 'source' command for common specification fragments.
    method Use {name} {
	# Pull code fragment out of the data store and run.
	uplevel 1 [context get $name]
	return
    }

    method Interactive {} {
	set myinteractive 1
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

	# And a second map, user-visible parameters only,
	# i.e. available on the cmdline, and documented.
	if {[$para cmdline] && [$para documented]} {
	    dict set mypub $name $para
	}

	if {$order} {
	    # Arguments, keep names, in order of definition
	    lappend myargs $name
	    set splat [$para list]
	} else {
	    # Keep map of options to their handlers.
	    foreach option [$para options] {
		dict set myoption $option $para
	    }
	}

	# And the list of all parameters in declaration order, for use
	# in 'force'.
	lappend mynames $name
	return
    }

    method ValidateAsUnknown {name} {
	if {![dict exists $mymap $name]} return
	return -code error -errorcode {XO CONFIG KNOWN} \
	    "Duplicate parameter \"[context fullname]: $name\", already specified."
    }

    # # ## ### ##### ######## #############
    ## Command completion. This is the entry point for recursion from
    ## the higher level officers, delegated to config from xo::private

    ## Note that command completion for the REPL of the private is
    ## handled by the internal xo::config instance, which also manages
    ## the REPL itself.

    method complete-words {parse} {
	dict with parse {}
	# -> ok, at, nwords, words, line

	#puts ?|$ok
	#puts @|$at
	#puts #|$nwords
	#puts =|$words|
	#puts L|$line|

	# The basic idea is to scan over the words, like with 'parse',
	# except that instead of letting the parameters taking their
	# values we keep track of which parameters could have been
	# set. To avoid complexities here we use the mycchain computed
	# by CompletionGraph to know the set of possible parameters,
	# simply stepping through.

	# at = word in the command line we are at.
	# ac = state in the completion chain we are at.
	# st = processing state

	set ac 0    ;# parameters which can be expected at this position
	set st none ;# expect an argument word
	set current [lindex $words $at end]

	while {$at < ($nwords-1)} {
	    if {$st eq "eov"} {
		# Skip over the option value
		set st none
		incr at
		continue
	    }

	    # We need just the text of the current word.
	    set current [lindex $words $at end]

	    if {[my IsOption $current implied]} {
		if {!$implied} {
		    # Expect next word to be an option value.
		    set st eov
		}
	    } else {
		# Step to the chain state for the next word.
		# Note how we bounce back on the loop/list marker.
		incr ac
		if {[lindex $mycchain $ac] eq "..."} { incr ac -1 }
	    }
	    # Step to the next word
	    incr at
	}

	# assert (at == (nwords-1))
	# We are now on the last word, and the system state tells us
	# what we can expect in terms of parameters and such.

	set state [lindex $mycchain $ac]
	dict set parse at $at

	#puts '|$current|
	#puts @|$at|
	#puts c|$ac|
	#puts x|$state|
	#puts s|$st|

	if {$st eq "eov"} {
	    # The last word is an option value, possible incomplete.
	    # The value of 'current' still points to the option name.
	    # Determine the responsible parameter, and delegate.

	    # Unknown option, unable to complete the value.
	    if {![dict exists $myfullopt $current]} { return {} }

	    # Ambiguous option name, unable to complete value.
	    set matches [dict get $myfullopt $current]
	    if {[llength $matches] > 1} { return {} }

	    # Delegate to the now known parameter for completion.
	    set match [lindex $matches 0]
	    set para  [dict get $myoption $match]
	    return [$para complete-words $parse]
	}

	# Not at option value, can be at incomplete option name, and parameters.
	set current [lindex $words $at end]

	if {$current eq {}} {
	    # All options are possible here.
	    set completions [my options]
	    # And the completeable values of the possible arguments.
	    foreach a $state {
		lappend completions {*}[[dict get $mymap $a] complete-words $parse]
	    }
	    return $completions
	}

	if {[string match -* $current]} {
	    # Can be option name, or value, if implied (special form --foo=bar).
	    if {[set pos [string first = $current]] < 0} {
		# Just option name to complete.
		return [context match $parse [my options]]
	    } else {
		set prefix [string range $current 0 $pos]
		set option [string range $prefix 0 end-1] ;# chop =

		# Unknown option, unable to complete the value.
		if {![dict exists $myfullopt $option]} { return {} }

		# Ambiguous option name, unable to complete value.
		set matches [dict get $myfullopt $option]
		if {[llength $matches] > 1} { return {} }

		# Delegate to the now known parameter for completion.
		set match [lindex $matches 0]
		set para  [dict get $myoption $match]
		incr pos
		set val [string range $curent $pos end]

		dict lappend parse words $val
		dict incr    parse at

		set completions
		foreach c [$para complete-words $parse] {
		    lappend completions $prefix$c
		}
		return $completions
	    }
	}

	# Only the completeable values of the possible arguments.
	set completions {}
	foreach a $state {
	    lappend completions {*}[[dict get $mymap $a] complete-words $parse]
	}
	return $completions
    }

    # # ## ### ##### ######## #############

    method IsOption {current iv} {
	upvar 1 $iv implied at at nwords nwords words words
	set implied 0

	if {![string match -* $current]} {
	    # Cannot be option
	    return 0
	}

	# Is an option (even if not known).

	if {[string first = $current] >= 0} {
	    # --foo=bar special form.
	    set implied 1
	} else {
	    # Try to expand the flag and look the whole option up. If
	    # we can, check if it is boolean, and if yes, look at the
	    # next argument, if any to determine if it belongs to the
	    # option, or not. The latter then means the argument is
	    # implied.

	    set next [expr {$at+1}]
	    if {$next < $nwords} {
		# Have a following word
		if {[dict exists $myfullopt $current]} {
		    # Option is possibly known
		    set matches [dict get $myfullopt $current]
		    if {[llength $matches] == 1} {
			# Option is unambiguously known
			set match [lindex $matches 0]
			set para [dict get $myoption $match]
			if {[$para isbool]} {
			    # option is boolean
			    set next [lindex $words $next end]
			    if {![string is boolean $next]} {
				# next word is not boolean => value is implied.
				# note that we are non-strict here.
				# an empty word is treated as boolean to be completed, not implied.
				set implied 1
			    }
			}
		    }
		}
	    }
	}
	return 1
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
	# - Reset the state values (we might be in an interactive shell, multiple commands).
	# - Stash the parameters into a queue for processing.
	# - Stash the (ordered) arguments into a second queue.
	# - Operate on parameter and arg queues until empty,
	#   dispatching the words to handlers as needed.

	my reset
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
	while {1} {
	    # Option ... Leaves A unchanged.
	    if {[P size]} {
		set word [P peek]
		if {[string match -* $word]} {
		    my ProcessOption
		    continue
		}
	    } else break

	    # Out of arguments, yet still getting a non-option word.
	    if {![A size]} { my tooMany }

	    # Note: The parameter instance is responsible for
	    # retrieving its value from the parameter queue.  It may
	    # pass on this. This also checks if there is enough in the
	    # P queue, aborting if not.

	    set argname [A get]
	    #puts [A size]|$argname|[P size]
	    [dict get $mymap $argname] process $argname $mypq
	    #puts \t==>[P size]

	    if {![P size]} break
	}

	# At this point P is empty. A may not be.  That is ok if the
	# remaining A's are optional.  Simply scan them, those which
	# are mandatory will throw the necessary error.

	while {[A size]} {
	    set argname [A get]
	    #puts [A size]|$argname|[P size]
	    [dict get $mymap $argname] process $argname $mypq
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

    variable mymap mypub myoption myfullopt myargs mynames \
	myaq mypq mycchain myreplexit myreplok myreplcommit \
	myreset myred mygreen mycyan myinteractive myinforce

    # # ## ### ##### ######## #############
    ## Local shell for interactive entry of the parameters in the collection.

    method interact {} {
	# compare xo::officer REPL (=> method "do").

	set shell [linenoise::facade new [self]]
	set myreplexit   0 ; # Flag: Stop repl, not yet.
	set myreplok     0 ; # Flag: We can't commit properly
	set myreplcommit 0 ; # Flag: We are not asked to commit yet.

	my ShowState

	$shell history 1
	try {
	    $shell repl
	} trap {XO CONFIG INTERACT CANCEL} {e o} {
	    return 0
	} trap {XO CONFIG INTERACT OK} {e o} {
	    if {!$myreplok} {
		# Bad commit with incomplete data.
		return -code error \
		    -errorcode {XO CONFIG COMMIT FAIL} \
		    "Unable to perform \"[context fullname]\", incomplete or bad arguments"
	    }
	    return 1
	} finally {
	    $shell destroy
	}
	return
    }

    # # ## ### ##### ######## #############
    ## Shell hook methods called by the linenoise::facade.

    method prompt1   {}     { return "[context fullname]> " }
    method prompt2   {}     { error {Continuation lines are not supported} }
    method continued {line} { return 0 }
    method exit      {}     { return $myreplexit }

    method dispatch {cmd} {
	switch -exact -- $cmd {
	    .run - .ok {
		set myreplexit   1
		set myreplcommit 1
		return
	    }
	    .exit - .cancel {
		set myreplexit 1
		return
	    }
	    .help {
		puts [xo help format plain \
			  [linenoise columns] \
			  [dict create [context fullname] \
			       [my help interact]]]
		return
	    }
	}

	set words [lassign [string token shell $cmd] cmd]
	# cmd = parameter name, words = parameter value.
	# Note: Most pseudo commands take a single argument!
	#       Presence-only options are the exception.
	# Note: The lookup accepts the undocumented parameters as
	#       well, despite them not shown by ShowState, nor
	#       available for completion.

	set para [my lookup $cmd]

	if {[$para presence] && ([llength $words] != 0)} {
	    return -code error -errorcode {XO CONFIG WRONG ARGS} \
		"wrong \# args: should be \"$cmd\""
	} elseif {[llength $words] != 1} {
	    return -code error -errorcode {XO CONFIG WRONG ARGS} \
		"wrong \# args: should be \"$cmd value\""
	}

	# cmd is option => Add the nessary dashes? No. Only needed for
	# boolean special form, and direct interaction does not allow
	# that.

	if {[$para presence]} {
	    # See also xo::parameter/ProcessOption
	    $para set yes
	} else {
	    $para set {*}$words
	}
	return
    }

    method report {what data} {
	if {$myreplexit} {
	    if {$myreplcommit} {
		return -code error -errorcode {XO CONFIG INTERACT OK} ""
	    } else {
		return -code error -errorcode {XO CONFIG INTERACT CANCEL} ""
	    }
	}

	my ShowState
	switch -exact -- $what {
	    ok {
		if {$data eq {}} return
		puts stdout $data
	    }
	    fail {
		puts stderr $data
	    }
	    default {
		return -code error \
		    "Internal error, bad result type \"$what\", expected ok, or fail"
	    }
	}
    }

    # # ## ### ##### ######## #############
    # Shell hook method - Command line completion.

    method complete {line} {
	#puts stderr ////////$line
	try {
	    set completions [my complete-repl [context parse-line $line]]
	} on error {e o} {
	    puts stderr "ERROR: $e"
	    puts stderr $::errorInfo
	    set completions {}
	}
	#puts stderr =($completions)
	return $completions
    }

    method complete-repl {parse} {
	#puts stderr [my fullname]/[self]/$parse/

	dict with parse {}
	# -> line, words, nwords, ok, at, doexit

	if {!$ok} {
	    #puts stderr \tBAD
	    return {}
	}

	# All arguments and options are (pseudo-)commands.
	# The special exit commands as well.
	set     commands [my Visible]
	lappend commands .ok     .run
	lappend commands .cancel .exit
	lappend commands .help

	set commands [lsort -unique [lsort -dict $commands]]

	if {$line eq {}} {
	    return $commands
	}

	if {$nwords == 1} {
	    # Match among the arguments, options, and specials
	    return [context completions $parse [context match $parse $commands]]
	}

	if {$nwords == 2} {
	    # Locate the responsible parameter and let it complete.
	    # Note: Here we non-public parameters as well.

	    set matches [context match $parse [my names]]

	    if {[llength $matches] == 1} {
		# Proper subordinate found. Delegate. Note: Step to next
		# word, we have processed the current one, the command.
		dict incr parse at
		set para [my lookup [lindex $matches 0]]

		# Presence-only options do not have an argument to complete.
		if {[$para presence]} {
		    return {}
		}
		return [context completions $parse [$para complete-words $parse]]
	    }

	    # No completion if nothing found, or ambiguous.
	    return {}
	}

	# No completion beyond the command and 1st argument.
	return {}
    }

    method Visible {} {
	set visible {}
	foreach p [my names] {
	    if {![dict exists $mypub $p] &&
		![[my lookup $p] defined?]
	    } continue
	    # Keep public elements, and any hidden ones already having
	    # a user definition. The user obviously knows about them.
	    lappend visible $p
	}
	return $visible
    }

    method dump {} {
	my PrintState [my names] 1
    }

    method ShowState {} {
	puts [my PrintState [my Visible] 0]
	flush stdout
	return
    }

    method PrintState {plist full} {
	set plist  [lsort -dict $plist]
	set labels [xo util padr $plist]
	set blank  [string repeat { } [string length [lindex $labels 0]]]

	# Recalculate all parameters in full.
	my forget
	my force

	set text {}
	set alldefined 1
	set somebad    0
	foreach label $labels para $plist {
	    set para [my lookup $para]

	    set label    [string totitle $label 0 0]
	    set required [$para required]
	    set islist   [$para list]
	    set defined  [$para defined?]

	    try {
		set value [$para value]
		if {$value eq {}} {
		    set value ${mycyan}<<epsilon>>${myreset}
		}
	    } trap {XO PARAMETER UNDEFINED} {e o} {
		# Mandatory argument, without user-specified value.
		set value "${mycyan}(undefined)$myreset"
	    } trap {XO VALIDATE} {e o} {
		# Any argument with a bad value.
		set value "[$para string] ${mycyan}($e)$myreset"
		set somebad 1
	    }

	    append text {    }

	    if {$required && !$defined} {
		set label ${myred}$label${myreset}+
		set alldefined 0
	    } else {
		set label "$label "
	    }

	    if {$full} {
		append label " ("
		append label [expr {[$para ordered]    ? "o":"-"}]
		append label [expr {[$para cmdline]    ? "c":"-"}]
		append label [expr {[$para list]       ? "L":"-"}]
		append label [expr {[$para presence]   ? "P":"-"}]
		append label [expr {[$para documented] ? "d":"-"}]
		append label [expr {[$para isbool]     ? "B":"-"}]
		append label [expr {[$para hasdefault] ? "D":"-"}]
		append label [expr {[$para defined?]   ? "!":"-"}]

		append label [expr {[$para required] ? "/.." : [$para threshold] < 0 ? "/pt":"/th"}]

		append label ")"
		set sfx {              }
	    } else {
		set sfx {}
	    }

	    append text $label
	    append text { : }

	    if {!$islist} {
		append text $value
	    } else {
		set remainder [lassign $value first]
		append text $first
		foreach r $remainder {
		    append text "\n    $blank$sfx  : $r"
		}
	    }

	    append text \n
	}

	if {$somebad} {
	    set text "[context fullname] (${myred}BAD$myreset):\n$text"
	} elseif {!$alldefined} {
	    set text "[context fullname] (${myred}INCOMPLETE$myreset):\n$text"
	} else {
	    set text "[context fullname] (${mygreen}OK$myreset):\n$text"
	    set myreplok 1
	}

	return $text
    }

    # # ## ### ##### ######## #############

    method Colors {} {
	if {$::tcl_platform(platform) eq "windows"} {
	    set myreset ""
	    set myred   ""
	    set mygreen ""
	    set mycyan  ""
	} else {
	    set myreset [::term::ansi::code::ctrl::sda_reset]
	    set myred   [::term::ansi::code::ctrl::sda_fgred]
	    set mygreen [::term::ansi::code::ctrl::sda_fggreen]
	    set mycyan  [::term::ansi::code::ctrl::sda_fgcyan]
	}
	return
    }

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::config 0.1
