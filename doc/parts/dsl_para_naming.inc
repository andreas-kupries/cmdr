
[para] We have two commands to influence the visible naming of all
parameters.

[para] As background, all parameters are named for proper
identification within the framework and other Tcl code, i.e. the
various callbacks, including a "private"s action. This "system name"
has to be unique within the "private" a parameter belongs to. Beyond
that however the visible parameters have to be identified within help
texts, and, in case of "options", for detection during "Parsing". That
is the visible naming, seen by a user of any application whose command
line processing is based on the [vset PTITLE] framework.

[list_begin definitions]

[def "[cmd label] [arg text]"]
This command declares the visible name, if different from the system
name used as the default. Note that in most cases this default is good
enough, obviating the need for this command.

[para] The only use case seen so far is when two semantically
equivalent input and option parameters clash, requiring different
internal names due to the requirement for uniqueness, yet also the
same visible name and flag within the help to highlight their
connection and equivalence.

[def "[cmd alias] [arg name]"]
For option parameters the "label" command and its default specifies
the name of the primary flag recognized during parsing. If that is not
enough for a specific option this command allows the specification of
any number additional flags to be recognized.

[para] Note however that the framework automatically recognizes not
only the specified flags, but also all unique prefixes, obviating the
need for this command in many cases.

[list_end]



