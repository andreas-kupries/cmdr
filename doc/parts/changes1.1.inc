[subsection {Changes for version 1.1}]

[list_begin enumerated]
[comment {- - -- --- ----- -------- ------------- ---------------------}]

[enum] Fixed broken requirement references in the meta data of packages
       [package cmdr::help::json] and [package cmdr::help::sql].

[enum] Fixed initialization issues in the help generator.

[enum] Fixed generated help, added the application name to the output
       when in a cmdr shell.

[enum] Fixed the generation of help format by-categorized, when
       encountering sections with sub-sections and no commands of their
       own.

[enum] Fixed bad method scoping in method [method extend] of officers.

[enum] Extended officer method [method extend] to return the created
       private, for immediate post-creation re-configuration.

[enum] Extended system with new help format [term tcl], and associated
       package [package cmdr::help::tcl]. Similar to format [term json]
       the help is printed as a nested data structure, just using Tcl
       syntax.

[enum] Extended officers and privates with method [method find] for
       path lookup of sub-ordinates.

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[list_end]
