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

# --- Integrity self-check (tamper-evident; auto-compares against canonical CHECKSUMS.txt) ---
# Resets PATH and uses absolute binaries so a PATH-shimmed `curl`/`sha256sum`
# can't spoof VERIFIED on a tampered script. The recording is where the grader
# reads the printed INTEGRITY: line (tamper-evident, not tamper-proof).
echo "=== check script integrity ==="
INTEGRITY_REL_PATH="labs/module-13-advanced-networking/check-net.sh"
INTEGRITY_REPO_URL="https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main"
__SAVED_PATH="$PATH"; PATH="/usr/bin:/bin"; unset -f curl sha256sum shasum awk 2>/dev/null
echo "  Script:      $(basename "$0")"
if [[ -x /usr/bin/sha256sum ]]; then
  LOCAL_SHA="$(/usr/bin/sha256sum "$0" | /usr/bin/awk '{print $1}')"
elif [[ -x /usr/bin/shasum ]]; then
  LOCAL_SHA="$(/usr/bin/shasum -a 256 "$0" | /usr/bin/awk '{print $1}')"
else
  LOCAL_SHA=""
fi
echo "  Local SHA:   ${LOCAL_SHA:-(no sha256sum/shasum available)}"
CANONICAL_TXT=""
[[ -x /usr/bin/curl ]] && CANONICAL_TXT="$(/usr/bin/curl -fsSL --max-time 10 "$INTEGRITY_REPO_URL/labs/CHECKSUMS.txt" 2>/dev/null)"
if [[ -z "$CANONICAL_TXT" ]]; then
  echo "  Canonical:   (could not fetch CHECKSUMS.txt — no network or curl missing)"
  echo "  INTEGRITY:   UNKNOWN — fix the network and re-run; canonical is at"
  echo "                 $INTEGRITY_REPO_URL/labs/CHECKSUMS.txt"
else
  EXPECTED_SHA="$(printf '%s
' "$CANONICAL_TXT" | /usr/bin/awk -v p="$INTEGRITY_REL_PATH" '$2==p {print $1; exit}')"
  if [[ -z "$EXPECTED_SHA" ]]; then
    echo "  Canonical:   (no matching line in CHECKSUMS.txt for $INTEGRITY_REL_PATH)"
    echo "  INTEGRITY:   UNKNOWN — re-fetch this script:"
    echo "                 curl -fsSLO $INTEGRITY_REPO_URL/$INTEGRITY_REL_PATH"
  elif [[ -z "$LOCAL_SHA" ]]; then
    echo "  Canonical:   $EXPECTED_SHA"
    echo "  INTEGRITY:   UNKNOWN — no SHA tool available to verify locally"
  elif [[ "$LOCAL_SHA" == "$EXPECTED_SHA" ]]; then
    echo "  Canonical:   $EXPECTED_SHA"
    echo "  INTEGRITY:   VERIFIED (matches canonical CHECKSUMS.txt)"
  else
    echo "  Canonical:   $EXPECTED_SHA"
    echo "  INTEGRITY:   *** MISMATCH *** — this check script differs from the canonical."
    echo "               Re-fetch: curl -fsSLO $INTEGRITY_REPO_URL/$INTEGRITY_REL_PATH"
  fi
fi
PATH="$__SAVED_PATH"; unset __SAVED_PATH CANONICAL_TXT EXPECTED_SHA LOCAL_SHA
echo

# 1. There is a default route (basic routing sanity).
if ip route | grep -q '^default '; then
  gw=$(ip route | awk '/^default/ {print $3; exit}')
  ok "A default route exists (gateway $gw)"
else
  no "No default route found — your VM cannot reach other networks"
fi

# 2. /etc/hosts has a fileserver entry that is NO LONGER the bogus address,
#    NOT loopback / broadcast (which would ping without proving anything),
#    NOT labvm's own IP, and NOT the default gateway. Each of those is a
#    plausible "cheat" that turns ping into a green check without ever
#    contacting the real second VM.
BOGUS_IP="192.0.2.123"
local_ips=$(ip -o -4 addr show 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | sort -u)
gateway_ip=$(ip route 2>/dev/null | awk '/^default/ {print $3; exit}')
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
  elif [[ -n "$gateway_ip" && "$ip_for_name" == "$gateway_ip" ]]; then
    no "'fileserver' resolves to the default gateway ($ip_for_name) — that pings, but it's not the second VM"
  elif printf '%s\n' "$local_ips" | grep -qFx "$ip_for_name"; then
    no "'fileserver' resolves to one of labvm's OWN IPs ($ip_for_name) — pinging yourself doesn't prove the second VM is reachable"
  elif ! [[ "$ip_for_name" =~ ^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.) ]]; then
    # Multipass always issues private RFC 1918 addresses (10.x on macOS, 192.168.x
    # on common Windows/QEMU configs, occasionally 172.16-31.x). A public IP
    # cannot be a real Multipass fileserver — most likely the student mapped it
    # to a random reachable host on the internet to fake a green check.
    no "'fileserver' resolves to $ip_for_name, which is a public address — Multipass VMs always get private IPs (10.x / 192.168.x / 172.16-31.x). Use the IP from 'multipass list'."
  else
    ok "'fileserver' resolves to $ip_for_name (no longer the bogus address, not local/gateway, in a Multipass-plausible private range)"
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
