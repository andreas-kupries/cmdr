Documentation structure
=======================

Directory hierarchy
-------------------

doc/
	*.man	- Guides, and user-specific documentation (packages,
                  whitepapers, etc.).

	cmdr_introduction
			Introduction to the project.
	cmdr_license	License of the project. BSD.
	cmdr_changes	ChangeLog for releases.

	cmdr_howto_get_sources
			How to get the sources of the project.

	cmdr_howto_installation
			How to install the packages in the project.

	cmdr_howto_development
			Portal document to the internals of the
			project.

doc/parts/

	*.inc	- Common parts and text blocks used by the main
                  documentation files in the parent directory.

	configuration.inc	Configuration variables.
				Query and modify using kettle's
				@doc-config command.

	definitions.inc		More variables, derived from the
				basic configuration, not directly
				configurable.

	module.inc		Module description and the common
				keywords of the project for indexing.

				Edit to suit. It is often good enough,
				and easier, to simply reconfigure
				various settings (like author name,
				keywords, etc.).

	welcome.inc		General welcome text for the project.

	related.inc		List of related documents for standard
				cross-references between the guides.
				Usually not edited, but can be.

				Requires the variables set in
				definitions.inc

	feedback.inc		Standard text block about feed-back
				for the project.

	retrieve.inc		Standard textblocks describing the SCM
	scm.inc	    		managing the sources, and how to
				retrieve revisions.

	license.inc		Text of the project's license. Query
				and modify via the kettle commands
				@license, and @licenses

Logical structure
-----------------

I.e. what document includes what parts.
For code this would be a call tree.

introduction.man
-->	parts/definitions.inc
	-->	configuration.inc
-->	parts/module.inc
-->	parts/welcome.inc
-->	parts/related.inc
-->	parts/feedback.inc

license.man
-->	parts/definitions.inc
	-->	configuration.inc
-->	parts/module.inc
-->	parts/welcome.inc
-->	parts/license.inc
-->	parts/related.inc
-->	parts/feedback.inc

changes.man
-->	parts/definitions.inc
	-->	configuration.inc
-->	parts/module.inc
-->	parts/welcome.inc
-->	parts/related.inc
-->	parts/feedback.inc

cmdr_howto_get_sources.man
-->	parts/definitions.inc
	-->	configuration.inc
-->	parts/module.inc
-->	parts/welcome.inc
-->	parts/retrieve.inc
-->	parts/scm.inc
-->	parts/related.inc
-->	parts/feedback.inc

cmdr_howto_installation.man
-->	parts/definitions.inc
	-->	configuration.inc
-->	parts/module.inc
-->	parts/welcome.inc
-->	parts/rq_tcl.inc
-->	parts/rq_kettle.inc
-->	parts/build.inc
-->	parts/related.inc
-->	parts/feedback.inc

cmdr_howto_development.man
-->	parts/definitions.inc
	-->	configuration.inc
-->	parts/module.inc
-->	parts/welcome.inc
-->	parts/related.inc
-->	parts/feedback.inc
