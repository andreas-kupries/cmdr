
[para] The specification of simple commands, i.e. "privates" is quite
easy, with only seven commands (see the table below). The important
parts are found in the parameter specifications, explained in the next
section.

[comment { No tables in doctools, using an example to get a tabular formatting. }]
[comment { TODO doctools: table markup }]
[comment { TODO doctools: named TOCs for commands - embedded small TOCs}]

[example {
description <text>             Set help text for command.
input <name> <help> <script>   Declare a positional parameter.
interactive                    Allow interactive shell.
option <name> <help> <script>  Declare a named parameter.
state <name> <help> <script>   Declare a hidden parameter.
undocumented                   Hide command from help.
use <name>                     Execute the named "common" block here.
}]

[list_begin definitions]
[def "[cmd description] [arg text]"]
Like the equivalent command for [sectref Officers] this command
declares the help text for the private.

[def "[cmd input] [arg name] [arg help] [arg script]"]
This command adds an "input" (positional) parameter to the "private",
with description [arg help] and its specification [arg script] of
parameter commands as described in the following section.

[def "[cmd interactive]"]
This command influences the runtime. By default the only interactive
command line shells are associated with the officers. Setting this
marker activates such a shell for the private, to be invoked when
required parameters do not have a value.

[para] The global command [cmd {cmdr::config interactive}] in package
[package cmdr::config] can be used to globally activate this type of
shell for all "privates".

[def "[cmd option] [arg name] [arg help] [arg script]"]
This command adds an "option" (named) parameter to the "private", with
description [arg help] and its specification [arg script] of parameter
commands as described in the following section.

[def "[cmd state] [arg name] [arg help] [arg script]"]
This command adds a "state" (hidden) parameter to the "private", with
description [arg help] and its specification [arg script] of parameter
commands as described in the following section.

[def "[cmd undocumented]"]
Like the equivalent command for [sectref Officers] use of this command
influences the generation of help, excluding all privates having this
marker from it.

[def "[cmd use] [arg name]"]
This command is the counterpart to [cmd common] of [sectref Officers].
It inserts the named block into the specification, executing it. As
such it expects the contents to be a script of private commands as
described in this section.

[list_end]
