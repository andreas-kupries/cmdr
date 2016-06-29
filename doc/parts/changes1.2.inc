[subsection {Changes for version 1.2}]
[vset tcllib http://core.tcl.tk/tcllib/doc/trunk/embedded/www]
[vset tm     [vset tcllib]/tcllib/files/modules]

[list_begin enumerated]
[comment {- - -- --- ----- -------- ------------- ---------------------}]

[enum] Extended the package [package cmdr::validate] with many new
       standard validation types:

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
              [enum] ISO-8601 date/time,
              [enum] year
              [enum] weekday, 
              [enum] hour:minute
              [list_end]
       [list_end]

[enum] In package [package cmdr::validate], modified the integer
       validation type to have a proper internal representation:
       decimal. Input in octal, hex, etc. is now normalized to this.

[enum] Extended package [package cmdr::validate::common] with more
       helper commands for the generation of validation failure
       messages

       [list_begin enumerated]
       [enum] [cmd fail-unknown-thing-msg]
       [enum] [cmd fail-unknown-simple]
       [enum] [cmd fail-unknown-simple-msg]
       [enum] [cmd fail-known-thing-msg]
       [enum] [cmd fail-known-simple]
       [enum] [cmd fail-known-simple-msg]
       [list_end]

[enum] Added various new supporting packages:

       [list_begin definitions]
       [def [package cmdr::tty]]
            Test for terminal.

       [def [package cmdr::color]]
            Color management, ansi control sequences.

       [def [package cmdr::ask]]
            User interaction commands.

       [def [package cmdr::pager]]
            Text display with automatic invokation of a pager for tall
            output.

       [def [package cmdr::history]]
            Pluggable management of command history.

       [def [package cmdr::table]]
            Table formatting, a simplified interface to
            [uri [vset tcllib]/toc.html Tcllib]'s
            [package struct::matrix] and [package report] packages.

       [def [package cmdr::validate::valtype-support]]

            Even more validation types, now as wrappers around the
            validation commands provided by
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

[enum] Extended package [package cmdr::officer] with 
       [list_begin enumerated]
       [enum] Support for per-officer options. The most common use
              case will likely be the declaration of global options in
              the root officer.

       [para] Related to this, a new common block [const *config*] is
              set to the active [package config] instance, which will
              be different from the defining instance, for per-officer
              options. This gives the per-officer options access to
              the arguments (and options) of the current command,
              instead of only their own sibling options.

       [enum] Support for an option [option -extend] for common
              blocks, allowing their extension in a subordinate
              instead of just replacing the entire content.

       [enum] Support to accept all unique command prefixes of an
              officer's subordinates for dispatch.
       [list_end]

[enum] Extended package [package cmdr::parameter] with 
       [list_begin enumerated]
       [enum] Support for the specification of negative aliases for
              boolean options, i.e. representing the inverted option.

       [para] See the DSL commands [cmd neg-alias] and [cmd !alias] in
              [term {Cmdr - Parameter Specification Language}].

       [enum] Support for option labeling, for use in the generated
              help, to make it more descriptive. Options for which no
              label is specified will use their name as fallback.

       [para] See DSL command [cmd label] in
              [term {Cmdr - Parameter Specification Language}].
       [list_end]

[enum] Help system changes
       [list_begin enumerated]

       [enum] Modified it to use the [const short] format for interior
              nodes of the command hierarchy by default.

       [enum] Modified it to exclude auto-added commands from the
              output generated by format [const by-category].

       [enum] Modified the format [const full] to show the option
       	      arguments for those which have such. See also the
       	      extension of package [package cmdr::parameter] with
       	      support for option labels, this is what is used here.

       [enum] Modified it to declare a standard global option
              [option --help] (with aliases [option -h] and
              [option -?]). Using the option invokes the standard help
              (command) on the current command, if any, or the global
              help if there is no command.

       [enum] Modified to use a minimum width of 10 characters for
       	      descriptions. If the user narrowed the terminal this far
       	      then having the text either cut off at the right edge,
       	      or wrapped around is not worse then the help trying to
       	      wrap the sentence with word boundaries, etc. Also,
       	      trying to use negative width threw Tcl errors.
       [list_end]

[enum] Fixed the handling of common block [const *all*] in package
       [package cmdr::officer]. While it was ok trapping and ignoring
       a missing definition of this block, trapping everything which
       could go wrong was not.

       [para][uri http://core.tcl.tk/akupries/cmdr/info/9159f68bc35d9747 Details].

[enum] Fixed a long-standing bug of package [package cmdr::config] in
       the forced calculation of parameter values in method
       [method Force]). Any error in the calculations left an internal
       flag set, causing future invokations to believe to be in a
       recursive call and thus do nothing.

       [para] While this had no effect on regular operation, i.e.
       with the application exiting after each command, in interactive
       mode this misbehaviour disabled all checks and validations for
       the command in question, and also retained old parameter
       values.

       [para][uri http://core.tcl.tk/akupries/cmdr/info/f74095b252d4c9df Details]

[enum] Modified the formatting of [package cmdr::config] state when
       interactively entering it for a private. Parameter names now
       are shown as declared, and an additional flag character
       indicates if it is inherited from above, or not.

[enum] General fixes to testsuite, code comments, bogus variable
       names, typos in error messages, etc.

[comment {- - -- --- ----- -------- ------------- ---------------------}]
[list_end]
