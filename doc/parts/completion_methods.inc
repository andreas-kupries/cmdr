
The methods relevant to command-line completion can be found in four
packages/classes, namely:

[list_begin definitions]
[def [package cmdr::actor]]
     [list_begin definitions]
     [def [method parse-line]]
     Takes a command-line and returns an initial parse structure as
     described in section [sectref {Parse State}]

     [def [method completions]]
     [def [method match]]
     [list_end]

[def [package cmdr::config]]
     [list_begin definitions]
     [def [method complete]]
     Hook method, entrypoint for the mini-shell.

     Takes the buffer to complete and returns the list of completions,
     which may be empty.

     Uses the workhorse method below and the [package cmdr::actor]
     methods.

     [def [method complete-repl]]
     Main work method taking a parse structure and returning the list
     of completions. More details about it (and the mini-shell) can be
     found in section [sectref {Mini Shell Operation}].

     [def [method complete-words]]
     Main work method for completion from the main shell, invoked by
     the [package cmdr::private] instance having to complete words.

     [list_end]

[def [package cmdr::officer]]
     [list_begin definitions]
     [def [method complete]]

     Hook method, entrypoint for the main shell.

     Takes the buffer to complete and returns the list of completions,
     which may be empty.

     Uses the workhorse method below and the [package cmdr::actor]
     methods.

     [def [method complete-words]]
     Main work method taking a parse structure and returning the list
     of completions. More details about it (and the main shell) can be
     found in section [sectref {Main Shell Operation}].

     [para] Can recurse to the same method of other officers, and
     private instances.

     [list_end]

[def [package cmdr::parameter]]
     [list_begin definitions]
     [def [method complete-words]]
     Main work method when reaching a parameter.

     Simply delegates the work to the method [method complete] of the
     validation type associated with the parameter.
     [list_end]

[def [package cmdr::private]]
     [list_begin definitions]
     [def [method complete-words]]
     Main work method when reaching a private while recursing through
     the command hierarchy from officers.

     Delegates to the [package cmdr::config] method of the same name.

     [list_end]
[list_end]
