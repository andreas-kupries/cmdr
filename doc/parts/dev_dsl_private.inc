
[para] The private DSL is only partially implemented in
[package cmdr::private].
Most of the implementation is in [package cmdr::config].

[para] While the specification is supplied with the instance
constructor it is not processed immediately, but saved for when it is
actually needed.

[para] The internal instance method [method Setup] is called at all
places requiring access to the specification and processes it (once,
on first call) to provide the necessary in-memory structures. This
then delegates to the embedded config instance.

[para] The DSL commands map to [emph config] instance methods as shown below:

[list_begin definitions]
[def [cmd description]]  [method Description],  forward to [package cmdr::actor] [method description:]
[def [cmd input]]        [method Input],  forward to [method DefineParameter])
[def [cmd interactive]]  [method Interactive]
[def [cmd option]]       [method Option], forward to [method DefineParameter])
[def [cmd section]]      [method Section]
[def [cmd state]]        [method State],  forward to [method DefineParameter])
[def [cmd undocumented]] [method Undocumented], forward to [package cmdr::actor] [method undocumented]
[def [cmd use]]          [method Use]
[list_end]
