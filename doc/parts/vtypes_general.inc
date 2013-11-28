
Given a [term {string representation}] they either return the
associated [term {internal representation}] or raise an error,
signaling that the string was illegal. This part of their work, the
verification of the legality of the input string gave them their name.

[para] The general concept of [term {validation types}] was taken from
[package snit], and modified to suit [vset PTITLE].

Where snit's types expect only a single method to validate the input
[vset PTITLE] expects all types to support an ensemble of [emph four]
methods.

One for the basic validation and transformation of the input, another
for the release of any internal representation so generated, plus two
more for delivery of a default representation and support for command
line completion.
