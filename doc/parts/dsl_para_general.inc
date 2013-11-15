
[para] The general handling of a [term parameter] is influenced by
three commands:

[list_begin definitions]

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

The details are explained in --TODO--(sectref:flow/parsing,flow/optional)--.

[comment {- - -- --- ----- -------- -------------}]
[call [cmd undocumented]]

This command excludes the [term parameter] from the generated help.

[para] Its main use case is the hiding of [term option]s giving an
application developer access to the internals of their application,
something a regular user has no need of, and doesn't have to know
about.

[list_end]




