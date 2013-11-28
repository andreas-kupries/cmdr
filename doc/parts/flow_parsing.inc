
[vset EXAMPLE_T {Example for Handling optional Inputs by Threshold}]

[para] This is the most complex phase internally, as it has to assign
the left-over words to the parameters of the chosen
[package cmdr::private] instance, taking into account the kind of
parameters, their requiredness, listness, and other attributes.

[para] Generally processing the words from left to right
[term options] are detected in all positions, through their flags
(primary, aliases, and all unique prefixes), followed by their
(string) value to assign.

[para] When a word cannot be the flag for an option the positional
[term inputs] are considered, in order of their declarations.

For a mandatory [term input] the word is simply assigned as its string
value and processing continues with the next word, and the next
[term input], if any.

Operation becomes more complex when the [term input] under
consideration is [term optional].

Now it is necessary to truly decide if the word should be assigned to
this [term input] or the following.

[para] The standard method for this decision is to count words and
compare to the count of mandatory [term inputs] left.

If there are more words available than required to satisfy all
mandatory [term inputs], then we can and do assign the current word to
the optional input.

Otherwise the current [term input] is skipped and we consider the
next.

A set of condensed examples can be found in section
[sectref [vset EXAMPLE_T]].

They demonstrate how a various numbers of argument words are assigned
to a specific set of [term inputs], [term optional] and non.

This is called the [term threshold] algorithm.

[para] The non-triviality in the above description is in the phrase to
[term {count words}].

We cannot simply count all words left on the command line.

To get a proper count we have discard/ignore all words belonging to
options.

At this point the processor essentially works ahead, processing and
removing all flags/options and their arguments from the command line
before performing the comparison and making its decision.

[para] The whole behaviour however can be changed via [cmd test]
(See section [term {General control}] of [term [vset TITLE_DSL_PARAMETER]]).

Instead of counting words the current word is run through the
validation type of the current [term input].

On acceptance the value is assigned to it, otherwise that [term input]
is skipped and the next one put under consideration.

[para] After all of the above the system will process any options
found after the last word assigned to the last [term input] to
consider.

[para] Errors are thrown if we either find more words than
[term inputs] to assign to, or encounter an unknown option flag.

Note that not having enough words for all required [term inputs] is
not an error unless the framework is not allowed to start an
interactive shell.

In this [term {mini shell}] all parameters are mapped to shell
commands taking a single argument, the string value of parameter to
assign.

Additional five pseudo commands are available to either abort, or
commit to the action, or gain help ([cmd .ok], [cmd .run],
[cmd .exit], [cmd .cancel], and [cmd .help]).

[para] Parameters marked as [term list]-valued also trigger special
behaviours.

For [term options] the assigned values get accumulated instead of each
new value overwriting the last.

For [term inputs] only one such parameter can exist, and will be the
last of the [term private].

The processor now takes all remaining words and assign them to this
parameter.

If the list is also optional then options may be processed ahead or
not, depending on the chosen decision mode, as described for regular
inputs above.

[para] Then are the [term boolean] and [term presence] [term options]
modifying the handling of flags and flag arguments.

The details of this were already explained in section
[term Validation] of [term [vset TITLE_DSL_PARAMETER]].


[subsection [vset EXAMPLE_T]]

The examples in this section demonstrate how the [term threshold]
algorithm assigns a various number of argument words to a specific set
of [term inputs], [term optional] and non.

[para][example {
 Parameter    | A? | B | C? | D? | E
 #Required    |   2|   |   1|   1|
--------------+----+---+----+----+----
 2 arguments: |    | a |    |    | b
 3 arguments: | a  | b |    |    | c
 4 arguments: | a  | b | c  |    | d
 5 arguments: | a  | b | c  | d  | e
}]
