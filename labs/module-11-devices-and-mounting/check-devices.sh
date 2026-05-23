#!/usr/bin/env bash
#
# check-devices.sh  —  Module 11: Devices, Mounting & Persistence
#
# Self-grades your work. Some checks read root-owned state (blkid, fstab), so
# run it with sudo:
#     sudo bash check-devices.sh
#
# Prints PASS/FAIL for each requirement. Exit code is 0 only if everything
# passes. Checks are anchored to durable, real state (the formatted loop image,
# the fstab line) PLUS the evidence report you wrote as you went — because the
# mount/unmount/fsck steps are torn down by the end of the workflow, those are
# verified through the recorded evidence rather than live state.
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

# Resolve the student's home/report even under sudo.
TARGET_USER="${SUDO_USER:-$(whoami)}"
USER_HOME="$(eval echo "~${TARGET_USER}")"
REPORT="${USER_HOME}/module11-devices-report.txt"
IMG="${USER_HOME}/loopdisk.img"

echo "=== Module 11 Lab Check: Devices, Mounting & Persistence ==="
echo

# Warn (but don't fail) if not root — some checks may be incomplete.
if [[ $EUID -ne 0 ]]; then
  echo "  NOTE  Not running as root. If blkid/fstab checks misbehave, re-run with: sudo bash check-devices.sh"
  echo
fi

# 1. The practice-disk image still exists.
if [[ -f "$IMG" ]]; then
  ok "practice-disk image exists at ~/loopdisk.img"
else
  no "~/loopdisk.img is missing — run 'sudo bash setup-devices.sh' (and don't delete it before grading)"
fi

# 2. A filesystem was actually CREATED on the loop image. blkid reads the
#    on-disk superblock; an ext4 (or any real) filesystem signature proves
#    mkfs ran against it. This is durable state that survives unmount/detach.
fs_type=""
if [[ -f "$IMG" ]]; then
  fs_type="$(blkid -o value -s TYPE "$IMG" 2>/dev/null || true)"
fi
if [[ -n "$fs_type" ]]; then
  ok "a filesystem was created on the practice disk (blkid reports type '$fs_type')"
else
  no "no filesystem detected on ~/loopdisk.img — attach it with losetup and run 'sudo mkfs -t ext4 /dev/loopX'"
fi

# 3. The evidence report exists and is non-empty.
if [[ -s "$REPORT" ]]; then
  ok "devices report exists at ~/module11-devices-report.txt"
else
  no "~/module11-devices-report.txt is missing or empty — create it as the instructions describe"
  echo
  echo "-----------------------------------------------"
  echo "  Passed: $pass    Failed: $fail"
  echo "  Not done yet — create the report and run me again."
  echo "-----------------------------------------------"
  exit 1
fi

# 4. The report carries THIS VM's real hostname.
this_host="$(hostname)"
if grep -qF "$this_host" "$REPORT"; then
  ok "report contains this VM's real hostname ('$this_host')"
else
  no "report does not contain this VM's hostname ('$this_host') — start it with:  hostname > ~/module11-devices-report.txt"
fi

# 5. The report contains lsblk output. lsblk -f prints NAME/FSTYPE columns and
#    device names like 'loop' or 'sda'/'vda'; require the header-ish evidence.
if grep -Eqi 'NAME[[:space:]]+(FSTYPE|MAJ)' "$REPORT" || grep -Eq '(sda|vda|loop)[0-9p]*' "$REPORT"; then
  ok "report contains lsblk output (block-device tree captured)"
else
  no "report is missing lsblk output — append it with:  lsblk -f >> ~/module11-devices-report.txt"
fi

# 6. Evidence of a successful MOUNT of the practice disk: require an actual
#    df/mount output line, not just the word 'practicedisk' (which appears
#    in the fstab line and elsewhere). The line should contain BOTH /mnt/
#    practicedisk AND a filesystem-type / size token. df -hT prints columns
#    like "Filesystem Type Size Used Avail Use% Mounted on", so we look for
#    a line that has 'practicedisk' AND either a size like '199M' / '188M'
#    / '/dev/loop' OR the ext4 type.
if grep -E '/mnt/practicedisk' "$REPORT" 2>/dev/null | grep -Eqi '/dev/loop|ext[234]|[0-9]+(\.[0-9]+)?[KMG][[:space:]]+[0-9]'; then
  ok "report shows real df/mount output for /mnt/practicedisk (loop device + size/type captured)"
else
  no "report has no concrete mount evidence — while the practice disk is mounted, run:  df -hT | grep practicedisk >> ~/module11-devices-report.txt"
fi

# 7. Evidence that fsck was run on the loop device: require ACTUAL fsck OUTPUT,
#    not just the word 'fsck' (which appears in the explanation header). e2fsck
#    output contains a version banner like 'e2fsck 1.46.x', 'Pass 1:', or a
#    'clean,' summary with block counts.
if grep -Eq 'e2fsck [0-9]|^Pass [12]|clean,[[:space:]]+[0-9]+/' "$REPORT" 2>/dev/null; then
  ok "report contains real fsck output (e2fsck banner / Pass lines / clean summary)"
else
  no "report has no real fsck output — run 'sudo fsck -f /dev/loopX' on the UNMOUNTED disk and append its full output, not just the word 'fsck'"
fi

# 8. A correctly-formatted /etc/fstab line for the practice image exists.
#    We accept either the file+loop form (recommended) or a UUID form whose
#    target is /mnt/practicedisk. The line must have at least the first four
#    fields, name /mnt/practicedisk, and (for the recommended form) include
#    the 'loop' option. We read /etc/fstab directly (needs root for some
#    permission setups, though it's world-readable by default).
fstab_ok=0
fstab_line=""
if [[ -r /etc/fstab ]]; then
  # Find a non-comment fstab line that mounts at /mnt/practicedisk.
  fstab_line="$(grep -E '^[[:space:]]*[^#].*[[:space:]]/mnt/practicedisk[[:space:]]' /etc/fstab 2>/dev/null | head -n1 || true)"
  if [[ -n "$fstab_line" ]]; then
    # Tokenize into fields.
    read -r f_src f_mnt f_type f_opts _rest <<<"$fstab_line"
    # Field 2 must be the mount point, field 3 a filesystem type.
    if [[ "$f_mnt" == "/mnt/practicedisk" && -n "$f_type" && -n "$f_opts" ]]; then
      # The lab requires 'noauto' regardless of source form, since this is a
      # loop-backed image that must never auto-mount at boot (a bad line could
      # block the boot otherwise).
      if [[ "$f_opts" == *noauto* ]]; then
        # Recommended file+loop form: source is the image (ABSOLUTE path —
        # fstab does NOT expand ~ or $HOME) and the image must actually
        # exist; options must include 'loop'.
        if [[ "$f_src" == /*loopdisk.img && "$f_opts" == *loop* && -f "$f_src" ]]; then
          fstab_ok=1
        # Acceptable UUID form: source begins with UUID= and a type is present.
        elif [[ "$f_src" == UUID=* && -n "$f_type" ]]; then
          fstab_ok=1
        fi
      fi
    fi
  fi
fi
if (( fstab_ok == 1 )); then
  ok "a correctly-formatted /etc/fstab line for the practice disk exists (mount point /mnt/practicedisk)"
else
  if [[ -z "$fstab_line" ]]; then
    # Show the student's REAL home path, not $HOME — when this check is run
    # via sudo (as the README says), $HOME is /root and a copy-pasted hint
    # would create a broken /root/loopdisk.img line.
    no "no /etc/fstab line mounts /mnt/practicedisk — add a line with the ABSOLUTE path to your image (fstab doesn't expand ~), e.g.:  ${IMG}  /mnt/practicedisk  ext4  loop,noauto  0  0"
  elif ! grep -Eq '[[:space:]/,]noauto[[:space:],]' <<<"$fstab_line"; then
    no "your /etc/fstab line is missing the 'noauto' option — a loop-backed image MUST use noauto so a typo can't block boot. Options should be 'loop,noauto'."
  else
    no "your /etc/fstab line for /mnt/practicedisk is malformed — it needs source, mount point, type, and options (use the file+'loop,noauto' form or UUID=...,noauto form)"
  fi
fi

# 9. ISO step: either real loopback evidence (iso9660 / lab.iso / LABISO / a
#    mount line for /mnt/iso) OR a written explanation mentioning iso9660 and
#    read-only. Accept either path (the README allows the explanation fallback).
if grep -Eqi 'iso9660|/mnt/iso|lab\.iso|LABISO' "$REPORT"; then
  ok "report shows the ISO read-only loopback step (real evidence or explanation)"
elif grep -qi 'iso' "$REPORT" && grep -Eqi 'read[- ]only|\bro\b' "$REPORT"; then
  ok "report explains read-only ISO loopback mounting (explanation fallback accepted)"
else
  no "report is missing the ISO step — loop-mount an ISO read-only and record it, or write the iso9660/read-only explanation the README allows"
fi

# 10. Written explanations present and FILLED IN: the three headers exist, no
#     '<...>' placeholder remains, and each key section has real prose.
expl_present=0
if grep -qi 'FSTAB FIELDS' "$REPORT" \
   && grep -qi 'WHY FSCK NEEDS AN UNMOUNTED' "$REPORT" \
   && grep -qi 'DF vs DU' "$REPORT"; then
  expl_present=1
fi

placeholder_left=0
if grep -Eq '<[^>]+>' "$REPORT"; then placeholder_left=1; fi

# The fsck-explanation body must contain real words after its header.
fsck_body="$(awk 'tolower($0) ~ /why fsck needs an unmounted/{flag=1; next} /^=== /{flag=0} flag' "$REPORT" \
             | tr -d '[:space:]')"
fsck_filled=0
if (( ${#fsck_body} >= 15 )); then fsck_filled=1; fi

if (( expl_present == 1 && placeholder_left == 0 && fsck_filled == 1 )); then
  ok "written explanations are complete (fstab fields, why-fsck-unmounted, df vs du; no placeholders)"
elif (( expl_present == 0 )); then
  no "explanations incomplete — need all three headers: FSTAB FIELDS / WHY FSCK NEEDS AN UNMOUNTED FILESYSTEM / DF vs DU"
elif (( placeholder_left == 1 )); then
  no "the report still contains '<...>' placeholders — replace every <...> with your own words"
else
  no "your 'why fsck needs an unmounted filesystem' explanation is empty — write it in your own words"
fi

echo
echo "-----------------------------------------------"
echo "  Passed: $pass    Failed: $fail"
if (( fail == 0 )); then
  echo "  ALL CHECKS PASSED. Record your Zoom screen recording and submit."
  echo "-----------------------------------------------"
  exit 0
else
  echo "  Not done yet — fix the FAILs above and run me again."
  echo "-----------------------------------------------"
  exit 1
fi
