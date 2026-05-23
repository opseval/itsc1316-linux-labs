#!/usr/bin/env bash
#
# check-netfund.sh  —  Module 9: Networking Fundamentals
#
# Run inside labvm:   bash check-netfund.sh
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

REPORT="$HOME/module9-network-report.txt"

echo "=== Module 9 Lab Check: Networking Fundamentals ==="
echo

# 1. A default route exists (basic routing sanity / Part B).
if ip route 2>/dev/null | grep -q '^default '; then
  gw=$(ip route | awk '/^default/ {print $3; exit}')
  ok "A default route exists (gateway $gw)"
else
  no "No default route found — your VM has no way to reach other networks"
fi

# 2. The VM can resolve an external name (proves the network actually works,
#    which is the baseline a fundamentals student needs).
if getent hosts ubuntu.com >/dev/null 2>&1; then
  ok "External name resolution works (ubuntu.com resolves)"
else
  no "Cannot resolve ubuntu.com — check your network/VPN"
fi

# 3. The report exists.
if [[ -f "$REPORT" ]]; then
  ok "Report file exists ($REPORT)"
else
  no "Report file $REPORT is missing — run setup-netfund.sh, then fill it in"
  echo; echo "  Passed: $pass  Failed: $fail"; exit 1
fi

# 4. Report is personalized with THIS VM's real hostname (not fakeable).
host="$(hostname)"
if grep -qF "$host" "$REPORT"; then
  ok "Report contains this VM's real hostname ($host)"
else
  no "Report does not contain this VM's hostname ($host) — fill in the hostname line with your own output"
fi

# 5. Report contains this VM's real IP address (anchors the work to this system).
#    Take the first global IPv4 from `hostname -I`.
myip="$(hostname -I 2>/dev/null | awk '{print $1}')"
if [[ -n "$myip" ]] && grep -qF "$myip" "$REPORT"; then
  ok "Report contains this VM's real IP address ($myip)"
else
  no "Report does not contain this VM's IP ($myip) — record the address you found with 'ip a' / 'hostname -I'"
fi

# 6. Report no longer has unfilled placeholders.
if grep -qE '<fill in>|<paste>' "$REPORT"; then
  no "Report still has <fill in> / <paste> placeholders — complete every section"
else
  ok "All report placeholders have been filled in"
fi

# 7. The reasoning sections have real prose (not left blank).
words=$(wc -w < "$REPORT")
if (( words >= 90 )); then
  ok "Report has substantive written content ($words words)"
else
  no "Report is too short ($words words) — the Part D reasoning needs real explanation"
fi

echo
echo "-----------------------------------------------"
echo "  Passed: $pass    Failed: $fail"
if (( fail == 0 )); then
  echo "  ALL CHECKS PASSED. Record your Zoom screen recording and submit."
  echo "-----------------------------------------------"
  exit 0
else
  echo "  Not done yet — fix the FAILs above and run me again."
  echo "-----------------------------------------------"
  exit 1
fi
