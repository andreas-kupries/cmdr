
[para] The parameters of private commands are the heart of the system,
providing the space needed to transfer the command arguments to the
implementations, and having the most attributes controlling their
behaviour.

[para] This complexity is mitigated strongly by the use of sensible
defaults for each of the three possible kinds of parameter, i.e.
positional "inputs", named "options", and "state" hidden from the
command line.

[para] Each kind has its own construction command in the DSL for
[sectref Privates] which specifies the common information which cannot
have defaults, i.e.

[list_begin enumerated]
[enum] the name identifying it to the system,
[enum] the help text describing it in informal speech, and, of course,
[enum] the parameter specification itself, using the commands of this section.
[list_end]

[comment { No tables in doctools, using an example to get a tabular formatting. }]
[comment { TODO doctools: table markup }]
[comment { TODO doctools: named TOCs for commands - embedded small TOCs}]

[example {
alias <name>              N  Declare alternate flag for an option.
default <value>            R Set constant default value.
defered                    R  Defer calculation of the internal representation until demanded.
generate <cmdprefix>       R  Set callback returning the default value.
immediate                  R  Complement of defered.
interact ?<prompt>?        R  Enable the interactive entry of the string value.
label <text>              N  Name to use in the help, and as primary flag (for an option).
list                       R Declare as list-valued.
optional                  G  Declare input as optional.
presence                   V Declare as boolean option without argument.
test                      G  Control the matching of words to optional inputs.
undocumented              G  Declare as hidden from help.
validate <cmdprefix>       V Declare validation type.
when-complete <cmdprefix> C  Set callback executed when the value becomes known.
when-set <cmdprefix>      C  Set callback executed when the string value becomes known.
}]

[para][emph Naming]            [include dsl_para_naming.inc]
[para][emph {General control}] [include dsl_para_general.inc]
[para][emph Representations]   [include dsl_para_reps.inc]
[para][emph Validation]        [include dsl_para_validation.inc]
[para][emph Signaling]         [include dsl_para_callbacks.inc]


[comment {


Command & Attribute & Input & Option & State & Notes





presence & presence &
no & no & n/a &
Declare as boolean \coption without argument.
Implies \cdefault and \cvalidate settings.

validate <cmdprefix> & validate &
$*$ & $*$ & $*$ &
Declare validation type.
Details in section \ref{para/vtype}.



when-complete <cmdprefix> & when-complete &
none & none & none &
Set callback executed when the value becomes known.

when-set <cmdprefix> & when-set &
none & none & none &
Set callback executed when the string value becomes known.

}]
