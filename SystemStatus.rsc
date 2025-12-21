# ============================================================================================================
# Script Name:   SystemStatus.rsc
# Author:        CtrlAltJon
# Descrizione:   Script to send MikroTik System Status to Telegram
#
# Copyright (c) 2025 CtrlAltJon
# Rilasciato sotto licenza MIT (https://opensource.org/licenses/MIT)
# ============================================================================================================

# Function - Generate String of dots for middle space from Name ad Value
:local GenerateDotsLen do={:return [:pick "........................................" 0 [:put (32 - $a - [:len "$b"])]]}

# Import Telegram configuration from other file script
:local filecfg [:parse [/system script get TelegramConfig source]]
:local cfg [$filecfg]
:local TToken ($cfg->"TToken")
:local TChatId ($cfg->"TChatId")

# Locals
:local msg "*Mikrotik - System Status* %E2%84%B9%0A```"
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
:local pubIP [:tostr [:pick [:toarray ([/tool fetch url="https://api.db-ip.com/v2/free/self/ipAddress" output=user as-value])] 0]]
:local activePPP [:len [/ppp active find]]

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
:set msg "$msg```"

# Send Message to Telegram
/tool fetch "https://api.telegram.org/bot$TToken/sendMessage\?chat_id=$TChatId&text=$msg&parse_mode=markdown" keep-result=no

# Firewall rules
#:set msg "%0A%0A*Firewall Rules %F0%9F%94%A5*"
#:local examplefwrule [/ip firewall get [find comment="Comment of the rule"] disabled]
#:if ($examplefwrule) do={:set msg "$msg%0AFW Rule: _OFF_"} else={:set msg "$msg%0AFW Rule: _ON_"}

# Firewall NAT rules
#:set msg "%0A%0A*NAT Firewall Rules %F0%9F%94%A5*"
#:local port80rule [/ip firewall nat get [find comment="Comment of the nat rule"] disabled]
#:if ($port80rule) do={:set msg "$msg%0APort 80: _OFF_"} else={:set msg "$msg%0APort 80: _ON_"}

# Queues
#:local msg "%0A%0A*Band Limits Queues %F0%9F%93%89*"
#:local qnet1 [/queue simple get [find comment="Comment of queue"] disabled]
#:if ($qnet1) do={ :set msg "$msg%0ABand Limit test: _OFF_" } else={ :set msg "$msg%0ABand Limit test: _ON_" }

