
Of the four callbacks supported by parameters the first two,
"generate" and "validate" have been described already, in the sections
--TODO--\ref{para/reps} about representations and
--TODO--\ref{para/vtype} about validation types, respectively.

[para] This section explains the commonalities between the callbacks
in general, and the last two, for notifications about state changes in
detail.

[para] All callbacks are treated as command prefixes, not
scripts.

There are no placeholder substitutions, only arguments added to each
command prefix on invokation. This does not harm the generality of the
system, as complex scripts can be used via procedures or equivalents
(i.e. [cmd apply]).

[para] The two callbacks not yet described are the state-change
callbacks through which the framework can actively drive parts of the
application while processing the command line, whereas normally the
application drives access to parameters through their methods.

[list_begin definitions]
[def "[cmd when-complete] [arg cmdprefix]"]

This command declares the state-change callback to invoke when the
internal representation of the parameter is generated from the string
representation, or the various ways of getting a default.

[para] The callback is invoked with two arguments, the
[package cmdr::parameter] instance of the parameter which changed, and
its internal representation, in this order.

[def "[cmd when-set] [arg cmdprefix]"]

This command declares the state-change callback to invoke when the
string representation of the parameter is set during command line
parsing.

[para] The callback is invoked with two arguments, the
[package cmdr::parameter] instance of the parameter which changed, and
its string representation, in this order.


[list_end]

Due to their nature these callbacks are invoked at runtime during
either parsing, completion," or execution. The details are shown in
the table below. The specification commands influencing the timing,
i.e. forcing the use in a specific phase are shown in the intersection
of callback and phase.

[example {
                    | Dispatch | Parsing | Completion  | Execution
--------------------+----------+---------+-------------+-----------
validate (default)  | *        |         |             |          
--------------------+----------+---------+-------------+-----------
validate (complete) |          | *       | immediate   | defered
when-set            |          | *       |             |          
--------------------+----------+---------+-------------+-----------
generate            |          |         | immediate   | defered
validate (validate) |          | test    | immediate   | defered
validate (release)  |          | test    | immediate   | defered
--------------------+----------+---------+-------------+-----------
when-complete       |          |         | immediate   | defered
--------------------+----------+---------+-------------+-----------
}]
