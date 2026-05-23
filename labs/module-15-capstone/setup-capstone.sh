#!/usr/bin/env bash
#
# setup-capstone.sh  —  Module 15: Comprehensive Review (Capstone)
#
# Builds the FULL capstone scenario inside your Multipass VM: an "inherited
# server" left in a messy, partly broken, partly insecure state. You bring it
# to a defined good state and write a handover report.
#
# Run it ONCE with sudo:
#     sudo bash setup-capstone.sh
#
# IMPORTANT (tell the student): SNAPSHOT THE VM FIRST so you can roll back.
#     (from your computer)  multipass stop labvm
#                           multipass snapshot --name pre-mod15 labvm
#                           multipass start labvm
#
# This script is SAFE and IDEMPOTENT: it removes any state left from a prior
# run before re-planting, so you can run it as many times as you like. It only
# touches the lab's own paths (/srv/inherited, /opt/finance, the inheritd
# service, /usr/local/bin lab tools, the diskhog fill file, and the student's
# own home). It does NOT modify any real system files.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash setup-capstone.sh"
  exit 1
fi

# Resolve the human running the lab (sudo makes $HOME root's). We seed and clean
# only THIS user's lab files.
REAL_USER="${SUDO_USER:-ubuntu}"
REAL_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)"
[[ -z "$REAL_HOME" ]] && REAL_HOME="/home/${REAL_USER}"

echo "[setup] Module 15 Capstone — planting the 'inherited server' scenario..."

# ===========================================================================
# CLEAN SLATE (idempotent): undo anything a previous run created so re-running
# always produces the same starting state.
# ===========================================================================
# Runaway process from a prior run.
pkill -f '/usr/local/bin/datacruncher' >/dev/null 2>&1 || true
# Service from a prior run.
if systemctl list-unit-files inheritd.service >/dev/null 2>&1; then
  systemctl stop inheritd.service    >/dev/null 2>&1 || true
  systemctl disable inheritd.service >/dev/null 2>&1 || true
fi
rm -f /etc/systemd/system/inheritd.service
systemctl daemon-reload
systemctl reset-failed inheritd.service >/dev/null 2>&1 || true
# Lab directories and tools.
rm -rf /srv/inherited /opt/finance
rm -f  /usr/local/bin/datacruncher /usr/local/bin/inheritd-report.sh
# The student's deliverables from a prior run.
rm -f "${REAL_HOME}/module15-handover-report.txt"
rm -f "${REAL_HOME}/inherited-backup.tar.gz"

# ===========================================================================
# PART A — a messy directory tree that needs organizing.
# /srv/inherited is a dumping ground: logs, configs, and reports all mixed
# together at the top level, plus junk. The spec asks the student to SORT
# files into logs/, configs/, and reports/ subdirectories by extension.
# (Wrong on purpose: everything is flat and unsorted.)
# ===========================================================================
echo "[setup] Part A: planting a messy directory tree at /srv/inherited..."
mkdir -p /srv/inherited
# Log files (should end up in logs/)
for n in web app auth; do
  echo "$(date '+%Y-%m-%d') ${n} service started" > "/srv/inherited/${n}.log"
done
# Config files (should end up in configs/)
for n in web app database; do
  printf '# %s configuration (inherited)\nenabled=true\n' "$n" > "/srv/inherited/${n}.conf"
done
# Report files (should end up in reports/)
for n in january february march; do
  echo "Monthly report for ${n}" > "/srv/inherited/${n}.report"
done
# Junk that should be cleaned up (the spec asks for tmp files to be removed).
touch "/srv/inherited/core.dump.tmp" "/srv/inherited/old-session.tmp" "/srv/inherited/.cache.tmp"
chown -R "${REAL_USER}:${REAL_USER}" /srv/inherited

# ===========================================================================
# PART B — a shared finance directory with WRONG ownership/permissions.
# The "finance" group should own /opt/finance, members collaborate inside it,
# and others should get nothing. Right now it is owned by root and world-open.
# (Wrong on purpose.)
# ===========================================================================
echo "[setup] Part B: planting a mis-permissioned shared directory at /opt/finance..."
groupadd -f finance
usermod -aG finance "${REAL_USER}" || true
mkdir -p /opt/finance
echo "Q1 budget figures (confidential)" > /opt/finance/budget.txt
# Wrong on purpose: root-owned and world-writable.
chown -R root:root /opt/finance
chmod -R 777 /opt/finance

# ===========================================================================
# PART C — a runaway CPU-hogging process planted as a "data cruncher" the
# previous admin left running. The student must find and stop it (ps/top/kill).
# ===========================================================================
echo "[setup] Part C: launching a runaway 'datacruncher' process..."
cat > /usr/local/bin/datacruncher <<'EOF'
#!/usr/bin/env bash
# Pretends to crunch data; actually just burns a CPU core forever.
while true; do : ; done
EOF
chmod +x /usr/local/bin/datacruncher
setsid /usr/local/bin/datacruncher >/dev/null 2>&1 < /dev/null &
echo $! > /run/datacruncher.pid || true

# ===========================================================================
# PART D — a big file eating disk space the student must locate (df/du) and
# report. Created sparsely-ish but with real data so `du` reports real size.
# Lives under /srv/inherited so it is inside the area being investigated.
# (~200 MB; safe on a default Multipass disk.)
# ===========================================================================
echo "[setup] Part D: creating a large file that consumes disk space..."
mkdir -p /srv/inherited/archive-staging
dd if=/dev/zero of=/srv/inherited/archive-staging/bigdata.bin bs=1M count=200 status=none
chown -R "${REAL_USER}:${REAL_USER}" /srv/inherited/archive-staging

# ===========================================================================
# PART E — a required service that should be running but is NOT enabled/started.
# Unlike Module 14 (which was broken), this unit is CORRECT — it just needs to
# be enabled and started. The student must bring it up.
# ===========================================================================
echo "[setup] Part E: installing the 'inheritd' service (present but not running)..."
cat > /usr/local/bin/inheritd-report.sh <<'EOF'
#!/usr/bin/env bash
# inheritd-report.sh — a tiny heartbeat the inheritd service runs.
# Writes one line to the journal then stays alive so the service is "active".
echo "inheritd: heartbeat at $(date '+%Y-%m-%d %H:%M:%S %Z') on host $(hostname)"
# Stay running so this is a real long-lived (Type=simple) service to manage.
while true; do sleep 3600; done
EOF
chmod 0755 /usr/local/bin/inheritd-report.sh

cat > /etc/systemd/system/inheritd.service <<'EOF'
[Unit]
Description=Inherited Heartbeat Daemon (capstone lab)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/inheritd-report.sh
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
# Leave it STOPPED and DISABLED on purpose — the student must enable + start it.
systemctl disable inheritd.service >/dev/null 2>&1 || true
systemctl stop    inheritd.service >/dev/null 2>&1 || true

echo
echo "[setup] Done. You have inherited a server in a messy, partly insecure,"
echo "        partly broken state. The README gives you the desired END STATE"
echo "        (the specifications). It does NOT give click-by-click steps —"
echo "        applying the right commands is the capstone."
echo
echo "        When finished, grade yourself with:  sudo bash check-capstone.sh"
