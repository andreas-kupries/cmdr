
[para] The first phase determines the [package cmdr::private] instance
to use.  To this end it processes words from the command line and uses
them to navigate the tree of [package cmdr::officer] instances until a
[term private] is reached.

[para] Each word of the command line is treated as the name of the
[package cmdr::officer] instance to descend into.

An error will be thrown when encountering a name for which there is no
known actor (officer or private), and the current [term officer] has
no [term default] declared for it.

[para] On the converse, when reaching the end of the command line but
not reaching a [term private] the framework will not throw an
error. It will start an interactive command line shell instead. This
[term {main shell}] provides access to exactly the commands of the
[package cmdr::officer] instance which was reached, plus two
pseudo-commands to either exit this shell or gain help.

[para] Execution of the command tree specification, i.e. the
generation of the in-memory command tree and the actor instances bound
in it, is intertwined with this descent through the command tree.

I.e. instead of processing the entire specification immediately in
full it is lazily unfolded on demand, ignoring all parts which are not
needed.

Note that the generated data structures are not destroyed after
[sectref Execution], but kept, avoiding the need to re-parse the parts
of the specification already used at least once when an interactive
command line shell is active.
