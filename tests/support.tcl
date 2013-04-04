# -*- tcl -*-
# # ## ### ##### ######## ############# #####################

if 0 {tcltest::customMatch exact Seq ; proc Seq {a b} {
    if {$a ne $b} {
	puts A|[string map [list "\[" "<" " " "\S" "\n" "\\N" "\t" "\\T"] $a]|
	puts B|[string map [list "\[" "<" " " "\S" "\n" "\\N" "\t" "\\T"] $b]|
    }
    string equal $a $b
}}

# # ## ### ##### ######## ############# #####################
## Standard help structures

proc HelpLarge {format {n 50}} {
    Help {
	description TEST
	officer bar {
	    private aloha {
		description hawaii
		option lulu loop {}
		input yoyo height
		input jump gate { optional }
		input run lane { list }
	    } ::hula
	}
	default
	alias snafu
	officer tool {
	    officer pliers {}
	    officer hammer {
		private nail {
		    description workbench
		    option driver force { validate adouble ; default 0 ; list ; alias force }
		    state  context orientation
		    input supply magazine { list ; optional }
		} ::wall
	    }
	    default hammer
	}
	alias hammer = tool hammer

	private hidden {
	    undocumented
	} ::missing

	officer stealth {
	    undocumented
	    private cloak {} ::dagger
	}
    } $format $n
}

proc HelpSmall {format {n 50}} {
    Help {
	description TEST
	private nail {
	    description workbench
	    option no-driver force { list ; alias force }
	} ::wall
    } $format $n
}

proc Help {def format n} {
    try {
	cmdr create x foo $def
	cmdr help format $format $n [x help]
    } finally {
	x destroy
    }
}

# # ## ### ##### ######## ############# #####################
## Supporting procedures for xo.test et. al.

proc StartNotes {}     { set ::result {} ; return }
proc Note       {args} { lappend ::result $args ; return }
proc StopNotes  {}     { unset ::result ; return }
proc Notes      {}     { Wrap $::result }

proc NiceParamSpec {kind spec {name A}} {
    try {
	cmdr create x foo [list private bar [list $kind $name - $spec] {}]
	ShowPrivate [x lookup bar]
    } finally {
	x destroy
    }
}

proc BadParamSpec {kind spec} {
    try {
	cmdr create x foo [list private bar [list $kind A A $spec] {}]
	[x lookup bar] keys
    } finally {
	x destroy
    }
}

proc Parse {spec args} {
    upvar 1 ons ons
    try {
	cmdr create x foo \
	    [list private bar $spec \
		 {::apply {{config} {}}}]
	# Eval the spec first.
	[x lookup bar] keys
	if {[info exists ons]} {
	    # x = officer, bar = private, ons = parameter
	    set ons [info object namespace [[x lookup bar] lookup $ons]]
	}
	# Now the runtime args processing.
	[x lookup bar] do {*}$args
	ShowParsed [x lookup bar]
    } finally {
	x destroy
    }
}

# # ## ### ##### ######## ############# #####################

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
	if {[info object class $c] eq "::cmdr::private"} continue
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

    set names [lsort -dict [$o names]]

    # Retrieve data
    foreach name $names {
	set c [$o lookup $name]
	if {[$c defined?]} {
	    set s '[$c string]'
	} else {
	    set s <undefined>
	}
	lappend strings $s
	lappend values  v'[$c value]'
    }

    # Table formatted output.
    foreach name [Padr $names] s [Padr $strings] v $values {
	lappend result "$name = $s $v"
    }
    return $result
}

proc Padr {list} {
    set maxl 0
    foreach str $list {
	set l [string length $str]
	if {$l <= $maxl} continue
	set maxl $l
    }
    set res {}
    foreach str $list { lappend res [format "%-*s" $maxl $str] }
    return $res
}

proc Padl {list} {
    set maxl 0
    foreach str $list {
	set l [string length $str]
	if {$l <= $maxl} continue
	set maxl $l
    }
    set res {}
    foreach str $list { lappend res [format "%*s" $maxl $str] }
    return $res
}
