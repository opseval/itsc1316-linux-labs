#!/usr/bin/env bash
#
# check-net.sh  —  Modules 9 & 13: Advanced Network Configuration
#
# Run inside labvm:   bash check-net.sh
# The second VM ("fileserver") must be running for the name-resolution
# checks to pass — that is the point.
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

echo "=== Modules 9 & 13 Lab Check: Advanced Network Configuration ==="
echo

# 1. There is a default route (basic routing sanity).
if ip route | grep -q '^default '; then
  gw=$(ip route | awk '/^default/ {print $3; exit}')
  ok "A default route exists (gateway $gw)"
else
  no "No default route found — your VM cannot reach other networks"
fi

# 2. /etc/hosts has a fileserver entry that is NO LONGER the bogus address,
#    NOT loopback (a common "cheat" that makes ping succeed without finding
#    the real second VM), and NOT broadcast/all-zeros.
BOGUS_IP="192.0.2.123"
if grep -qE '[[:space:]]fileserver([[:space:]]|$)' /etc/hosts; then
  ip_for_name=$(getent hosts fileserver | awk '{print $1; exit}')
  if [[ -z "$ip_for_name" ]]; then
    no "'fileserver' is in /etc/hosts but does not resolve — check the line format"
  elif [[ "$ip_for_name" == "$BOGUS_IP" ]]; then
    no "'fileserver' still resolves to the bogus $BOGUS_IP — replace it with the real IP from 'multipass list'"
  elif [[ "$ip_for_name" =~ ^127\. ]]; then
    no "'fileserver' resolves to loopback ($ip_for_name) — that pings, but it's not the real second VM"
  elif [[ "$ip_for_name" == "0.0.0.0" || "$ip_for_name" == "255.255.255.255" ]]; then
    no "'fileserver' resolves to $ip_for_name, which isn't a real host — use the IP from 'multipass list'"
  else
    ok "'fileserver' resolves to $ip_for_name (no longer the bogus address)"
  fi
else
  no "No 'fileserver' entry found in /etc/hosts"
fi

# 3. fileserver is reachable BY NAME (proves the mapping is correct AND the
#    second VM is up). This is the real end-to-end test.
if ping -c1 -W2 fileserver >/dev/null 2>&1; then
  ok "fileserver responds to ping by name (name resolution + connectivity both work)"
else
  no "Cannot ping 'fileserver' by name — is the second VM running, and is the IP correct?"
fi

# 4. Confirm the student can resolve an EXTERNAL name too (DNS works at all).
if getent hosts ubuntu.com >/dev/null 2>&1; then
  ok "External DNS resolution works (ubuntu.com resolves)"
else
  no "External name resolution is failing — check /etc/resolv.conf / systemd-resolved"
fi

echo
echo "-----------------------------------------------"
echo "  Passed: $pass    Failed: $fail"
if (( fail == 0 )); then
  echo "  ALL CHECKS PASSED. Record your Zoom screen recording and submit."
  echo "-----------------------------------------------"
  exit 0
else
  echo "  Not done yet — investigate the FAILs above and run me again."
  echo "-----------------------------------------------"
  exit 1
fi
