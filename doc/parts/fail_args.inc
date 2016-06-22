[arg_def [package cmdr::parameter] p]
The [package cmdr::parameter] instance whose validation failed.
The error message will contain this parameter's type and label
(flag in case of an option).

[arg_def list code]
A list of additional elements for the error code to throw.
Should detail the internal name of the validation type triggering the
error.

[arg_def string type]
A string holding a human-readable name for the validation type
triggering the error. (Conversely to the [arg code], which is for
machine-readability, i.e. trapping)

[arg_def string x]
The string value which failed the validation.

[arg_def string context]
Additional context to show in the message.
Defaults to the empty string.
