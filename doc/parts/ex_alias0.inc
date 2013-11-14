
[para] This example specifies a command line providing 3 commands for
the management of command aliases.

This is actually a slice of [syscmd stackato]'s interface, reduced and
modified to fit here.

While it does not have the necessary backend procedures required to
actually run the commands, it is enough to demonstrate basic features,
namely the declaration of "privates" with "input" parameters.

[para] "privates" are the actual commands, the leaves at the bottom of
the hierarchy. Their "inputs" are positional parameters, i.e. the
association of argument words on a command line to parameter is done
in order of occurence (on command line, and in the specification).

[example {
# -*- tcl -*
package require Tcl 8.5
package require cmdr
package require foo-backend

cmdr create ::foo foo {
    private alias+ {
	description {
	    Create a shortcut for a command (prefix).
	}
	input name {
	    The name of the new shortcut.
	} {
	    validate ::foo::backend::vt::notacommand
	}
	input command {
	    The command (prefix) the name will map to.
	} {
	    list
	}
    } ::foo::backend::alias::add

    private alias- {
	description {
	    Remove a shortcut by name.
	}
	input name {
	    The name of the shortcut to remove.
	} {
	    validate ::foo::backend::vt::aliasname
	}
    } ::foo::backend::alias::remove

    private alias? {
	description {
	    List the known aliases (shortcuts).
	}
    } ::foo::backend::alias::list
}

foo do {*}$argv
exit
}]

[para] At the bottom of the example, just above we can also see the
very simple Tcl command which invokes the command line processing for
a list of words, here coming from [var \$argv], i.e. the application's
command line.
