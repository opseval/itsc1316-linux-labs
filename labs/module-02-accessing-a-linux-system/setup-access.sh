#!/usr/bin/env bash
#
# setup-access.sh  —  Module 2: Accessing a Linux System
#
# Builds the lab scenario inside your Multipass VM. Run it ONCE with sudo:
#     sudo bash setup-access.sh
#
# Creates two extra user accounts (devops1, devops2) whose passwords are
# DELIBERATELY left unset (locked) — part of the lab is setting them.
# Also drops a starter template for your access-notes evidence file.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash setup-access.sh"
  exit 1
fi

LAB_USER="${SUDO_USER:-ubuntu}"
LAB_HOME="$(getent passwd "$LAB_USER" | cut -d: -f6)"
NOTES="${LAB_HOME}/module2-access-notes.txt"

echo "[setup] Creating users devops1 and devops2 with NO password set yet..."
for u in devops1 devops2; do
  if ! id "$u" &>/dev/null; then
    # Create the account with a home dir and bash shell, but DO NOT set a
    # password. A fresh useradd account has a locked/unset password — the
    # student must set one with 'sudo passwd <user>'. That's the lab.
    useradd -m -s /bin/bash "$u"
  fi
  # Make sure the password really is unset/locked even on a re-run, so the
  # check is meaningful (idempotent: locking an account is safe to repeat).
  passwd -d "$u" >/dev/null 2>&1 || true   # clear any password
  passwd -l "$u" >/dev/null 2>&1 || true   # lock it (state the student must fix)
done

echo "[setup] Ensuring the systemd time daemon is present (you'll verify sync)..."
# systemd-timesyncd ships with Ubuntu 22.04; make sure it's enabled so the
# student can observe NTP synchronization with timedatectl. We don't force a
# particular sync state beyond enabling the service — verifying it is the lab.
systemctl enable --now systemd-timesyncd >/dev/null 2>&1 || true

echo "[setup] Preparing your evidence-file template at ${NOTES}"
if [[ -e "$NOTES" ]]; then
  echo "[setup] ${NOTES} already exists — leaving it alone so your work is safe."
else
  cat > "$NOTES" <<'EOF'
================================================================
 MODULE 2 ACCESS NOTES
 Replace each <...> with the REAL output / answer from YOUR vm.
 The check script verifies several of these against live state.
================================================================

# --- Identity (ties this file to your VM) ---
HOSTNAME:            <run: hostname>

# --- TASK 1: Access the VM two different ways ---
# (a) You are already in via 'multipass shell labvm'. Confirm it:
ACCESS_MULTIPASS:    <run: who   -- paste the line showing your session>
# (b) Now access it over SSH from your computer's terminal. Get the IP with
#     'multipass list', then 'ssh ubuntu@<ip>'. Multipass injects your key,
#     so no password is needed. Paste the IP you connected to and one line of
#     proof you were in over SSH (e.g. the output of 'who' showing a pts/ ssh
#     session, or the SSH login banner):
ACCESS_SSH_IP:       <the IP you used, e.g. 10.122.45.7>
ACCESS_SSH_PROOF:    <paste a line proving the SSH session worked>

# --- TASK 2: Set passwords for the two new users ---
# Set each one with: sudo passwd devops1   (and devops2). Then confirm the
# password is SET (status 'P') with: sudo passwd -S devops1
PASSWD_STATUS_D1:    <run: sudo passwd -S devops1   -- paste the line>
PASSWD_STATUS_D2:    <run: sudo passwd -S devops2   -- paste the line>
# Practice switching users (you do NOT need to stay logged in as them):
SU_PRACTICE_NOTE:    <one line: what 'su - devops1' did and how you got back>

# --- TASK 3: Verify time synchronization ---
TIMEDATECTL:         <run: timedatectl   -- paste the 'System clock synchronized'
                       and 'NTP service' lines>
TIMEDATECTL_SHOW:    <run: timedatectl show | grep -i ntp>

# --- TASK 4: Use built-in documentation ---
# Pick ANY command you were curious about. Show three ways to learn about it.
DOC_COMMAND:         <the command you researched, e.g. 'cp'>
DOC_TYPE:            <run: type <yourcommand>   -- is it a shell builtin or external?>
DOC_HELP:            <run: <yourcommand> --help   -- paste one useful line>
DOC_MAN:             <run: man <yourcommand>   -- paste the one-line NAME description>

# --- TASK 5: Logout vs shutdown understanding ---
LOGOUT_VS_SHUTDOWN:  <one sentence: the difference between 'logout' (or exit)
                       and 'sudo poweroff'. DO NOT actually power off now.>

================================================================
 REFLECTION (full sentences, your own words):

 1) GUI vs CLI: give one situation where a CLI is clearly the right
    tool and one where a GUI is, and why.

 2) Why does keeping a server's clock synced with a time server
    actually matter? Give a concrete consequence of a wrong clock.

 3) The command you researched in TASK 4: what is one thing you
    learned about it from man or --help that you did not know?
================================================================
EOF
  chown "$LAB_USER":"$LAB_USER" "$NOTES"
  chmod 644 "$NOTES"
  echo "[setup] Template created and owned by ${LAB_USER}."
fi

echo
echo "[setup] Done."
echo "        Users devops1 and devops2 exist but their passwords are LOCKED."
echo "        Set them with 'sudo passwd devops1' and 'sudo passwd devops2'."
echo "        Fill in ${NOTES} as you work."
echo "        When finished, grade yourself with:  sudo bash check-access.sh"
echo "          (sudo is required — the check reads /etc/shadow via passwd -S.)"
