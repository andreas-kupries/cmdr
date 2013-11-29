
[para] The conceptual model underneath the command hierarchy is that
of a tree.

[para] The inner nodes of the tree represent command ensembles, here
called [term officer]s. Each officer knows one or more commands to
perform, and delegates actual execution to their respective
specification, which may be another [term officer], or a [term private].

[para] The leaf nodes of the tree represent the individual commands,
here called [term private]s.

Each [term private] is responsible for a single action and knows how
to perform it, and the set of [term parameter]s used to configure that
action at runtime.

[para] The same model is graphically presented in the
Entity-Relationship-Diagram below.

[para] [image erd]

[para] The [term actor] in that diagram is the common base class for the
ensembles and commands and not directly relevant to users.

[para] The [term config] on the other hand is the second interface
seen by the user, as the sole argument to the action command prefix of
[cmd private]. See [term [vset TITLE_DSL_OFFICER]] for the details.

This container, an instance of [package cmdr::config], holds all the
declared parameters of the command the action is invoked for, and
provides easy access to them through its methods at the time of
execution.
