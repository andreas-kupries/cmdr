
[comment ==============================================================]
[subsection Overview]

The [term {mini shell}] and its command-line completion is fully
implemented within the package [package cmdr::config].

The purpose of this shell is the interactive entry of the parameters
for a [term private].

[para] To this end this shell accepts the [term system] names of all
parameters held by the config instance as commands, plus five
hard-wired commands to control exit conditions and access to help.

[para] The parameter commands all take single value as their argument,
the string value to set.

The sole exception to this are [term {presence options}] which do not
take any argument.

[para] Similarly none of the hardwired commands take an
argument. Their names all start with a [const .]. They are, in
alphabetical order, [const .cancel], [const .exit], [const .help]
[const .ok], and [const .run].

[comment ==============================================================]
[subsection {Sequencing and Rules}]

[para][image mini-shell]

[para] This rest of this section is a textual description of the UML
sequence diagram shown above.

[para] Note that the state structure used by this code and referenced
in the text is explained in section [sectref {Parse State}].

[list_begin enumerated]

[enum] The mini shell's core read-eval-print-loop calls on the
instance method [method complete] for command-line completion,
providing the text of the buffer to complete at the end).

[enum] The method [package cmdr::actor]::[method parse-line] is called
on first, to get a parse of the buffer. This parse is then delegated
to the instance method [method complete-repl] to perform the bulk of
the work.

[para] Note: The config instance has access to [method parse-line]
through its internal [const context] command, which is an alias of the
[package cmdr::private] instance the configuration belongs to. This
class is derived from [package cmdr::actor].

[enum] The implementation of method [method complete-repl] applies the
rules below:

[list_begin enumerated]
[enum] If the buffer was not properly parsed (i.e. the state indicates
a syntax error), the list of completions is empty.

[enum] When the buffer is empty all commands are possible completions.

[enum] When the buffer contains more than three words the list of
completions is empty, as all valid mini-shell commands consist of at
most two words.

[enum] A buffer containing a single word contain a partial command
name and the list of completions is the set of commands having this
word as prefix.

[enum] A buffer containing two words contains a command name and a
partial argument. Completion is delegated to the parameter (method
[package cmdr::parameter]::[method complete-words]) indicated by the
command name, and through it to the associated validation type.

[para] No completion is done however if the first word does not yield
a parameter to delegate to (i.e. unknown or ambigous), or if it is a
presence option, which does not take an argument.

[para] The hardwired commands fall here implicitly under unknown
parameter.

[list_end]
[list_end]
