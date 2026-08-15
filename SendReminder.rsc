# ============================================================================================================
# Script Name:   WireGuardMonitor.rsc
# Author:        CtrlAltJon
# Descrizione:   Script to monitor a WireGuard peer and send a notification to Telegram if it's down.
#
# Copyright (c) 2026 CtrlAltJon
# Released under the MIT License (https://opensource.org/licenses/MIT)
# ============================================================================================================

# ------------------------------------------------------------------------------------------------------------
# --- USER CONFIGURATION ---
# ------------------------------------------------------------------------------------------------------------
# Set the exact comment of the WireGuard peer you want to monitor.
# Example: go to Winbox -> WireGuard -> Peers, open the peer, and in the "Comment" field write "VPN_SERVER_MONITOR".
:local wgPeerComment "WG_CasteloSanta"

# ------------------------------------------------------------------------------------------------------------
# --- SCRIPT START ---
# ------------------------------------------------------------------------------------------------------------

# Import Telegram configuration (TToken and TChatId)
:local telegramConfigFile [:parse [/system script get TelegramConfig source]]
:local telegramConfig [$telegramConfigFile]
:local telegramToken ($telegramConfig->"TToken")
:local telegramChatId ($telegramConfig->"TChatId")

# Find the WireGuard peer based on the comment
:local peerToMonitor [/interface wireguard peers find comment=$wgPeerComment]

:if ([:len $peerToMonitor] > 0) do={
  :local lastHandshake [/interface wireguard peers get $peerToMonitor last-handshake]
    
  # If the handshake is older than 3 minutes (180 seconds), connection is considered down
  :if ([:len $lastHandshake] = 0 || $lastHandshake > 3m) do={    
    # Check for general internet connectivity before sending an alert.
    :if ([/ping 8.8.8.8 count=1] = 1) do={
      :local routerName [/system identity get name]
      :local message "<b>Test</b>%0A%0A"
      :set message ($message . "UDM offline.%0A")
      
      # Send the message to Telegram
      /tool fetch url=("https://api.telegram.org/bot" . $telegramToken . "/sendMessage") http-method=post http-data=("chat_id=" . $telegramChatId . "&text=" . $message . "&parse_mode=HTML") output=none
    }
  }
}
