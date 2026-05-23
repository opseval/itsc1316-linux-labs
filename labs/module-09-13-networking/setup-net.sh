#!/usr/bin/env bash
#
# setup-net.sh  —  Module 13: Advanced Network Configuration
#
# Run this INSIDE your labvm with sudo, AFTER you have launched the second
# VM (see the lab instructions):
#     sudo bash setup-net.sh
#
# It plants a broken name-resolution scenario: a /etc/hosts entry that maps
# the name "fileserver" to the WRONG IP address. Your job in the lab is to
# diagnose that this is a name-resolution problem (not a connectivity
# problem) and correct the mapping.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash setup-net.sh"
  exit 1
fi

MARKER="# lab13-fileserver"

echo "[setup] Planting a misconfigured hosts entry for 'fileserver'..."

# Remove any prior lab entry so the script is re-runnable.
sed -i "/${MARKER}/d" /etc/hosts

# Add a deliberately WRONG mapping (an unreachable address).
echo "10.99.99.99    fileserver    ${MARKER}" >> /etc/hosts

echo
echo "[setup] Done. Your /etc/hosts now claims 'fileserver' lives at"
echo "        10.99.99.99, which is wrong. Use the lab instructions to"
echo "        investigate and fix it."
echo "        Grade yourself with:  bash check-net.sh"
