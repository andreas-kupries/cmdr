
[para] This phase is reached when all words of the command line have
been processed and no error was thrown by the preceding phases.

At this point we know the [package cmdr::private] instance to use, and
its parameters may have a string representation.

[para] All [term immediate]-mode parameters are now given their
internal representation.

The parameters marked as [term defered] are ignored here and will get
theirs on first access by the backend.

[para] This completion of parameters is done in their order of
declaration within the enclosing [term private] command.

Note that when parameters have dependencies between them, i.e. the
calculation of their internal representation requires the internal
representation of another parameter, then this order may be violated
as the requesting parameter triggers completion in the requested one
on access.

If this is behaviour not wanted then it is the responsibility of the
user specifying the [term private] to place the parameters into an
order where all parameters access only previously completed parameters
during their own completion.
