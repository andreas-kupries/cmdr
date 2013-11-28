
[para] The last phase is also the most simple.

[para] It only invokes the Tcl command prefix associated with the
chosen [package cmdr::private] instance, providing it with the
[package cmdr::config] instance holding the parameter information
extracted from the command line as its single argument.

[para] Listing --TODO--backend-example-\ref{ex/execution} is an
example of very simple action implementations, matching to the example
specifications provided in [term [vset TITLE_DSL]]


[para] All parameters declared for a [term private] are made
accessible through individual methods associated with each.

As example, a parameter with system name [var P] is mapped to the
method [method @P], with all instance methods provided by the
[package cmdr::parameter] class accessible as sub-methods.

This general access to all methods may be removed in the future,
restricting actions and callbacks to a safe subset.

[comment { @EDIT --todo-- figure out if we want this table (safe para methods) in the docs, and where
A first approximation of such a set can be found in the table
below.

[example {

 cmdline      & True if the parameter accessible on command line. \\
 config \arg{...} & Access to the methods of the container the
                    parameter belongs to, and thus all other
                    parameters of the private. \\
 default      & Default value, if specified. See \cmd{hasdefault}. \\
 defered      & True if the internal representation is generated on
                demand. \\
 description \arg{?detail?} & Help text. May be generated. \\
 documented   & True if the parameter is not hidden from help. \\
 forget       & Squash the internal representation. See also
                \cmd{reset}. \\
 generator    & Command prefix to generate a default value (internal
                representation). \\
 hasdefault   & True if a default value was specified. See
                \cmd{default}. \\
 help         & Help structure describing the parameter. \\
 interactive  & True if the parameter allows interactive entry of its
                value. \\
 is \arg{type} & Check if the result of \cmd{type} matches the
                 argument. \\
 isbool       & True if the parametr is a boolean option. \\
 list         & True if the parameter holds a list of values. \\
 lock \arg{reason} & For use in \cmd{when-set} callbacks. Allows
                      parameters to exclude each other's use. \\
 locker       & The \arg{reason} set by \cmd{lock}, if any. \\
 name         & The parameter's name. \\
 options      & List of option flags, if any. \\
 ordered      & True if the parameter is positional. \\
 presence     & True if the parameter is a boolean option not taking
                arguments. \\
 primary \arg {option} & True if the provided flag name is the
                         primary option to be recognized (instead of
                         an alias, or complement). \\
 prompt       & Text used as prompt during interactive entry. \\
 required     & True if the option is mandatory (\const(input) only). \\
 reset        & Squash internal and string representations. See also
                \cmd{forget}. \\
 self         & The parameter's instance command \\
 set \arg{value} & Programmatically set the string representation. \\
 set?     & True if the string representation was set. \\
 string          & Return the string representation, or error. \\
 type         & Parameter type. One of \const{input}, \const{option}, or
                \const{state}. \\
 validator    & Command prefix used to validate the string
                representation and transform it into the internal
                representation. \\
 value        & Return the internal representation. May calculate it
                now from the string representation. \\
 when-complete & Command prefix invoked when the internal representation is set. \\
 when-set     & Command prefix invoked when the string representation is set. \\


}]
}]


[para] Calling [method @P] without arguments is a shorthand for
calling ``@P value'', i.e. the retrieval of the parameter's internal
representation. Which may calculate the value if the call is the first
access and the parameter specified as [term defered].
