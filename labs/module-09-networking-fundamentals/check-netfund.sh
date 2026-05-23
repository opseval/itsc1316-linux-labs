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

# --- Integrity self-check (auto-compares against canonical CHECKSUMS.txt on GitHub) ---
echo "=== check script integrity ==="
INTEGRITY_REL_PATH="labs/module-09-networking-fundamentals/check-netfund.sh"
INTEGRITY_REPO_URL="https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main"
echo "  Script:      $(basename "$0")"
if command -v sha256sum >/dev/null 2>&1; then
  LOCAL_SHA="$(sha256sum "$0" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  LOCAL_SHA="$(shasum -a 256 "$0" | awk '{print $1}')"
else
  LOCAL_SHA=""
fi
echo "  Local SHA:   ${LOCAL_SHA:-(no sha256sum/shasum available)}"
EXPECTED_SHA="$(curl -fsSL --max-time 10 "$INTEGRITY_REPO_URL/labs/CHECKSUMS.txt" 2>/dev/null \
  | awk -v p="$INTEGRITY_REL_PATH" '$2==p {print $1; exit}')"
if [[ -z "$EXPECTED_SHA" ]]; then
  echo "  Canonical:   (could not fetch — check network; compare manually at"
  echo "                 $INTEGRITY_REPO_URL/labs/CHECKSUMS.txt )"
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
