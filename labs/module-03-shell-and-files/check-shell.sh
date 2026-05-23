#!/usr/bin/env bash
#
# check-shell.sh  —  Module 3: Working with the Shell
#
# Self-grades your work. Run it (no sudo needed):
#     bash check-shell.sh
#
# Prints PASS/FAIL for each requirement. Exit code is 0 only if everything
# passes. Fix any FAILs and run it again.
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

LABDIR="${HOME}/mod03"
HOST="$(hostname)"

echo "=== Module 3 Lab Check: Working with the Shell ==="
echo

# --- Integrity self-check (the grader will verify this SHA against labs/CHECKSUMS.txt) ---
echo "=== check script integrity ==="
if command -v sha256sum >/dev/null 2>&1; then
  echo "  This script: $(basename "$0")"
  echo "  SHA256:      $(sha256sum "$0" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  echo "  This script: $(basename "$0")"
  echo "  SHA256:      $(shasum -a 256 "$0" | awk '{print $1}')"
else
  echo "  This script: $(basename "$0")"
  echo "  SHA256:      (no sha256sum or shasum available)"
fi
echo "  Expected:    see labs/CHECKSUMS.txt in the repo"
echo

# ---------------------------------------------------------------------------
# Part 1 — Redirection: stdout and stderr separated, plus an appended error.
# out.txt must contain the successful listing of servers.csv (stdout) and must
# NOT contain an error message. err.txt must contain at least one "No such
# file" style error (stderr) — and the lab's append step should leave TWO.
# ---------------------------------------------------------------------------
if [[ -s "${LABDIR}/out.txt" && -s "${LABDIR}/err.txt" ]]; then
  out_has_servers=0
  out_has_error=0
  grep -q "servers.csv" "${LABDIR}/out.txt" 2>/dev/null && out_has_servers=1
  # An error in the stdout file means the streams were not actually separated.
  grep -qiE "No such file|cannot access" "${LABDIR}/out.txt" 2>/dev/null && out_has_error=1
  # NB: `grep -c` exits 1 when there are zero matches even though it prints "0".
  # The old `|| echo 0` fallback then ALSO printed "0", giving err_count=$'0\n0'
  # — which crashes the arithmetic on the next line. $(...) already strips the
  # trailing newline; just default the empty case so this stays a single integer.
  err_count=$(grep -cE "No such file|cannot access" "${LABDIR}/err.txt" 2>/dev/null)
  err_count="${err_count:-0}"
  if (( out_has_servers == 1 && out_has_error == 0 && err_count >= 2 )); then
    ok "out.txt has the listing (stdout) and err.txt has the errors (stderr), with an appended second error"
  elif (( out_has_servers == 0 )); then
    no "out.txt should contain the 'servers.csv' listing (stdout) — re-run: ls -l servers.csv nope-does-not-exist.txt > out.txt 2> err.txt"
  elif (( out_has_error == 1 )); then
    no "out.txt contains an error message — stdout and stderr were not separated. Use '> out.txt 2> err.txt'"
  else
    no "err.txt should contain TWO error lines (the append step). Did you run the '>> ... 2>>' append in Part 1c? (found $err_count)"
  fi
else
  no "out.txt and/or err.txt are missing or empty in ${LABDIR} — complete Part 1 (redirection)"
fi

# ---------------------------------------------------------------------------
# Part 2 — Pipes: role-count.txt and user-count.txt each hold a single number,
# and user-count.txt must equal the real number of lines in /etc/passwd
# (anchored to THIS system, so it cannot be faked).
# ---------------------------------------------------------------------------
if [[ -s "${LABDIR}/role-count.txt" ]]; then
  rc=$(tr -d '[:space:]' < "${LABDIR}/role-count.txt")
  # servers.csv has 5 distinct roles: web, database, cache, app, mail.
  if [[ "$rc" == "5" ]]; then
    ok "role-count.txt = 5 (distinct roles from the pipeline)"
  else
    no "role-count.txt should be 5 distinct roles (found '$rc') — re-run the Part 2 cut|tail|sort|uniq|wc pipeline"
  fi
else
  no "role-count.txt is missing or empty — complete the first pipeline in Part 2"
fi

if [[ -s "${LABDIR}/user-count.txt" ]]; then
  uc=$(tr -d '[:space:]' < "${LABDIR}/user-count.txt")
  real_users=$(cut -d: -f1 /etc/passwd | sort | wc -l | tr -d '[:space:]')
  if [[ "$uc" == "$real_users" ]]; then
    ok "user-count.txt matches the real account count in /etc/passwd ($real_users)"
  else
    no "user-count.txt ('$uc') does not match this system's /etc/passwd count ($real_users) — re-run: cat /etc/passwd | cut -d: -f1 | sort | wc -l > user-count.txt"
  fi
else
  no "user-count.txt is missing or empty — complete the second pipeline in Part 2"
fi

# ---------------------------------------------------------------------------
# Part 3 — Variables: varproof.txt must show ENVVAR set (inherited by child)
# and SHELLONLY empty (not inherited).
# ---------------------------------------------------------------------------
if [[ -s "${LABDIR}/varproof.txt" ]]; then
  env_ok=0
  shell_empty=0
  grep -q "^ENVVAR=i-get-inherited$" "${LABDIR}/varproof.txt" 2>/dev/null && env_ok=1
  # SHELLONLY must be present as a line but EMPTY after the '=' (not inherited).
  grep -q "^SHELLONLY=$" "${LABDIR}/varproof.txt" 2>/dev/null && shell_empty=1
  if (( env_ok == 1 && shell_empty == 1 )); then
    ok "varproof.txt shows the child inherited ENVVAR but not the un-exported SHELLONLY"
  elif (( env_ok == 0 )); then
    no "varproof.txt should contain a line 'ENVVAR=i-get-inherited' — re-do Part 3 (did you export ENVVAR?)"
  else
    no "varproof.txt should contain an EMPTY 'SHELLONLY=' line (the child must NOT inherit it) — do not export SHELLONLY"
  fi
else
  no "varproof.txt is missing or empty — complete Part 3 (shell vs environment variable)"
fi

# ---------------------------------------------------------------------------
# Part 4 — The script: ~/sysreport.sh must exist, be executable by the owner,
# and running it must produce a CSV whose data row's first field is the real
# hostname of THIS machine.
# ---------------------------------------------------------------------------
SCRIPT="${HOME}/sysreport.sh"
if [[ -f "$SCRIPT" ]]; then
  m=$(stat -c '%a' "$SCRIPT" 2>/dev/null)
  m_padded=$(printf '%03d' "$m")
  perms="${m_padded: -3}"
  owner_digit="${perms:0:1}"
  # Owner must have the execute bit (& 1).
  if (( (owner_digit & 1) == 1 )); then
    # Run it fresh into a checker-controlled file so we test what it actually
    # produces (not a stale file the student may have hand-edited).
    CHECK_OUT="${LABDIR}/.sysreport-check.csv"
    rm -f "$CHECK_OUT"
    # Redirect stdin from /dev/null and cap the runtime so a student script that
    # accidentally calls `read` (waiting for input) doesn't hang the checker.
    if timeout 15 "$SCRIPT" "$CHECK_OUT" < /dev/null >/dev/null 2>&1 && [[ -s "$CHECK_OUT" ]]; then
      # The first field of the data row (line 2) should be the real hostname.
      data_host=$(sed -n '2p' "$CHECK_OUT" | cut -d, -f1)
      if [[ "$data_host" == "$HOST" ]]; then
        ok "sysreport.sh accepts an output-path argument and produced a CSV with this machine's real hostname ($HOST)"
      else
        no "sysreport.sh ran but its CSV hostname ('$data_host') does not match this machine ('$HOST') — use \$(hostname) in the script"
      fi
      rm -f "$CHECK_OUT"
    else
      # No fallback to a default ~/sysreport.csv on purpose: the README requires
      # the script to accept the output path as \$1. A solution that ignores \$1
      # misses the lesson and must FAIL here so the student fixes it.
      no "sysreport.sh did not write to the path we gave it as \$1 — your script must accept the output path as its first argument (see the if-test in the README example)"
    fi
  else
    no "sysreport.sh exists but is not executable by its owner — run: chmod +x ~/sysreport.sh"
  fi
else
  no "~/sysreport.sh does not exist — write it as described in Part 4"
fi

# ---------------------------------------------------------------------------
# Part 5 — Docs evidence: docs-evidence.txt must contain the real hostname AND
# proof that 'type cd' was run and reports cd as a shell builtin.
# ---------------------------------------------------------------------------
EVID="${LABDIR}/docs-evidence.txt"
if [[ -s "$EVID" ]]; then
  host_ok=0
  builtin_ok=0
  grep -q "$HOST" "$EVID" 2>/dev/null && host_ok=1
  grep -qi "cd is a shell builtin" "$EVID" 2>/dev/null && builtin_ok=1
  if (( host_ok == 1 && builtin_ok == 1 )); then
    ok "docs-evidence.txt contains your hostname and 'type cd' showing cd is a shell builtin"
  elif (( host_ok == 0 )); then
    no "docs-evidence.txt does not contain this machine's hostname ($HOST) — rebuild it as shown in Part 5c"
  else
    no "docs-evidence.txt does not show 'cd is a shell builtin' — include the output of 'type cd' (Part 5c)"
  fi
else
  no "docs-evidence.txt is missing or empty in ${LABDIR} — complete Part 5"
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
