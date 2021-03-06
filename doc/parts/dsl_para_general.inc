
[para] The general handling of a [term parameter] is influenced by
three commands:

[list_begin definitions]

[comment {- - -- --- ----- -------- -------------}]
[call [cmd no-promotion]]

When the framework encounters an unknown flag during the
[term Parsing] phase it will not unconditionally throw an error about
it, but first check if the next available [term input]
[term parameter] (if any) could accept the flag string as its value,
per that [term input]'s [term {validation type}], and if yes, does so.

[para] This command causes the rejection of such flag strings by this
parameter on general principle, without having to validate it.

[para] [emph Note] that it is only useful for and applicable to
[term input] [term parameters].

[comment {- - -- --- ----- -------- -------------}]
[call [cmd optional]]

This command marks the parameter as [term optional], i.e. as something
the user may skip on the command line, with the application supplying
sensible defaults (See section [sectref Representations]).

This causes the framework to expend some effort in the [term Parsing]
phase to determine whether an argument word should be assigned to the
parameter, or not.

[para] This setting is only applicable to [term input]s, as
[term option]s are optional by definition, and [term state] is hidden.

[comment {- - -- --- ----- -------- -------------}]
[call [cmd test]]

This command is related to the above, switching the runtime from the
standard regime for acceptance (based on counting and thresholds) to a
different regime based on validation.

[para] More details are explained in section [term Parsing] of
[term [vset TITLE_FLOW]].

[comment {- - -- --- ----- -------- -------------}]
[call [cmd undocumented]]

This command excludes the [term parameter] from the generated help.

[para] Its main use case is the hiding of [term option]s giving an
application developer access to the internals of their application,
something a regular user has no need of, and doesn't have to know
about.

[list_end]




