## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Help - JSON format. Not available by default.
## Require this package before creation a commander, so that the
## mdr::help heuristics see and automatically integrate the format.

# @@ Meta Begin
# Package cmdr::help::json 0.1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Formatting help as JSON object.
# Meta description Formatting help as JSON object.
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require debug
# Meta require debug::caller
# Meta require cmdr::help
# Meta require json::write
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require debug
package require debug::caller
package require cmdr::help
package require json::write

# # ## ### ##### ######## ############# #####################

debug define cmdr/help/json
debug level  cmdr/help/json
debug prefix cmdr/help/json {[debug caller] | }

# # ## ### ##### ######## ############# #####################
## Definition

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::help::format {
    namespace export json
    namespace ensemble create

    namespace import ::cmdr::help::query
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::help::format::json {root width help} {
    debug.cmdr/help/json {}
    # help = dict (name -> command)
    set dict {}
    dict for {cmd desc} $help {
	lappend dict $cmd [JSON $desc]
    }
    return [json::write object {*}$dict]
}

# # ## ### ##### ######## ############# #####################

namespace eval ::cmdr::help::format::JSON {}

proc ::cmdr::help::format::JSON {command} {
    # Data structure: see config.tcl,  method 'help'.
    # Data structure: see private.tcl, method 'help'.

    dict with command {}
    # -> action, desc, options, arguments, parameters, states, sections

    lappend dict description [JSON::astring    $desc]
    lappend dict action      [JSON::alist      $action]
    lappend dict arguments   [JSON::alist      $arguments]
    lappend dict options     [JSON::adict      $options]
    lappend dict states      [JSON::alist      $states]
    lappend dict parameters  [JSON::parameters $parameters]
    lappend dict sections    [JSON::alist      $sections]
    
    return [json::write object {*}$dict]
}

proc ::cmdr::help::format::JSON::parameters {parameters} {
    set dict {}
    foreach {name def} [::cmdr::help::DictSort $parameters] {
	set tmp {}
	foreach {xname xdef} [::cmdr::help::DictSort $def] {
	    switch -glob -- $xname {
		cmdline -
		defered -
		documented -
		interactive -
		isbool -
		list -
		ordered -
		presence -
		required -
		@bool {
		    # normalize to boolean
		    set value [expr {!!$xdef}]
		}
		threshold {
		    # null|integer
		    set value [expr {($xdef eq {}) ? "null" : $xdef}]
		}
		code -
		default -
		description -
		prompt -
		type -
		label -
		@string {
		    set value [astring $xdef]
		}
		generator -
		validator -
		@cmdprefix { 
		    set value [alist $xdef]
		}
		flags -
		@dict {
		    set value [adict $xdef]
		}
		* {
		    error "Unknown key \"$xname\", do not know how to format"
		    #lappend tmp $xname [astring $xdef]
		}
	    }
	    lappend tmp $xname $value
	}
	lappend dict $name [json::write object {*}$tmp]
    }
    return [json::write object {*}$dict]
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::help::format::JSON::alist {thelist} {
    set tmp {}
    foreach w $thelist {
	lappend tmp [json::write string $w]
    }
    return [json::write array {*}$tmp]
}

proc ::cmdr::help::format::JSON::adict {thedict} {
    set tmp {}
    foreach {k v} [::cmdr::help::DictSort $thedict] {
	lappend tmp $k [json::write string $v]
    }
    return [json::write object {*}$tmp]
}

proc ::cmdr::help::format::JSON::astring {string} {
    regsub -all -- {[ \n\t]+} $string { } string
    return [json::write string [string trim $string]]
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::help::json 0.1
