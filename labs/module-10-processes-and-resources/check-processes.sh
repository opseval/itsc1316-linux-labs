#!/usr/bin/env bash
#
# check-processes.sh  —  Module 10: Processes and System Resources
#
# Self-grades your work. Run it (no sudo needed):
#     bash check-processes.sh
#
# Prints PASS/FAIL for each requirement. Exit code is 0 only if everything
# passes. Fix any FAILs and run it again — just like re-testing a real system.
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

HOST="$(hostname)"
REPORT="${HOME}/module10-process-report.txt"

echo "=== Module 10 Lab Check: Processes and System Resources ==="
echo

# --- Integrity self-check (tamper-evident; auto-compares against canonical CHECKSUMS.txt) ---
# Resets PATH and uses absolute binaries so a PATH-shimmed `curl`/`sha256sum`
# can't spoof VERIFIED on a tampered script. The recording is where the grader
# reads the printed INTEGRITY: line (tamper-evident, not tamper-proof).
echo "=== check script integrity ==="
INTEGRITY_REL_PATH="labs/module-10-processes-and-resources/check-processes.sh"
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

# ---------------------------------------------------------------------------
# 1. The runaway CPU hog 'labhog-runaway' is no longer running. This is real
#    system state: pgrep must find nothing matching it.
# ---------------------------------------------------------------------------
if pgrep -f 'labhog-runaway' >/dev/null 2>&1; then
  hogpid="$(pgrep -f 'labhog-runaway' | head -n1)"
  no "the runaway process 'labhog-runaway' is STILL running (PID $hogpid) — find it (top/ps/pgrep) and stop it (kill $hogpid)"
else
  ok "the runaway 'labhog-runaway' process is no longer running (you found and stopped it)"
fi

# ---------------------------------------------------------------------------
# 2. The evidence report exists and contains THIS machine's hostname.
# ---------------------------------------------------------------------------
report_exists=0
if [[ -f "$REPORT" ]]; then
  report_exists=1
  if grep -qw "$HOST" "$REPORT" 2>/dev/null; then
    ok "report includes this machine's hostname ($HOST) — built from your own VM"
  else
    no "report does not contain this machine's hostname ($HOST) — add the output of 'hostname' to $REPORT"
  fi
else
  no "evidence report $REPORT is missing — create it as described in the lab"
fi

# ---------------------------------------------------------------------------
# 3. The report documents HOW the student found the hog: it must name the
#    offending process ('labhog-runaway'), record a PID (any number), and name
#    at least one discovery command (top / ps / pgrep). This proves they did
#    the investigation rather than just blindly killing something.
# ---------------------------------------------------------------------------
if (( report_exists == 1 )); then
  named_hog=0; has_pid=0; named_tool=0
  grep -qw 'labhog-runaway' "$REPORT" 2>/dev/null && named_hog=1
  # A PID must be explicitly labeled, not just "any multi-digit number anywhere".
  # Accept "PID 1234", "PID:1234", "pid=1234", "pid is 1234" etc. (case-insensitive).
  grep -Eqi '\bpid\b[^[:alnum:]]{0,5}[0-9]{2,}' "$REPORT" 2>/dev/null && has_pid=1
  grep -Eqi '\b(top|ps|pgrep)\b' "$REPORT" 2>/dev/null && named_tool=1
  if (( named_hog == 1 && has_pid == 1 && named_tool == 1 )); then
    ok "report documents the offending process name, a PID, and the command used to find it"
  elif (( named_hog == 0 )); then
    no "report should name the offending process ('labhog-runaway') in the 'how I found it' section"
  elif (( has_pid == 0 )); then
    no "report should record the PID of the runaway process you found"
  else
    no "report should name the command you used to find the hog (top, ps, or pgrep)"
  fi
fi

# ---------------------------------------------------------------------------
# 4. The report captures real resource-monitoring output. Look for fingerprints
#    of `ps aux` (a USER ... %CPU %MEM header or a recognizable process row),
#    `free -h` (its 'Mem:' line), and a load average (from uptime/top).
# ---------------------------------------------------------------------------
if (( report_exists == 1 )); then
  ps_ok=0; free_ok=0; load_ok=0
  # ps aux header has columns USER PID %CPU %MEM ...; accept the header OR any
  # row that contains a typical command path/owner. Match the distinctive
  # "%CPU" / "%MEM" tokens or the USER+PID header.
  if grep -Eq '%CPU|%MEM' "$REPORT" 2>/dev/null \
     || grep -Eq '^USER[[:space:]]+PID' "$REPORT" 2>/dev/null \
     || grep -Eq '^[A-Za-z0-9_+-]+[[:space:]]+[0-9]+[[:space:]]' "$REPORT" 2>/dev/null; then
    ps_ok=1
  fi
  # free -h prints a 'Mem:' line.
  grep -Eq '^[[:space:]]*Mem:' "$REPORT" 2>/dev/null && free_ok=1
  # load average appears as "load average:" (uptime / top header).
  grep -Eqi 'load average' "$REPORT" 2>/dev/null && load_ok=1
  if (( ps_ok == 1 && free_ok == 1 && load_ok == 1 )); then
    ok "report captures process listing, 'free -h' memory output, and a load average"
  elif (( ps_ok == 0 )); then
    no "report needs process-listing output — paste 'ps aux | head' (should show %CPU/%MEM columns)"
  elif (( free_ok == 0 )); then
    no "report needs memory output — paste 'free -h' (it prints a 'Mem:' line)"
  else
    no "report needs a load average — paste 'uptime' or the top header (it shows 'load average:')"
  fi
fi

# ---------------------------------------------------------------------------
# 5. The report shows nice/renice practice: evidence the student started a
#    process with `nice` and changed it with `renice`. Look for both keywords
#    plus a niceness value (NI column or a number argument).
# ---------------------------------------------------------------------------
if (( report_exists == 1 )); then
  nice_ok=0; renice_ok=0
  grep -Eqi '\bnice\b' "$REPORT" 2>/dev/null && nice_ok=1
  # renice prints lines like: "old priority 10, new priority 15"
  if grep -Eqi '\brenice\b' "$REPORT" 2>/dev/null \
     || grep -Eqi 'old priority .*new priority' "$REPORT" 2>/dev/null; then
    renice_ok=1
  fi
  if (( nice_ok == 1 && renice_ok == 1 )); then
    ok "report shows nice/renice practice (you started a process with nice and adjusted it with renice)"
  elif (( nice_ok == 0 )); then
    no "report should show a process started with 'nice' — see Part 4"
  else
    no "report should show a priority change with 'renice' (its output mentions 'old priority ... new priority')"
  fi
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
