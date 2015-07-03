[comment {--- !doctools --- template, not main}]
[comment { -- Variables --
	VERSION
	VALTYPE
}]
[include parts/definitions.inc]
[manpage_begin [vset PROJECT]::validate::valtype::[vset VALTYPE] [vset MAN_SECTION] [vset VERSION]]
[include parts/module.inc]
[require cmdr::validate::valtype::[vset VALTYPE]]
[titledesc "[vset PTITLE] - Validation type facade for Tcllib valtype::[vset VALTYPE]"]

[description]
[include parts/welcome.inc]

[para] This package is a facade to Tcllib's package
[package valtype::[vset VALTYPE]], wrapping it for use as a
proper Cmdr validation type.

[para] Please read that package's documentation for details on the accepted input.

[para] The type has no input completion.

[para] The details of the exported API can be found in
[term [vset TITLE_DEV_VT]]. The chosen default is the empty string.

[include parts/feedback.inc]
[manpage_end]
