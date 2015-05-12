
[para] We have two commands to influence the visible naming of all
[term parameter]s.

[para] As background, all [term parameter]s are named, to properly
identify them within the framework and other Tcl code, i.e. in the
various callbacks and the [term private]'s action.

This [term {system name}] has to be unique within the [term private] a
[term parameter] belongs to.

Beyond that however the visible (i.e. non-term state])

[term parameter]s have to be identified by users within help texts,
and, in the case of [term option]s, for detection during the
[term Parsing] phase.

That is the visible naming, seen by a user of any application whose
command line processing is based on the [vset PTITLE] framework.

[list_begin definitions]

[comment {- - -- --- ----- -------- -------------}]
[call [cmd label] [arg text]]

This command declares the [term parameter]'s visible name, if
different from the [term {system name}] used as the default. Note that
in most cases this default is good enough, obviating the need for this
command.

[para] The only use case seen so far is when two semantically
equivalent [term input] and [term option] [term parameter]s clash,
forcing the use of different system names due to the requirement for
their uniqueness, yet also use the same visible name and flag within
the help to highlight their connection and equivalence.

[comment {- - -- --- ----- -------- -------------}]
[call [cmd alias] [arg name]]

For [term option]s the [cmd label] command and its default specifies
the name of the [term {primary flag}] recognized during the
[term Parsing] phase.

If that is not enough for a specific [term option] this command allows
the specification of any number additional flags to be recognized.

[para] Note however that the framework automatically recognizes not
only the specified flag(s), but also all their unique prefixes,
obviating the need for this command in many cases.

[comment {- - -- --- ----- -------- -------------}]
[call [cmd neg-alias] [arg name]]
[call [cmd !alias] [arg name]]

This command applies only to [term boolean] [term option]s. For them it allows
the specification of any number additional flags to be recognized, which are
aliases of its [emph inverted] form, i.e. of [const --no-FOO] for an option [const FOO].

[para] This in contrast to [cmd alias]es, which are for the regular form of the option.

[para] Note further that the framework automatically recognizes not
only the specified flag(s), but also all their unique prefixes,
obviating the need for this command in many cases.

[list_end]



