
[para] All packages in the framework belong to one of three layers,
as shown below:

[para][image architecture]

[para] Note that:

[list_begin itemized]

[item] Packages marked with a dashed blue border are public in parts,
and private in parts.

[item] Packages marked with an unbroken blue border are fully public.

[item] The topmost layer contains only a single package,
[package cmdr], which is the trivial entry point to the system.

[item] The bottom layer contains the mainly internal utility packages.
The exception is [package cmdr::validate::common], for use in bespoke
validation types. See the document about [term [vset TITLE_DEV_VT]]
for details.

[item] The important pieces implementing the various entities are all
in the middle layer. The relationship of these entities can be seen in
the next diagram:

[para][image erd]
[list_end]

[para] The dependencies between the packages are very
straight-forward, following mostly directly out of the relationships
shown above, plus the few where the utilities are imported. To reduce
the complexity of the diagram below a few direct dependencies on
[package cmdr::util] were omitted where indirectly present through
other dependencies (i.e. through [package cmdr::help]):

[para][image pkg_dependencies]
