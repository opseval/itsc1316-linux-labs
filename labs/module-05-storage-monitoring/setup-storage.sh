#!/usr/bin/env bash
#
# setup-storage.sh  —  Module 5: Linux Filesystem Management (Storage Monitoring)
#
# Plants a realistic "disk hog" scenario inside your Multipass VM so you can
# practice finding what is consuming disk space. Run it ONCE (no sudo needed):
#     bash setup-storage.sh
#
# Everything it creates lives under ~/bigdata in YOUR home directory. It does
# NOT touch any system files and does NOT require root. It is idempotent:
# re-running it removes the previous scenario first.
#
set -euo pipefail

# Resolve the invoking user's home directory even if run oddly.
HOME_DIR="${HOME:-/home/ubuntu}"
HOG_DIR="${HOME_DIR}/bigdata"
BIG_FILE="${HOG_DIR}/hog.img"
MANY_DIR="${HOG_DIR}/manyfiles"

echo "[setup] Cleaning up any previous scenario under ${HOG_DIR}..."
rm -rf "${HOG_DIR}"

echo "[setup] Creating the disk-hog directory..."
mkdir -p "${HOG_DIR}"
mkdir -p "${MANY_DIR}"

# --- The single large file (the obvious consumer the student must locate). ---
# 200 MB. Prefer fallocate (instant); fall back to dd if fallocate is missing
# or the filesystem doesn't support it (e.g. some overlay/tmpfs setups).
echo "[setup] Creating a 200 MB file at ${BIG_FILE} ..."
if command -v fallocate >/dev/null 2>&1 && fallocate -l 200M "${BIG_FILE}" 2>/dev/null; then
  :
else
  echo "[setup] fallocate unavailable; using dd (this takes a moment)..."
  dd if=/dev/zero of="${BIG_FILE}" bs=1M count=200 status=none
fi

# --- A directory of MANY small files (the non-obvious consumer). ---
# 600 small files so `find ... | wc -l` is clearly large and du reports a
# non-trivial size, without taking long to create.
echo "[setup] Creating 600 small files in ${MANY_DIR} ..."
for i in $(seq 1 600); do
  # ~4 KB each so the directory has measurable size.
  printf 'log entry %s: the quick brown fox jumps over the lazy dog\n' "$i" \
    | head -c 4096 > "${MANY_DIR}/file_$(printf '%04d' "$i").log"
done

echo
echo "[setup] Done. A disk-hog scenario now lives under ${HOG_DIR}:"
echo "          - one large file:  ${BIG_FILE}"
echo "          - many small files: ${MANY_DIR}/ (600 files)"
echo
echo "        Your job: investigate with df / du / find, document it in"
echo "        ~/module5-storage-report.txt, then grade yourself with:"
echo "          bash check-storage.sh"
