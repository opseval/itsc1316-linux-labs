#!/usr/bin/env bash
#
# setup-security.sh  —  Module 14: Security & Troubleshooting Foundations
#
# Builds a deliberately INSECURE and partly BROKEN system for you to
# investigate and repair. Run ONCE with sudo:
#     sudo bash setup-security.sh
#
# IMPORTANT: take a VM snapshot BEFORE running this, so you can restore if
# you get stuck:  (from your computer)  multipass snapshot labvm
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash setup-security.sh"
  exit 1
fi

echo "[setup] Planting security and troubleshooting issues..."

# --- Issue 1: a custom SUID-root binary that should NOT be SUID ---
# Copy a harmless tool and set the SUID bit on it as if a careless admin did so.
cp /bin/cp /usr/local/bin/backup-helper
chown root:root /usr/local/bin/backup-helper
chmod 4755 /usr/local/bin/backup-helper   # 4xxx = SUID set (the problem)

# --- Issue 2: a world-writable sensitive file ---
mkdir -p /opt/payroll
echo "employee,salary
avery,72000
jordan,68000" > /opt/payroll/salaries.csv
chmod 666 /opt/payroll/salaries.csv        # world-writable (the problem)
chown root:root /opt/payroll/salaries.csv

# --- Issue 3: a "system optimizer" cron-style hog the student must find ---
# A runaway process that pegs a CPU, simulating the "free optimizer" scenario.
cat > /usr/local/bin/sysoptimizer <<'EOF'
#!/usr/bin/env bash
# Pretends to be a helpful optimizer; actually just burns CPU.
while true; do : ; done
EOF
chmod +x /usr/local/bin/sysoptimizer
# Launch it in the background, detached, so it shows up in process listings.
setsid /usr/local/bin/sysoptimizer >/dev/null 2>&1 < /dev/null &
echo $! > /run/sysoptimizer.pid || true

# --- Issue 4: a failed/oddly-configured service for troubleshooting ---
cat > /etc/systemd/system/reportd.service <<'EOF'
[Unit]
Description=Nightly Report Daemon (lab)
After=network.target

[Service]
Type=simple
# BROKEN ON PURPOSE: points at a binary that does not exist.
ExecStart=/usr/local/bin/reportd-does-not-exist
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable reportd.service >/dev/null 2>&1 || true
systemctl start reportd.service >/dev/null 2>&1 || true

echo
echo "[setup] Done. Your system now has several security and operational"
echo "        problems. The lab instructions tell you what to investigate."
echo "        Grade yourself when finished with:  bash check-security.sh"
