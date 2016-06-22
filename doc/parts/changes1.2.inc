[subsection {Changes for version 1.2}]
[vset tcllib http://core.tcl.tk/tcllib/doc/trunk/embedded/www]
[vset tm     [vset tcllib]/tcllib/files/modules]

[list_begin enumerated]
[comment {- - -- --- ----- -------- ------------- ---------------------}]

[enum] Added many new standard validation types to package
       [package cmdr::validate]:

[list_begin enumerated]
[enum] Double
[enum] Percent
[enum] Posint (positive integers, > 0)
[enum] Paths and channels
       [list_begin enumerated]
       [enum] Readable file
       [enum] Writable file
       [enum] Read/writable file
       [enum] Readable directory
       [enum] Read/writeable directory
       [enum] readable path
       [enum] Read/writable path
       [enum] Readable path, as channel
       [enum] Writable path, as channel
       [enum] Read/writable path, as channel
       [list_end]
[enum] Date and time related:
       [list_begin enumerated]
       [enum] iso8601 date/time,
       [enum] year
       [enum] weekday, 
       [enum] hour:minute
       [list_end]
[list_end]

[enum] Added more helper commands for validation failure messages to
       package [package cmdr::validate::common].

       [list_begin enumerated]
       [enum] [cmd fail-unknown-thing]
       [enum] [cmd fail-unknown-thing-msg]
       [enum] [cmd fail-unknown-simple]
       [enum] [cmd fail-unknown-simple-msg]
       [enum] [cmd fail-known-thing]
       [enum] [cmd fail-known-thing-msg]
       [enum] [cmd fail-known-simple]
       [enum] [cmd fail-known-simple-msg]
       [list_end]

[enum] Modified integer validation to have a proper internal
       representation: decimal. Octal, hex, etc. input is now
       normalized to this.

[enum] Various new supporting packages:
[list_begin definitions]
[def [package cmdr::tty]] Test for terminal.
[def [package cmdr::color]] Color management, ansi control sequences.
[def [package cmdr::ask]] User interaction commands.
[def [package cmdr::pager]] Text display with automatic invokation of
     	      		    a pager for tall output.
[def [package cmdr::history]] Pluggable management of command history.
[def [package cmdr::table]] Table formatting, simplified interface to
      		            [uri [vset tcllib]/toc.html Tcllib]'s
      		            [package struct::matrix] and
			    [package report] packages.
[def [package cmdr::validate::valtype-support]] Even more validation types.
     Wrappers around the validation commands provided by
       [uri [vset tcllib]/toc.html Tcllib]:
       [list_begin enumerated]
       [enum] [uri [vset tm]/valtype/cc_amex.html       valtype::creditcard::amex]
       [enum] [uri [vset tm]/valtype/cc_discover.html   valtype::creditcard::discover]
       [enum] [uri [vset tm]/valtype/cc_mastercard.html valtype::creditcard::mastercard]
       [enum] [uri [vset tm]/valtype/cc_visa.html       valtype::creditcard::visa]
       [enum] [uri [vset tm]/valtype/ean13.html         valtype::gs1::ean13]
       [enum] [uri [vset tm]/valtype/iban.html          valtype::iban]
       [enum] [uri [vset tm]/valtype/imei.html          valtype::imei]
       [enum] [uri [vset tm]/valtype/isbn.html          valtype::isbn]
       [enum] [uri [vset tm]/valtype/luhn.html          valtype::luhn]
       [enum] [uri [vset tm]/valtype/luhn5.html         valtype::luhn5]
       [enum] [uri [vset tm]/valtype/usnpi.html         valtype::usnpi]
       [enum] [uri [vset tm]/valtype/verhoeff.html      valtype::verhoeff]
       [list_end]

[list_end]

[enum] Added support for per-officer options. The most common use case
       will likely be the declaration of global options in the root
       officer.

[para] Related to this, a new common block [const *config*] is set to
       the active [package config] instance, which will be different
       from the defining instance, , for per-officer options. This
       gives the per-officer options access to the arguments (and
       options) of the current command, instead of only their own
       sibling options.

[enum] Added support for an option [option -extend] for common blocks,
       allowing their extension in a subordinate instead of just
       replacing the entire content.

[enum] Extended boolean options to allow the specification of negative
       aliases, i.e. representing the inverted option. See the DSL
       commands [cmd neg-alias] and [cmd !alias] in
       [term {Cmdr - Parameter Specification Language}].

[enum] Extended the DSL for options in general with the ability to set
       a label for the option argument so that the generated help can
       be more descriptive. The option name is used as fallback for
       options for which no such label was specified.

       See DSL command [cmd label] in
       [term {Cmdr - Parameter Specification Language}].

[enum] Extended officers to accept all unique command prefixes of
       their subordinates for dispatch.

[enum] Modified the help system to use the [const short] format for
       interior nodes of the command hierarchy by default.

[enum] Modified the help system to exclude auto-added commands from
       the output generated by format [const by-category].

[enum] ... A suite of bug fixes ... // TODO: list the details.

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[list_end]
