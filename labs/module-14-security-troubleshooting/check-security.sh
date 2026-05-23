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
  if (( (other_digit & 6) == 0 && (group_digit & 6) == 0 )); then bits_locked=1; fi
  if (( bits_locked == 1 )) && [[ "$ow" == "root" && "$gr" == "root" ]]; then
    ok "salaries.csv is owned by root:root and locked down from group/others (mode $m)"
  elif (( bits_locked == 0 )); then
    if (( (other_digit & 2) != 0 )); then
      no "salaries.csv is still world-writable (mode $m) — fix the permissions"
    elif (( (other_digit & 4) != 0 )); then
      no "salaries.csv is no longer world-writable but is still world-readable (mode $m) — payroll data should not be readable by others"
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
