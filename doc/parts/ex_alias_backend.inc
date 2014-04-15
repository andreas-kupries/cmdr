
[para] This example shows a possible implementation of the backend for
the command hierarchies shown in the previous two sections.

It is important to note, I believe, that this backend works for both
command hierarchies, despite the changes to the command names (flat
versus nesting) they do.

[para] Note further that while this example uses a
[cmd {namespace ensemble}] to organize the backend other methods are
possible too, i.e. all the various object systems for Tcl would be
suitable as well.

[para] Lastly, for the sake of brevity this code is incomplete, not
showing any utility commands we may have importet from somewhere else,
nor the low-level workhorse procedures operating on the actual
alias database or whatnot.

[para] [example {
# -*- tcl -*-
# # ## ### ##### ######## ############# #####################

namespace eval ::foo::backend::alias {
    namespace export list add remove
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################
## Command implementations.

proc ::foo::backend::alias::list {config} {
    set aliases [manager known]

    if {[$config @json]} {
	puts [jmap aliases $aliases]
	return
    }

    [table::do t {Alias Command} {
	foreach {name command} $aliases {
	    $t add $name $command
	}
    } show display]
    return
}

proc ::foo::backend::alias::add {config} {
    set name    [$config @name]
    set command [$config @command]

    manager add $name $command
    say [color green "Successfully aliased '$name' to '$command'"]
    return
}

proc ::foo::backend::alias::remove {config} {
    set name [$config @name]

    if {![manager has $name]} {
	err [color red "Unknown alias '$name'"]
    } else {
	manager remove $name
	say [color green "Successfully unaliased '$name'"]
    }
    return
}

# # ## ### ##### ######## ############# #####################
package provide \
	foo::backend::alias 0
# 2 lines, hidden from kettle scanner.
}]
