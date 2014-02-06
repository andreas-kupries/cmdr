[subsection {Changes for version 1}]

This is the first release of [vset PROJECT].
The changes therefore describe the initial features of the system.

[para] In detail:

[list_begin enumerated]
[comment {- - -- --- ----- -------- ------------- ---------------------}]

[enum] [vset PROJECT] requires Tcl 8.5 or higher.
       Tcl 8.4 or less is not supported.

[enum] The framework provides a DSL for the declaration of a hierarchy
       of commands and their parameters (named options, positional
       arguments, hidden state), with help texts, type information, and
       various callbacks (command actions, parameter definition,
       parameter completion, type validation, command completion, etc.)

[enum] At runtime the framework provides parsing and processing of command
       lines per specifications written in that DSL, determining the command
       to run, and the mapping from command line words to its parameters.

[enum] The framework also provides shells for the interactive entry of
	commands and parameters, with command line completion.

[enum] Last, but not least is the automatic generation of command line
       help for commands and parameters, based on the information provided
       in a specification.

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[list_end]
