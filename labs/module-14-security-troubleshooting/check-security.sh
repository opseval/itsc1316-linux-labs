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

# 2. /opt/payroll/salaries.csv: not readable or writable by GROUP or OTHERS.
#    The lab says "only root" should read/write, so both group and other bits
#    must be zero (mode 600 or 400 is correct; anything else fails).
if [[ -f /opt/payroll/salaries.csv ]]; then
  m=$(mode /opt/payroll/salaries.csv)
  perms="${m: -3}"
  group_digit="${perms:1:1}"
  other_digit="${perms:2:1}"
  if (( (other_digit & 6) == 0 && (group_digit & 6) == 0 )); then
    ok "salaries.csv is locked down — neither group nor others can read or write it (mode $m)"
  elif (( (other_digit & 2) != 0 )); then
    no "salaries.csv is still world-writable (mode $m) — fix the permissions"
  elif (( (other_digit & 4) != 0 )); then
    no "salaries.csv is no longer world-writable but is still world-readable (mode $m) — payroll data should not be readable by others"
  else
    no "salaries.csv is still group-readable or group-writable (mode $m) — 'only root' means group bits must be 0 too"
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

# 4. The broken reportd service is no longer in a failed/active-restarting state.
#    Acceptable fixes: stop+disable it, or mask it. We pass if it is not running
#    and not enabled.
active=$(systemctl is-active reportd.service 2>/dev/null || true)
enabled=$(systemctl is-enabled reportd.service 2>/dev/null || true)
if [[ "$active" != "active" && "$active" != "activating" ]]; then
  if [[ "$enabled" == "disabled" || "$enabled" == "masked" || -z "$enabled" || "$enabled" == "static" ]]; then
    ok "reportd.service is no longer running and won't auto-start (state: active=$active enabled=$enabled)"
  else
    no "reportd.service is stopped but still enabled — disable or mask it (enabled=$enabled)"
  fi
else
  no "reportd.service is still trying to run (active=$active) — investigate with journalctl and stop it"
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
