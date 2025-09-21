# Import Telegram configuration from other file script
:local filecfg [:parse [/system script get TelegramConfig source]]
:local cfg [$filecfg]
:local TToken ($cfg->"TToken")
:local TChatId ($cfg->"TChatId")

# Locals
:local error ""
:local filename "myIP.txt"
:local curIP [:tostr [:pick [:toarray ([/tool fetch url="https://api.db-ip.com/v2/free/self/ipAddress" output=user as-value])] 0]]
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
  :set msg "*MikroTik - IP changed* %F0%9F%8C%8F%0A_$curDate $curTime_%0A%0ANew IP, file created%0A*Current IP:* $curIP"
  /tool fetch "https://api.telegram.org/bot$TToken/sendMessage\?chat_id=$TChatId&text=$msg&parse_mode=markdown" keep-result=no
} else={

  # If the file exists read the IP saved on it (previously)
  :set prevIP [/file get [/file find name=$filename] contents]
  
  # If Previous IP is not equal to Current IP write on file the new IP
  :if ($prevIP != $curIP) do={
    /file set [find name=$filename] contents=$curIP
    :set msg "*MikroTik - IP changed* %F0%9F%8C%8F%0A_$curDate $curTime_%0A%0A*Prevoius IP:* $prevIP%0A*Current IP:* $curIP"
    /tool fetch "https://api.telegram.org/bot$TToken/sendMessage\?chat_id=$TChatId&text=$msg&parse_mode=markdown" keep-result=no
  }
}
