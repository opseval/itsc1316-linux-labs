#!/usr/bin/env bash
#
# setup-shell.sh  —  Module 3: Working with the Shell (streams, pipes, scripts)
#
# Builds the lab scenario inside your Multipass VM. Run it ONCE with sudo:
#     sudo bash setup-shell.sh
#
# It seeds a small data directory in your home folder (~/mod03) with a couple
# of files you will redirect, pipe, and manipulate. Nothing here is "broken on
# purpose" — this lab is about DOING shell work, not fixing it — but the files
# give you something concrete and real to operate on.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash setup-shell.sh"
  exit 1
fi

# Work in the 'ubuntu' user's home, not root's, since the student works as ubuntu.
TARGET_HOME="/home/ubuntu"
LABDIR="${TARGET_HOME}/mod03"

echo "[setup] Preparing a clean ${LABDIR} ..."
# Idempotent / re-runnable: clear any prior state first.
rm -rf "${LABDIR}"
mkdir -p "${LABDIR}"

# A small CSV of fake server inventory the student will pipe through.
cat > "${LABDIR}/servers.csv" <<'EOF'
hostname,role,location,cpu
web01,web,dallas,4
web02,web,dallas,4
db01,database,austin,8
db02,database,austin,8
cache01,cache,dallas,2
app01,app,houston,4
app02,app,houston,4
mail01,mail,austin,2
EOF

# A file that already exists, so the student can practice redirecting into a
# file that is there (overwrite vs append).
echo "This file existed before you started the lab." > "${LABDIR}/existing.txt"

# Hand the directory and its contents to the ubuntu user so they can edit freely.
chown -R ubuntu:ubuntu "${LABDIR}"

echo
echo "[setup] Done. Your lab files are in ${LABDIR}:"
ls -l "${LABDIR}"
echo
echo "        Follow the lab instructions. When finished, grade yourself with:"
echo "          bash check-shell.sh"
