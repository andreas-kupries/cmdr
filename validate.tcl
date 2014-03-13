## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate - Definition of core validation classes.

# @@ Meta Begin
# Package cmdr::validate 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard validation types for parameters.
# Meta description Standard validation types for parameters.
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require {cmdr::validate::common 1.2}
# Meta require debug
# Meta require debug::caller
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::validate::common 1.2
package require debug
package require debug::caller

# # ## ### ##### ######## ############# #####################
## Definition

namespace eval ::cmdr {
    namespace export validate
    namespace ensemble create
}

namespace eval ::cmdr::validate {
    namespace export boolean integer double percent identity \
	pass str rfile wfile rwfile rdirectory rwdirectory \
	rpath rwpath rchan wchan rwchan
    #namespace ensemble create

    # For external v-types relying on them here.
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-enum
}

# # ## ### ##### ######## ############# #####################

debug define cmdr/validate
debug level  cmdr/validate
debug prefix cmdr/validate {[debug caller] | }

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::validate::boolean {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-enum
}

proc ::cmdr::validate::boolean::release  {p x} { return }
proc ::cmdr::validate::boolean::default  {p}  {
    debug.cmdr/validate {}
    return no
}

proc ::cmdr::validate::boolean::complete {p x} {
    debug.cmdr/validate {} 10
    return [complete-enum {yes no false true on off 0 1} 1 $x]
}

proc ::cmdr::validate::boolean::validate {p x} {
    debug.cmdr/validate {}
    if {[string is boolean -strict $x]} {
	# Double inverse keeps value, and makes it canonical.
	return [expr {!!$x}]
    }
    fail $p BOOLEAN "a boolean" $x
}

# # ## ### ##### ######## ############# #####################
## Any integer

namespace eval ::cmdr::validate::integer {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
}

proc ::cmdr::validate::integer::release  {p x} { return }
proc ::cmdr::validate::integer::default  {p}  {
    debug.cmdr/validate {}
    return 0
}
proc ::cmdr::validate::integer::complete {p x} {
    debug.cmdr/validate {} 10
    return {}
}
proc ::cmdr::validate::integer::validate {p x} {
    debug.cmdr/validate {}
    if {[string is integer -strict $x]} { return $x }
    fail $p INTEGER "an integer" $x
}

# # ## ### ##### ######## ############# #####################
## Any double

namespace eval ::cmdr::validate::double {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
}

proc ::cmdr::validate::double::release  {p x} { return }
proc ::cmdr::validate::double::default  {p}  {
    debug.cmdr/validate {}
    return 0
}
proc ::cmdr::validate::double::complete {p x} {
    debug.cmdr/validate {} 10
    return {}
}
proc ::cmdr::validate::double::validate {p x} {
    debug.cmdr/validate {}
    if {[string is double -strict $x]} { return $x }
    fail $p DOUBLE "a double" $x
}

# # ## ### ##### ######## ############# #####################
## Any double in [0,100]

namespace eval ::cmdr::validate::percent {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
}

proc ::cmdr::validate::percent::release  {p x} { return }
proc ::cmdr::validate::percent::default  {p}  {
    debug.cmdr/validate {}
    return 0
}
proc ::cmdr::validate::percent::complete {p x} {
    debug.cmdr/validate {} 10
    return {}
}
proc ::cmdr::validate::percent::validate {p x} {
    debug.cmdr/validate {}
    if {[string is double -strict $x] &&
	($x >= 0) &&
	($x <= 100)} { return $x }
    fail $p PERCENT "a percentage" $x
}

# # ## ### ##### ######## ############# #####################
## Any string

namespace eval ::cmdr::validate::identity {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::identity::release  {p x} { return }
proc ::cmdr::validate::identity::default  {p}   { debug.cmdr/validate {}    ; return {} }
proc ::cmdr::validate::identity::complete {p x} { debug.cmdr/validate {} 10 ; return {} }
proc ::cmdr::validate::identity::validate {p x} { debug.cmdr/validate {}    ; return $x }

# # ## ### ##### ######## ############# #####################
## Any string, alternate name

namespace eval ::cmdr::validate::pass {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::pass::release  {p x} { return }
proc ::cmdr::validate::pass::default  {p}   {debug.cmdr/validate {}    ; return {} }
proc ::cmdr::validate::pass::complete {p x} {debug.cmdr/validate {} 10 ; return {} }
proc ::cmdr::validate::pass::validate {p x} {debug.cmdr/validate {}    ; return $x }

# # ## ### ##### ######## ############# #####################
## Any string, alternate name, the second

namespace eval ::cmdr::validate::str {
    namespace export default validate complete release
    namespace ensemble create
}

proc ::cmdr::validate::str::release  {p x} { return }
proc ::cmdr::validate::str::default  {p}   { debug.cmdr/validate {}    ; return {} }
proc ::cmdr::validate::str::complete {p x} { debug.cmdr/validate {} 10 ; return {} }
proc ::cmdr::validate::str::validate {p x} { debug.cmdr/validate {}    ; return $x }

# # ## ### ##### ######## ############# #####################
## File, existing and readable

namespace eval ::cmdr::validate::rfile {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
}

proc ::cmdr::validate::rfile::release  {p x} { return }
proc ::cmdr::validate::rfile::default  {p}   { return {} }
proc ::cmdr::validate::rfile::complete {p x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rfile::Ok $x
}
proc ::cmdr::validate::rfile::validate {p x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail $p RFILE "an existing readable file" $x
}

proc ::cmdr::validate::rfile::Ok {path} {
    if {![file exists   $path]} {return 0}
    if {![file isfile   $path]} {return 0}
    if {![file readable $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## File, existing and writable

namespace eval ::cmdr::validate::wfile {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
    namespace import ::cmdr::validate::common::ok-directory
}

proc ::cmdr::validate::wfile::release  {p x} { return }
proc ::cmdr::validate::wfile::default  {p}   { return {} }
proc ::cmdr::validate::wfile::complete {p x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::wfile::Ok $x
}
proc ::cmdr::validate::wfile::validate {p x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail $p WFILE "a writable file" $x
}

proc ::cmdr::validate::wfile::Ok {path} {
    if {![file exists $path]} {
	# The file is allowed to not exist if its directory exists and
	# is writable. This can apply recursively up the chain of
	# directories.
	return [ok-directory [file dirname $path]]
    }
    if {![file isfile   $path]} {return 0}
    if {![file writable $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## File, existing and read/writable

namespace eval ::cmdr::validate::rwfile {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
    namespace import ::cmdr::validate::common::ok-directory
}

proc ::cmdr::validate::rwfile::release  {p x} { return }
proc ::cmdr::validate::rwfile::default  {p}   { return {} }
proc ::cmdr::validate::rwfile::complete {p x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rwfile::Ok $x
}
proc ::cmdr::validate::rwfile::validate {p x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail $p RWFILE "a read/writable file" $x
}

proc ::cmdr::validate::rwfile::Ok {path} {
    if {![file exists $path]} {
	# The file is allowed to not exist if its directory exists and
	# is writable. This can apply recursively up the chain of
	# directories.
	return [ok-directory [file dirname $path]]
    }
    if {![file isfile   $path]} {return 0}
    if {![file readable $path]} {return 0}
    if {![file writable $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Directory, existing and readable.

namespace eval ::cmdr::validate::rdirectory {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
}

proc ::cmdr::validate::rdirectory::release  {p x} { return }
proc ::cmdr::validate::rdirectory::default  {p}   { return {} }
proc ::cmdr::validate::rdirectory::complete {p x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rdirectory::Ok $x
}

proc ::cmdr::validate::rdirectory::validate {p x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail $p RDIRECTORY "an existing readable directory" $x
}

proc ::cmdr::validate::rdirectory::Ok {path} {
    if {![file exists      $path]} {return 0}
    if {![file isdirectory $path]} {return 0}
    if {![file readable    $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Directory, existing and read/writable.

namespace eval ::cmdr::validate::rwdirectory {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
    namespace import ::cmdr::validate::common::ok-directory
}

proc ::cmdr::validate::rwdirectory::release  {p x} { return }
proc ::cmdr::validate::rwdirectory::default  {p}   { return {} }
proc ::cmdr::validate::rwdirectory::complete {p x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rwdirectory::Ok $x
}

proc ::cmdr::validate::rwdirectory::validate {p x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail $p RWDIRECTORY "an existing read/writeable directory" $x
}

proc ::cmdr::validate::rwdirectory::Ok {path} {
    if {![file exists $path]} {
	# The directory is allowed to not exist if its parent
	# directory exists and is writable. This can apply recursively
	# up the chain of directories.
	return [ok-directory [file dirname $path]]
    }
    if {![file isdirectory $path]} {return 0}
    if {![file readable    $path]} {return 0}
    if {![file writable    $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Any path, existing and readable.

namespace eval ::cmdr::validate::rpath {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
}

proc ::cmdr::validate::rpath::release  {p x} { return }
proc ::cmdr::validate::rpath::default  {p}   { return {} }
proc ::cmdr::validate::rpath::complete {p x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rpath::Ok $x
}

proc ::cmdr::validate::rpath::validate {p x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail $p RPATH "an existing readable path" $x
}

proc ::cmdr::validate::rpath::Ok {path} {
    if {![file exists      $path]} {return 0}
    if {![file isdirectory $path]} {return 0}
    if {![file readable    $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Any path, existing and read/writable.

namespace eval ::cmdr::validate::rwpath {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
    namespace import ::cmdr::validate::common::ok-directory
}

proc ::cmdr::validate::rwpath::release  {p x} { return }
proc ::cmdr::validate::rwpath::default  {p}   { return {} }
proc ::cmdr::validate::rwpath::complete {p x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rwpath::Ok $x
}

proc ::cmdr::validate::rwpath::validate {p x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return $x }
    fail $p RWPATH "an existing read/writeable path" $x
}

proc ::cmdr::validate::rwpath::Ok {path} {
    if {![file exists $path]} {
	# The path is allowed to not exist if its directory exists and
	# is writable. This can apply recursively up the chain of
	# directories.
	return [ok-directory [file dirname $path]]
    }
    if {![file readable    $path]} {return 0}
    if {![file writable    $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Channel, for existing and readable file. Defaults to stdin.

namespace eval ::cmdr::validate::rchan {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
}

proc ::cmdr::validate::rchan::release  {p x} {
    if {$x eq "stdin"} return
    close $x
    return
}
proc ::cmdr::validate::rchan::default  {p}   { return stdin }
proc ::cmdr::validate::rchan::complete {p x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rchan::Ok $x
}
proc ::cmdr::validate::rchan::validate {p x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return [open $x r] }
    fail $p RCHAN "an existing readable file" $x
}

proc ::cmdr::validate::rchan::Ok {path} {
    if {![file exists   $path]} {return 0}
    if {![file isfile   $path]} {return 0}
    if {![file readable $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Channel, for existing and writable file. Defaults to stdout.

namespace eval ::cmdr::validate::wchan {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
    namespace import ::cmdr::validate::common::ok-directory
}

proc ::cmdr::validate::wchan::release  {p x} {
    if {$x eq "stdout"} return
    close $x
    return
}
proc ::cmdr::validate::wchan::default  {p}   { return stdout }
proc ::cmdr::validate::wchan::complete {p x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::wchan::Ok $x
}
proc ::cmdr::validate::wchan::validate {p x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return [open $x w] }
    fail $p WCHAN "a writable file" $x
}

proc ::cmdr::validate::wchan::Ok {path} {
    if {![file exists $path]} {
	# The file is allowed to not exist if its directory exists and
	# is writable. This can apply recursively up the chain of
	# directories.
	return [ok-directory [file dirname $path]]
    }
    if {![file isfile   $path]} {return 0}
    if {![file writable $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Channel, for existing and read/writable file. No default.

namespace eval ::cmdr::validate::rwchan {
    namespace export default validate complete release
    namespace ensemble create
    namespace import ::cmdr::validate::common::fail
    namespace import ::cmdr::validate::common::complete-glob
    namespace import ::cmdr::validate::common::ok-directory
}

proc ::cmdr::validate::rwchan::release  {p x} { close $x }
proc ::cmdr::validate::rwchan::default  {p}   { return {} }
proc ::cmdr::validate::rwchan::complete {p x} {
    debug.cmdr/validate {} 10
    complete-glob ::cmdr::validate::rwchan::Ok $x
}
proc ::cmdr::validate::rwchan::validate {p x} {
    debug.cmdr/validate {}
    if {[Ok $x]} { return [open $x w+] }
    fail $p RWCHAN "a read/writable file" $x
}

proc ::cmdr::validate::rwchan::Ok {path} {
    if {![file exists   $path]} {
	# The file is allowed to not exist if its directory exists and
	# is writable. This can apply recursively up the chain of
	# directories.
	return [ok-directory [file dirname $path]]
    }
    if {![file isfile   $path]} {return 0}
    if {![file readable $path]} {return 0}
    if {![file writable $path]} {return 0}
    return 1
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate 1.3
return
