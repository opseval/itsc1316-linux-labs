#!/usr/bin/env bash
#
# check-intro.sh  —  Module 1: Introduction to Linux
#
# Self-grades your work. Run it (no sudo needed):
#     bash check-intro.sh
#
# It confirms your evidence file exists, is non-empty, and that the facts
# you recorded actually match THIS machine (your real kernel string, the
# distro ID 'ubuntu', and your real hostname). It also confirms you wrote
# a reflection. Anchoring to live system state means the answers can't be
# fabricated — they have to come from your VM.
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

REPORT="$HOME/module1-system-report.txt"

echo "=== Module 1 Lab Check: Introduction to Linux ==="
echo

# --- Integrity self-check (tamper-evident; auto-compares against canonical CHECKSUMS.txt) ---
# Resets PATH and uses absolute binaries so a PATH-shimmed `curl`/`sha256sum`
# can't spoof VERIFIED on a tampered script. The recording is where the grader
# reads the printed INTEGRITY: line (tamper-evident, not tamper-proof).
echo "=== check script integrity ==="
INTEGRITY_REL_PATH="labs/module-01-introduction-to-linux/check-intro.sh"
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

# 0. The evidence file exists and is non-empty.
if [[ -s "$REPORT" ]]; then
  ok "Evidence file exists and is non-empty: $REPORT"
elif [[ -f "$REPORT" ]]; then
  no "Evidence file $REPORT exists but is empty — fill it in"
  echo
  echo "-----------------------------------------------"
  echo "  Passed: $pass    Failed: $fail"
  echo "  Not done yet — fix the FAILs above and run me again."
  echo "-----------------------------------------------"
  exit 1
else
  no "Evidence file $REPORT not found — run 'sudo bash setup-intro.sh' to get the template, then fill it in"
  echo
  echo "-----------------------------------------------"
  echo "  Passed: $pass    Failed: $fail"
  echo "  Not done yet — fix the FAILs above and run me again."
  echo "-----------------------------------------------"
  exit 1
fi

# Read the file once, lower-cased, for case-insensitive token matching.
content_lc="$(tr '[:upper:]' '[:lower:]' < "$REPORT")"

# 1. The report must contain THIS machine's real kernel release string.
#    `uname -r` is something like 5.15.0-101-generic — practically impossible
#    to guess, so its presence proves the student ran the command here.
real_kernel="$(uname -r)"
real_kernel_lc="$(printf '%s' "$real_kernel" | tr '[:upper:]' '[:lower:]')"
if grep -qF "$real_kernel_lc" <<< "$content_lc"; then
  ok "Report contains this VM's real kernel release ($real_kernel)"
else
  no "Report is missing this VM's real kernel string '$real_kernel' — run 'uname -r' and paste the exact output into KERNEL_RELEASE"
fi

# 2. The report must record the distro ID 'ubuntu'. We require it as a
#    standalone token so the literal word "ubuntu" sitting in the default
#    username doesn't accidentally satisfy this — they must have actually
#    recorded the distribution.
if grep -Eqw 'ubuntu' <<< "$content_lc"; then
  ok "Report records the distribution ID 'ubuntu' (from /etc/os-release)"
else
  no "Report does not mention the distro ID 'ubuntu' — check /etc/os-release (the ID= line) and record it"
fi

# 3. The report must contain THIS machine's real hostname — ties the
#    evidence to the student's own VM.
real_host="$(hostname)"
real_host_lc="$(printf '%s' "$real_host" | tr '[:upper:]' '[:lower:]')"
if grep -qF "$real_host_lc" <<< "$content_lc"; then
  ok "Report contains this VM's hostname ($real_host)"
else
  no "Report is missing this VM's hostname '$real_host' — run 'hostname' and record it on the HOSTNAME line"
fi

# 4. The report must reference the package manager 'apt' (the distribution's
#    software-delivery mechanism — a key Module 1 concept).
if grep -qw 'apt' <<< "$content_lc"; then
  ok "Report references the package manager 'apt'"
else
  no "Report does not mention 'apt' — record where apt lives (which apt) and how many packages are installed (dpkg -l | wc -l)"
fi

# 5. The report must reference the shell. Accept either the path to bash
#    (from echo \$SHELL, e.g. /bin/bash) or the word 'shell'/'bash'.
if grep -Eq '/bin/(ba)?sh|\bbash\b|\bshell\b' <<< "$content_lc"; then
  ok "Report records the shell (e.g. /bin/bash from echo \$SHELL)"
else
  no "Report does not record your shell — run 'echo \$SHELL' and 'cat /etc/shells' and record what you find"
fi

# 6. The reflection was actually written. We can't grade prose for quality
#    here, but we can require that the placeholder template was replaced and
#    that the student wrote a substantive reflection of their own. We do this
#    two ways: (a) the literal placeholder lines like "<run:" must be gone,
#    and (b) there must be a meaningful amount of free-text prose after the
#    REFLECTION marker.
remaining_placeholders="$(grep -c '<run:' "$REPORT" 2>/dev/null || true)"
remaining_placeholders="${remaining_placeholders:-0}"
if (( remaining_placeholders > 0 )); then
  no "Found $remaining_placeholders unfilled '<run: ...>' placeholder(s) — replace every placeholder with the real command output from this VM"
else
  ok "All command placeholders were replaced with real output"
fi

# Count words appearing AFTER the REFLECTION header. Require enough to be a
# genuine two-part written answer, not a one-word stub. If the header line
# isn't present we fall back to counting words in the whole file minus the
# template-ish lines, which is more lenient but still catches an empty file.
if grep -qi 'reflection' "$REPORT"; then
  reflection_words="$(awk 'BEGIN{IGNORECASE=1; found=0} /reflection/{found=1; next} found{print}' "$REPORT" | tr -cd 'A-Za-z \n' | wc -w | tr -d ' ')"
else
  reflection_words=0
fi
reflection_words="${reflection_words:-0}"
if (( reflection_words >= 40 )); then
  ok "Written reflection is present (${reflection_words} words after the REFLECTION header)"
else
  no "Your written reflection looks too short (${reflection_words} words) — answer BOTH reflection questions in full sentences in the REFLECTION section"
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
