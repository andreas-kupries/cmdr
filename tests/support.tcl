# -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## Supporting procedures for xo.test et. al.

proc ShowOfficer {o} { Wrap [DumpOfficer $o] }
proc ShowPrivate {o} { Wrap [DumpPrivate $o] }
proc ShowParsed  {o} { Wrap [DumpParsed  $o] }

proc Trigger {o} {
    # o is xo::private
    # Force DSL execution.
    $o keys
}

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

    # List the argument and option parameters.
    foreach name [lsort -dict [$o arguments]] {
	lappend result "    argument ($name)"
    }
    foreach name [lsort -dict [$o options]] {
	lappend result "    option ($name) = [[$o lookup-option $name] name]"
    }

    # List the mapping from option prefixes to the list of full options.
    foreach {opt v} [kt dictsort [$o eoptions]] {
	lappend result "    map $opt --> ($v)"
    }

    # Lastly, show the full state of all parameters.
    foreach name [lsort -dict [$o names]] {
	set c [$o lookup $name]

	lappend result "    para ($name) \{"
	lappend result "        description: '[$c description]'"

	set state {}
	if {[$c ordered]}     { lappend state ordered  } else { lappend state !ordered  }
	if {[$c cmdline]}     { lappend state cmdline  } else { lappend state !cmdline  }
	if {[$c list]}        { lappend state splat    } else { lappend state !splat    }
	if {[$c required]}    { lappend state required } else { lappend state !required }
	if {[$c interactive]} { lappend state interact } else { lappend state !interact }
	lappend result "        [join $state {, }]"

	if {[$c hasdefault]}  {
	    lappend result "        default: '[$c default]'"
	} else {
	    lappend result "        no default"
	}
	if {[$c interactive]} {
	    lappend result "        prompt: '[$c prompt]'"
	}
	if {[$c cmdline] && [$c ordered] && ![$c required]} {
	    if {[$c threshold] >= 0} {
		lappend result "        mode=threshold [$c threshold]"
	    } else {
		lappend result "        mode=peek+test"
	    }
	}
	lappend result "        flags \[[$c options]\]"
	lappend result "        ge ([$c generator])"
	lappend result "        va ([$c validator])"
	lappend result "        wd ([$c when-defined])"
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
