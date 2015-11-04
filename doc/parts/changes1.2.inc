[subsection {Changes for version 1.2}]

[list_begin enumerated]
[comment {- - -- --- ----- -------- ------------- ---------------------}]

[enum] Many new validation types:
[list_begin enumerated]
[enum] double
[enum] percent
[enum] posint (positive integers, > 0)
[enum] paths and channels // TODO: List exact
[enum] Wrappers around the Tcllib valtypes // TODO: List exact
[enum] Date and time related: iso8601 date/time, year, weekday, hour:minute
[list_end]

[enum] More helper commands for validation failure messages.

[enum] Modified integer validation to have a proper internal representation: decimal. Octal, hex, etc. input is now normalized to this.

[enum] Various new supporting packages:
[list_begin definitions]
[def [package tty]]     Test for terminal.
[def [package color]]   Color management, ansi control sequences.
[def [package ask]]     User interaction commands.
[def [package pager]]   Text display with automatic invokation of a pager
     	      		for tall output.
[def [package history]] Pluggable management of command history.
[def [package table]]   Table formatting, simplified interface to Tcllib's
     	      		[package struct::matrix] and [package report] packages.
[list_end]

[enum] Added support for per-officer options. Most common use case
       are likely global options added to the root officer.

[para] A new common block [const *config*] is set to the active
       [package config] instance, different from the defining instance
       for per-officer options. This gives the per-officer options
       access to the arguments (and options) of the current command,
       instead of only their own sibling options.

[enum] Added support for an otion [option -exted] for common blocks
       allowing their extension in a subordinate instead of just
       replacing the entire content.

[enum] Extended boolean options to allow specification of negative
       aliases, i.e. representing the inverted option.

[enum] Extended officers to accept all unique command prefixes of
       their subordinates for dispatch.

[enum] Modified the help system to use the [const short] format for
       interior nodes of the command hierarchy by default.

[enum] Extended the DSL for options with the ability to set a label
       for the option argument so that help can be more descriptive.
       The option name is used as fallback for options with no such
       label specified.

[enum] ... A suite of bug fixes ... // TODO: list the details.

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[list_end]
