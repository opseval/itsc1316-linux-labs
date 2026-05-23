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

# The invoking (default) user is 'ubuntu' on Multipass but can be different on a
# cloud-fallback VM. Use whoever is logged in as the expected owner so the check
# is meaningful on both setups.
LAB_USER="${SUDO_USER:-$(id -un)}"

# Helpers
owner() { stat -c '%U' "$1" 2>/dev/null; }
group() { stat -c '%G' "$1" 2>/dev/null; }
mode()  { stat -c '%a' "$1" 2>/dev/null; }

echo "=== Module 6 Lab Check: Users, Ownership, and Permissions ==="
echo

# --- Integrity self-check (tamper-evident; auto-compares against canonical CHECKSUMS.txt) ---
# Resets PATH and uses absolute binaries so a PATH-shimmed `curl`/`sha256sum`
# can't spoof VERIFIED on a tampered script. The recording is where the grader
# reads the printed INTEGRITY: line (tamper-evident, not tamper-proof).
echo "=== check script integrity ==="
INTEGRITY_REL_PATH="labs/module-06-users-and-permissions/check-users.sh"
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

# 1. /salesteam owned by ${LAB_USER}:salesteam
if [[ "$(owner /salesteam)" == "$LAB_USER" && "$(group /salesteam)" == "salesteam" ]]; then
  ok "/salesteam is owned by ${LAB_USER}:salesteam"
else
  no "/salesteam should be owned by ${LAB_USER}:salesteam (found $(owner /salesteam):$(group /salesteam))"
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
  if (( perm_ok == 1 )) && [[ "$o_user" == "$LAB_USER" && "$o_group" == "salesteam" ]]; then
    ok "generate_reports.sh is owner-only executable and non-writable by others, owned by ${LAB_USER}:salesteam (mode $m)"
  elif (( perm_ok == 0 )); then
    no "generate_reports.sh: owner needs read AND execute; group AND other must have neither execute nor write (mode $m)"
  else
    no "generate_reports.sh permissions are right but ownership is $o_user:$o_group, should be ${LAB_USER}:salesteam"
  fi
else
  no "generate_reports.sh is missing from /salesteam"
fi

# 4. The three quarterly .xls reports were produced by the script — not just
#    touched into existence. generate_reports.sh writes a line of the form
#    "Sales report for QN - generated <date>" into each file; require that
#    exact pattern so empty `touch`ed files don't pass.
bad=()
for q in Q1 Q2 Q3; do
  f="/salesteam/${q}-report.xls"
  if [[ ! -f "$f" ]]; then
    bad+=("${q}-report.xls (missing)")
  elif ! grep -q "^Sales report for ${q} - generated " "$f" 2>/dev/null; then
    bad+=("${q}-report.xls (no script-generated content)")
  fi
done
if (( ${#bad[@]} == 0 )); then
  ok "Q1/Q2/Q3 reports exist and contain script-generated content (script was actually run)"
else
  no "Report problems: ${bad[*]} — run ./generate_reports.sh from inside /salesteam"
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
