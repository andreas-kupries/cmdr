## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate::Valtype::Luhn - Luhn checksum validation

# @@ Meta Begin
# Package cmdr::validate::valtype::luhn 1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard parameter validation type for luhn checksums
# Meta description Standard parameter validation type for luhn checksums
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require cmdr::validate::valtype-support
# Meta require valtype::luhn
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::validate::valtype-support

# # ## ### ##### ######## ############# #####################

cmdr validate valtype-support wrap luhn

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::valtype::luhn 1
return
