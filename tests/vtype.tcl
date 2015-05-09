# -*- tcl -*- tcl.tk//DSL tcltest--template//EN//2.0
# # ## ### ##### ######## ############# #####################
## Testing a validation type.

# Sourced from the actual .test file and parameterized with the main
# ensemble command of the validation type. This file only tests the
# standard part of the API for the type, i.e. the command
# signatures. The actual validation, completion, etc. must be tested
# by the caller, as that changes from type to type.
#
# File API variables
#
# - "vtype"  - command for the validation type.
# - "vtparm" - name of the parameter variable used by all VT API commands.
# - "vtval"  - name of the value variable used by the all VT API commands except "default".
#
# The last two can be left unspecified, and will default to "p" and "x", respectively.

if {![info exists vtparm]} { set vtparm p }
if {![info exists vtval]}  { set vtval  x }

if {![info exists vtype]} {
    # TODO: kt ... - Abort testsuite
}

# # ## ### ##### ######## ############# #####################
## default

test vt-${vtype}-default-1.0 "$vtype default, wrong args, not enough" -body {
    $vtype default
} -returnCodes error -result "wrong # args: should be \"$vtype default $vtparm\""

test vt-${vtype}-default-1.1 "$vtype default, wrong args, too many" -body {
    $vtype default P X
} -returnCodes error -result "wrong # args: should be \"$vtype default $vtparm\""

# # ## ### ##### ######## ############# #####################
## validate

test vt-${vtype}-validate-1.0 "$vtype validate, wrong args, not enough" -body {
    $vtype validate
} -returnCodes error -result "wrong # args: should be \"$vtype validate $vtparm $vtval\""

test vt-${vtype}-validate-1.1 "$vtype validate, wrong args, not enough" -body {
    $vtype validate P
} -returnCodes error -result "wrong # args: should be \"$vtype validate $vtparm $vtval\""

test vt-${vtype}-validate-1.2 "$vtype validate, wrong args, too many" -body {
    $vtype validate P V X
} -returnCodes error -result "wrong # args: should be \"$vtype validate $vtparm $vtval\""

# # ## ### ##### ######## ############# #####################
## complete

test vt-${vtype}-complete-1.0 "$vtype complete, wrong args, not enough" -body {
    $vtype complete
} -returnCodes error -result "wrong # args: should be \"$vtype complete $vtparm $vtval\""

test vt-${vtype}-complete-1.1 "$vtype complete, wrong args, not enough" -body {
    $vtype complete P
} -returnCodes error -result "wrong # args: should be \"$vtype complete $vtparm $vtval\""

test vt-${vtype}-complete-1.2 "$vtype complete, wrong args, too many" -body {
    $vtype complete P V X
} -returnCodes error -result "wrong # args: should be \"$vtype complete $vtparm $vtval\""

# # ## ### ##### ######## ############# #####################
## release

test vt-${vtype}-release-1.0 "$vtype release, wrong args, not enough" -body {
    $vtype release
} -returnCodes error -result "wrong # args: should be \"$vtype release $vtparm $vtval\""

test vt-${vtype}-release-1.1 "$vtype release, wrong args, not enough" -body {
    $vtype release P
} -returnCodes error -result "wrong # args: should be \"$vtype release $vtparm $vtval\""

test vt-${vtype}-release-1.2 "$vtype release, wrong args, too many" -body {
    $vtype release P V X
} -returnCodes error -result "wrong # args: should be \"$vtype release $vtparm $vtval\""

# # ## ### ##### ######## ############# #####################
##
return
