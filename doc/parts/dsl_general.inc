
[para] The conceptual model underneath the command hierarchy is that
of a tree.

[para] The inner nodes of the tree represent command ensembles, here
called "officer"s. Each officer knows one or more commands, and
delegates actual execution to their respective specification, which
may be another officer, or a private.

[para] The leaf nodes of the tree represent the individual commands,
here called "private"s. Each private is responsible for a single
action, and knows how to perform it and the parameters used to
configure that action at runtime.

[para] The same model is graphically presented in the
Entity-Relationship-Diagram below.

[image erd]

[para] The "Actor" in that diagram is the common base class for the
ensembles and commands and not directly relevant to users.

[para] The "Config" on the other hand is the second interface seen by
the user, as the sole argument to the action command prefix of
[cmd private] (See section [sectref Officer]).

This container holds all the declared parameters of the command the
action is invoked for, and provides easy access to them through its
methods (see package [package cmdr::config]) at the time of execution.
