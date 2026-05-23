#!/usr/bin/env bash
#
# check-systemd.sh  —  Module 12: System Initialization & Services
#
# Self-grades your work. Run it (some checks read root-only systemd state, so
# run with sudo for the most accurate results):
#     sudo bash check-systemd.sh
#
# It also works without sudo, but a couple of checks fall back to "best effort"
# and will tell you to re-run with sudo if they can't read what they need.
#
# Prints PASS/FAIL for each requirement. Exit code is 0 only when everything
# passes. Fix any FAILs and run it again — exactly what an admin does after a
# change: re-test until the system is in the desired state.
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

UNIT="labhealth.service"
UNIT_FILE="/etc/systemd/system/${UNIT}"

# The evidence report lives in the home dir of the human running the lab. When
# this script is invoked with sudo, $HOME is root's, so resolve the real user.
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)
[[ -z "$REAL_HOME" ]] && REAL_HOME="$HOME"
REPORT="${REAL_HOME}/module12-systemd-report.txt"

echo "=== Module 12 Lab Check: System Initialization & Services ==="
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
# 1. The labhealth.service unit FILE exists and points at the lab's script.
#    We require the real ExecStart so a student can't pass with an empty stub.
# ---------------------------------------------------------------------------
if [[ -f "$UNIT_FILE" ]]; then
  if grep -Eq '^[[:space:]]*ExecStart=.*labhealth\.sh' "$UNIT_FILE"; then
    ok "$UNIT unit file exists and its ExecStart runs /usr/local/bin/labhealth.sh"
  else
    no "$UNIT_FILE exists but its ExecStart= line does not run labhealth.sh — point it at /usr/local/bin/labhealth.sh"
  fi
else
  no "$UNIT_FILE does not exist — create the unit file, then run 'sudo systemctl daemon-reload'"
fi

# ---------------------------------------------------------------------------
# 2. The unit is ENABLED (will start on boot). 'enabled' or 'enabled-runtime'
#    both count. 'static'/'disabled'/empty do not — the lab asks for enable.
# ---------------------------------------------------------------------------
enabled=$(systemctl is-enabled "$UNIT" 2>/dev/null || true)
if [[ "$enabled" == "enabled" || "$enabled" == "enabled-runtime" ]]; then
  ok "$UNIT is enabled (will start at boot) [is-enabled=$enabled]"
else
  no "$UNIT is not enabled (is-enabled=${enabled:-unknown}) — run 'sudo systemctl enable --now $UNIT'"
fi

# ---------------------------------------------------------------------------
# 3. The unit is/was ACTIVE — proof it actually RAN. This is the subtle part:
#    a Type=simple/oneshot script that does its job and exits 0 will report
#    is-active = 'inactive' (dead) or 'failed' depending on RemainAfterExit,
#    NOT 'active'. So "did it run?" cannot be answered by is-active alone.
#    We accept ANY of these as proof the service ran successfully:
#      (a) is-active == active/activating  (a long-running or RemainAfterExit unit), OR
#      (b) the journal for the unit shows our script's success line, OR
#      (c) the unit's last run result was success (Result=success / ExecMainStatus=0).
#    We explicitly REJECT a unit whose last result was a failure.
# ---------------------------------------------------------------------------
active=$(systemctl is-active "$UNIT" 2>/dev/null || true)

# (c) Inspect the service's recorded result, if systemd knows about the unit.
result=$(systemctl show "$UNIT" -p Result --value 2>/dev/null || true)
exitcode=$(systemctl show "$UNIT" -p ExecMainStatus --value 2>/dev/null || true)

# (b) Look for the script's own success marker in the journal for this unit.
#     Needs root to read other units' logs reliably; tolerate failure.
journal_ok=0
if journalctl -u "$UNIT" -n 200 --no-pager 2>/dev/null | grep -q "labhealth: health check OK"; then
  journal_ok=1
fi

ran_ok=0
if [[ "$active" == "active" || "$active" == "activating" ]]; then
  ran_ok=1
elif (( journal_ok == 1 )); then
  ran_ok=1
elif [[ -f "$UNIT_FILE" && ( "$result" == "success" || "$exitcode" == "0" ) ]]; then
  # Only trust a 'success' Result if the unit file actually exists — systemd
  # reports a benign default for unknown units, which must not pass this check.
  ran_ok=1
fi

if [[ "$result" == "exit-code" || "$result" == "core-dump" || "$result" == "signal" || "$result" == "timeout" ]]; then
  # Last run ended in failure — that overrides everything: the service is broken.
  no "$UNIT ran but FAILED (Result=$result, exit=$exitcode) — check 'systemctl status $UNIT' and 'journalctl -u $UNIT'; fix the unit and 'systemctl restart $UNIT'"
elif (( ran_ok == 1 )); then
  ok "$UNIT is/was active and ran successfully (is-active=$active, Result=${result:-?}, journal-marker=$journal_ok)"
else
  # Could not prove it ran. If we likely lacked permission to read the journal,
  # nudge toward sudo rather than failing the student for our own blind spot.
  if [[ $EUID -ne 0 ]]; then
    no "could not confirm $UNIT ran — re-run this check with sudo so it can read the unit's journal ('sudo bash check-systemd.sh'), or run 'systemctl start $UNIT' and check 'journalctl -u $UNIT'"
  else
    no "$UNIT has not run successfully yet — run 'sudo systemctl start $UNIT', then confirm with 'journalctl -u $UNIT' that it printed 'labhealth: health check OK'"
  fi
fi

# ---------------------------------------------------------------------------
# 4. Timezone was SET. The README asks the student to set the VM timezone to
#    America/Chicago (the course's region) with timedatectl. We read the live
#    systemd state, not a config file, so it reflects the real setting.
# ---------------------------------------------------------------------------
EXPECTED_TZ="America/Chicago"
tz=$(timedatectl show -p Timezone --value 2>/dev/null || true)
if [[ -z "$tz" ]]; then
  # Fallback for environments where 'show' is unavailable.
  tz=$(timedatectl 2>/dev/null | awk -F': ' '/Time zone/ {print $2}' | awk '{print $1}')
fi
if [[ "$tz" == "$EXPECTED_TZ" ]]; then
  ok "system timezone is set to $EXPECTED_TZ (timedatectl)"
else
  no "system timezone is '${tz:-unknown}', expected $EXPECTED_TZ — run 'sudo timedatectl set-timezone $EXPECTED_TZ'"
fi

# ---------------------------------------------------------------------------
# 5. Evidence report exists, is non-trivial, is tied to THIS VM (its hostname),
#    and captures the required command outputs + the student's explanations.
#    Anchoring to the live hostname makes a fabricated/borrowed file fail here.
# ---------------------------------------------------------------------------
HOST="$(hostname)"
if [[ ! -f "$REPORT" ]]; then
  no "evidence file $REPORT not found — create it per the README (it must include your hostname and the captured command outputs)"
else
  problems=()

  # 5a. Must contain this VM's actual hostname so it can't be a generic copy.
  if ! grep -qiF "$HOST" "$REPORT"; then
    problems+=("missing this VM's hostname ('$HOST') — paste your 'hostname' output into the report")
  fi

  # 5b. Must show evidence of the boot/init inspection commands.
  grep -q "systemd-analyze" "$REPORT" 2>/dev/null \
    || problems+=("no 'systemd-analyze' output — capture 'systemd-analyze' and 'systemd-analyze blame'")

  # 5c. Must show the default target (multi-user vs graphical discussion).
  grep -Eq "multi-user\.target|graphical\.target|get-default" "$REPORT" 2>/dev/null \
    || problems+=("no default-target evidence — capture 'systemctl get-default' and explain multi-user vs graphical")

  # 5d. Must show the labhealth service / journal evidence.
  grep -Eq "labhealth" "$REPORT" 2>/dev/null \
    || problems+=("no labhealth evidence — paste 'systemctl status labhealth.service' and its 'journalctl -u labhealth.service' output")

  # 5e. Must show localization evidence (timedatectl AND localectl).
  grep -q "timedatectl" "$REPORT" 2>/dev/null \
    || problems+=("no 'timedatectl' output — paste it to document the timezone you set")
  grep -q "localectl" "$REPORT" 2>/dev/null \
    || problems+=("no 'localectl' output — paste it to document the system locale/keymap")

  # 5f. Must contain real written reasoning, not just pasted command output.
  #     Require a reasonable amount of prose by word count.
  words=$(wc -w < "$REPORT" 2>/dev/null || echo 0)
  if (( words < 120 )); then
    problems+=("the report is very short ($words words) — add your written explanations (boot process, why ordered startup matters citing your numbers, graphical vs text, localization)")
  fi

  if (( ${#problems[@]} == 0 )); then
    ok "evidence report $REPORT is present, tied to host '$HOST', and includes the required outputs + writeup"
  else
    no "evidence report problems:"
    for p in "${problems[@]}"; do echo "          - $p"; done
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
