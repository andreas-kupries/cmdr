
[para] The parameter DSL is implemented in [package cmdr::parameter].

[para] The specification is supplied with the instance constructor and
processed immediately. This is different from officers and privates
which defer processing until use. When a parameter is declared the
containing private is in use, and so is the parameter. Thus no delay.

[para] The DSL commands map to instance methods as shown below:

[list_begin definitions]
[def [cmd alias]]         [method Alias]
[def [cmd default]]       [method Default]
[def [cmd defered]]       [method Defered]
[def [cmd generate]]      [method Generate]
[def [cmd immediate]]     [method Immediate]
[def [cmd interact]]      [method Interact]
[def [cmd label]]         [method Label]
[def [cmd list]]          [method List]
[def [cmd no-promotion]]  [method NoPromote]
[def [cmd optional]]      [method Optional]
[def [cmd presence]]      [method Presence]
[def [cmd test]]          [method Test]
[def [cmd undocumented]]  [method Undocumented]
[def [cmd validate]]      [method Validate]
[def [cmd when-complete]] [method WhenComplete]
[def [cmd when-set]]      [method WhenSet]
[list_end]
