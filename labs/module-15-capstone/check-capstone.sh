#!/usr/bin/env bash
#
# check-capstone.sh  —  Module 15: Comprehensive Review (Capstone)
#
# Self-grades the whole capstone. Some checks read root-only systemd/file state,
# so run it WITH SUDO for accurate results:
#     sudo bash check-capstone.sh
#
# It also runs without sudo, but a couple of checks may be less reliable and
# will tell you to re-run with sudo.
#
# Prints PASS/FAIL for each end-state specification. Exit code is 0 only when
# everything passes. Fix the FAILs and run it again — exactly what an admin
# does after a change: re-test until the system is in the desired state.
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

# Resolve the human running the lab (sudo makes $HOME root's). The deliverables
# live in THAT user's home.
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)"
[[ -z "$REAL_HOME" ]] && REAL_HOME="$HOME"

HOST="$(hostname)"
ROOT_DIR="/srv/inherited"
FIN_DIR="/opt/finance"
ARCHIVE="${REAL_HOME}/inherited-backup.tar.gz"
REPORT="${REAL_HOME}/module15-handover-report.txt"

owner_of() { stat -c '%U' "$1" 2>/dev/null; }
group_of() { stat -c '%G' "$1" 2>/dev/null; }
mode_of()  { stat -c '%a' "$1" 2>/dev/null; }

# Return the last 3 octal permission digits, zero-padded. `stat -c '%a'` strips
# leading zeros (mode 040 prints as '40'), so pad before slicing.
perm3() { printf '%03d' "$(mode_of "$1")" 2>/dev/null; }

echo "=== Module 15 Capstone Check: Comprehensive Review ==="
echo

# ---------------------------------------------------------------------------
# SPEC 1 — Directory tree organized by file type.
#   logs/*.log, configs/*.conf, reports/*.report must each contain the 3 files
#   of their kind, and the top level must no longer hold loose .log/.conf/
#   .report files. We verify by counting the right files in the right places.
# ---------------------------------------------------------------------------
declare -A want=( [logs]="log" [configs]="conf" [reports]="report" )
declare -A names=( [logs]="web app auth" [configs]="web app database" [reports]="january february march" )
spec1_problems=()
for sub in logs configs reports; do
  ext="${want[$sub]}"
  d="${ROOT_DIR}/${sub}"
  if [[ ! -d "$d" ]]; then
    spec1_problems+=("missing directory ${d}")
    continue
  fi
  for base in ${names[$sub]}; do
    if [[ ! -f "${d}/${base}.${ext}" ]]; then
      spec1_problems+=("${sub}/${base}.${ext} not in ${d}")
    fi
  done
done
# Loose typed files left at the top level mean the sort is not finished.
loose=$(find "$ROOT_DIR" -maxdepth 1 -type f \( -name '*.log' -o -name '*.conf' -o -name '*.report' \) 2>/dev/null | wc -l)
if (( loose > 0 )); then
  spec1_problems+=("$loose log/conf/report file(s) still loose at the top of ${ROOT_DIR} — move them into logs/, configs/, reports/")
fi
if (( ${#spec1_problems[@]} == 0 )); then
  ok "directory tree under ${ROOT_DIR} is organized into logs/, configs/, reports/ correctly"
else
  no "directory organization not complete:"
  for p in "${spec1_problems[@]}"; do echo "          - $p"; done
fi

# ---------------------------------------------------------------------------
# SPEC 2 — Junk .tmp files removed from the directory tree.
#   The spec asks the student to delete the temp/junk files. Any *.tmp anywhere
#   under /srv/inherited (including hidden ones) is a fail.
# ---------------------------------------------------------------------------
tmpcount=$(find "$ROOT_DIR" -name '*.tmp' 2>/dev/null | wc -l)
if (( tmpcount == 0 )); then
  ok "all temporary/junk *.tmp files have been removed from ${ROOT_DIR}"
else
  no "$tmpcount '*.tmp' junk file(s) still present under ${ROOT_DIR} — remove them (e.g. find ${ROOT_DIR} -name '*.tmp' -delete)"
fi

# ---------------------------------------------------------------------------
# SPEC 3 — Backup archive: a valid .tar.gz at ~/inherited-backup.tar.gz that
#   contains the THREE config files and does NOT contain the big bigdata.bin
#   file (the spec says back up the configs only — not the multi-hundred-MB
#   disk hog). We read the real table of contents with tar -tzf.
# ---------------------------------------------------------------------------
if [[ -f "$ARCHIVE" ]]; then
  if toc="$(tar -tzf "$ARCHIVE" 2>/dev/null)"; then
    have_conf=0
    for c in web app database; do
      grep -q "${c}\.conf" <<<"$toc" && have_conf=$((have_conf+1))
    done
    if grep -q 'bigdata\.bin' <<<"$toc"; then
      no "backup archive includes bigdata.bin — the spec says back up the CONFIG files only, not the large disk-hog file"
    elif (( have_conf == 3 )); then
      ok "~/inherited-backup.tar.gz is a valid .tar.gz containing all three config files (and not the disk hog)"
    else
      no "~/inherited-backup.tar.gz is valid but is missing config files (found $have_conf of 3: web/app/database.conf) — archive the configs directory"
    fi
  else
    no "~/inherited-backup.tar.gz exists but is not a valid gzip tar archive — recreate it (e.g. tar -czf ~/inherited-backup.tar.gz -C ${ROOT_DIR} configs)"
  fi
else
  no "~/inherited-backup.tar.gz does not exist — create a .tar.gz backup of the config files"
fi

# ---------------------------------------------------------------------------
# SPEC 4 — Shared finance directory: group 'finance' owns it, group can
#   collaborate (rwx) with the setgid bit so new files inherit the group, and
#   OTHERS get nothing. Least privilege: no world access.
# ---------------------------------------------------------------------------
if [[ -d "$FIN_DIR" ]]; then
  gd=$(group_of "$FIN_DIR")
  rawmode=$(mode_of "$FIN_DIR")     # full mode incl. setgid (e.g. 2770)
  # Take the LAST 3 octal digits for owner/group/other, so a 4-digit mode like
  # 2770 (setgid set) still yields group='7' other='0', not '2'/'7'.
  fp=$(printf '%03d' "$rawmode")
  perms="${fp: -3}"
  gdig="${perms:1:1}"   # group digit
  odig="${perms:2:1}"   # other digit
  # setgid is the leading special bit: with a 4-digit mode, first char & 2.
  setgid=0
  if [[ "${#rawmode}" -ge 4 ]]; then
    lead="${rawmode:0:1}"
    (( (lead & 2) != 0 )) && setgid=1
  fi
  dir_ok=0
  # Group must have read+write+execute (7); others must have nothing (0).
  if (( (gdig & 7) == 7 && (odig & 7) == 0 )); then dir_ok=1; fi
  if (( dir_ok == 1 )) && [[ "$gd" == "finance" ]] && (( setgid == 1 )); then
    ok "${FIN_DIR} is group-owned by 'finance', group rwx, no access for others, setgid set (mode $rawmode)"
  elif [[ "$gd" != "finance" ]]; then
    no "${FIN_DIR} group should be 'finance' (found '$gd') — chown :finance ${FIN_DIR}"
  elif (( dir_ok == 0 )); then
    no "${FIN_DIR} permissions wrong (mode $rawmode) — group needs rwx and OTHERS must have nothing (e.g. chmod 2770)"
  else
    no "${FIN_DIR} needs the setgid bit so new files inherit the finance group (mode $rawmode) — chmod g+s ${FIN_DIR}"
  fi
else
  no "${FIN_DIR} is missing — it should exist and be a properly-secured finance share, not deleted"
fi

# ---------------------------------------------------------------------------
# SPEC 5 — The confidential budget file is not exposed to others.
#   budget.txt must not be readable or writable by GROUP-others... actually the
#   finance group SHOULD be able to read/write it (shared), but OTHERS must
#   have nothing. We enforce: others get no read and no write.
# ---------------------------------------------------------------------------
BUDGET="${FIN_DIR}/budget.txt"
if [[ -f "$BUDGET" ]]; then
  bp=$(perm3 "$BUDGET")
  bother="${bp: -1}"   # last octal digit = 'other' permissions
  if (( (bother & 6) == 0 )); then
    ok "${BUDGET} is not readable or writable by others (mode $(mode_of "$BUDGET"))"
  elif (( (bother & 2) != 0 )); then
    no "${BUDGET} is still world-writable (mode $(mode_of "$BUDGET")) — confidential data must not be writable by others"
  else
    no "${BUDGET} is still world-readable (mode $(mode_of "$BUDGET")) — confidential budget data must not be readable by others"
  fi
else
  no "${BUDGET} is missing — secure it, do not delete it"
fi

# ---------------------------------------------------------------------------
# SPEC 6 — The runaway 'datacruncher' process is stopped.
# ---------------------------------------------------------------------------
if pgrep -f '/usr/local/bin/datacruncher' >/dev/null 2>&1; then
  no "the runaway 'datacruncher' process is still running — find it (ps/top/pgrep) and stop it (kill)"
else
  ok "the runaway 'datacruncher' process has been stopped"
fi

# ---------------------------------------------------------------------------
# SPEC 7 — The required 'inheritd' service is ACTIVE and ENABLED (auto-start).
# ---------------------------------------------------------------------------
active=$(systemctl is-active inheritd.service 2>/dev/null || true)
enabled=$(systemctl is-enabled inheritd.service 2>/dev/null || true)
if [[ "$active" == "active" && ( "$enabled" == "enabled" || "$enabled" == "enabled-runtime" ) ]]; then
  ok "inheritd.service is active and enabled (running now and at boot)"
elif [[ "$active" != "active" ]]; then
  no "inheritd.service is not running (is-active=${active:-unknown}) — start it (sudo systemctl start inheritd.service)"
else
  no "inheritd.service is running but not enabled (is-enabled=${enabled:-unknown}) — enable it (sudo systemctl enable inheritd.service)"
fi

# ---------------------------------------------------------------------------
# SPEC 8 — The handover report exists, is tied to THIS VM, has all required
#   sections filled in (no leftover placeholders), and contains real prose.
# ---------------------------------------------------------------------------
if [[ ! -f "$REPORT" ]]; then
  no "handover report $REPORT not found — create it per the README template (must include your hostname and all sections)"
else
  rep_problems=()

  # 8a. Must include this VM's actual hostname (proves it is the student's box).
  grep -qiF "$HOST" "$REPORT" 2>/dev/null \
    || rep_problems+=("missing this VM's hostname ('$HOST') — paste your 'hostname' output into the report")

  # 8b. Required section headings present (the template's labels).
  for kw in "STATE FOUND" "ACTIONS TAKEN" "REASONING" "WHAT I" "DISK" "NETWORK"; do
    grep -qiF "$kw" "$REPORT" 2>/dev/null \
      || rep_problems+=("report is missing the '$kw' section — fill in every section of the template")
  done

  # 8c. No leftover placeholders. The template uses <...> angle-bracket fields
  #     and the words TODO/FIXME; any of those left means it isn't filled in.
  if grep -Eq '<[^>]+>' "$REPORT" 2>/dev/null; then
    rep_problems+=("report still contains <placeholder> text — replace every <...> with your own words")
  fi
  if grep -Eqi '\b(TODO|FIXME|FILL ?IN)\b' "$REPORT" 2>/dev/null; then
    rep_problems+=("report still contains TODO/FIXME/'fill in' markers — complete those sections")
  fi

  # 8d. Disk-investigation evidence: the spec asks the student to identify the
  #     disk hog. Require a mention of the large file and a df/du fingerprint.
  grep -qiF "bigdata.bin" "$REPORT" 2>/dev/null \
    || rep_problems+=("report does not name the large disk-consuming file (bigdata.bin) — identify it with du and record it")
  grep -Eqi '\b(df|du)\b' "$REPORT" 2>/dev/null \
    || rep_problems+=("report shows no df/du evidence — paste the disk-usage command output you used")

  # 8e. Network evidence: the spec asks the student to verify reachability and
  #     name resolution and record the result. Require a host/IP fingerprint
  #     plus one of the tools used.
  grep -Eqi 'ping|getent|nslookup|dig|host |resolvectl|systemd-resolve' "$REPORT" 2>/dev/null \
    || rep_problems+=("report shows no network verification — record the result of a reachability/DNS check (ping, getent hosts, dig, etc.)")

  # 8f. Real written reasoning, not just pasted output. Require enough prose.
  words=$(wc -w < "$REPORT" 2>/dev/null || echo 0)
  if (( words < 200 )); then
    rep_problems+=("the report is short ($words words) — a handover report needs real explanation: state found, what you changed, WHY, and what you'd check next")
  fi

  if (( ${#rep_problems[@]} == 0 )); then
    ok "handover report $REPORT is complete, tied to host '$HOST', and includes disk + network evidence and reasoning"
  else
    no "handover report problems:"
    for p in "${rep_problems[@]}"; do echo "          - $p"; done
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
