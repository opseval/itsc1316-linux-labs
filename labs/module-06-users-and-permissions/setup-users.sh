#!/usr/bin/env bash
#
# setup-users.sh  —  Module 6: Users, Ownership, and Permissions
#
# Builds the lab scenario inside your Multipass VM. Run it ONCE with sudo:
#     sudo bash setup-users.sh
#
# It creates a shared "salesteam" group, two extra users, a /salesteam
# directory, and a report-generating script with deliberately wrong
# permissions for you to fix.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash setup-users.sh"
  exit 1
fi

echo "[setup] Creating the salesteam group..."
groupadd -f salesteam

echo "[setup] Creating users avery and jordan..."
for u in avery jordan; do
  if ! id "$u" &>/dev/null; then
    useradd -m -s /bin/bash -G salesteam "$u"
    echo "${u}:lab6-${u}" | chpasswd
  fi
done

# Make sure the default 'ubuntu' user is in the salesteam group too,
# since that is the account you work from.
usermod -aG salesteam ubuntu

echo "[setup] Building /salesteam directory and seed files..."
mkdir -p /salesteam
# Start ownership WRONG on purpose: owned by root, so the student must fix it.
chown root:root /salesteam
chmod 755 /salesteam

# Drop a report-generating script with the WRONG permissions (not executable,
# world-readable). The student must lock it down and make it run.
cat > /salesteam/generate_reports.sh <<'EOF'
#!/usr/bin/env bash
# Generates three quarterly sales reports in the current directory.
for q in Q1 Q2 Q3; do
  echo "Sales report for ${q} - generated $(date)" > "/salesteam/${q}-report.xls"
done
echo "Three quarterly reports created."
EOF

# Wrong on purpose: not executable, owned by root.
chown root:root /salesteam/generate_reports.sh
chmod 644 /salesteam/generate_reports.sh

echo
echo "[setup] Done. The scenario is intentionally MISCONFIGURED."
echo "        Your job is described in the lab instructions."
echo "        When finished, grade yourself with:  bash check-users.sh"
