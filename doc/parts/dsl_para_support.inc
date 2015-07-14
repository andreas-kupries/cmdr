
The parameter language currently provides four supporting commands
which provide quick access to commonly useful functionality. All the
helper command return anonymous procedures for use with the various
callbacks of a parameter.

[list_begin definitions]

[comment {- - -- --- ----- -------- -------------}]
[call [cmd stop!]]

The returned callback unconditionally declares its parameter as [term undefined]. This is useful in combination with [cmd generate] to abort value processing for an [term optional] [term input] after the interaction stage.

[para] This is for inputs which are not optional per se, but declared
as such to allow interactive entry when missing. A [example {
    generate [stop!]
}] clause then ensures an error when interactive entry gets disabled,
either global, or for the specific command.

[call [cmd touch] [arg name] [arg value]]

The returned callback sets the [arg name]d sibling parameter to the
specified [arg value]. A simple method of communication between
parameters of a command.

[para] Useful for use with [cmd when-set] and/or [cmd when-complete]

[call [cmd touch] [arg name] [arg value]]

The returned callback sets the [arg name]d sibling parameter to the
specified [arg value], if and only if that parameter exists. A simple
method of communication between parameters of a command, where the
sibling may not exists, depending on usage context.

[para] Useful for use with [cmd when-set] and/or [cmd when-complete]

[call [cmd disallow] [arg name]]

This command simplifies the use of the parameter's [method lock]
method to signal that the [arg name]d parameter cannot be used with
this one, returning a callback generating all the proper arguments
required by the method, especially the name of the parameter invoking
the lock.

[para] Useful for use with [cmd when-set].

[list_end]
