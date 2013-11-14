
[para] The answer to the necessity of moving between the string and
internal representations described in the previous section are the
validation types. Given a string representation they either return the
associated internal representation or raise an error, signaling that
the input was illegal. This part of their work, the verification of
the legality of the input string gave them their name.


[comment {--TODO--(textblock shared with cmdr-vtypes.man)}]
[para] The general concept of validation types was taken from
[package snit], and modified to suit [vset PTITLE]. Where snit's types
expect only a single method to validate the input [vset PTITLE]
expects all types to support an ensemble of [emph four] methods, one
for the basic validation and transformation of the input, another for
the release of any internal representation so generated, plus delivery
of a default representation and support for command line completion.


[list_begin definitions]
[def "[cmd validate] [arg cmdprefix]"]

This command specifies a validation type for the parameter, in the
form of a command prefix.

The set of methods this callback has to support, their signatures,
etc. are all explained in [term [vset TITLE_DEV_VT]]. This document
contains the implementation of the standard boolean validation type as
an example as well.

[para] Because of the same necessity all parameters must have a
validation type assigned to them, and the system will choose which, if
the user did not. This choice is made per the six rules below and
always returns one of the standard types implemented in package
[package cmdr::validate].

[list_begin enumerated]
[enum] Use "identity" if a "generate" callback is specified.
[enum] Use "boolean"  if no "default" is specified and the parameter is an option.
[enum] Use "identity" if no "default" is specified and the parameter is an input.
[enum] Use "boolean"  if the specified "default" value is a Tcl boolean.
[enum] Use "integer"  if the specified "default" value is a Tcl integer.
[enum] Use "identity" as fallback of last resort.
[list_end]

[def "[cmd presence]"]
This command is best discussed as part of the wider area of "boolean"
options, i.e. options with validation type "boolean" assigned to
them. These have associated special behaviours, both in the handling
of the specification, and during parsing.

[para] First, normal boolean options. They have automatic aliases
declared for them, derived from their primary flag. An option named
"foo" will have an alias of "no-foo", and the reverse. During parsing
the "foo" and "no-foo" flags have inverse semantics, and both are
allowed to occur without option argument following the flag. This is
in contrast to all other options which must have such an argument. The
parser essentially uses the validation type to decide if the word
after the flag is a proper boolean value, or not, i.e. an argument to
assign to the parameter, or not.

[para] Now "presence" declares a variant of the above, a boolean
option without the automatic aliases, and [emph never] taking an
argument during parsing. Its mere [emph presence] on the command line
will set its parameter. Their default value is consequently fixed to
[const false] as well.

[list_end]
