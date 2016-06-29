## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - History - Utility package commands.

# @@ Meta Begin
# Package cmdr::history 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Utilities to support an external history
# Meta description Utilities to support an external history
# Meta subject {command line} history {external history}
# Meta subject {save history} {load history}
# Meta require {Tcl 8.5-}
# Meta require fileutil
# Meta require debug
# Meta require debug::caller
# @@ Meta End

# Limits 'n'
# < 0 | History on.  Keep everything 
# = 0 | History off. Keep nothing.
# > 0 | History on.  Keep last n entries.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require fileutil
package require debug
package require debug::caller

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export history
    namespace ensemble create
}

namespace eval ::cmdr::history {
    namespace export attach save-to initial-limit
    namespace ensemble create

    # Path to the file the history is stored in.
    # The default value shown below disables history.
    variable file {}

    # State information about the history subsystem.
    variable loaded  0 ; # Boolean: Has the history file been loaded yet ?
    variable limit  -1 ; # Limits. Default: active, no limits.
    variable cache  {} ; # In-memory list of the saved commands for easier limit handling.
}

# Helper ensemble.
namespace eval ::cmdr::history::mgr {
    namespace ensemble create -map {
	initialize ::cmdr::history::Init
	add        ::cmdr::history::Add
    }
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/history
debug level  cmdr/history
debug prefix cmdr/history {[debug caller] | }

# # ## ### ##### ######## ############# #####################

proc ::cmdr::history::save-to {path} {
    debug.cmdr/history {}
    variable file $path
    return
}

proc ::cmdr::history::initial-limit {new} {
    debug.cmdr/history {}
    variable limit $new
    return
}

proc ::cmdr::history::attach {actor} {
    debug.cmdr/history {}
    # For use by cmdr's custom-setup command.
    # The actor is the officer to extend.

    # (***) Detect recursive entry through the extend statements
    # below. Use this to make 'history list' the default of the whole
    # history officer. And, of course, prevent infinite recursion.
    # Lastly, not leastly, add help describing the entire ensemble.

    if {[$actor name] eq "history"} {
	$actor learn {
	    default list
	    #section Introspection {Command history}
	    description {
		Manage the command history.
	    }
	}
	return
    }

    # (1) Intercept dispatch and record all user commands.
    #
    # Note how this is NOT attached to the history officer itself.
    # Execution of history management commands is not recorded in the
    # history.
    #
    # Note also that it is attached to all privates of any officer we
    # attach to.

    $actor history-via ::cmdr::history::mgr
    foreach a [$actor children] {
	$a history-via ::cmdr::history::mgr
    }

    # (2) Extend the root officer, and only the root, with a
    #     subordinate officer and privates providing access to the
    #     history management here.

    # FUTURE: Limit amount of saved commands.
    # FUTURE: Automatic loading of saved history into the
    # FUTURE: toplevel officer. (dhandler sub-methods?)
    # FUTURE: History redo commands.

    if {[$actor root] != $actor} return

    $actor extend {history list} {
	section Introspection {Command history}
	description {
	    Show the saved history of commands.
	}
	input n {
	    Show the last n history entries.
	    Default is to show all.
	} {
	    optional
	    default 0
	    validate integer
	}
    } ::cmdr::history::Show
    # This recurses into 'attach' through the automatic inheritance of
    # the custom-setup hooks. See (***) above for the code
    # intercepting the recursion and preventing it from becoming
    # infinite.

    $actor extend {history clear} {
	section Introspection {Command history}
	description {
	    Clear the saved history.
	}
    } ::cmdr::history::Clear

    $actor extend {history limit} {
	section Introspection {Command history}
	description {
	    Limit the size of the history.
	    If no limit is specified the current limit is shown.
	}
	input n {
	    The number of commands to limit the history to.
	    For a value > 0 we keep that many commands in the history.
	    For a value < 0 we keep all commands, i.e. unlimited history.
	    For a value = 0 we keep nothing, i.e. no history.
	} {
	    optional
	    default -1
	    validate integer
	}
    } ::cmdr::history::Limit

    return
}

# # ## ### ##### ######## ############# #####################
## Handler invoked by the main framework when an officer starts
## an interactive shell.

proc ::cmdr::history::Init {actor} {
    debug.cmdr/history {}
    Load

    # Non-root actors and shell do not have access to the full history.
    if {[$actor root] != $actor} {
	return {}
    }

    # Root actor gets access the saved history
    variable cache
    return  $cache
}

# # ## ### ##### ######## ############# #####################
## Handler invoked by the main framework to save commands
## just before they are run.

proc ::cmdr::history::Add {command} {
    debug.cmdr/history {}
    Load

    # Shortcircuit if we are not keeping any history.
    variable limit
    if {$limit == 0} return

    # Extend history
    variable cache
    lappend  cache $command

    # And save it, possibly limiting the number of entries.
    if {[Restrict]} {
	SaveAll
    } else {
	SaveLast
    }
    return
}

proc ::cmdr::history::Restrict {} {
    variable limit
    debug.cmdr/history {limit = $limit}

    # There are no limits set, there is nothing to do.
    if {$limit < 0} {
	debug.cmdr/history {/no limit}
	return 0
    }

    variable cache
    debug.cmdr/history {cache len = [llength $cache]}

    set delta [expr {[llength $cache] - $limit}]

    debug.cmdr/history {delta = $delta}

    # The stored amount of history is still under the imposed limit,
    # so there is nothing to do.
    if {$delta < 0} {
	debug.cmdr/history {Under limit by [expr {- $delta}]}
	return 0
    }

    # Throw the <delta> oldest entries out. This may be all.
    set cache [lrange $cache $delta end]

    debug.cmdr/history {cache len = [llength $cache]}
    return 1
}

proc ::cmdr::history::SaveLast {} {
    debug.cmdr/history {}
    variable file
    variable cache

    debug.cmdr/history {file      = $file}
    debug.cmdr/history {cache len = [llength $cache]}

    file mkdir [file dirname $file]
    fileutil::appendToFile $file [lindex $cache end]\n
    return
}

proc ::cmdr::history::SaveAll {} {
    debug.cmdr/history {}

    variable limit
    variable cache
    variable file

    debug.cmdr/history {file      = $file}
    debug.cmdr/history {limit     = $limit}
    debug.cmdr/history {cache len = [llength $cache]}

    set contents ""

    if {$limit >= 0} {
	# We need a marker for limited and disabled history.
	append contents "#limit=$limit\n"
    }

    if {[llength $cache]} {
	append contents "[join $cache \n]\n"
    }

    file mkdir [file dirname $file]
    fileutil::writeFile $file $contents
    return
}

proc ::cmdr::history::Load {} {
    CheckActive

    variable loaded
    if {$loaded} return
    set loaded 1

    variable file
    variable limit
    variable cache

    if {![file exists $file]} {
	# Initial memory defaults for cache and limit are good.
	# Write the latter to external to keep it properly.
	SaveAll
	return
    }

    # We have a saved history, pull it in.
    set lines [split [string trimright [fileutil::cat $file]] \n]

    # Detect and strip a leading limit clause from the contents.
    if {[regexp "#limit=(\\d+)\$" [lindex $lines 0] -> plimit]} {
	set lines [lrange $lines 1 end]
    } else {
	set plimit -1
    }

    set limit $plimit
    set cache $lines
    # Apply the limit clause if the user tried to circumvent it by
    # manually extending the history. Any changes we had to make are
    # saved back.
    if {[Restrict]} SaveAll
    return
}

proc ::cmdr::history::CheckActive {} {
    variable file
    if {$file ne {}} return

    # No location to save to nor load from, abort request/caller.
    # Abort caller.
    return -code error \
	-errorcode {CMDR HISTORY NO-FILE} \
	"No history file specified"
}

# # ## ### ##### ######## ############# #####################
## Backend management actions.

proc ::cmdr::history::Show {config} {
    debug.cmdr/history {}
    Load

    variable cache

    set off [$config @n]
    if {$off <= 0} {
	# Show entire cache.
	# Start numbering at 1.

	set show $cache
	set num  1
    } else {
	# Partial history, show n last elements.
	incr off -1
	set show [lrange $cache end-$off end]
	set num  [expr {[llength $cache] - $off}]
    }

    variable cache
    set nlen [string length [llength $cache]]
    foreach line $show {
	puts " [format %${nlen}s $num] $line"
	incr num
    }
    return
}

proc ::cmdr::history::Clear {config} {
    debug.cmdr/history {}
    Load

    # Clear in-memory, and then external
    variable cache {}
    SaveAll
    return
}

proc ::cmdr::history::Limit {config} {
    debug.cmdr/history {}
    Load

    variable limit

    if {![$config @n set?]} {
	# Show current limit
	puts [Describe]
	return
    }

    # Retrieve the new limit, apply it to the in-memory history, and
    # at last refresh the external state.
    debug.cmdr/history {current = $limit}
    set new [$config @n]
    if {$new < 0 } {
	set new -1
    }

    debug.cmdr/history {new     = $new}

    if {$new == $limit} {
	puts {No change}
	return
    }

    set limit $new
    Restrict
    SaveAll

    puts "Changed limit to: [Describe]"
    return
}

proc ::cmdr::history::Describe {} {
    variable limit
    if {$limit < 0} {
	return "Keep an unlimited history"
    } elseif {$limit == 0} {
	return "Keep no history (off)"
    } elseif {$limit == 1} {
	return "Keep one entry"
    } else {
	return "Keep $limit entries"
    }
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::history 0.2
return
