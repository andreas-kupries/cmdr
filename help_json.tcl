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
package require dictutil

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
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::help::format::json {width help} {
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
    # command = list ('desc'      -> description
    #                 'options'   -> options
    #                 'arguments' -> arguments)

    dict with command {} ; # -> desc, options, arguments

    # options   = list (option...)
    # option    = dict (name -> description)
    # arguments = dict (name -> argdesc)
    # argdesc   = dict ('code' -> code
    #                   'desc' -> description)
    # code in {
    #     +		<=> required
    #     ?		<=> optional
    #     +*	<=> required splat
    #     ?* 	<=> optional splat
    # }

    lappend dict arguments   [JSON::arguments $arguments]
    lappend dict description [json::write string [JSON::astring $desc]]
    lappend dict options     [JSON::options   $options]
    
    return [json::write object {*}$dict]
}

proc ::cmdr::help::format::JSON::options {options} {
    set dict {}
    foreach {name description} [::cmdr::help::DictSort $options] {
	lappend dict $name [json::write string [astring $description]]
    }
    return [json::write object {*}$dict]
}

proc ::cmdr::help::format::JSON::arguments {arguments} {
    set dict {}
    foreach {name def} [::cmdr::help::DictSort $arguments] {
	set tmp {}
	foreach {xname xdef} [::cmdr::help::DictSort $def] {
	    lappend tmp $xname [json::write string [astring $xdef]]
	}
	lappend dict $name [json::write object {*}$tmp]
    }
    return [json::write object {*}$dict]
}

# # ## ### ##### ######## ############# #####################

proc ::cmdr::help::format::JSON::astring {string} {
    regsub -all -- {[ \n\t]+} $string { } string
    string trim $string
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::help::json 0.1
