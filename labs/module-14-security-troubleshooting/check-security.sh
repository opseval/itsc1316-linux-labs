#!/usr/bin/env bash
#
# check-security.sh  —  Module 14: Security & Troubleshooting Foundations
#
# Self-grades your remediation. Run it:
#     bash check-security.sh
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

mode() { stat -c '%a' "$1" 2>/dev/null; }

echo "=== Module 14 Lab Check: Security & Troubleshooting ==="
echo

# --- Integrity self-check (tamper-evident; auto-compares against canonical CHECKSUMS.txt) ---
# Resets PATH and uses absolute binaries so a PATH-shimmed `curl`/`sha256sum`
# can't spoof VERIFIED on a tampered script. The recording is where the grader
# reads the printed INTEGRITY: line (tamper-evident, not tamper-proof).
echo "=== check script integrity ==="
INTEGRITY_REL_PATH="labs/module-14-security-troubleshooting/check-security.sh"
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

# 1. SUID bit removed from /usr/local/bin/backup-helper
if [[ -f /usr/local/bin/backup-helper ]]; then
  m=$(mode /usr/local/bin/backup-helper)
  # 4-digit mode beginning with a 4 (or 6,7) means SUID set. Pass if no leading SUID.
  if [[ "${#m}" -le 3 ]]; then
    ok "backup-helper no longer has the SUID bit set (mode $m)"
  else
    lead="${m:0:1}"
    if (( (lead & 4) == 0 )); then
      ok "backup-helper no longer has the SUID bit set (mode $m)"
    else
      no "backup-helper still has the SUID bit set (mode $m) — remove it"
    fi
  fi
else
  ok "backup-helper was removed entirely (also an acceptable fix)"
fi

# 2. /opt/payroll/salaries.csv: owned by root:root AND not readable or writable
#    by GROUP or OTHERS. The lab says "only root" should read/write, so the
#    owner must actually be root (mode 600 owned by ubuntu still gives ubuntu
#    full access — that's not "only root").
owner_of() { stat -c '%U' "$1" 2>/dev/null; }
group_of() { stat -c '%G' "$1" 2>/dev/null; }
if [[ -f /opt/payroll/salaries.csv ]]; then
  m=$(mode /opt/payroll/salaries.csv)
  ow=$(owner_of /opt/payroll/salaries.csv)
  gr=$(group_of /opt/payroll/salaries.csv)
  # Zero-pad — `stat -c '%a'` strips leading zeros, so a mode like 040 prints
  # as '40' and would leave the digit slices below empty.
  m_padded=$(printf '%03d' "$m")
  perms="${m_padded: -3}"
  group_digit="${perms:1:1}"
  other_digit="${perms:2:1}"
  bits_locked=0
  # "Only root" means NO bits for group or others — not even execute. Mode 661
  # (sets execute for others) should fail, so check the full octal digit == 0.
  if (( other_digit == 0 && group_digit == 0 )); then bits_locked=1; fi
  if (( bits_locked == 1 )) && [[ "$ow" == "root" && "$gr" == "root" ]]; then
    ok "salaries.csv is owned by root:root and locked down from group/others (mode $m)"
  elif (( bits_locked == 0 )); then
    if (( (other_digit & 2) != 0 )); then
      no "salaries.csv is still world-writable (mode $m) — fix the permissions"
    elif (( (other_digit & 4) != 0 )); then
      no "salaries.csv is no longer world-writable but is still world-readable (mode $m) — payroll data should not be readable by others"
    elif (( (other_digit & 1) != 0 || (group_digit & 1) != 0 )); then
      no "salaries.csv still has an execute bit set for group or other (mode $m) — for a data file, group/other should be 0"
    else
      no "salaries.csv is still group-readable or group-writable (mode $m) — 'only root' means group bits must be 0 too"
    fi
  else
    no "salaries.csv permissions look OK but ownership is $ow:$gr — for 'only root' the owner must be root:root"
  fi
else
  no "salaries.csv is missing — it should exist but be properly secured, not deleted"
fi

# 3. The CPU-hogging sysoptimizer process is stopped
if pgrep -f '/usr/local/bin/sysoptimizer' >/dev/null 2>&1; then
  no "the runaway 'sysoptimizer' process is still running — find and stop it"
else
  ok "the runaway 'sysoptimizer' process has been stopped"
fi

# 4. The broken reportd service is no longer in an active/failed state AND
#    will not auto-start. Acceptable fixes: stop+disable it, or mask it.
#    Also explicitly check that the unit isn't in 'failed' state — a unit
#    that has been disabled but is still failed leaves a red mark in
#    `systemctl --failed` and is not actually remediated.
active=$(systemctl is-active reportd.service 2>/dev/null || true)
enabled=$(systemctl is-enabled reportd.service 2>/dev/null || true)
failed=$(systemctl is-failed reportd.service 2>/dev/null || true)
if [[ "$active" == "active" || "$active" == "activating" ]]; then
  no "reportd.service is still trying to run (active=$active) — investigate with journalctl and stop it"
elif [[ "$failed" == "failed" ]]; then
  no "reportd.service has been stopped but is still in failed state — run 'sudo systemctl reset-failed reportd.service' after disabling/masking it"
elif [[ "$enabled" == "disabled" || "$enabled" == "masked" || -z "$enabled" || "$enabled" == "static" ]]; then
  ok "reportd.service is no longer running, not failed, and won't auto-start (active=$active enabled=$enabled)"
else
  no "reportd.service is stopped but still enabled — disable or mask it (enabled=$enabled)"
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
