## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## XO - Private - Command execution. Simple case.
##                An actor.

## - Privates know to do one thing, exactly, and nothing more.
##   They can process their command line to extract/validate
##   the inputs they need for their action from the arguments.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO
package require xo::actor
package require ooutil 1.2 ;# link helper

# # ## ### ##### ######## ############# #####################
## Definition - Single purpose command.

oo::class create ::xo::private {
    superclass ::xo::actor
    # # ## ### ##### ######## #############
    ## Lifecycle.

    # argument specification + callback performing the action.
    # callback takes dictionary containing the actual arguments
    constructor {name arguments cmdprefix} {
	next $name
    }

    # argument specification:
    # - script.
    # - define the commands.


	# XXX run the specification in my instance context. note that
	# XXX we need access to the methods without 'my'.

	# body or cmd prefix ? - cmdprefix is easier for the arguments to pass in.
	# - standard argument ? - xo (context)

	# process interface, filling out holes...
	# do not touch empty interfaces.

	# interface:
	# -- below is dict. alternate would be script, with commands
	#    setting things => command object getting configured.

	# map input names to input specifications -> order important
	# specification is dictionary.
	# - input -> argument|flag
	# - argument may be optional
	# - flag (input?) may be hidden
	# - flag may have aliases (alternate names)
	# - input may have default value, or callback for entry of such
	# - input may have validation (type of value, callback - snit validation type).
	# - input may have callback for calculated entry (interactive or other)

    # # ## ### ##### ######## #############

    method do {args} {}
    method help {} {}

    # # ## ### ##### ######## #############
}

# # ## ### ##### ######## ############# #####################
## Ready
package provide xo::private 0.1
