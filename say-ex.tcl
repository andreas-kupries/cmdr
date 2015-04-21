
source color.tcl
source say.tcl

#debug on cmdr/say

if 0 {
    puts |[join [cmdr say larson-phases 23 ***] |\n|]|
    exit
}


if 0 {
    puts |[join [cmdr say pulse-phases 6 *] |\n|]|
    exit
}

if 0 {
    puts |[join [cmdr say pulse-phases 3 [cmdr color red .]] |\n|]|
    exit
}

if 0 {
    puts |[join [cmdr say progress-phases 6 * ^] |\n|]|
    exit
}

if 0 {
    # larson scanner
    set B [cmdr say animate -phases [cmdr say larson-phases 9 ***]]
    while {1} {
	after 100
	cmdr say rewind
	$B step

	# NOTE: putting the rewind after the step means that we will
	# see the animation output only for a split second and the
	# erased/empty line for the 100 milli delay => the terminal
	# will look empty, with nothing happening.
    }
}

if 0 {
    # scanner
    set B [cmdr say animate -phases {
	{[***      ]}
	{[** *     ]}
	{[ ** *    ]}
	{[  ** *   ]}
	{[   ** *  ]}
	{[    ** * ]}
	{[     ** *]}
	{[      ***]}
	{[     * **]}
	{[    * ** ]}
	{[   * **  ]}
	{[  * **   ]}
	{[ * **    ]}
	{[* **     ]}
    }]
    while {1} {
	after 100
	cmdr say rewind
	$B step

	# NOTE: putting the rewind after the step means that we will
	# see the animation output only for a split second and the
	# erased/empty line for the 100 milli delay => the terminal
	# will look empty, with nothing happening.
    }
}

if 0 {
    # infinite slider - semi-barberpole
    set B [cmdr say animate -phases [cmdr say slider-phases 9 ***]]
    while {1} {
	after 100
	cmdr say rewind
	$B step
    }
}

if 1 {
    # infinite slider - semi-barberpole
    set B [cmdr say animate -phases {
	{[         ]}
	{[*        ]}
	{[**       ]}
	{[***      ]}
	{[* **     ]}
	{[ * **    ]}
	{[  * **   ]}
	{[   * **  ]}
	{[    * ** ]}
	{[     * **]}
	{[      * *]}
	{[       * ]}
	{[        *]}
    }]
    while {1} {
	after 100
	cmdr say rewind
	$B step
    }
}

if 0 {
    # infinite pulse - semi-barberpole
    set B [cmdr say animate \
	       -phases [cmdr say pulse-phases 3 [cmdr color {bg-blue white} *]]]
    while {1} {
	after 100
	cmdr say rewind
	$B step
    }
}

if 0 {
    # infinite barberpole
    set B [cmdr say barberpole -width 30]
    while {1} {
	after 100
	cmdr say rewind
	$B step
    }
}

if 0 {
    # infinite barberpole with a prefix
    set B [cmdr say barberpole -width 30]
    cmdr say add "download ... "
    cmdr say lock-prefix
    while {1} {
	#
	# fake download, unknown size, sync ... actual use:
	# - fcopy callback,
	# - http progress-callback
	# - tcllib transfer callback
	after 100
	#
	cmdr say rewind
	$B step
    }
}

if 0 {
    # progress counter.
    set B [cmdr say progress-counter 100]
    set i 0
    cmdr say add "upload ... "
    cmdr say lock-prefix
    while {$i < 100} {
	#
	# fake upload, sync ... actual use:
	# - fcopy callback,
	# - http progress-callback
	# - tcllib transfer callback
	after 100
	#
	cmdr say rewind
	incr i
	$B step $i
    }
}

if 0 {
    # percent progress counter
    set B [cmdr say percent -max 10000 -digits 2]
    set i 0
    cmdr say add "upload ... "
    cmdr say lock-prefix
    while {$i < 10000} {
	#
	# fake upload, sync ... actual use:
	# - fcopy callback,
	# - http progress-callback
	# - tcllib transfer callback
	after 10
	#
	cmdr say rewind
	incr i
	$B step $i
    }
}

if 0 {
    # percent progress bar
    set B [cmdr say progress -max 1000 -width 50]
    set C [cmdr say percent  -max 1000]
    set i 0
    cmdr say add "upload ... "
    cmdr say lock-prefix
    while {$i < 1000} {
	#
	# fake upload, sync ... actual use:
	# - fcopy callback,
	# - http progress-callback
	# - tcllib transfer callback
	after 10
	#
	cmdr say rewind
	incr i
	cmdr say add \[
	$B step $i
	cmdr say add \]

	cmdr say add { }
	$C step $i
    }
    #after 10
    #cmdr say rewind
    cmdr say line { OK}
}

if 0 {
    # percent progress bar, full width
    set C [cmdr say percent -max 1000]

    set  n [string length "upload ... \[\] "]
    incr n [$C width]

    set B [cmdr say progress -max 1000 -width -$n]
    set i 0
    cmdr say add "upload ... "
    cmdr say lock-prefix
    while {$i < 1000} {
	#
	# fake upload, sync ... actual use:
	# - fcopy callback,
	# - http progress-callback
	# - tcllib transfer callback
	after 10
	#
	cmdr say rewind
	incr i
	$C step $i
	cmdr say add { }

	cmdr say add \[
	$B step $i
	cmdr say add \]
    }
    after 1000
    cmdr say rewind
    cmdr say line { OK}
}
