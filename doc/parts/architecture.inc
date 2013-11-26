
[para] All packages in the framework belong to one of three layers,
as shown below:

[image architecture].

[list_begin itemized]

[item] The topmost layer contains only a single package,
[package cmdr], which is a trivial entry point to the system.

[item] The bottom layer contains the mainly internal utility packages.
The exception is [package cmdr::validate::common], for use in bespoke
validation types. See the document about [term [vset TITLE_DEV_VT]]
for details.

[item] The important pieces implementing the various entities are all
in the middle layer. The relationship of these entities can be seen in
the next diagram:

[image erd]
[list_end]

[para] Packages marked with a dashed blue border are public in parts,
and private in parts.

[para] Packages marked with an unbroken blue border are fully public.
