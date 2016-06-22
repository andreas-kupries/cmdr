## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate::Valtype::EAN13 - EAN13 checksum validation

# @@ Meta Begin
# Package cmdr::validate::valtype::creditcard::mastercard 1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard parameter validation type for creditcard::mastercard checksums
# Meta description Standard parameter validation type for creditcard::mastercard checksums
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require cmdr::validate::valtype-support
# Meta require valtype::ean13
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::validate::valtype-support

# # ## ### ##### ######## ############# #####################

cmdr validate valtype-support wrap creditcard::mastercard

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::valtype::creditcard::mastercard 1
return
