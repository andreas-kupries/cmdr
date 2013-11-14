
[comment { No tables in doctools, using an example to get a tabular formatting. }]
[comment { TODO doctools: table markup }]
[comment { TODO doctools: named TOCs for commands - embedded small TOCs}]

[comment {


Command & Attribute & Input & Option & State & Notes

-- & name        & --  & --  & --  &
Parameter name, unique within the \cprivate.

-- & description & --  & --  & --  &
Help text.

-- & visible     & yes & yes & no  &
Parameter is (in)visible to \parsing.

-- & ordered     & yes & no  & n/a &
Access during \parsing is ordered.

label <text> & label &
\texttt{name} & \texttt{name} & n/a &
Name to use in the help, and as primary flag (for an \coption).

alias <name> & aliases & n/a & none & n/a &
Declare alternate flag for an \coption to be recognized by.
Multiple aliases are allowed.


optional & optionality & no & n/a (yes) & n/a (no) &
Declare \cinput as optional.

test & acceptance & threshold & n/a & n/a &
Control the matching of words to optional \cinputs
(\ra\ref{flow/optional}).

undocumented & undocumented & no & no & n/a (yes) &
Declare as hidden from help.



list & listness & no  & no  & no &
Declare as list-valued.

default <value> & default & $*$ & $*$ & $*$ &
Set constant default value.
Details in section \ref{para/reps}.

generate <cmdprefix> & generate & $*$ & $*$ & $*$ &
Set callback returning the default value.
Details in section \ref{para/reps}.

interact <?prompt?> & interact, prompt & $*$ & $*$ & $*$ &
Enable the interactive entry of the string value.
Default prompt derives from the \texttt{label}.
Details in section \ref{para/reps}.

defered & defered & no & no & yes &
Defer calculation of the internal representation until demanded.

immediate & defered & yes & yes & no &
Complement of \cdefered.
Calculate the internal representation during \completion.



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

[example {
alias <name>              & Declare alternate flag for an option.
default <value>           & Set constant default value.
defered                   & Defer calculation of the internal representation until demanded.
generate <cmdprefix>      & Set callback returning the default value.
immediate                 & Complement of defered.
interact ?<prompt>?       & Enable the interactive entry of the string value.
label <text>              & Name to use in the help, and as primary flag (for an option).
list                      & Declare as list-valued.
optional                  & Declare input as optional.
presence                  & Declare as boolean option without argument.
test                      & Control the matching of words to optional inputs.
undocumented              & Declare as hidden from help.
validate <cmdprefix>      & Declare validation type.
when-complete <cmdprefix> & Set callback executed when the value becomes known.
when-set <cmdprefix>      & Set callback executed when the string value becomes known.
}]

[list_begin definitions]
[def "[cmd alias] [arg name]"]
[def "[cmd default] [arg value]"]
[def "[cmd defered]"]
[def "[cmd generate] [arg cmdprefix]"]
[def "[cmd immediate]"]
[def "[cmd interact] [opt [arg prompt]]"]
[def "[cmd label] [arg text]"]
[def "[cmd list]"]
[def "[cmd optional]"]
[def "[cmd presence]"]
[def "[cmd test]"]
[def "[cmd undocumented]"]
[def "[cmd validate] [arg cmdprefix]"]
[def "[cmd when-complete] [arg cmdprefix]"]
[def "[cmd when-set] [arg cmdprefix]"]
[list_end]
