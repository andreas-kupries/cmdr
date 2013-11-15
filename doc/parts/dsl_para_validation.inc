
[para] The answer to the necessity of moving between the [term string]
and [term {internal representations}] described in the previous
section are the [term {validation types}].

Given a [term {string representation}] they either return the
associated [term {internal representation}] or raise an error,
signaling that the string was illegal. This part of their work, the
verification of the legality of the input string gave them their name.

[comment {--TODO--(textblock shared with cmdr-vtypes.man)}]
[para] The general concept of [term {validation types}] was taken from
[package snit], and modified to suit [vset PTITLE].

Where snit's types expect only a single method to validate the input
[vset PTITLE] expects all types to support an ensemble of [emph four]
methods, one for the basic validation and transformation of the input,
another for the release of any internal representation so generated,
plus delivery of a default representation and support for command line
completion.

[list_begin definitions]

[comment {- - -- --- ----- -------- -------------}]
[call [cmd validate] [arg cmdprefix]]

This command specifies a [term {validation type}] for the

[term parameter], in the form of a command prefix (or the name of one
of the builtin types, see package [package cmdr::validate]).

The set of methods this callback has to support, their signatures,
etc. are all explained in [term [vset TITLE_DEV_VT]]. This document
contains the implementation of the standard boolean validation type as
an example as well.

[para] Because of the same necessity all [term parameter]s must have a
[term {validation type}] assigned to them, and the system will choose
which, if the user did not. This choice is made as per the six rules
below and always returns one of the standard types implemented by
package [package cmdr::validate].

[list_begin enumerated]
[enum] Use [const identity] if a [cmd generate] callback is specified.
[enum] Use [const boolean]  if no [cmd default] is specified and the parameter is an [term option].
[enum] Use [const identity] if no [cmd default] is specified and the parameter is an [term input].
[enum] Use [const boolean]  if the specified [cmd default] value is a Tcl boolean.
[enum] Use [const integer]  if the specified [cmd default] value is a Tcl integer.
[enum] Use [const identity] as fallback of last resort.
[list_end]

[comment {- - -- --- ----- -------- -------------}]
[call [cmd presence]]

This command is best discussed as part of the wider area of

[term boolean] [term option]s, i.e. [term option]s with the standard
[term {validation type}] [const boolean] assigned to them. These have
associated special behaviours, both in the handling of the
specification, and in the [term Parsing] phase.

[para] First, normal boolean options.

They have automatic aliases declared for them, derived from their
primary flag.

An option named "foo" will have an alias of "no-foo", and the
reverse.

In the [term Parsing] phase the "foo" and "no-foo" flags have inverse
semantics, and both are allowed to occur without option argument
following the flag.

This is in contrast to all other [term option]s which must have such
an argument. The parser essentially uses the [term {validation type}]
to decide if the word after the flag is a proper boolean value, or
not, i.e. an argument to assign to the [term parameter], or not.

[para] Now [cmd presence] declares a variant of the above, a boolean
option [emph without] the automatic aliases, and [emph never] taking
an argument during parsing.

Its mere [emph presence] on the command line will set its
[term parameter].

Their [cmd default] value is consequently fixed to [const false] as
well.

[list_end]
