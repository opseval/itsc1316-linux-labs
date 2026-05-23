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

# 2. meeting-highlights.txt exists, is non-empty, has mode 660, AND is group-owned
#    by salesteam (mode alone isn't enough — if the group isn't salesteam, teammates
#    can't use it; and the lab specifically asks students to put a line in the file).
if [[ -s /salesteam/meeting-highlights.txt ]]; then
  m=$(mode /salesteam/meeting-highlights.txt)
  g=$(group /salesteam/meeting-highlights.txt)
  if [[ "$m" == "660" && "$g" == "salesteam" ]]; then
    ok "meeting-highlights.txt has mode 660 and group 'salesteam' (sales team can collaborate)"
  elif [[ "$m" != "660" ]]; then
    no "meeting-highlights.txt should be mode 660 (found $m)"
  else
    no "meeting-highlights.txt has mode 660 but is group '$g', not 'salesteam' — the team can't access it"
  fi
elif [[ -f /salesteam/meeting-highlights.txt ]]; then
  no "meeting-highlights.txt exists but is empty — the lab asks you to put a line of text in it"
else
  no "meeting-highlights.txt does not exist in /salesteam"
fi

# 3. generate_reports.sh: executable by OWNER only AND owned by ubuntu:salesteam.
#    Just adding +x while leaving root as owner leaks privilege via the existing
#    setup state, so we check ownership too.
if [[ -f /salesteam/generate_reports.sh ]]; then
  m=$(mode /salesteam/generate_reports.sh)
  o_user=$(owner /salesteam/generate_reports.sh)
  o_group=$(group /salesteam/generate_reports.sh)
  # Zero-pad to at least 3 digits — `stat -c '%a'` strips leading zeros
  # (mode 040 prints as '40'), which would leave the digit slices below empty
  # and crash the arithmetic.
  m_padded=$(printf '%03d' "$m")
  perms="${m_padded: -3}"
  o="${perms:0:1}"   # owner digit
  g="${perms:1:1}"   # group digit
  t="${perms:2:1}"   # other digit
  # Required: owner has BOTH read (4) and execute (1) — the lab says keep
  # the script readable, so mode 100 (--x------) isn't acceptable even
  # though it's "executable by owner only". Group: no write, no execute.
  # Other: no write, no execute. A mode like 722 would slip past an
  # execute-only check while still letting anyone overwrite the script.
  perm_ok=0
  if (( (o & 5) == 5 && (g & 3) == 0 && (t & 3) == 0 )); then perm_ok=1; fi
  if (( perm_ok == 1 )) && [[ "$o_user" == "ubuntu" && "$o_group" == "salesteam" ]]; then
    ok "generate_reports.sh is owner-only executable and non-writable by others, owned by ubuntu:salesteam (mode $m)"
  elif (( perm_ok == 0 )); then
    no "generate_reports.sh: owner needs read AND execute; group AND other must have neither execute nor write (mode $m)"
  else
    no "generate_reports.sh permissions are right but ownership is $o_user:$o_group, should be ubuntu:salesteam"
  fi
else
  no "generate_reports.sh is missing from /salesteam"
fi

# 4. The three quarterly .xls reports were produced (script was actually run).
#    Check the exact filenames the script generates — not just any Q*-report
#    glob — so manually-touched files like Qx-report.xls don't slip through.
missing=()
for q in Q1 Q2 Q3; do
  [[ -f "/salesteam/${q}-report.xls" ]] || missing+=("${q}-report.xls")
done
if (( ${#missing[@]} == 0 )); then
  ok "Q1-report.xls, Q2-report.xls, Q3-report.xls all exist (script was executed)"
else
  no "Missing in /salesteam: ${missing[*]} — did you actually run generate_reports.sh?"
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
