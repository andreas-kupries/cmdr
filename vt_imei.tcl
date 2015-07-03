## -*- tcl -*-
# # ## ### ##### ######## ############# #####################
## CMDR - Validate::Valtype::IMEI - IMEI checksum validation

# @@ Meta Begin
# Package cmdr::validate::valtype::imei 1
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/cmdr
# Meta platform tcl
# Meta summary     Standard parameter validation type for imei checksums
# Meta description Standard parameter validation type for imei checksums
# Meta subject {command line}
# Meta require {Tcl 8.5-}
# Meta require cmdr::validate::valtype-support
# Meta require valtype::imei
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require cmdr::validate::valtype-support

# # ## ### ##### ######## ############# #####################

cmdr validate valtype-support wrap imei

# # ## ### ##### ######## ############# #####################
## Ready
package provide cmdr::validate::valtype::imei 1
return
