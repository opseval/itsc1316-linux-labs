#!/usr/bin/env bash
#
# setup-systemd.sh  —  Module 12: System Initialization & Services
#
# Prepares your Multipass VM for the systemd lab. Run it ONCE with sudo:
#     sudo bash setup-systemd.sh
#
# Unlike the Module 14 break/fix lab, this script does NOT break anything.
# It simply drops a tiny health-check script at /usr/local/bin/labhealth.sh
# (the script your service will run) and guarantees a CLEAN SLATE by removing
# any labhealth.service unit left over from a previous run, so the lab is
# fully idempotent / re-runnable.
#
# IMPORTANT (tell the student): snapshot the VM first so you can roll back:
#     (from your computer)  multipass stop labvm
#                           multipass snapshot --name pre-mod12 labvm
#                           multipass start labvm
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash setup-systemd.sh"
  exit 1
fi

echo "[setup] Module 12 — preparing a clean slate for the systemd lab..."

# --- Clean slate: remove any prior labhealth unit so re-runs are idempotent ---
# Stop and disable a leftover unit before deleting its file, then forget any
# 'failed' bookkeeping. None of this errors out if the unit was never created.
if systemctl list-unit-files labhealth.service >/dev/null 2>&1; then
  systemctl stop labhealth.service    >/dev/null 2>&1 || true
  systemctl disable labhealth.service >/dev/null 2>&1 || true
fi
rm -f /etc/systemd/system/labhealth.service
systemctl daemon-reload
systemctl reset-failed labhealth.service >/dev/null 2>&1 || true

# Remove any stale evidence report so the student starts fresh.
# (It lives in the student's home dir; only delete the lab's own file.)
if [[ -n "${SUDO_USER:-}" ]]; then
  rm -f "/home/${SUDO_USER}/module12-systemd-report.txt"
fi

# --- Drop the health-check script the student's service will run ---
# This is a SAFE, tiny script: it writes one timestamped status line, logged
# to the journal via stdout, then exits 0. The student does NOT edit this;
# they write the *unit file* that runs it. We keep the script here (not in the
# unit) so the centerpiece task — authoring a real .service file — is the work.
install -d -m 0755 /usr/local/bin
cat > /usr/local/bin/labhealth.sh <<'EOF'
#!/usr/bin/env bash
# labhealth.sh — a tiny "is this box healthy?" reporter for the Module 12 lab.
# Prints a few facts to stdout. When run by systemd, stdout goes to the journal,
# so `journalctl -u labhealth.service` will show these lines.
echo "labhealth: report at $(date '+%Y-%m-%d %H:%M:%S %Z') on host $(hostname)"
echo "labhealth: uptime -> $(uptime -p 2>/dev/null || uptime)"
echo "labhealth: root filesystem usage -> $(df -h / | awk 'NR==2 {print $5" used of "$2}')"
echo "labhealth: health check OK"
exit 0
EOF
chmod 0755 /usr/local/bin/labhealth.sh

echo
echo "[setup] Done. Nothing is broken — this lab is build/manage, not break/fix."
echo "        A health-check script is now at /usr/local/bin/labhealth.sh"
echo "        Your job (see the README): write the labhealth.service unit that"
echo "        runs it, manage an existing service, and set localization."
echo "        Grade yourself when finished with:  sudo bash check-systemd.sh"
echo "          (sudo is required — the check reads journalctl and systemd state.)"
