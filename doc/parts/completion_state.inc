
The state structure used by all methods relevant to command line
completion is a dictionary containing the six keys listed below.

The only generator for this structure is method [method parse-line] of
the base-class [package cmdr::actor]. All others parts of the system
then only read and manipulate it.

[list_begin definitions]
[def [const ok]]
A boolean flag. Indicates if the [const line] parsed sucessfully into
words ([const true]), or not ([const false], syntax error).

[para] The framework expects basic shell syntax with space-separated
words using single- and double-quotes for words containing whitespace
themselves. Note that complex syntax like variable- and
command-substitutions are not allowed.

[def [const line]]
A copy of the unparsed command line.

[def [const words]]

The command [const line] parsed into the bare words. The data is not
valid if [const ok] indicates a parsing error. This is not a list of
strings, but actually a list of tokens.

[para] Each token is a list of four elements containing, in the order
below:

[list_begin enumerated]
[enum] Type of the token (implicitly specifies found quoting).
[enum] Start index of token in [const line] including quoting.
[enum] End index of token in [const line], including quoting.
[enum] The string value of the token, with escapes fully resolved.
	I.e. the actual word.
[list_end]

[para] Note: If [const line] ended in trailing whitespace the last
element of this list will be an empty string representing the word
started by the user, yet still empty.

[def [const nwords]]
The number of element in [const words]. The data is not valid if
[const ok] indicates a parsing error.

[def [const at]]
The index of the [term {current word}] in [const words] currently
considered by the completion code. Initially [const 0] this advances
as the completion code works through the prefix to determine the
context for the completion of the last word.

[def [const doexit]]
A boolean flag. Indicates if the pseudo-command [cmd .exit] is active
([const true]), or not. Initially [const true].

[list_end]
