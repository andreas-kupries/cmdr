
[para] An important concept of parameters is something taken up from
Tcl itself.

The differentation between string and internal representations.

Where Tcl uses internal representations to speed up its execution here
this separation is that of between the information delivered to the
application by a user, and the application-specific data structures
behind them.

[para] All parameters will have an internal representation.

This is usually derived from the string representation provided by the
user.

The details of that process are explained in section
--TODO--(sectref:para/vtype)--
about validation types.

However we have cases where the user cannot specify a string
representation ("states"), or is allowed to choose not to (optional
"inputs", "options").

For these cases three specification commands are made available
enabling us to programmatically choose the internal representation.

[list_begin definitions]
[def "[cmd default] [arg value]"]

This command provides a constant value for the internal
representation.

[def "[cmd generate] [arg cmdprefix]"]

This command provides a callback to compute the internal
representation at runtime. This is useful if the default is something
which cannot be captured as a fixed value, for example a handle to
some resource, or a dynamically created object.

[para] The command prefix is invoked with a single argument, the
[package cmdr::parameter] instance for which to generate the internal
representation. 

[list_end]

[para] The commands "default" and "generate" exclude each other,
i.e. only of them can be specified.

If neither are specified, and we need a default (see the cases
above) a default is chosen per the two rules below:

[list_begin enumerated]
[enum] Use the empty string for a "list" parameter.

[enum] Use the default value supplied by the chosen validation type
       (See section --TODO--(sectref:para/vtype)--).
[list_end]

[list_begin definitions]
[def "[cmd interact] [opt [arg prompt]]"]
This command actually does not specify an internal representation, but
activates another method for the user to specify a string value for
the parameter, outside of the command line. 

As such it has priority over either "default" and "generate," and can
be specified with either. A parameter marked with it will
interactively ask the user for a value if none was specified on the
command line.

[para] The default [arg prompt] is derived from the system name.

[list_end]

[para] To recapitulate:

[list_begin enumerated]

[enum] A string representation specified on the command line has the
       highest priority and goes through the chosen validation type to
       get the associated internal representation.

[enum] If activated via "interact" a small shell is run asking the
       user for a value (or more, as per "list", see below). The
       result goes through the chosen validation type to get the
       associated internal representation.

[enum] After that the internal representation is either the declared
       "default," or the result of invoking the "generate"
       callback. As internal representations they are [emph not] run
       through the chosen validation type.
[list_end]

[list_begin definitions]
[def "[cmd list]"]
This command is used to mark parameters whose string and thus internal
value should be treated as a list. By default all parameters are scalar.

[para] This affects the handling of the parameter during parsing, by
"interact" above, and the use of the validation type. The last two ask
for multiple values, and feed the elements of the string value
separately through validation instead of just the string value in one.
During parsing treatment of "options" changes from keeping only the
last assigned value to accumulation of all values. Similarly a
list-"input" takes all remaining words on the command line for itself
instead of just the current word. Because of this list-"inputs" are
only allowed as the last parameter of a "private."

[list_end]

[para] The last two specification commands dealing with the
representations control when the internal representation is created.

[list_begin definitions]
[def "[cmd defered]"]
This command marks a parameter as defered, with the internal
representation computed on first access to its value. This is the
default for "state" parameters.

[def "[cmd immediate]"]
This command marks a parameter as immediate, with the internal
representation computed in the "Completion" phase. This is the default
for "input" and "option" parameters.

[list_end]
