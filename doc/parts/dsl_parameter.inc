
[para] The [term parameter]s of [term private]s are the heart of the
system, providing the space needed to transfer command arguments to
their implementations, and having the most attributes controlling
their behaviour.

[para] This complexity is strongly mitigated by the use of sensible
defaults for each of the three possible kinds of parameter, i.e.
positional [term input]s, named [term option]s", and [term state]
hidden from the command line.

[para] Each kind has its own construction command in the language for
[term private]s (See [term [vset TITLE_DSL_PRIVATE]]) which specifies
the common information which cannot have defaults, i.e.

[list_begin enumerated]
[enum] the name identifying it to the system,
[enum] the help text describing it in informal speech, and, of course,
[enum] the parameter specification itself, using the commands of this section.
[list_end]

[para][subsection Naming]
[include dsl_para_naming.inc]

[para][subsection {General control}]
[include dsl_para_general.inc]

[para][subsection Representations]
[include dsl_para_reps.inc]

[para][subsection Validation]
[include dsl_para_validation.inc]

[para][subsection Signaling]
[include dsl_para_callbacks.inc]
