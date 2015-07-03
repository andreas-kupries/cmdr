## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate::Valtype::ISBN - ISBN checksum validation

# @@ Meta Begin
# Package cmdr::validate::valtype::isbn 1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard parameter validation type for isbn checksums
# Meta description Standard parameter validation type for isbn checksums
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require cmdr::validate::valtype-support
# Meta require valtype::isbn
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::validate::valtype-support

# # ## ### ##### ######## ############# #####################

cmdr validate valtype-support wrap isbn

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::valtype::isbn 1
return
