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

# Work in the invoking user's home (not root's, since we ran via sudo). Defaults
# to 'ubuntu' on Multipass; works correctly on cloud fallback VMs whose default
# user is something else.
REAL_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)"
[[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]] && TARGET_HOME="/home/${REAL_USER}"
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

# Hand the directory and its contents to the invoking user so they can edit freely.
chown -R "${REAL_USER}:$(id -gn "$REAL_USER")" "${LABDIR}"

echo
echo "[setup] Done. Your lab files are in ${LABDIR}:"
ls -l "${LABDIR}"
echo
echo "        Follow the lab instructions. When finished, grade yourself with:"
echo "          bash check-shell.sh"
