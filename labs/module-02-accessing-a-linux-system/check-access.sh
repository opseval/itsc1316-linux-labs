#!/usr/bin/env bash
#
# check-access.sh  —  Module 2: Accessing a Linux System
#
# Self-grades your work. Some checks read /etc/shadow (via 'passwd -S'),
# which requires root, so run this with sudo:
#     sudo bash check-access.sh
#
# It confirms: the two users exist, their passwords are actually SET (not
# empty/locked), NTP time synchronization is active, and your evidence file
# exists with the required tokens (including this VM's real hostname).
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

# Resolve the evidence file in the real user's home even when run via sudo.
LAB_USER="${SUDO_USER:-$(id -un)}"
LAB_HOME="$(getent passwd "$LAB_USER" | cut -d: -f6)"
NOTES="${LAB_HOME}/module2-access-notes.txt"

echo "=== Module 2 Lab Check: Accessing a Linux System ==="
echo

if [[ $EUID -ne 0 ]]; then
  echo "  NOTE: not running as root. The password-status checks read"
  echo "        /etc/shadow and need sudo. Re-run with:  sudo bash check-access.sh"
  echo
fi

# Helper: report the password status field from 'passwd -S'.
#   passwd -S <user>  prints:  <user> P 04/01/2026 ...   (P=set, L=locked, NP=none)
# We must run it as root; if we're not root the field comes back empty and
# we report that clearly rather than passing by accident.
pw_status_field() {
  local u="$1"
  passwd -S "$u" 2>/dev/null | awk '{print $2}'
}

# 1 & 2. Each user exists AND has a password that is actually SET (status P).
for u in devops1 devops2; do
  if id "$u" &>/dev/null; then
    if [[ $EUID -ne 0 ]]; then
      no "Cannot verify $u's password status without root — re-run with 'sudo bash check-access.sh'"
    else
      st="$(pw_status_field "$u")"
      case "$st" in
        P)
          ok "User '$u' exists and has a password SET (passwd -S status: P)"
          ;;
        L)
          no "User '$u' exists but the password is LOCKED (status L) — set it with 'sudo passwd $u' (this also unlocks it)"
          ;;
        NP|"")
          no "User '$u' exists but has NO usable password (status '${st:-empty}') — set one with 'sudo passwd $u'"
          ;;
        *)
          no "User '$u' password status is '$st', expected 'P' (set) — run 'sudo passwd $u'"
          ;;
      esac
    fi
  else
    no "User '$u' does not exist — re-run 'sudo bash setup-access.sh'"
  fi
done

# 3. NTP time synchronization is active. timedatectl reports either
#    'System clock synchronized: yes' or 'NTP service: active' (wording
#    varies slightly by release), and/or NTPSynchronized=yes in 'show'.
#    Accept any of these as proof sync is on.
synced="no"
tdc="$(timedatectl 2>/dev/null || true)"
tdc_show="$(timedatectl show 2>/dev/null || true)"
if grep -qiE 'System clock synchronized:\s*yes' <<< "$tdc"; then synced="yes"; fi
if grep -qiE 'NTP service:\s*active' <<< "$tdc"; then synced="yes"; fi
if grep -qiE 'NTPSynchronized=yes' <<< "$tdc_show"; then synced="yes"; fi
if [[ "$synced" == "yes" ]]; then
  ok "Time synchronization is active (timedatectl reports the clock is synced / NTP active)"
else
  no "NTP synchronization does not look active — run 'sudo timedatectl set-ntp true', wait a few seconds, then check 'timedatectl' for 'System clock synchronized: yes'"
fi

# 4. Evidence file exists and is non-empty.
if [[ -s "$NOTES" ]]; then
  ok "Evidence file exists and is non-empty: $NOTES"
  content_lc="$(tr '[:upper:]' '[:lower:]' < "$NOTES")"

  # 4a. Contains this VM's real hostname.
  real_host="$(hostname)"
  real_host_lc="$(printf '%s' "$real_host" | tr '[:upper:]' '[:lower:]')"
  if grep -qF "$real_host_lc" <<< "$content_lc"; then
    ok "Evidence file contains this VM's hostname ($real_host)"
  else
    no "Evidence file is missing this VM's hostname '$real_host' — run 'hostname' and record it"
  fi

  # 4b. References both access methods AND has concrete SSH evidence: an IP
  #     address recorded for the SSH session, plus a 'pts/' session marker (or
  #     equivalent SSH-session fingerprint). The 'ssh' and 'multipass' tokens
  #     alone aren't proof — they already appear in the starter template.
  has_ip=0; has_pts=0
  grep -Eq '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$NOTES" 2>/dev/null && has_ip=1
  grep -Eqi 'pts/[0-9]+|sshd?:?\s+session|accepted publickey|from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "$NOTES" 2>/dev/null && has_pts=1
  if grep -q 'ssh' <<< "$content_lc" && grep -q 'multipass' <<< "$content_lc" && (( has_ip == 1 )) && (( has_pts == 1 )); then
    ok "Evidence file documents both access methods AND records SSH session evidence (IP + pts/ marker)"
  elif (( has_ip == 0 )); then
    no "Evidence file must include the IP address you SSH'd to (4 numbers like 10.122.45.7), not just the literal '<that-ip>' placeholder"
  elif (( has_pts == 0 )); then
    no "Evidence file must include real SSH session evidence — paste the 'who' line showing your 'pts/' session, or an sshd log line"
  else
    no "Evidence file must document BOTH access methods — your 'multipass shell' session and your 'ssh ubuntu@<ip>' session"
  fi

  # 4c. References password status for the two users (the token 'devops').
  if grep -q 'devops1' <<< "$content_lc" && grep -q 'devops2' <<< "$content_lc"; then
    ok "Evidence file records both users' password status (devops1 and devops2)"
  else
    no "Evidence file must record the 'sudo passwd -S devops1' and 'devops2' status lines"
  fi

  # 4d. References time sync and the docs task.
  if grep -qiE 'ntp|synchronized|timedatectl' <<< "$content_lc"; then
    ok "Evidence file documents the time-synchronization check"
  else
    no "Evidence file must record your 'timedatectl' time-sync findings"
  fi
  if grep -qiE 'man |--help|\btype\b' <<< "$content_lc"; then
    ok "Evidence file documents the built-in-docs task (man / --help / type)"
  else
    no "Evidence file must record the command you researched with man, --help, and type"
  fi

  # 4e. All template placeholders were replaced.
  remaining="$(grep -c '<run:' "$NOTES" 2>/dev/null || true)"
  remaining="${remaining:-0}"
  # Also catch the angle-bracket free-text placeholders that don't start with 'run:'
  remaining_other="$(grep -cE '<[^>]+>' "$NOTES" 2>/dev/null || true)"
  remaining_other="${remaining_other:-0}"
  if (( remaining == 0 && remaining_other == 0 )); then
    ok "All template placeholders were replaced with real answers"
  else
    no "Found unfilled placeholders ($remaining '<run:...>' + $remaining_other total '<...>') — replace every '<...>' with real output/answers"
  fi

  # 4f. The reflection was actually written (enough prose after the header).
  if grep -qi 'reflection' "$NOTES"; then
    rwords="$(awk 'BEGIN{IGNORECASE=1; found=0} /reflection/{found=1; next} found{print}' "$NOTES" | tr -cd 'A-Za-z \n' | wc -w | tr -d ' ')"
  else
    rwords=0
  fi
  rwords="${rwords:-0}"
  if (( rwords >= 50 )); then
    ok "Written reflection is present (${rwords} words after the REFLECTION header)"
  else
    no "Your written reflection looks too short (${rwords} words) — answer all three reflection questions in full sentences"
  fi
else
  no "Evidence file $NOTES not found or empty — run 'sudo bash setup-access.sh' for the template, then fill it in"
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
