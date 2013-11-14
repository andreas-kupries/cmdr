
[para] The general handling of a parameter is influenced by three
commands.

[list_begin definitions]
[def "[cmd optional]"]

This command marks the parameter as optional, i.e. as something the
user may skip on the command line, and the application supplying
sensible defaults. --TODO--(sectref:para/vtype)--

During parsing the framework will then expend some effort to determine
whether an argument word should be assigned to the parameter, or not.

[para] This setting is only applicable to "inputs", as "options" are
optional by definition, and "state" is hidden.

[def "[cmd test]"]

This command is related to the above, switching from the standard
regime for acceptance based on counting and thresholds to a different
one based on validation. The details are explained in section
--TODO--(sectref:flow/parsing, flow/optional)--.

[def "[cmd undocumented]"]

Like "officers" and "privates" parameters can be hidden from the
generated help. This is the command for doing so, the same as for the
first two.

[para] The main use case is the hiding of options giving an
application developer access to the internals of their application,
something a regular user has no need of, and doesn't have to know
about.

[list_end]




