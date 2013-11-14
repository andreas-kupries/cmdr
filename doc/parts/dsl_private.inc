
[comment { No tables in doctools, using an example to get a tabular formatting. }]
[comment { TODO doctools: table markup }]
[comment { TODO doctools: named TOCs for commands - embedded small TOCs}]

[example {
description <text>             Set help text for command.
input <name> <help> <script>   Declare a positional parameter.
interactive                    Allow interactive shell.
option <name> <help> <script>  Declare a named parameter.
state <name> <help> <script>   Declare a hidden parameter.
undocumented                   Hide command from help.
use <name>                     Execute the named common block here.
}]

[list_begin definitions]
[def "[cmd description] [arg text]"]
[def "[cmd input] [arg name] [arg help] [arg script]"]
[def "[cmd interactive]"]
[def "[cmd option] [arg name] [arg help] [arg script]"]
[def "[cmd state] [arg name] [arg help] [arg script]"]
[def "[cmd undocumented]"]
[def "[cmd use] [arg name]"]
[list_end]
