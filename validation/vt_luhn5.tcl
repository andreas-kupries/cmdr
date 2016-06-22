## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate::Valtype::Luhn5 - Luhn5 checksum validation

# @@ Meta Begin
# Package cmdr::validate::valtype::luhn5 1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard parameter validation type for luhn5 checksums
# Meta description Standard parameter validation type for luhn5 checksums
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require cmdr::validate::valtype-support
# Meta require valtype::luhn5
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::validate::valtype-support

# # ## ### ##### ######## ############# #####################

cmdr validate valtype-support wrap luhn5

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::valtype::luhn5 1
return
