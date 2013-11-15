
[para] An important concept of [term parameter]s is something taken up
from Tcl itself.

The differentation between [term string] and [term {internal representations}].

Where Tcl uses [term {internal representations}] to speed up its
execution here this separation is that of between the information
delivered to the application by a user, and the application-specific
data structures behind them.

[para] All [term parameter]s will have an [term {internal representation}].

This is usually derived from the [term {string representation}]
provided by the user.

The details of that process are explained in section [sectref Validation].

However we have cases where the user cannot specify a string
representation ([term state]s), or is allowed to choose not to
(optional [term input]s, [term option]s).

For these cases three specification commands are made available
enabling us to programmatically choose the internal representation.

[list_begin definitions]

[comment {- - -- --- ----- -------- -------------}]
[call [cmd default] [arg value]]

This command specifies a constant default value for the internal
representation.

[comment {- - -- --- ----- -------- -------------}]
[call [cmd generate] [arg cmdprefix]]

This command specifies a callback to compute the default internal
representation at runtime. This is useful if the default is something
which cannot be captured as a fixed value. An example would be a
handle to some resource, or a dynamically created object.

[para] The command prefix is invoked with a single argument, the
[package cmdr::parameter] instance for which to generate the internal
representation.

[list_end]

[para] The commands [cmd default] and [cmd generate] exclude each
other, i.e. only of them can be specified, but not both.

If neither are specified, and we need a default (see the cases above)
then a default is chosen by the framework itself, as per the two rules
below:

[list_begin enumerated]
[enum] Use the empty string for a [cmd list] parameter.

[enum] Use the default value supplied by the chosen
[term {validation type}] (See section [sectref Validation]).
[list_end]

[list_begin definitions]
[comment {- - -- --- ----- -------- -------------}]
[call [cmd interact] [opt [arg prompt]]]

This command actually does not specify an
[term {internal representation}], but activates another method for the
user to specify the [term {string representation}] of the
[term parameter], outside of the command line.

As such it has priority over either [cmd default] and [cmd generate],
and can be specified with either. A [term parameter] marked with it
will interactively ask the user for a value if none was specified on
the command line.

[para] The default for the [arg prompt] is derived from the
[term parameter]'s [term {system name}].

[list_end]

[para] To recapitulate:

[list_begin enumerated]

[enum] A [term {string representation}] specified on the command line
has the highest priority and goes through the chosen
[term {validation type}] to get the associated
[term {internal representation}].

[enum] If activated via [cmd interact] a small shell is run asking the
user for a value (or more, as per [cmd list], see below). The result
goes through the chosen [term {validation type}] to get the associated
[term {internal representation}].

[enum] After that the [term {internal representation}] is either the
declared [cmd default] value, or the result of invoking the
[cmd generate] callback.

As [term {internal representation}]s the resulting values are
[emph not] run through the chosen [term {validation type}].

[list_end]

[list_begin definitions]
[comment {- - -- --- ----- -------- -------------}]
[call [cmd list]]

This command marks the [term parameter] as a list. In other words, its
[term string] and [term {internal representation}] is actually a list
of such, instead of a single value.

By default all parameters are scalar.

[para] This affects the handling of the parameter by the
[term Parsing] phase, by [cmd interact] above, and the use of the
[term {validation type}].

The last two ask for multiple values, and feed the elements of the
[term {string representation}] separately through validation instead
of just the string value in one. 

In the [term Parsing] phase treatment of [term option]s changes from
keeping only the last assigned value to the accumulation of all
values.

Similarly a list-[term input] takes all the remaining words on the
command line for itself instead of just the current word. Because of
this list-[term inputs] are only allowed as the last [term parameter]
of a [term private].

[list_end]

[para] The last two specification commands dealing with the
representations control [emph when] the
[term {internal representation}] is created.

[list_begin definitions]

[comment {- - -- --- ----- -------- -------------}]
[call [cmd defered]]

This command marks a [term parameter] as [term defered], causing its
[term {internal representation}] to be computed on first access to its
value. This is the default for [term state] parameters.

[comment {- - -- --- ----- -------- -------------}]
[call [cmd immediate]]

This command marks a [term parameter] as [term immediate], causing its
[term {internal representation}] to be computed in the
[term Completion] phase.

This is the default for [term input] and [term option] parameters.

[list_end]
