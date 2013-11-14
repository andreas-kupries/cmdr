
[comment { No tables in doctools, using an example to get a tabular formatting. }]
[comment { TODO doctools: table markup }]
[comment { TODO doctools: named TOCs for commands - embedded small TOCs}]

[example {
alias <name> = <name'>...            Declare an alternate name for a command path.
alias <name>                         Declare an alternate name for the previous command.
common <name> <script>               Declare a named shared code block.
default                              Set last command as default.
description <text>                   Set help text for the current ensemble.
ehandler <cmdprefix>                 Execution Interposition.
officer <name> <script>              Declare a nested ensemble = sub-officer
private <name> <script> <cmdprefix>  Declare a simple command  = private
undocumented                         Hide ensemble from help.
}]

[list_begin definitions]
[def "[cmd alias] [arg name] [const =] [arg name']..."]
[def "[cmd alias] [arg name]"]

This is a structuring command, for the command hierarchy. Its main
uses are the creation of alternate command names, and of shortcuts
through the command hierarchy. 

[para] For example, stackato's command specification for alias management is
more like [sectref {Basic setup, command nesting}] and uses shortcuts
similar to what is shown in
--TODO--(example ls-alias2)-- to provide the look of a flat namespace.

[para] In the first form the [arg name] is given the explicit path to
the command it is an alias for. In the second form it implicitly
refers to the immediately preceding officer or private.

Note that "immediately" is interpreted at the current level. The
system is [emph not] looking into a nested specification for its last
command.

[def "[cmd common] [arg name] [arg text]"]

This is another structuring command, for structuring the specification
itself instead of the command tree it declares.

[para] It creates named values, usually code blocks, which can be
shared between specifications. Note that while each block is visible
in the current officer and its subordinates, parents and siblings have
no access.

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
reserved by the framework. This block, if defined, is automatically
included at the front of all "private" specifications, i.e. shared
across all the specified commands underneath this officer. A very
important trait for the option in the example, as it makes the debug
setup available to all commands without having to explicitly include
the block, and possibly forgetting such.

[para] Generally speaking, the framework reserves all blocks whose
name begins with a star, i.e [const *], for its own use.

[def "[cmd default]"]
This command sets up a special kind of alias. The last "private" or
"officer" is set as the default command to use at runtime.

This means that if during "Dispatch" the currently processed word does
not match any of the commands known to this officer this default is
used. If no default is specified an error will be thrown instead.

[def "[cmd description] [arg text]"]
This command declares the help text of the officer.

[def "[cmd ehandler] [arg cmdprefix]"]

This is an advanced command which should normally only be specified at
the top of the whole hierarchy (from which its value will
automatically propagate to all subordinates).

[para] At runtime the framework will call the specified command prefix
with a single argument, a script whose execution is equivalent to the
phases "Parsing", "Completion", and "Execution" of the framework, as
described in section --TODO--(sectref:flow/phases)--. The handler [emph must]
call this script, and can perform any application-specific actions
before and after.

[para] This handler's main uses are two-fold:
[list_begin enumerated]
[enum] Capture and hande application-specific errors which should not
abort the application, or shown as Tcl stacktrace.

[enum] Cleanup of application-specific transient settings the
parameter callbacks and/or command implementations may have set during
their execution. This is especially important if the interactive
command line shells of the framework are active. Without such a
handler and its bespoke cleanup code transient settings will leak
between multiple commands run from such a shell, something which is
definitely not wanted.
[list_end]

[def "[cmd officer] [arg name] [arg script]"]
This command creates a named subordinate officer with its
specification [arg script] of officer commands as described here.

[def "[cmd private] [arg name] [arg script] [arg cmdprefix]"]
This command creates a named subordinate private with its
specification [arg script] of private commands as described in the
following section, and a command prefix to invoke when it is chosen.

[para] This command prefix is called with a single argument, the
[package cmdr::config] instance holding the parameters of the private.

--TODO--(ref:backend-example-code)--

[def "[cmd undocumented]"]
Use of this command influences the generation of help, excluding all
officers having this marker (and their subordinates) from the
help. Note that subordinates reachable through aliases may be
included, under the alias name, if not explicitly excluded themselves.

[list_end]
