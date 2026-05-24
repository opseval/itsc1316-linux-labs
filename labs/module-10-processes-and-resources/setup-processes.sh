#!/usr/bin/env bash
#
# setup-processes.sh  —  Module 10: Processes and System Resources
#
# Builds the lab scenario inside your Multipass VM. Run it ONCE with sudo:
#     sudo bash setup-processes.sh
#
# It plants a deliberately RUNAWAY, CPU-hogging process (named
# 'labhog-runaway') that you must FIND and STOP during the lab, and drops a
# starter evidence report in your home directory.
#
# SAFETY NOTES:
#   - The hog is a plain shell 'while true' loop. It burns ONE CPU but cannot
#     harm your system, your files, or anything outside the VM. You will stop
#     it with `kill` as part of the lab; if you forget, it dies when the VM
#     stops.
#   - The script is idempotent: re-running it first kills any previous hog so
#     you never end up with several copies running.
#   - It changes no system services and modifies no files outside the project.
#     A snapshot is still recommended (see the lab README) so you can reset.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash setup-processes.sh"
  exit 1
fi

# Work out the human's home directory even though we're running as root via sudo.
TARGET_USER="${SUDO_USER:-ubuntu}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_HOME="${TARGET_HOME:-/home/ubuntu}"

HOG_BIN="/usr/local/bin/labhog-runaway"

echo "[setup] Installing the runaway-process binary at ${HOG_BIN} ..."
# A recognizable, clearly-named CPU hog. The distinctive name 'labhog-runaway'
# is what students will spot in `top`/`ps` and `pgrep` against.
cat > "$HOG_BIN" <<'EOF'
#!/usr/bin/env bash
# labhog-runaway: a deliberately runaway "background task" for the Module 10
# lab. It does nothing useful — it just burns one CPU core in a tight loop so
# you can practise finding and stopping a runaway process. Stop it with `kill`.
while true; do
  :
done
EOF
chmod +x "$HOG_BIN"

echo "[setup] Stopping any previous hog so we don't stack duplicates ..."
# Idempotent: clear prior runs (match the binary path, and the script name).
pkill -f 'labhog-runaway' >/dev/null 2>&1 || true
sleep 1

echo "[setup] Launching the runaway process (detached) ..."
# setsid + redirection detaches it so it survives this script and shows up as a
# normal background process owned by root in `ps`/`top`.
setsid "$HOG_BIN" >/dev/null 2>&1 < /dev/null &
HOG_PID=$!
echo "$HOG_PID" > /run/labhog-runaway.pid 2>/dev/null || true

# Drop a starter evidence report so students know the filename and headings.
REPORT="${TARGET_HOME}/module10-process-report.txt"
if [[ ! -f "$REPORT" ]]; then
  cat > "$REPORT" <<EOF
MODULE 10 EVIDENCE REPORT — Processes and System Resources
(Replace these placeholders with the real command output from your VM.)

Hostname:
(paste the output of:  hostname)

=== HOW I FOUND THE RUNAWAY PROCESS ===
Offending process NAME:
Offending process PID:
Command(s) I used to find it (e.g. top, ps aux, pgrep):

=== RESOURCE SNAPSHOTS ===
(paste output of:  ps aux | head , free -h , uptime/top header)

=== NICE / RENICE EVIDENCE ===
(paste output showing a process started with nice and adjusted with renice)
EOF
  chown "${TARGET_USER}:${TARGET_USER}" "$REPORT"
fi

echo
echo "[setup] Done. A runaway process is now burning CPU on this VM."
echo "        (PID withheld — finding it with top/ps/pgrep IS the lab.)"
echo "        Your job: FIND it, then STOP it with kill."
echo "        Starter evidence report: ${REPORT}"
echo "        Grade yourself when finished with:  bash check-processes.sh"
