#!/usr/bin/env bash
#
# setup-devices.sh  —  Module 11: Devices, Mounting & Persistence
#
# Prepares a SAFE practice environment for the loop-device / mkfs / mount /
# fstab / fsck workflow. Run ONCE with sudo:
#     sudo bash setup-devices.sh
#
# IMPORTANT — SAFETY:
#   * Take a VM snapshot BEFORE running this lab:
#       (from your computer)  multipass snapshot --name pre-mod11 labvm
#   * Everything in this lab targets a FILE-BACKED LOOP DEVICE
#     (~/loopdisk.img). You must NEVER run mkfs/fsck against your real disk.
#
# This script only creates the practice IMAGE FILE and installs the small
# tools the lab needs (genisoimage for the ISO step). Attaching, formatting,
# mounting, fstab, and fsck are done BY THE STUDENT in the lab steps.
#
# It is idempotent: it detaches any leftover loop device and unmounts any
# leftover mount points from a previous attempt before recreating the image.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash setup-devices.sh"
  exit 1
fi

# The image lives in the invoking user's home dir. When run via sudo, $HOME may
# be /root, so resolve the real user's home explicitly.
TARGET_USER="${SUDO_USER:-ubuntu}"
USER_HOME="$(eval echo "~${TARGET_USER}")"
IMG="${USER_HOME}/loopdisk.img"
MNT="/mnt/practicedisk"
ISO_MNT="/mnt/iso"

echo "[setup] Cleaning up any leftover state from a previous attempt..."
# Unmount practice mount points if mounted (ignore errors if not mounted).
umount "${MNT}" 2>/dev/null || true
umount "${ISO_MNT}" 2>/dev/null || true
# Detach any loop devices currently backed by our image.
if [[ -e "${IMG}" ]]; then
  while read -r loopdev; do
    [[ -n "${loopdev}" ]] && losetup -d "${loopdev}" 2>/dev/null || true
  done < <(losetup -j "${IMG}" 2>/dev/null | cut -d: -f1)
fi
rm -f "${IMG}"

echo "[setup] Installing tools needed for the ISO step (genisoimage)..."
# Non-fatal if apt is unavailable/offline; the README has an explanation path.
if command -v apt-get >/dev/null 2>&1; then
  DEBIAN_FRONTEND=noninteractive apt-get update -qq >/dev/null 2>&1 || true
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq genisoimage >/dev/null 2>&1 \
    || echo "[setup] NOTE: could not install genisoimage (offline?). The README explains the fallback."
fi

echo "[setup] Creating the 200 MB practice-disk image at ${IMG} ..."
if command -v fallocate >/dev/null 2>&1 && fallocate -l 200M "${IMG}" 2>/dev/null; then
  :
else
  echo "[setup] fallocate unavailable; using dd (this takes a moment)..."
  dd if=/dev/zero of="${IMG}" bs=1M count=200 status=none
fi
# The image file belongs to the student, not root, so they can manage it.
chown "${TARGET_USER}:${TARGET_USER}" "${IMG}" 2>/dev/null || true

echo
echo "[setup] Done. Your practice disk image is ready: ${IMG}"
echo
echo "  SAFETY REMINDERS:"
echo "    * Snapshot the VM first if you haven't:  multipass snapshot --name pre-mod11 labvm"
echo "    * Only ever target the /dev/loopN device that 'losetup --find --show' reports."
echo "    * NEVER run mkfs or fsck against /dev/sda, /dev/vda, or any real disk."
echo
echo "  Next: follow the lab steps (losetup -> mkfs -> mount -> fstab -> ISO -> fsck),"
echo "  record evidence in ~/module11-devices-report.txt, then grade yourself with:"
echo "    sudo bash check-devices.sh"
