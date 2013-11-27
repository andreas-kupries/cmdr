
[para] The specification of [term private]s is quite easy, with only
seven commands. The important parts are found in the [term parameter]
specifications, explained in [term [vset TITLE_DSL_PARAMETER]].

[list_begin definitions]

[comment {- - -- --- ----- -------- -------------}]
[call [cmd description] [arg text]]

This command declares the help text for the [term private].

[comment {- - -- --- ----- -------- -------------}]
[call [cmd input] [arg name] [arg help] [arg script]]

This command adds an [term input] (i.e. positional) [term parameter]
to the [term private], with description [arg help] and its
specification [arg script] of parameter commands as described in
[term [vset TITLE_DSL_PARAMETER]].

[comment {- - -- --- ----- -------- -------------}]
[call [cmd interactive]]

This command activates a mini-shell for this [term private] which will
be invoked when required [term parameter]s do not have a value after
argument extraction and matching.

[para] By default the only interactive command line shells are
associated with the [term officer]s.

[para] The command [cmd {cmdr::config interactive}] provided by the
package [package cmdr::config] can be used to globally activate this
type of shell for all [term private]s.

[comment {- - -- --- ----- -------- -------------}]
[call [cmd option] [arg name] [arg help] [arg script]]

This command adds an [term option] (i.e. named) [term parameter] to
the [term private], with description [arg help] and its specification
[arg script] of parameter commands as described in
[term [vset TITLE_DSL_PARAMETER]].

[comment {- - -- --- ----- -------- -------------}]
[call [cmd section] [arg word]...]

This command places the [term private] into a help section/category,
for use by the standard help format [term by-category]
(See [term [vset TITLE_HELP]]).

[para] The section/category is specified as a list of words, each
denoting part of the path to the section. This means that the last
word is the section of the private, with the preceding words the
sections it is nested in.

[para] Multiple calls are possible and accumulate. In other words,
the private can be placed in more than one section/category.

[comment {- - -- --- ----- -------- -------------}]
[call [cmd state] [arg name] [arg help] [arg script]]

This command adds a [term state] (i.e. hidden) [term parameter] to the
[term private], with description [arg help] and its specification
[arg script] of parameter commands as described in
[term [vset TITLE_DSL_PARAMETER]].

[comment {- - -- --- ----- -------- -------------}]
[call [cmd undocumented]]

This command excludes the [term private] from the generated help.

[comment {- - -- --- ----- -------- -------------}]
[call [cmd use] [arg name]]

This command is the counterpart to [cmd common] of [term officer]s
(See [term [vset TITLE_DSL_OFFICER]]).

It inserts the named block into the specification, executing it in
place. As such it expects the contents to be a script of private
commands as described in this section.

[list_end]
