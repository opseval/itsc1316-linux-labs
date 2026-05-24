#!/usr/bin/env bash
#
# setup-netfund.sh  —  Module 9: Networking Fundamentals
#
# Run this INSIDE your labvm (no sudo needed):
#     bash setup-netfund.sh
#
# This lab is investigation-based, so setup is light: it drops a fill-in
# report template in your home directory. You complete it as you work.
#
set -euo pipefail

REPORT="$HOME/module9-network-report.txt"

cat > "$REPORT" <<'EOF'
MODULE 9 — NETWORKING FUNDAMENTALS REPORT
=========================================
Name:
VM hostname (run `hostname`):

--- Part A: Identifying this machine on the network ---
Primary network interface name (from `ip a`):       <fill in>
This VM's IP address (from `ip a` or `hostname -I`): <fill in>
Paste the relevant line(s) of `ip a` here (the whole `enp0s1` stanza is fine — link, mac, inet, inet6, valid_lft — 4-5 lines):
<paste>

--- Part B: How traffic leaves this machine ---
Default gateway (from `ip route`):                  <fill in>
In one sentence, what does the default route do?    <fill in>

--- Part C: Layered connectivity tests (paste the result of each) ---
1) ping the gateway (local network reachable?):     <paste 1 line>
2) ping 1.1.1.1   (internet reachable by IP?):       <paste 1 line>
3) ping ubuntu.com (name resolution working?):       <paste 1 line>

--- Part D: Reasoning ---
If ping 1.1.1.1 SUCCEEDS but ping ubuntu.com FAILS, what is broken,
and what is fine? (2-3 sentences):
<fill in>

Name two common causes of "I can't reach the network" and how you'd
check each (2-3 sentences):
<fill in>
EOF

echo "[setup] Created report template: $REPORT"
echo "[setup] Work through the lab and fill it in. Grade with: bash check-netfund.sh"
