
[para] The officer DSL is implemented in [package cmdr::officer].

[para] While the specification is supplied with the instance
constructor it is not processed immediately, but saved for when it is
actually needed.

[para] The internal instance method [method Setup] is called at all
places requiring access to the specification and processes it (once,
on first call) to provide the necessary in-memory structures.

[para] The DSL commands map to instance methods as shown below:

[list_begin definitions]
[def [cmd alias]]        [method Alias]
[def [cmd common]]       [package cmdr::actor] [method set]
[def [cmd custom-setup]] [method custom-setup]
[def [cmd default]]      [method Default]
[def [cmd description]]  [package cmdr::actor] [method description:]
[def [cmd ehandler]]     See [cmd intercept]. [emph Deprecated].
[def [cmd intercept]]    [method intercept]
[def [cmd officer]]      [method Officer], forward to [method DefineAction]
[def [cmd private]]      [method Private], forward to [method DefineAction]
[def [cmd undocumented]] [package cmdr::actor] [method undocumented]
[list_end]
