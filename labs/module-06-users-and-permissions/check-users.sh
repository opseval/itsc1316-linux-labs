#!/usr/bin/env bash
#
# check-users.sh  —  Module 6: Users, Ownership, and Permissions
#
# Self-grades your work. Run it (no sudo needed):
#     bash check-users.sh
#
# Prints PASS/FAIL for each requirement. Exit code is 0 only if everything
# passes. Fix any FAILs and run it again — just like re-testing a real system.
#
pass=0
fail=0

ok()   { echo "  PASS  $1"; pass=$((pass+1)); }
no()   { echo "  FAIL  $1"; fail=$((fail+1)); }

# Helpers
owner() { stat -c '%U' "$1" 2>/dev/null; }
group() { stat -c '%G' "$1" 2>/dev/null; }
mode()  { stat -c '%a' "$1" 2>/dev/null; }

echo "=== Module 6 Lab Check: Users, Ownership, and Permissions ==="
echo

# 1. /salesteam owned by ubuntu:salesteam
if [[ "$(owner /salesteam)" == "ubuntu" && "$(group /salesteam)" == "salesteam" ]]; then
  ok "/salesteam is owned by ubuntu:salesteam"
else
  no "/salesteam should be owned by ubuntu:salesteam (found $(owner /salesteam):$(group /salesteam))"
fi

# 2. meeting-highlights.txt exists with rw for user+group, nothing for others (660)
if [[ -f /salesteam/meeting-highlights.txt ]]; then
  m=$(mode /salesteam/meeting-highlights.txt)
  if [[ "$m" == "660" ]]; then
    ok "meeting-highlights.txt has mode 660 (rw for user and group, none for others)"
  else
    no "meeting-highlights.txt should be mode 660 (found $m)"
  fi
else
  no "meeting-highlights.txt does not exist in /salesteam"
fi

# 3. generate_reports.sh executable by OWNER only (others/group not executable).
#    Acceptable owner-exec modes that keep group/other non-exec: 700, 740, 750?
#    Requirement: only the owner can execute. So group-exec and other-exec must be OFF.
if [[ -f /salesteam/generate_reports.sh ]]; then
  m=$(mode /salesteam/generate_reports.sh)
  # Take the last three octal digits (handles a leading special-bit digit).
  perms="${m: -3}"
  o="${perms:0:1}"   # owner digit
  g="${perms:1:1}"   # group digit
  t="${perms:2:1}"   # other digit
  # Execute bit is the 1's place of each octal digit.
  if (( (o & 1) == 1 && (g & 1) == 0 && (t & 1) == 0 )); then
    ok "generate_reports.sh is executable by the owner only (mode $m)"
  else
    no "generate_reports.sh should be executable by the owner only (mode $m: owner-exec on, group/other-exec off)"
  fi
else
  no "generate_reports.sh is missing from /salesteam"
fi

# 4. The three quarterly .xls reports were produced (script was actually run)
count=$(ls /salesteam/Q*-report.xls 2>/dev/null | wc -l)
if (( count == 3 )); then
  ok "Three quarterly .xls reports exist (script was executed)"
else
  no "Expected three Q*-report.xls files in /salesteam (found $count) — did you run the script?"
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
