# -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## Supporting procedures for xo.test et. al.

proc ShowOfficer {o} { Wrap [DumpOfficer $o] }
proc ShowPrivate {o} { Wrap [DumpPrivate $o] }
proc ShowParsed  {o} { Wrap [DumpParsed  $o] }

# Indent a list of lines, generate text block.
proc Wrap {list} {
    set p "\n    "
    return ${p}[join $list $p]\n
}

# Dumping the state of an officer and its subordinates.
# Assumes that the children are all oficers too, and not privates.
# This may be fixable.

proc DumpOfficer {o} {
    set name [$o fullname]
    set result {}

    # Description
    lappend result "$name = \{"
    lappend result "    description: '[$o description]'"
    # Default action, if any.
    if {[$o hasdefault]} {
	lappend result "    default: [$o default]"
    } else {
	lappend result "    no default"
    }
    # Data store. Note how it shows the entire inherited store, not
    # just the local settings.
    foreach k [lsort -dict [$o keys]] {
	lappend result "    store ($k): '[$o get $k]'"
    }
    # Delegates - Action mapping
    foreach a [lsort -dict [$o known]] {
	set c [$o lookup $a]
	lappend result "    $a --> [$c name]"
    }
    lappend result "\}"

    # Delegates II. Full dump of the subordinates.
    set tmp {}
    foreach c [$o children] {
	lappend tmp [list $c [$c name]]
    }
    foreach item [lsort -dict -index 1 $tmp] {
	lassign $item c _
	lappend result {*}[DumpOfficer $c]
    }
    return $result
}

# Dumping the state of a private and its parameters.
proc DumpPrivate {o} {
    set name [$o fullname]
    set result {}

    # Description
    lappend result "$name = \{"
    lappend result "    description: '[$o description]'"

    # Data store. Inherited. Note how it shows the entire inherited
    # store, not just the local settings. Which a private usually has
    # none of.
    foreach k [lsort -dict [$o keys]] {
	lappend result "    store ($k): '[$o get $k]'"
    }

    # Options (Mapping from prefix to full options).
    foreach {opt v} [kt dictsort [$o options]] {
	lappend result "    $opt --> ($v)"
	# TODO: option handler and configuration
    }

    # Options II. From full options to their parameter.
    # TODO

    # All parameters.
    foreach name [lsort -dict [$o names]] {
	set c [$o lookup $name]

	lappend result "    P ($name) \{"
	lappend result "        description: '[$c description]'"

	set state {}
	if {[$c ordered]}     { lappend state ordered }
	if {[$c hidden]}      { lappend state hidden }
	if {[$c list]}        { lappend state splat }
	if {[$c required]}    { lappend state required }
	if {[$c interactive]} { lappend state interact }
	if {[llength $state]} {
	    lappend result "        [join $state {, }]"
	}

	if {[$c hasdefault]}  {
	    lappend result "        default: '[$c default]'"
	} else {
	    lappend result "        no default"
	}
	if {[$c interactive]} {
	    lappend result "        prompt: '[$c prompt]'"
	}
	if {[$c ordered] && ![$c required]} {
	    if {[$c threshold] >= 0} {
		lappend result "        mode=threshold [$c threshold]"
	    } else {
		lappend result "        mode=peek+test"
	    }
	}
	lappend result "        \[[$c options]\]"
	lappend result "        g ([$c generator])"
	lappend result "        v ([$c validator])"
	lappend result "        o ([$c on])"
	lappend result "    \}"
    }

    lappend result "\}"
    return $result
}

# Dumping the parsed parameters of a private
proc DumpParsed {o} {
    set name [$o fullname]
    set result {}
    lappend result "$name = \{"
    foreach name [lsort -dict [$o names]] {
	set c [$o lookup $name]

	set s <undef>
	if {[$c string?]}  { set s [$c string] }

	set d <undef>
	if {[$c defined?]} { set d [$c get] }

	lappend result "    P ($name) =	[$c string?] '$s' [$c defined?] '$d'"
    }
    lappend result "\}"
    return $result
}
