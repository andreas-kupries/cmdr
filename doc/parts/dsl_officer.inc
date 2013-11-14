
[comment { No tables in doctools, using an example to get a tabular formatting. }]
[comment { TODO doctools: table markup }]
[comment { TODO doctools: named TOCs for commands - embedded small TOCs}]

[example {
alias <name> = <name'>...            Declare an alternate name for a command path.
alias <name>                         Declare an alternate name for the previous command.
common <name> <script>               Declare a named shared code block.
default                              Set last command as default.
description <text>                   Set help text for the current ensemble.
ehandler <cmdprefix>                 Execution Interposition.
officer <name> <script>              Declare a nested ensemble = sub-officer
private <name> <script> <cmdprefix>  Declare a simple command  = private
undocumented                         Hide ensemble from help.
}]

[list_begin definitions]
[def "[cmd alias] [arg name] [const =] [arg name']..."]
[def "[cmd alias] [arg name]"]
[def "[cmd common] [arg name] [arg text]"]
[def "[cmd default]"]
[def "[cmd description] [arg text]"]
[def "[cmd ehandler] [arg cmdprefix]"]
[def "[cmd officer] [arg name] [arg script]"]
[def "[cmd private] [arg name] [arg script] [arg cmdprefix]"]
[def "[cmd undocumented]"]
[list_end]
