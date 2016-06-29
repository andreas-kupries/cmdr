## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Officer - Command execution. Dispatcher.
##                An actor.

## - Officers can learn to do many things, by delegating things to the
##   privates actually able to perform it.

# @@ Meta Begin
# Package cmdr::officer 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary Aggregation of multiple commands for dispatch.
# Meta description 'cmdr::officer's can learn to do many things,
# Meta description by delegating things to the 'cmdr::private's
# Meta description actually able to perform it.
# Meta subject {command line} delegation dispatch
# Meta require TclOO
# Meta require cmdr::actor
# Meta require cmdr::help
# Meta require cmdr::private
# Meta require debug
# Meta require debug::caller
# Meta require linenoise::facade
# Meta require try
# Meta require {Tcl 8.5-}
# Meta require {oo::util 1.2}
# Meta require {string::token::shell 1.2}
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require debug
package require debug::caller
package require linenoise::facade
package require string::token::shell 1.2
package require try
package require TclOO
package require oo::util 1.2 ;# link helper.
package require cmdr::actor
package require cmdr::private
package require cmdr::help
package require cmdr::config

# # ## ### ##### ######## ############# #####################

debug define cmdr/officer
debug level  cmdr/officer
#debug prefix cmdr/officer {[debug caller] | }
debug prefix cmdr/officer {}

# # ## ### ##### ######## ############# #####################
## Definition - Single purpose command.

# # ## ### ##### ######## ############# #####################
## Definition

oo::class create ::cmdr::officer {
    superclass ::cmdr::actor
    # # ## ### ##### ######## #############
    ## Lifecycle.

    # action specification.
    # declares a hierarchy of sub-ordinate officers and privates.

    # Specification commands.
    #
    # private $name $arguments $cmdprefix --> sub-ordinate private for the action.
    # officer $name $actions              --> sub-ordinate officer with more actions.
    # default $name                       --> default action

    constructor {super name actions} {
	debug.cmdr/officer {[self] $super $name}
	next

	my super: $super
	my name:  $name

	set myactions     $actions ; # Action spec for future initialization
	set myinit        no       ; # Dispatch map will be initialized lazily
	set mymap         {}       ; # Action map starts knowing nothing
	set mypmap        {}       ; # Ditto for the map of action abbreviations.
	set mycommands    {}       ; # Ditto
	set myccommands   {}       ; # Ditto, derived cache, see method CCommands.
	set mychildren    {}       ; # List of created subordinates.
	set myintercept   {}       ; # Handler around cmd parsing and execution.
	set mycustomsetup {}       ; # List of setup handlers, run after regular object
	#                            # initialization from its definition.
	set myconfig    {}
	return
    }

    # # ## ### ##### ######## #############

    method intercept {cmd} {
	debug.cmdr/officer {[self] $cmd}
	set myintercept $cmd
	return
    }

    method custom-setup {cmd} {
	debug.cmdr/officer {[self] $cmd}
	lappend mycustomsetup $cmd
	return
    }

    forward ehandler my intercept
    forward shandler my custom-setup

    # # ## ### ##### ######## #############
    ## Public API. (Introspection, mostly).
    ## - Determine set of known actions.
    ## - Determine default action.
    ## - Determine handler for an action.

    method known {} {
	debug.cmdr/officer {[debug caller] | }
	my Setup
	set result {}
	dict for {k v} $mymap {
	    if {![string match a,* $k]} continue
	    lappend result [string range $k 2 end]
	}
	return $result
    }

    method hasdefault {} {
	debug.cmdr/officer {[debug caller] | } 10
	my Setup
	return [dict exists $mymap default]
    }

    method default {} {
	debug.cmdr/officer {[debug caller] | } 10
	my Setup
	return [dict get $mymap default]
    }

    method lookup {name} {
	debug.cmdr/officer {[debug caller] | }
	my Setup
	# An exact action name has priority over any prefixes.
	if {[dict exists $mymap a,$name]} {
	    return [dict get $mymap a,$name]
	}
	# Accept any unique prefix.
	if {
	    [dict exists $mypmap $name] &&
	    ([llength [set hl [dict get $mypmap $name]]] == 1)
	} {
	    return [lindex $hl 0]
	}
	return -code error \
	    -errorcode [list CMDR ACTION UNKNOWN $name] \
	    "Expected action name, got \"$name\""
    }

    method find {words} {
	# Resolve chain of words (command name path) to the actor
	# responsible for that command, starting from the current
	# actor.  This is very much a convenience method built on top
	# of lookup (see above).

	my internal_find $words {}
    }

    method internal_find {words prefix} {
	if {![llength $words]} {
	    return [self]
	}

	set word [lindex $words 0]
	if {[llength $words] <= 1} {
	    return [my lookup $word]
	}

	[my lookup $word] internal_find \
	    [lrange $words 1 end] \
	    [linsert $prefix end $word]
    }

    method has {name} {
	debug.cmdr/officer {[debug caller] | }
	my Setup
	return [dict exists $mymap a,$name]
    }

    method children {} {
	debug.cmdr/officer {[debug caller] | }
	my Setup
	return $mychildren
    }

    # Make the parameter container accessible.
    method config {} {
	debug.cmdr/officer {[debug caller] | $myconfig}
	return $myconfig
    }

    # # ## ### ##### ######## #############
    ## Internal. Dispatcher setup. Defered until required.
    ## Core setup code runs only once.

    method Setup {} {
	debug.cmdr/officer {[debug caller] | $myinit}
	# Process the action specification only once.
	if {$myinit} return
	set myinit 1
	debug.cmdr/officer {[debug caller] | }

	set super [my super]
	if {$super ne {}} {
	    set super [$super config]
	}

	debug.cmdr/officer {[debug caller] | make config}
	set myconfig [cmdr::config create config [self] {} $super]

	# Option --help, -h, -?, added early. Done to ensure that it
	# is known should the specification we will learn in a moment
	# (*) unfold itself deeper during learning, and push the
	# global options down. Adding is done only at the root of the
	# hierarchy, to be inherited by everybody.
	if {[[self] super] eq {}} {
	    cmdr help auto-option [self]
	}

	# (*)
	debug.cmdr/officer {[debug caller] | learn}
	my learn $myactions

	debug.cmdr/officer {[debug caller] | complete}
	config complete-definitions

	# Auto-create a 'help' command when possible, i.e not in
	# conflict with a user-specified command.
	debug.cmdr/officer {[debug caller] | make help}
	if {![my has help]} {
	    cmdr help auto [self]
	}

	# Auto-create an 'exit' command when possible, i.e not in
	# conflict with a user-specified command.
	debug.cmdr/officer {[debug caller] | make exit}
	if {![my has exit]} {
	    my extend exit {
		section *AutoGenerated*
		description {
		    Exit the shell.
		    No-op if not in a shell.
		}
	    } [mymethod shell-exit]
	}

	# Invoke the user-specified hook for extending a newly-made
	# officer, if any.
	debug.cmdr/officer {[debug caller] | call custom-setup}
	foreach cmd $mycustomsetup {
	    {*}$cmd [self]
	}

	debug.cmdr/officer {[debug caller] | /done}
	return
    }

    method learn {script} {
	debug.cmdr/officer {[self] learn}
	# Make the DSL commands directly available. Note that
	# "description:" and "common" are superclass methods, and
	# renamed to their DSL counterparts. The others are unexported
	# instance methods of this class.

	link \
	    {intercept   intercept} \
	    {ehandler    intercept} \
	    \
	    {custom-setup custom-setup} \
	    {shandler     custom-setup} \
	    \
	    {private     Private} \
	    {officer     Officer} \
	    {default     Default} \
	    {alias       Alias} \
	    {description description:} \
	    undocumented \
	    {common      set} \
	    {option      Option} \
	    {state       State}
	eval $script

	# Postprocessing.
	set mycommands [lsort -dict $mycommands]

	debug.cmdr/officer {[self] learn /done}
	return
    }

    # Convenience method for dynamically creating a command hierarchy.
    # Command specified as path, intermediate officers are generated
    # automatically as needed.

    method extend {path arguments action} {
	debug.cmdr/officer {[debug caller] | }
	if {[llength $path] == 1} {
	    # Reached the bottom of the recursion.
	    # Generate the private handling arguments and action.
	    set cmd [lindex $path 0]
	    return [my Private $cmd $arguments $action]
	}

	# Recurse, creating the intermediate officers as needed.
	set path [lassign $path cmd]
	if {![my has $cmd]} {
	    my Officer $cmd {}
	}

	[my lookup $cmd] extend $path $arguments $action
    }

    # # ## ### ##### ######## #############
    ## Implementation of the action specification language.

    forward Option  config make-option
    forward State   config make-state

    # common      => set          (super cmdr::actor)
    # description => description: (super cmdr::actor)

    forward Private my DefineAction private
    forward Officer my DefineAction officer

    method Default {{name {}}} {
	debug.cmdr/officer {[self] Default ($name)}
	if {[llength [info level 0]] == 2} {
	    set name [my Last]
	} elseif {![dict exists $mymap a,$name]} {
	    return -code error \
		-errorcode [list CMDR ACTION UNKNOWN $name] \
		"Unable to set default, expected action, got \"$name\""
	}
	dict set mymap default $name
	return
    }

    method Alias {name args} {
	debug.cmdr/officer {[self] Alias ($name) $args}
	set n [llength $args]
	if {($n == 1) || (($n > 1) && ([lindex $args 0] ne "="))} {
	    return -code error \
		"wrong\#args: should be \"name ?= cmd ?word...??\""
	}
	my ValidateAsUnknown $name

	if {$n == 0} {
	    # Simple alias, to preceding action.
	    set handler [my lookup [my Last]]
	} else {
	    # Track the chain of words through the existing hierarchy
	    # of actions to locate the final handler.
	    set handler [self]
	    foreach word [lassign $args _dummy_] {
		set handler [$handler lookup $word]
	    }
	}

	# We essentially copy the definition of the command the alias
	# refers to.
	my Def $name $handler
	return
    }

    # Internal. Common code to declare actions and their handlers.
    method DefineAction {what name args} {
	debug.cmdr/officer {[self] DefineAction $what ($name) ...}
	my ValidateAsUnknown $name

	# Note: By placing the subordinate objects into the officer's
	# namespace they will be automatically destroyed with the
	# officer itself. No special code for cleanup required.

	set handler [self namespace]::${what}_$name
	cmdr::$what create $handler [self] $name {*}$args

	# Propagate error (interceptor) and custom setup handlers.
	$handler intercept $myintercept
	foreach cmd  $mycustomsetup {
	    $handler custom-setup $cmd
	}

	lappend mychildren $handler

	my Def $name $handler
	return $handler
    }

    method Def {name handler} {
	# Make an action known to the dispatcher.
	dict set mymap last $name
	dict set mymap a,$name $handler
	lappend mycommands $name

	# Update the map of action prefixes
	set prefix {}
	foreach c [split $name {}] {
	    append prefix $c
	    dict lappend mypmap $prefix $handler
	}
	return
    }

    method ValidateAsUnknown {name} {
	debug.cmdr/officer {[debug caller] | }
	if {![dict exists $mymap a,$name]} return
	return -code error -errorcode {CMDR ACTION KNOWN} \
	    "Unable to learn $name, already specified."
    }

    method Last {} {
	if {![dict exists $mymap last]} {
	    return -code error -errorcode {CMDR ACTION NO-LAST} \
		"Cannot be used as first command"
	}
	return [dict get $mymap last]
    }

    method Known {name} {
	debug.cmdr/officer {[debug caller] | }
	# Known exact action is good
	if {[dict exists $mymap a,$name]} { return 1 }
	debug.cmdr/officer {no action, maybe prefix}
	# Unknown prefix is bad
	if {![dict exists $mypmap $name]} { return 0 }
	debug.cmdr/officer {prefix, maybe ambiguous}
	# As is an ambiguous prefix
	if {[llength [dict get $mypmap $name]] > 1} { return 0 }
	debug.cmdr/officer {unique prefix}
	# Known unique prefix is good.
	return 1
    }

    # # ## ### ##### ######## #############
    ## Command dispatcher. Choose the subordinate and delegate.

    method do {args} {
	debug.cmdr/officer {[debug caller] | }
	my Setup

	# Process any options we may find. The first non-option
	# will be the command to dispatch on.
	set args [config parse-head-options {*}$args]

	# No command specified, what should we do ?
	# (1) If there is a default, we can go on (Do will call on it).
	# (2) Without default we must enter an interactive shell.
	# (3) Except if interaction is globally suppressed. Then we
	#     fall through, again, to generate the proper error message.
	#
	# Result: Interact with the user if no command was specified,
	# we have no default to punt to and interaction is globally
	# allowed.

	if {![llength $args] && ![my hasdefault] && [cmdr interactive?]} {
	    # Drop into a shell where the user can enter her commands
	    # interactively.

	    debug.cmdr/officer {[debug caller] | shell}

	    set shell [linenoise::facade new [self]]
	    set myreplexit 0 ; # Initialize stop signal, no stopping
	    $shell history 1
	    $shell history= [my history-setup]
	    [my root] set *in-shell* true
	    $shell repl
	    [my root] set *in-shell* false
	    $shell destroy

	    debug.cmdr/officer {[debug caller] | /done shell}
	    return
	}

	my Do {*}$args

	debug.cmdr/officer {[debug caller] | /done}
	return
    }

    # Internal. Actual dispatch. Shared by main entry and shell.
    method Do {args} {
	debug.cmdr/officer {[debug caller] | }
	set reset 0
	if {![my exists *command*]} {
	    # Prevent handling of application-specific options here.
	    my set *command* -- $args
	    set reset 1
	}
	try {
	    # Empty command. Delegate to the default, if we have any.
	    # Otherwise fail.
	    if {![llength $args]} {
		if {[my hasdefault]} {
		    return [[my lookup [my default]] do]
		}
		return -code error -errorcode {CMDR DO EMPTY} \
		    "No command found."
	    }

	    # Split into command and arguments
	    set remainder [lassign $args cmd]

	    # Delegate to the handler for a known command.
	    if {[my Known $cmd]} {
		debug.cmdr/officer {[debug caller] | /known $cmd}

		[my root] lappend *prefix* $cmd
		debug.cmdr/officer {[debug caller] | /prefix [my root] ([my get *prefix*])}

		[my lookup $cmd] do {*}$remainder
		debug.cmdr/officer {[debug caller] | /done known}
		return
	    }

	    # The command word is not known. Delegate the full command to
	    # the default, if we have any. Otherwise fail.

	    if {[my hasdefault]} {
		# prefix left as is.
		debug.cmdr/officer {[debug caller] | /default}

		[my lookup [my default]] do {*}$args
		debug.cmdr/officer {[debug caller] | /done default}
		return
	    }

	    # See also private::FullCmd
	    if {[catch {
		set prefix " [my get *prefix*] "
	    }]} { set prefix "" }
	    return -code error \
		-errorcode [list CMDR DO UNKNOWN $cmd] \
		"Unknown command \"[string trimleft $prefix]$cmd\". Please use 'help[string trimright $prefix]' to see the list of available commands."
	} finally {
	    if {$reset} {
		my unset *command*
	    }
	    my unset *prefix*
	}

	debug.cmdr/officer {[debug caller] | /done}
    }

    # # ## ### ##### ######## #############
    ## Shell hook methods called by the linenoise::facade.

    method prompt1   {}     { return "[my fullname] > " }
    method prompt2   {}     { error {Continuation lines are not supported} }
    method continued {line} { return 0 }
    method exit      {}     { return $myreplexit }

    method shell-exit {config} {
	# No arguments, ignore config.
	set myreplexit 1
	return
    }

    method dispatch {cmd} {
	debug.cmdr/officer {[debug caller] | }

	if {$cmd eq {}} {
	    # No command, do nothing.
	    return
	}

	if {$cmd eq ".exit"} {
	    # See method 'shell-exit' as well, and 'Setup' for
	    # the auto-creation of an 'exit' command when possible,
	    # i.e not in conflict with a user-specified command.
	    set myreplexit 1 ; return
	}
	my Do {*}[string token shell -- $cmd]
    }

    method report {what data} {
	debug.cmdr/officer {[debug caller] | }
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
	debug.cmdr/officer {[debug caller] | } 10
	#puts stderr ////////$line
	try {
	    set completions [my complete-words [my parse-line $line]]
	} on error {e o} {
	    puts stderr "ERROR: $e"
	    puts stderr $::errorInfo
	    set completions {}
	}
	#puts stderr =($completions)
	return $completions
    }

    method complete-words {parse} {
	debug.cmdr/officer {[debug caller] | } 10
	#puts stderr [my fullname]/[self]/$parse/
	# Note: This method has to entry-points.
	# (1) Above in 'complete', for command completion from self's REPL.
	# (2) Below, as part of recursion from a higher officer while
	#     following the chain of words to the actor responsible
	#     for handling the last word.

	my Setup

	# Unfold the parse state
	dict with parse {} ;# --> line ok words at nwords doexit
	# ok     - boolean flag, syntax ok ? yes/no
	# line   - string, the raw command line with quotes, escapes, etc.
	# nwords - number of words found in the -> line
	# words  - list of words found in the -> line.
	# at     - index of the current word to process.
	# doexit - boolean flag, pseudo-command 'exit' active ? yes/no
	#
	# words = list (tuple), where tuple = (type startoff endoff string)
	# doexit - True only for entry point (1), false for all of (2) and down.

	# Parse error, bad syntax. No completions.

	if {!$ok} {
	    #puts stderr \tBAD
	    return {}
	}

	# Empty line. All our commands are completions, plus the
	# special '.exit' command to stop the REPL. Thus using
	# my<c>commands instead of mycommands.

	if {$line eq {}} {
	    #puts stderr \tALL
	    set completions [my CCommands]
	    if {[my hasdefault]} {
		dict set parse doexit 0
		lappend completions {*}[[my lookup [my default]] complete-words $parse]
	    }
	    return [lsort -unique [lsort -dict $completions]]
	}

	# Beyond the end of the line. No completions.

	if {$at == $nwords} {
	    #puts stderr \tBEYOND
	    return {}
	}

	if {$at < ($nwords - 1)} {
	    # This officer has to handle a word in the middle of the
	    # command line. This is done by delegating to the
	    # subordinate associated with the current word and letting
	    # it handle the remainder.

	    #puts stderr \tRECURSE
	    return [my CompleteRecurse $parse]
	}

	# This officer is responsible for handling the last word on
	# the command line. We do this by computing the set of
	# matching commands from the set the officer knows and
	# providing them as completions. One tricky thing: If we have
	# a default we ask it as well, and merge its completions to
	# ours. Lastly, we may have to add the '.exit' pseudo-command
	# as well.

	#puts stderr \tMATCH\ ([lindex $words $at end])

	set commands [my CCommands $doexit]

	set completions \
	    [my completions $parse \
		 [my match $parse $commands]]

	if {[my hasdefault]} {
	    dict set parse doexit 0
	    lappend completions {*}[[my lookup [my default]] complete-words $parse]
	}

	#puts stderr \tC($completions)
	return [lsort -unique [lsort -dict $completions]]
    }

    method CompleteRecurse {parse} {
	debug.cmdr/officer {[debug caller] | } 10
	# Inside the command line. Find the relevant subordinate based
	# on the current word and let it handle everything.

	# The '.exit' pseudo-command of the subordinate is irrelevant
	# during recursion from the current or higher REPL, suppress
	# it. The pseudo-command is only relevant to the officers
	# actually in their REPL.
	dict set parse doexit 0

	set matches [my match $parse [my known]]

	if {[llength $matches] == 1} {
	    # Proper subordinate found. Delegate. Note: Step to next
	    # word, we have processed the current one.
	    dict incr parse at
	    set handler [my lookup [lindex $matches 0]]
	    return [$handler complete-words $parse]
	}

	# The search was inconclusive. Try the default, if we have any.
	if {[my hasdefault]} {
	    return [[my lookup [my default]] complete-words $parse]
	}

	# No default, no completions.
	return {}
    }

    # # ## ### ##### ######## #############

    method CCommands {{doexit 1}} {
	debug.cmdr/officer {[debug caller] | } 10
	if {![llength $myccommands]} {
	    # Fill completion command cache.

	    # Standard pseudo-commands.
	    if {$doexit} {
		lappend myccommands .exit
	    }

	    foreach c $mycommands {
		# Undocumented commands are not available to completion.
		if {![[my lookup $c] documented]} continue
		lappend myccommands $c
	    }

	    set myccommands [lsort -unique [lsort -dict $myccommands]]
	}

	return $myccommands
    }


    # # ## ### ##### ######## #############

    method help {{prefix {}}} {
	debug.cmdr/officer {[debug caller] | }
	my Setup
	# Query each subordinate for their help and use it to piece ours together.
	# Note: Result is not finally formatted text, but nested dict structure.
	# Same is expected from the sub-ordinates

	# help = dict (name -> command)
	#if {![my documented]} { return {} }
	set help {}
	foreach c [my known] {
	    set cname [list {*}$prefix $c]
	    set actor [my lookup $c]
	    if {![$actor documented]} continue
	    set help [dict merge $help [$actor help $cname]]
	}

	# Add the officer itself, to provide its shared options.
	dict set help $prefix [config help]

	return $help
    }

    # # ## ### ##### ######## #############

    variable myinit myactions mymap mycommands myccommands mychildren \
	myreplexit myintercept mypmap mycustomsetup myconfig

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::officer 1.4.1
