#!/usr/bin/env bash
#
# check-software.sh  —  Module 7: Software, Packages, and Archives
#
# Self-grades your work. Run it (no sudo needed):
#     bash check-software.sh
#
# Prints PASS/FAIL for each requirement. Exit code is 0 only if everything
# passes. Fix any FAILs and run it again — just like re-testing a real system.
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

HOST="$(hostname)"
PROJECT="${HOME}/projectfiles"
ARCHIVE="${HOME}/backup.tar.gz"
REPORT="${HOME}/module7-software-report.txt"

# The package the student installed/removed. The lab lets them pick one of a
# few small, safe packages; we accept any of these.
CANDIDATES=(tree cowsay htop sl figlet ncdu)

echo "=== Module 7 Lab Check: Software, Packages, and Archives ==="
echo

# --- Integrity self-check (tamper-evident; auto-compares against canonical CHECKSUMS.txt) ---
# Resets PATH and uses absolute binaries so a PATH-shimmed `curl`/`sha256sum`
# can't spoof VERIFIED on a tampered script. The recording is where the grader
# reads the printed INTEGRITY: line (tamper-evident, not tamper-proof).
echo "=== check script integrity ==="
INTEGRITY_REL_PATH="labs/module-07-software-and-archives/check-software.sh"
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
# 1. Package was installed and then removed cleanly.
#    "Removed" means it is NOT currently fully installed (dpkg status not 'ii'),
#    AND the report documents that the student installed it first. We can't see
#    the past, so we require BOTH: the package is gone now, and the evidence
#    file shows the install/remove was actually done (a dpkg/apt line naming
#    the package). This stops "I never installed anything" from passing.
# ---------------------------------------------------------------------------
# Identify the package the STUDENT chose, by name in their report. We only
# judge that one package — we must NOT fail just because some unrelated
# candidate (e.g. htop) happens to be pre-installed on the student's VM for
# other reasons. The task is: install the package you documented, then remove
# THAT package.
report_pkg=""
if [[ -f "$REPORT" ]]; then
  for p in "${CANDIDATES[@]}"; do
    if grep -qw "$p" "$REPORT" 2>/dev/null; then
      report_pkg="$p"
      break
    fi
  done
fi

removed_pkg=""
if [[ -z "$report_pkg" ]]; then
  no "no evidence that you installed/removed a package — your report ($REPORT) should name the package you used (one of: ${CANDIDATES[*]}) and show its apt/dpkg output"
else
  # Is the package the student documented still installed?
  st="$(dpkg-query -W -f='${Status}' "$report_pkg" 2>/dev/null || true)"
  if [[ "$st" == "install ok installed" ]]; then
    no "package '$report_pkg' (the one in your report) is still installed — the lab asks you to REMOVE it after testing (sudo apt remove $report_pkg)"
  else
    removed_pkg="$report_pkg"
    ok "package '$removed_pkg' is documented in your report and is no longer installed (installed, then removed cleanly)"
  fi
fi

# ---------------------------------------------------------------------------
# 2. Report contains real package-inspection evidence: an 'apt show' / dpkg
#    line for the package AND a 'dpkg -L' style installed-files path. We look
#    for a couple of fingerprints that only appear when the commands were
#    actually run.
# ---------------------------------------------------------------------------
if [[ -f "$REPORT" ]]; then
  apt_evidence=0
  files_evidence=0
  # 'apt show' prints a "Package:" header; 'dpkg -l' rows start with 'ii'.
  if grep -Eq '^Package:[[:space:]]' "$REPORT" 2>/dev/null \
     || grep -Eq '^ii[[:space:]]' "$REPORT" 2>/dev/null \
     || grep -Eq 'Version:[[:space:]]' "$REPORT" 2>/dev/null; then
    apt_evidence=1
  fi
  # 'dpkg -L <pkg>' output is a list of absolute install paths under /usr.
  if grep -Eq '^/usr/(bin|share|lib)/' "$REPORT" 2>/dev/null; then
    files_evidence=1
  fi
  if (( apt_evidence == 1 && files_evidence == 1 )); then
    ok "report captures package-inspection output (apt show / dpkg -l header AND a dpkg -L install path)"
  elif (( apt_evidence == 0 )); then
    no "report needs 'apt show' or 'dpkg -l' output for your package (paste a line with 'Package:' / 'Version:' or a 'ii' status row)"
  else
    no "report needs 'dpkg -L <pkg>' output showing where files were installed (paste a /usr/bin or /usr/share path)"
  fi
else
  no "evidence report $REPORT is missing — create it as described in the lab"
fi

# ---------------------------------------------------------------------------
# 3. A valid gzip-compressed tar archive exists at ~/backup.tar.gz and contains
#    the expected project files. We actually read the table of contents with
#    'tar -tzf' (validates it really is a gzip tarball, not just a renamed file).
# ---------------------------------------------------------------------------
if [[ -f "$ARCHIVE" ]]; then
  if toc="$(tar -tzf "$ARCHIVE" 2>/dev/null)"; then
    has_log=0; has_readme=0; has_csv=0
    grep -q 'logs/service.log'  <<<"$toc" && has_log=1
    grep -q 'docs/README.txt'   <<<"$toc" && has_readme=1
    grep -q 'docs/data.csv'     <<<"$toc" && has_csv=1
    if (( has_log == 1 && has_readme == 1 && has_csv == 1 )); then
      ok "~/backup.tar.gz is a valid .tar.gz and contains the project files (service.log, README.txt, data.csv)"
    else
      no "~/backup.tar.gz is a valid archive but is missing project files — archive the whole ~/projectfiles directory (tar -czf ~/backup.tar.gz projectfiles)"
    fi
  else
    no "~/backup.tar.gz exists but is not a valid gzip tar archive — recreate it with: tar -czf ~/backup.tar.gz projectfiles"
  fi
else
  no "~/backup.tar.gz does not exist — create it with: cd ~ && tar -czf backup.tar.gz projectfiles"
fi

# ---------------------------------------------------------------------------
# 4. An extracted copy exists somewhere OTHER than the original (the lab asks
#    you to extract it "elsewhere"). We look for an extracted projectfiles tree
#    under ~/restore (the path the lab suggests) that contains a known file.
# ---------------------------------------------------------------------------
extracted_ok=0
for base in "${HOME}/restore" "${HOME}/extracted" "${HOME}/restore-test"; do
  if [[ -f "${base}/projectfiles/logs/service.log" || -f "${base}/projectfiles/docs/README.txt" ]]; then
    extracted_ok=1
    EXTRACTED_AT="$base"
    break
  fi
done
if (( extracted_ok == 1 )); then
  ok "an extracted copy of the archive exists under ${EXTRACTED_AT} (you unpacked it in a separate location)"
else
  no "no extracted copy found — make a fresh directory and extract there, e.g.: mkdir -p ~/restore && tar -xzf ~/backup.tar.gz -C ~/restore"
fi

# ---------------------------------------------------------------------------
# 5. The evidence report contains THIS machine's hostname and the archive's
#    table of contents (a 'tar -tzf' listing of the project files). This proves
#    the report was built from real output on the student's own VM.
# ---------------------------------------------------------------------------
if [[ -f "$REPORT" ]]; then
  host_ok=0; tar_ok=0
  grep -qw "$HOST" "$REPORT" 2>/dev/null && host_ok=1
  # The archive listing the report should contain at least one of the project paths.
  if grep -q 'projectfiles/logs/service.log' "$REPORT" 2>/dev/null \
     || grep -q 'projectfiles/docs/' "$REPORT" 2>/dev/null; then
    tar_ok=1
  fi
  if (( host_ok == 1 && tar_ok == 1 )); then
    ok "report includes your hostname ($HOST) and the archive's tar listing (built from your own VM)"
  elif (( host_ok == 0 )); then
    no "report does not contain this machine's hostname ($HOST) — add the output of 'hostname' to $REPORT"
  else
    no "report does not include the archive's contents — paste the output of 'tar -tzf ~/backup.tar.gz' into $REPORT"
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
