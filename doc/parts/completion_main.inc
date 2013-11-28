
[comment ==============================================================]
[subsection Overview]

The [term {main shell}] is fully implemented within the package
[package cmdr::officer], while its command-line completion also
reaches into the packages [package cmdr::private],
[package cmdr::config], and [package cmdr::parameter].

The purpose of this shell is interactive access to the commands of an
officer. Which implies, for the toplevel officer, access to the entire
command hierarchy.

[para] To this end this shell accepts the names of all subordinate
commands known to the officer as commands.

[para] It may additional accept a hard-wired command [cmd .exit],
depending on the parse state (see flag [const doexit]).


[comment ==============================================================]
[subsection {Sequencing and Rules}]

[para][image main-shell]

[para] This rest of this section is a textual description of the UML
sequence diagram shown above.

[para] Note that the state structure used by this code and referenced
in the text is explained in section [sectref {Parse State}].

[list_begin enumerated]

[enum] The main shell's core read-eval-print-loop calls on the
instance method [method complete] for command-line completion,
providing the text of the buffer to complete at the end).

[enum] The method [package cmdr::actor]::[method parse-line] is called
on first, to get a parse of the buffer. This parse is then delegated
to the instance method [method complete-words] to perform the bulk of
the work.

[para] Note: The officer instance has access to [method parse-line]
because it is a derived class of [package cmdr::actor].

[enum] The implementation of method [method complete-words] applies
the rules below:

[list_begin enumerated]

[enum] If the buffer was not properly parsed (i.e. the state indicates
a syntax error), the list of completions is empty.

[enum] When the buffer is empty all commands are possible completions,
as are all the commands of the default subordinate, if any was
specified.

[enum] If the [term {current word}] (as per [const at]) is the last
word (per [const nwords]) on the command line then completion is done
using the set of commands known to the officer and its default
subordinate, if any.

[enum] For a [term {current word}] which is not the last, i.e. at the
beginning or in the middle of the command line instead, then this word
is the name of the subordinate object responsible for handling the
remaining words.

[para] No completion is done however if the current word does not
yield a subordinate to delegate to (i.e. unknown or ambigous). If a
default command is known this case will delegate to this subordinate,
as a last attempt.

[para] When a subordinate was found the system advances the current
word, resets the [const doexit] flag, and lastly invokes the method
[method complete-words] of the sub-ordinate.

[enum] When the subordinate is again an [term officer], these rules
here apply again.

[enum] A [term private] however will delegate to the embedded
[package cmdr::config] instance, again using the method
[method complete-words].

[enum] This method processes the remaining words similar to how the
command line is parsed at runtime to match words to parameters, to
know at the end which (set of) parameter(s) governs the last word.

[para] For [term options] the last word may be partial name of a flag,
or it may be the partial argument to an option.

In case of the first the set of completions is the set of all flags
with the word as its prefix.

In case of the second the completion delegates to the parameter
governing the flag, if there is any, which in turn delegates to its
associated validation type.

[para] For [term inputs] the system essentially steps through a
non-deterministic finite automaton to find all the parameters which
may govern the current word. Completion is done as the union of the
completion done by the individual parameters.

[para] Note that the automaton and its results can be precomputed,
this happens in the internal method [method CompletionGraph].

[list_end]
[list_end]
