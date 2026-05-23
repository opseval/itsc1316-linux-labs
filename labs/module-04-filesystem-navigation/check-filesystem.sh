#!/usr/bin/env bash
#
# check-filesystem.sh  —  Module 4: Filesystems & Directory Navigation
#
# Self-grades your work. Run it (no sudo needed):
#     bash check-filesystem.sh
#
# Prints PASS/FAIL for each requirement. Exit code is 0 only if everything
# passes. Fix any FAILs and run it again.
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

DOCS="${HOME}/Documents"
HOST="$(hostname)"

echo "=== Module 4 Lab Check: Filesystems & Directory Navigation ==="
echo

# ---------------------------------------------------------------------------
# Part 2 — Directory structure exists with the right subdirectories.
# ---------------------------------------------------------------------------
struct_ok=1
for d in utilities scripts backups; do
  [[ -d "${DOCS}/${d}" ]] || struct_ok=0
done
if (( struct_ok == 1 )); then
  ok "~/Documents has utilities/, scripts/, and backups/ subdirectories"
else
  no "~/Documents must contain utilities/, scripts/, and backups/ — run: mkdir -p ~/Documents/{utilities,scripts,backups}"
fi

# ---------------------------------------------------------------------------
# Part 2 — Files landed in the right subdirectories after the moves/copy.
# scripts/ should hold both moved scripts; they should NO LONGER be in staging
# (proving a move, not a copy). backups/ should hold the moved log.
# utilities/ should hold the copied readme AND the new notes.txt.
# ---------------------------------------------------------------------------
# scripts/backup.sh and scripts/diskcheck.sh present
if [[ -f "${DOCS}/scripts/backup.sh" && -f "${DOCS}/scripts/diskcheck.sh" ]]; then
  ok "scripts/ contains backup.sh and diskcheck.sh"
else
  no "scripts/ should contain backup.sh and diskcheck.sh — move them from ~/mod04-staging (Part 2b)"
fi

# Verify they were MOVED (no longer in staging), not copied.
if [[ ! -f "${HOME}/mod04-staging/backup.sh" && ! -f "${HOME}/mod04-staging/diskcheck.sh" ]]; then
  ok "the two scripts were moved out of ~/mod04-staging (mv, not cp)"
else
  no "backup.sh / diskcheck.sh are still in ~/mod04-staging — Part 2b asks you to MOVE them (mv), so they should leave staging"
fi

# backups/old-backup.log present and moved
if [[ -f "${DOCS}/backups/old-backup.log" ]]; then
  ok "backups/ contains old-backup.log"
else
  no "backups/ should contain old-backup.log — move it from ~/mod04-staging (Part 2c)"
fi

# utilities/ holds the copied readme AND the new notes.txt; the readme should
# STILL exist in staging too (proving a copy, not a move).
util_ok=1
[[ -f "${DOCS}/utilities/utilities-readme.txt" ]] || util_ok=0
[[ -s "${DOCS}/utilities/notes.txt" ]] || util_ok=0
# Part 2d explicitly says COPY (not move). The original must still exist in
# staging — accepting a moved file would defeat the cp-vs-mv lesson.
staging_copy_present=0
[[ -f "${HOME}/mod04-staging/utilities-readme.txt" ]] && staging_copy_present=1
if (( util_ok == 1 )) && (( staging_copy_present == 1 )); then
  ok "utilities/ has the COPIED utilities-readme.txt (original still in staging) and a non-empty notes.txt"
elif (( util_ok == 1 )) && (( staging_copy_present == 0 )); then
  no "utilities/utilities-readme.txt exists, but the original is gone from ~/mod04-staging — Part 2d says COPY (cp), not MOVE (mv). Put the original back."
else
  no "utilities/ should contain utilities-readme.txt (copied, Part 2d) and a non-empty notes.txt (created, Part 2e)"
fi

# ---------------------------------------------------------------------------
# Part 4 — ~/results contains the find output, including the moved scripts and
# the system /etc/hostname; errors were redirected separately.
# ---------------------------------------------------------------------------
RES="${HOME}/results"
if [[ -s "$RES" ]]; then
  has_scripts=0
  has_etc_hostname=0
  has_errors=0
  if grep -q "/Documents/scripts/backup.sh" "$RES" 2>/dev/null \
     && grep -q "/Documents/scripts/diskcheck.sh" "$RES" 2>/dev/null; then
    has_scripts=1
  fi
  grep -q "^/etc/hostname$" "$RES" 2>/dev/null && has_etc_hostname=1
  # Errors must NOT be in the results file (they should be in find-errors.log).
  grep -qi "Permission denied" "$RES" 2>/dev/null && has_errors=1
  if (( has_scripts == 1 && has_etc_hostname == 1 && has_errors == 0 )); then
    ok "~/results lists your moved scripts and /etc/hostname, with no error noise mixed in"
  elif (( has_errors == 1 )); then
    no "~/results contains 'Permission denied' errors — Part 4b sends errors to a separate file with '2> ~/find-errors.log'"
  elif (( has_scripts == 0 )); then
    no "~/results should include ~/Documents/scripts/backup.sh and diskcheck.sh — run the Part 4a find AFTER moving the scripts"
  else
    no "~/results should include /etc/hostname — run the Part 4b system-wide find for files named 'hostname'"
  fi
else
  no "~/results is missing or empty — complete Part 4 (find with redirection)"
fi

# Errors were actually captured to find-errors.log (must contain at least one
# permission-denied line from the system-wide find).
if [[ -f "${HOME}/find-errors.log" ]] && grep -qi "Permission denied" "${HOME}/find-errors.log" 2>/dev/null; then
  ok "~/find-errors.log captured the search's permission errors (stderr separated from stdout)"
else
  no "~/find-errors.log should capture the 'Permission denied' errors from 'find /' — re-run Part 4b with '2> ~/find-errors.log'"
fi

# ---------------------------------------------------------------------------
# Part 5 — fhs-evidence.txt contains the real hostname and the four FHS notes.
# ---------------------------------------------------------------------------
EVID="${DOCS}/fhs-evidence.txt"
if [[ -s "$EVID" ]]; then
  host_ok=0; etc_ok=0; home_ok=0; var_ok=0; usr_ok=0
  grep -q "$HOST" "$EVID" 2>/dev/null && host_ok=1
  grep -q "/etc/hostname" "$EVID" 2>/dev/null && etc_ok=1
  # Accept the literal /home/ubuntu (Multipass default) OR the invoking user's
  # actual home (cloud-fallback). The lab only requires "an example file from /home".
  grep -qE "(/home/ubuntu|/home/${USER}|${HOME})" "$EVID" 2>/dev/null && home_ok=1
  grep -q "/var/log/" "$EVID" 2>/dev/null && var_ok=1
  grep -q "/usr/bin/" "$EVID" 2>/dev/null && usr_ok=1
  if (( host_ok && etc_ok && home_ok && var_ok && usr_ok )); then
    ok "fhs-evidence.txt has your hostname and an example file from /etc, /home, /var, and /usr"
  elif (( host_ok == 0 )); then
    no "fhs-evidence.txt does not contain this machine's hostname ($HOST) — rebuild it as shown in Part 5"
  else
    no "fhs-evidence.txt is missing one of the FHS examples (/etc, /home, /var, /usr) — rebuild it as shown in Part 5"
  fi
else
  no "~/Documents/fhs-evidence.txt is missing or empty — complete Part 5"
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
