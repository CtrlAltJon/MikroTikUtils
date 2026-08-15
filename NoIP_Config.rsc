# ============================================================================================================
# Script Name:   NoIP_Config.rsc
# Author:        CtrlAltJon
# Descrizione:   Configuration file script for No-IP.com DDNS service
#
# Copyright (c) 2025 CtrlAltJon
# Released under the MIT License (https://opensource.org/licenses/MIT)
# ============================================================================================================

# Configuration of DDNS no-ip.com
# Create Base64 encoded auth string from username:password with command: echo -n "noipusername:noippassword" | base64
:local config {
"noipAuth"="Basic xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
"noipHost"="your.dynamic.dns.address"
}

return $config
