
[para] The decoupling of command names from their implementations seen
in the previous example makes it easy to re-arrange and re-label the
user visible commands without having to touch any other part of the
code.

[para] This is demonstrated in the example below, moving the 3
"privates" into an "officer" and renaming them, without changing the
actions. Note that the parameter specifications were removed for
clarity, as they were not changed compared to the original example.

[para] "officers" are named inner nodes in the command hierarchy. They
aggregate related commands, which may not only be "privates" as seen
here, but sub-officers as well.

[example {
...
cmdr create ::foo foo {
    officer alias {
	description {
	    A collection of commands to manage
	    user-specific shortcuts for command
	    entry
	}

	private add {
	    ...
	} ::foo::backend::alias::add

	private remove {
	    ...
	} ::foo::backend::alias::remove

	private list {
	    ...
	} ::foo::backend::alias::list
    }
}
...
}]
