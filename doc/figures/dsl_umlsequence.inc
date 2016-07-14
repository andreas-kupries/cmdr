# -*- tcl -*-
## ====================================================================
## UML sequence diagram DSL, assembly level.

# Should have a grid parameter the others are based on.

set boxheight  [10 mm]
set boxwidth   [30 mm]
set movelength [10 mm]
set actorstep  [5 mm]

proc actor {code n {w {}}} {
    global $code 
    variable actorstep
    if {$w eq ""} {
	upvar 1 boxwidth bw
	set w $bw
    }
    box "$n" width $w
    group { down ; line }
    move to [by $actorstep e]
    set $code [last line end]
    return
}

proc skip {code} {
    global $code
    group { down ; line from [set $code] }
    set $code [last line end]
    return
}

proc skip-> {code} {
    global $code
    group { down ; line -> from [set $code] }
    set $code [last line end]
    return
}

proc action {code args} {
    global $code a$code
    box fillcolor white {*}$args with north at [set $code] width [3 mm] height [10 mm]
    set $code [last box south]
    set a$code [last box]
    return
}

proc label {code text} {
    global a$code
    text text $text with sw at [[set a$code] ne]
    return
}

proc call-up {from to label} {
    global a$from a$to
    arrow from [[set a$from] w] to [[set a$to] e] stroke 2
    text $label with sw at [[last arrow end] by [2 mm] e]
    return
}

proc call-down {from to label} {
    global a$from a$to
    arrow from [[set a$from] e] to [[set a$to] w] stroke 2
    text $label with se at [[last arrow end] by [2 mm] w]
    return
}

proc return-down {from to label} {
    global a$from a$to
    arrow from [[set a$from] e] to [[set a$to] w] dotted
    text $label with sw at [[last arrow start] by [2 mm] e]
    return
}

proc return-up {from to label} {
    global a$from a$to
    arrow from [[set a$from] w] to [[set a$to] e] dotted
    text $label with se at [[last arrow start] by [2 mm] w]
    return
}

proc stop {code} {
    global $code
    skip $code
    circle with center at [set $code] radius [1 mm] fillcolor black
    return
}

## ====================================================================
