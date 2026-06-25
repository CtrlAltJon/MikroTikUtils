# ============================================================================================================
# Script Name:   IPchanged.rsc
# Author:        CtrlAltJon
# Descrizione:   Script to monitor public IP changes and send Telegram notification
#
# Copyright (c) 2025 CtrlAltJon
# Rilasciato sotto licenza MIT (https://opensource.org/licenses/MIT)
# ============================================================================================================

# Import Telegram configuration from other file script
:local filecfgtg [:parse [/system script get TelegramConfig source]]
:local cfgtg [$filecfgtg]
:local TToken ($cfgtg->"TToken")
:local TChatId ($cfgtg->"TChatId")

# Import DDNS configuration from other file script
:local filecfgddns [:parse [/system script get NoIP_Config source]]
:local cfgddns [$filecfgddns]
:local noipAuth ($cfgddns->"noipAuth")
:local noipHost ($cfgddns->"noipHost")

# Locals
:local error ""
:local filename "myIP.txt"
:local curIP (([/tool fetch url="https://api.db-ip.com/v2/free/self/ipAddress" output=user as-value])->"data")
:local prevIP ""
:local msg ""
:local curTime [/system clock get time]
:local curDate [/system clock get date]

# Check if file with current IP exists
:if ([:len [/file find name=$filename]] = 0) do={
  # If the file doesn't exist, save current IP to the file and send a notification.
  /file print file=$filename
  /file set [find name=$filename] contents=$curIP
  :delay 1s
  :set msg "<b>MikroTik - IP changed</b> %F0%9F%8C%8F%0A<i>$curDate $curTime</i>%0A%0ANew IP, file created%0A<b>Current IP:</b> $curIP"
  /tool fetch url=("https://api.telegram.org/bot" . $TToken . "/sendMessage") http-method=post http-data=("chat_id=" . $TChatId . "&text=" . $msg . "&parse_mode=HTML") output=none
  # Update IP in DDNS no-ip.com (log result for diagnostics)
  :local noipResult ([/tool fetch url=("https://dynupdate.no-ip.com/nic/update?hostname=" . $noipHost . "&myip=" . $curIP) http-header-field=("Authorization: " . $noipAuth . ",User-Agent: MikroTikScript/1.0") output=user as-value]->"data")
  :log info ("No-IP DDNS update: " . $noipResult)
} else={

  # If the file exists read the IP saved on it (previously)
  :set prevIP [/file get [/file find name=$filename] contents]
  
  # If Previous IP is not equal to Current IP write on file the new IP
  :if ($prevIP != $curIP) do={
    /file set [find name=$filename] contents=$curIP
    :set msg "<b>MikroTik - IP changed</b> %F0%9F%8C%8F%0A<i>$curDate $curTime</i>%0A%0A<b>Previous IP:</b> $prevIP%0A<b>Current IP:</b> $curIP"
    # Send Telegram notification
    /tool fetch url=("https://api.telegram.org/bot" . $TToken . "/sendMessage") http-method=post http-data=("chat_id=" . $TChatId . "&text=" . $msg . "&parse_mode=HTML") output=none
    # Update IP in DDNS no-ip.com (log result for diagnostics)
    :local noipResult ([/tool fetch url=("https://dynupdate.no-ip.com/nic/update?hostname=" . $noipHost . "&myip=" . $curIP) http-header-field=("Authorization: " . $noipAuth . ",User-Agent: MikroTikScript/1.0") output=user as-value]->"data")
    :log info ("No-IP DDNS update: " . $noipResult)
  }
}
