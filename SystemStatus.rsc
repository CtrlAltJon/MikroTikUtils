# ============================================================================================================
# Script Name:   SystemStatus.rsc
# Author:        CtrlAltJon
# Descrizione:   Script to send MikroTik System Status to Telegram
#
# Copyright (c) 2025 CtrlAltJon
# Released under the MIT License (https://opensource.org/licenses/MIT)
# ============================================================================================================

# Function - Generate String of dots for middle space from Name ad Value
:local GenerateDotsLen do={:return [:pick "........................................" 0 (32 - $a - [:len $b])]}

# Import Telegram configuration from other file script
:local filecfg [:parse [/system script get TelegramConfig source]]
:local cfg [$filecfg]
:local TToken ($cfg->"TToken")
:local TChatId ($cfg->"TChatId")

# Locals
:local msg "<b>Mikrotik - System Status</b> %E2%84%B9%0A<pre>"
:local tmpStr ""
:local firmw [:tostr ([/system resource get factory-software]) ]
:local vers [:tostr ([/system resource get version]) ]
:local uptime [:tostr [/system resource get uptime]]
:local temp [:tostr [/system health get [find where name=temperature] value]]
:local volt [:tostr [/system health get [find where name=voltage] value]]
:local cpuLoad [:tostr ([/system resource get cpu-load]) ]
:local ramFree [:tostr ([/system resource get free-memory]/(1024*1024)) ]
:local ramTot [:tostr ([/system resource get total-memory]/(1024*1024)) ]
:local diskFree [:tostr ([/system resource get free-hdd-space]/(1024*1024)) ]
:local diskTot [:tostr ([/system resource get total-hdd-space]/(1024*1024)) ]
:local diskBad [:tostr ([/system resource get bad-blocks]) ]
:local pubIP (([/tool fetch url="https://api.db-ip.com/v2/free/self/ipAddress" output=user as-value])->"data")
:local activePPP [:len [/ppp active find]]

# Scan active WireGuard peers (handshake < 3m)
:local wgActiveCount 0
:local wgUsersList ""
:foreach peer in=[/interface wireguard peers find] do={
  :local lastHandshake [/interface wireguard peers get $peer last-handshake]
  :local peerComment [/interface wireguard peers get $peer comment]
  :if ([:len $peerComment] = 0) do={ :set peerComment "unnamed" }
  :if ([:len $lastHandshake] > 0 && $lastHandshake < 3m) do={
    :set wgActiveCount ($wgActiveCount + 1)
    :set wgUsersList ($wgUsersList . "%0A- " . $peerComment . " (handshake: " . $lastHandshake . ")")
  }
}

# Compile active PPP users list
:local pppUsersList ""
:if ($activePPP > 0) do={
  :foreach p in=[/ppp active find] do={
    :local pName [/ppp active get $p name]
    :local pProto [/ppp active get $p service]
    :local pUptime [/ppp active get $p uptime]
    :set pppUsersList ($pppUsersList . "%0A- " . $pName . " (" . $pProto . ", " . $pUptime . ")")
  }
}

# Generate msg 
:set tmpStr [$GenerateDotsLen a=8 b=$firmw]
:set msg "$msg%0AFirmware$tmpStr$firmw"
:set tmpStr [$GenerateDotsLen a=7 b=$vers]
:set msg "$msg%0AVersion$tmpStr$vers"
:set tmpStr [$GenerateDotsLen a=6 b=$uptime]
:set msg "$msg%0AUptime$tmpStr$uptime"
:set tmpStr [$GenerateDotsLen a=14 b=$temp]
:set msg "$msg%0ATemperature$tmpStr$temp °C"
:set tmpStr [$GenerateDotsLen a=9 b=$volt]
:set msg "$msg%0AVoltage$tmpStr$volt V"
:set tmpStr [$GenerateDotsLen a=10 b=$cpuLoad]
:set msg "$msg%0ACPU Load$tmpStr$cpuLoad %"
:set tmpStr [$GenerateDotsLen a=13 b=$diskFree MiB]
:set msg "$msg%0ADisk Free$tmpStr$diskFree MiB"
:set tmpStr [$GenerateDotsLen a=12 b=$diskTot]
:set msg "$msg%0ADisk Tot$tmpStr$diskTot MiB"
:set tmpStr [$GenerateDotsLen a=12 b=$ramFree]
:set msg "$msg%0ARAM Free$tmpStr$ramFree MiB"
:set tmpStr [$GenerateDotsLen a=11 b=$ramTot]
:set msg "$msg%0ARAM Tot$tmpStr$ramTot MiB"
:set tmpStr [$GenerateDotsLen a=12 b=$diskBad]
:set msg "$msg%0ABad Blocks$tmpStr$diskBad %"
:set tmpStr [$GenerateDotsLen a=9 b=$pubIP]
:set msg "$msg%0APublic IP$tmpStr$pubIP"
:set tmpStr [$GenerateDotsLen a=16 b=$activePPP]
:set msg "$msg%0APPP Active Users$tmpStr$activePPP"
:set tmpStr [$GenerateDotsLen a=22 b=$wgActiveCount]
:set msg "$msg%0AWireGuard Active Users$tmpStr$wgActiveCount"
:set msg "$msg</pre>"

# Firewall rules
#:set msg "$msg%0A%0A<b>Firewall Rules %F0%9F%94%A5</b>"
#:local examplefwruleFind [/ip firewall filter find comment="Comment of the rule"]
#:if ([:len $examplefwruleFind] > 0) do={
#  :if ([/ip firewall filter get $examplefwruleFind disabled]) do={:set msg "$msg%0AFW Rule: <i>OFF</i>"} else={:set msg "$msg%0AFW Rule: <i>ON</i>"}
#} else={
#  :set msg "$msg%0AFW Rule: <i>Not Found</i>"
#}

# Firewall NAT rules
#:set msg "$msg%0A%0A<b>NAT Firewall Rules %F0%9F%94%A5</b>"
#:local port80ruleFind [/ip firewall nat find comment="Comment of the nat rule"]
#:if ([:len $port80ruleFind] > 0) do={
#  :if ([/ip firewall nat get $port80ruleFind disabled]) do={:set msg "$msg%0APort 80: <i>OFF</i>"} else={:set msg "$msg%0APort 80: <i>ON</i>"}
#} else={
#  :set msg "$msg%0APort 80: <i>Not Found</i>"
#}

# Queues
#:set msg "$msg%0A%0A<b>Band Limits Queues %F0%9F%93%89</b>"
#:local qnet1Find [/queue simple find comment="Comment of queue"]
#:if ([:len $qnet1Find] > 0) do={
#  :if ([/queue simple get $qnet1Find disabled]) do={:set msg "$msg%0ABand Limit test: <i>OFF</i>"} else={:set msg "$msg%0ABand Limit test: <i>ON</i>"}
#} else={
#  :set msg "$msg%0ABand Limit test: <i>Not Found</i>"
#}

# Send Message to Telegram
/tool fetch url=("https://api.telegram.org/bot" . $TToken . "/sendMessage") http-method=post http-data=("chat_id=" . $TChatId . "&text=" . $msg . "&parse_mode=HTML") output=none
