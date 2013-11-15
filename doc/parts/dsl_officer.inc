
[list_begin definitions]
[comment {- - -- --- ----- -------- -------------}]
[call [cmd alias] [arg name] [const =] [arg name']...]
[call [cmd alias] [arg name]]

This is a structuring command, for the command hierarchy. Its main
uses are the creation of alternate command names, and of shortcuts
through the command hierarchy.

[para] For example, [syscmd stackato]'s command specification for
alias management is written using deep nesting and uses aliases to
provide the look of a flat namespace to application users.

[para] In the first form the [arg name] is given the explicit path to
the actor the name is an alias for.

In the second form the alias implicitly refers to the immediately
preceding [term officer] or [term private].

Note that "immediately" is interpreted at the current level. The
system is [emph not] looking into a nested specification for its last
command.

[list_begin arguments]
[arg_def string name]
The name of the alias.

[arg_def string name'...]
The path to the actor, as list of names.
[list_end]

[comment {- - -- --- ----- -------- -------------}]
[call [cmd common] [arg name] [arg text]]

This is another structuring command, for structuring the specification
itself instead of the command tree it declares.

[para] It creates named values, usually code blocks, which can be
shared between specifications. Note that while each block is visible
in the current [term officer] and its subordinates, parents and
siblings have no access.

[para] An example of such a block would be

[example {
common *all* {
    option debug {
	Activate client internal tracing.
    } {
	undocumented
	list
	when-complete [lambda {p tags} {
	    foreach t $tags { debug on $t }
	}]
    }
}
}]

This example defines an option to access the subsystem for debug
narative (See package [package Tcllib]).

The example is actually special, as the block named [const *all*] is
reserved by the framework.

This block, if defined, is automatically included at the front of all
[term private] specifications, i.e. shared across all the privates
specified underneath this [term officer]. A very important trait for
the [term option] in the example, as it makes the debug setup
available to all privates without having to explicitly include the
block, and possibly forgetting such.

[para] Generally speaking, the framework reserves all blocks whose
name begins with a star, i.e [const *], for its own use.

[list_begin arguments]
[arg_def string name]
The name of the common block.

[arg_def string text]
The text of the block.
[list_end]

[comment {- - -- --- ----- -------- -------------}]
[call [cmd default]]

This command sets up a special kind of alias.

The last [term private] or [term officer] is set as the default
command to use at runtime.

This means that if during "Dispatch" phase the currently processed
word does not match any of the commands known to this [term officer]
this default is used. If no default is specified an error will be
thrown instead.

[comment {- - -- --- ----- -------- -------------}]
[call [cmd description] [arg text]]

This command declares the help text of the [term officer].

[comment {- - -- --- ----- -------- -------------}]
[call [cmd ehandler] [arg cmdprefix]]

This is an advanced command which should normally only be specified at
the top of the whole hierarchy (from which its value will
automatically propagate to all subordinates).

[para] At runtime the framework will call the specified command prefix
with a single argument, a script whose execution is equivalent to the
phases "Parsing", "Completion", and "Execution" of the framework, as
described in --TODO--(sectref:flow/phases)--. The handler [emph must]
call this script, and can perform any application-specific actions
before and after.

[para] This handler's main uses are two-fold:

[list_begin enumerated]

[enum] Capture and hande application-specific errors which should not
abort the application, nor shown as Tcl stacktrace.

[enum] Cleanup of application-specific transient state the
[term parameter] callbacks (See [term [vset TITLE_DSL_PARAMETER]])
and/or actions may have set during their execution.

This is especially important if the interactive command line shells of
the framework are enabled. Without such a handler and its bespoke
cleanup code transient state [emph will] leak between multiple
commands run from such a shell, something which is definitely not
wanted.

[list_end]

[comment {- - -- --- ----- -------- -------------}]
[call [cmd officer] [arg name] [arg script]]

This command creates a named subordinate [term officer] with its
specification [arg script] of officer commands as described here.

[comment {- - -- --- ----- -------- -------------}]
[call [cmd private] [arg name] [arg script] [arg cmdprefix]]

This command creates a named subordinate [term private] with its
specification [arg script] of private commands
(See [term [vset TITLE_DSL_PRIVATE]]), and a command prefix to invoke
when it is chosen.

[para] This command prefix is called with a single argument, the
[package cmdr::config] instance holding the [term parameter]s of the
private.

--TODO--(ref:backend-example-code)--

[comment {- - -- --- ----- -------- -------------}]
[call [cmd undocumented]]

This command excludes the [term officer] (and its subordinates) from
the generated help.

Note that subordinates reachable through aliases may be included,
under the alias name, if they are not explicitly excluded themselves.

[list_end]
