#!/usr/bin/env bash
#
# setup-filesystem.sh  —  Module 4: Filesystems & Directory Navigation
#
# Builds the lab scenario inside your Multipass VM. Run it ONCE with sudo:
#     sudo bash setup-filesystem.sh
#
# It seeds a small, slightly messy "staging" directory in your home folder
# (~/mod04-staging) holding a few files that currently live in the wrong place.
# Part of the lab is reorganizing them into a proper structure under
# ~/Documents and finding them with `find`.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash setup-filesystem.sh"
  exit 1
fi

# Work in the invoking user's home (not root's, since we ran via sudo). Defaults
# to 'ubuntu' on Multipass; works correctly on cloud fallback VMs whose default
# user is something else.
REAL_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)"
[[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]] && TARGET_HOME="/home/${REAL_USER}"
STAGING="${TARGET_HOME}/mod04-staging"

echo "[setup] Preparing a clean ${STAGING} ..."
# Idempotent / re-runnable: clear any prior staging state first.
rm -rf "${STAGING}"
mkdir -p "${STAGING}"

# A few files dumped together in staging that BELONG in different subdirs once
# you build the structure under ~/Documents. (Not "broken" — just unsorted,
# the way a real download/scratch folder gets.)
echo "#!/usr/bin/env bash
echo 'nightly backup placeholder'" > "${STAGING}/backup.sh"

echo "df -h
free -m
uptime" > "${STAGING}/diskcheck.sh"

echo "Backup taken on a previous run. Keep for records." > "${STAGING}/old-backup.log"

echo "Notes about the utilities folder." > "${STAGING}/utilities-readme.txt"

# Give the whole staging tree to the invoking user so they can move files freely.
chown -R "${REAL_USER}:$(id -gn "$REAL_USER")" "${STAGING}"

echo
echo "[setup] Done. Unsorted files are waiting in ${STAGING}:"
ls -l "${STAGING}"
echo
echo "        Follow the lab instructions to explore the filesystem and to"
echo "        build & organize a directory structure under ~/Documents."
echo "        When finished, grade yourself with:  bash check-filesystem.sh"
