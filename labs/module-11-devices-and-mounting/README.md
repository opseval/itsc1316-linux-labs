# Module 11 Lab: Filesystem Administration — Devices, Mounting & Persistence (Multipass)

**Hands-on lab — runs on your own `labvm`. Replaces the former Option-2 hands-on disk assignment.**

## Lab Overview

Every storage device on a Linux system shows up as a *file* under `/dev`, and you make a device usable by putting a **filesystem** on it and **mounting** it into the directory tree. Administrators do this constantly: adding a new disk, attaching a USB drive, mounting an ISO image, or making a mount survive a reboot by editing `/etc/fstab`. In this lab you do the full workflow safely — but instead of risking the real disk, you build a **file-backed loop device**: a regular file that the kernel treats as if it were a block device. You will inspect block devices, create and format a "practice disk," mount and unmount it, make a *safe* persistent-mount entry in `/etc/fstab`, mount an ISO read-only, and run `fsck` on the unmounted filesystem — recording your evidence as you go.

> **SAFETY FIRST — read this before you start.** Everything in this lab is done against a **loop device backed by a file in your home directory** (`~/loopdisk.img`). You will **never** run `mkfs`, `fsck`, or destructive `mount` operations against your real disk (`/dev/sda`, `/dev/vda`, etc.). Formatting the wrong device destroys data instantly. Two rules: (1) **snapshot the VM before you begin** (steps below), and (2) **only ever target the `/dev/loopN` device that `losetup` reports back to you** — type it, don't guess it.

|  |  |
| --- | --- |
| **Estimated Time** | 50–75 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-devices.sh`, `check-devices.sh` (pulled into `labvm` from the public repo with curl — see Setup Guide) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-devices.sh` passing, plus your written **devices report** (`~/module11-devices-report.txt`) |
| **Key Artifacts** | `~/loopdisk.img` (practice disk), `/mnt/practicedisk` (mount point), an `/etc/fstab` entry |

## Outcomes

By the end of this lab you will be able to:

- Explain how Linux represents storage devices as files under `/dev`, and inspect them with `lsblk` and `lsblk -f`.
- Create a filesystem on a device with `mkfs`, and describe when you'd choose `ext4` vs other types.
- Mount a filesystem at a mount point you create, prove it is mounted, and unmount it.
- Read an `/etc/fstab` line field-by-field and configure a persistent mount **safely** (using `noauto` and testing with `mount -a`).
- Mount an ISO image read-only via a loopback device.
- Explain why `fsck` must be run on an **unmounted** filesystem, and run it safely.

---

## Start the Lab Environment

> **Snapshot first — this lab uses root and creates a filesystem.** Multipass won't snapshot a running instance, so stop it first. From your computer's terminal:
>
> ```
> multipass stop labvm
> multipass snapshot --name pre-mod11 labvm
> multipass start labvm
> ```
>
> If anything goes sideways (especially a bad `/etc/fstab` line), you can roll back with:
> `multipass stop labvm && multipass restore labvm.pre-mod11 && multipass start labvm`

Open a shell into `labvm` (from your computer's terminal):

```
multipass shell labvm
```

Then **inside `labvm`**, pull this lab's two scripts straight from the public course repo, eyeball them, and run the setup. The setup pre-creates the 200 MB practice-disk image (`~/loopdisk.img`) so you have something to work with, installs the small tools this lab needs (`genisoimage` for the ISO step), and prints safety reminders. It is idempotent — re-running it cleans up any half-finished previous attempt first.

```
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-11-devices-and-mounting/setup-devices.sh
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-11-devices-and-mounting/check-devices.sh
# Optional safety review (this lab touches loop devices — worth a quick scan).
# Skim each script for red flags: any 'rm -rf /', any 'curl ... | bash', any URL
# not under raw.githubusercontent.com/opseval/, any unexpected modification of
# /etc/passwd, /etc/shadow, or /etc/sudoers.d/, or any write to /dev/sda*. The
# INTEGRITY: VERIFIED line the check script prints is the stronger guarantee —
# this is the human-eye supplement. Press q to exit each file.
less setup-devices.sh
less check-devices.sh
sudo bash setup-devices.sh
```

> The setup creates the **image file only**. Attaching it to a loop device, formatting it, mounting it, and the `fstab`/`fsck` work are the lab — that is the part you do by hand.

---

## Start your evidence file

You will record real output from *your* VM as you go. The check reads this file, so create it now and stamp it with your hostname (the check requires your VM's real hostname on it):

```
hostname > ~/module11-devices-report.txt
echo "Investigator: <your name>" >> ~/module11-devices-report.txt
echo "Date: $(date)" >> ~/module11-devices-report.txt
```

---

## Instructions

**1. Inspect the system's block devices.**
Look at how Linux presents storage as device files. Run each of these and read the output:

```
lsblk
lsblk -f
ls -l /dev/sd* /dev/vda* 2>/dev/null
```

`lsblk` shows the block-device tree (your real disk, its partitions, their mount points). `lsblk -f` adds the **filesystem type** and **UUID** of each. Note which device is your real root disk — that is the one you must **never** format. Capture the tree into your report:

```
echo "=== lsblk -f (before) ===" >> ~/module11-devices-report.txt
lsblk -f >> ~/module11-devices-report.txt
```

**2. Create a "practice disk" safely with a loop device.**
The setup already created the 200 MB image at `~/loopdisk.img`. Attach it to the next free loop device and let `losetup` tell you the device name:

```
sudo losetup --find --show ~/loopdisk.img
```

This prints something like `/dev/loop7`. **Use exactly the path it printed** in the next commands (substitute it wherever you see `/dev/loopX`). Confirm it appears as a block device, then put an **ext4** filesystem on it:

```
lsblk /dev/loopX
sudo mkfs -t ext4 /dev/loopX
```

> **Why a loop device?** It lets you practice the *entire* real disk workflow — partition-less, but otherwise identical to a physical disk — without any chance of destroying real data. `mkfs` is destructive by design; doing it on a loop file is the safe sandbox.

Record proof into your report:

```
echo "=== loop device + mkfs ===" >> ~/module11-devices-report.txt
losetup -j ~/loopdisk.img >> ~/module11-devices-report.txt
sudo blkid /dev/loopX >> ~/module11-devices-report.txt   # shows the new ext4 UUID
```

**3. Mount it, prove it, write to it, unmount it.**
Create a mount point you own and mount the practice disk there:

```
sudo mkdir -p /mnt/practicedisk
sudo mount /dev/loopX /mnt/practicedisk
df -hT | grep practicedisk          # proof it's mounted, and its type
```

Write a test file onto the mounted filesystem (use `sudo` since it's freshly formatted and owned by root), then unmount it:

```
echo "module 11 practice file on $(hostname)" | sudo tee /mnt/practicedisk/proof.txt
sync
sudo umount /mnt/practicedisk
```

Record the mount proof in your report **while it is mounted** (don't wait until after you unmount):

```
echo "=== mount proof (df -hT) ===" >> ~/module11-devices-report.txt
# run this line BEFORE you umount:
# df -hT | grep practicedisk >> ~/module11-devices-report.txt
```

> The check looks for evidence of both a successful mount **and** a clean unmount in your report, because in a real workflow you leave the device unmounted when you're done with it. Record the `df` line while mounted, then note that you unmounted it.

**4. Make the mount persistent — SAFELY — with `/etc/fstab`.**
A real persistent mount is configured in `/etc/fstab` so it comes back after a reboot. A *bad* fstab line can stop a machine from booting, so you will do this the safe way: use the **`noauto`** option (so the system won't try it automatically at boot) and **test with `mount -a`** before trusting it.

First get the practice disk's UUID:

```
sudo blkid /dev/loopX
```

Then add a single line to `/etc/fstab`. Use the **image file with the `loop` option** so the entry is self-contained (it re-creates the loop device on demand). Replace `<UUID>` only if you prefer the UUID form; the file+loop form below is recommended for this lab:

```
# Append to /etc/fstab (edit with: sudo nano /etc/fstab):
/home/ubuntu/loopdisk.img   /mnt/practicedisk   ext4   loop,noauto   0   2
```

The six fields, in order, are:

| Field | Value here | Meaning |
| --- | --- | --- |
| 1 — device/source | `/home/ubuntu/loopdisk.img` | what to mount (a file, with `loop`; or `UUID=...`, or `/dev/...`) |
| 2 — mount point | `/mnt/practicedisk` | where it attaches in the tree |
| 3 — filesystem type | `ext4` | what filesystem to expect |
| 4 — options | `loop,noauto` | `loop` = treat the file as a loop device; `noauto` = do **not** mount at boot |
| 5 — dump | `0` | legacy backup flag; `0` = don't dump |
| 6 — fsck pass | `2` | boot-time fsck order; root is `1`, others `2`, `0` = never |

Now **test the line without rebooting**:

```
sudo mount -a              # mounts everything in fstab marked for auto-mount; should NOT error
sudo mount /mnt/practicedisk   # 'noauto' means we mount it by name to test the fstab entry
df -hT | grep practicedisk     # confirm the fstab-driven mount worked — keep this output, it's your evidence
sudo umount /mnt/practicedisk
```

> **Use *your* home path.** The README shows `/home/ubuntu/...` because that's the Multipass default. If you're doing the cloud fallback as a different user, your fstab line and check evidence should use **your** real home directory (run `echo $HOME` to see it). The check accepts either. **`fstab` does NOT expand `~` or `$HOME`** — use the literal absolute path like `/home/ubuntu/loopdisk.img`, not `~/loopdisk.img`. (The check will tell you so if you get this wrong, but knowing it ahead of time saves a debug cycle.)

Because the entry is `noauto`, a mistake in it can't break a future boot — and you proved it works by mounting it by name. **Keep this fstab line in place** (the check confirms a correctly-formatted line exists). Record your fstab line and the test result in your report:

```
echo "=== /etc/fstab entry for the practice disk ===" >> ~/module11-devices-report.txt
grep loopdisk.img /etc/fstab >> ~/module11-devices-report.txt
```

> **Why `noauto` matters:** if you wrote a normal auto-mount line and the device were missing or the line had a typo, the machine could drop to emergency mode at boot. `noauto` lets you stage and test a persistent mount with zero risk to boot. (On a production server you'd switch to a tested auto line plus the `nofail` option once you trust it.)

**5. Mount an ISO read-only via loopback.**
Optical media and ISO images use the `iso9660` filesystem and are always mounted **read-only**. The setup installed `genisoimage`. Build a tiny ISO and loop-mount it read-only:

```
mkdir -p ~/isosrc && echo "hello from a lab ISO" > ~/isosrc/readme.txt
genisoimage -o ~/lab.iso -V LABISO ~/isosrc      # build the ISO
sudo mkdir -p /mnt/iso
sudo mount -o loop,ro ~/lab.iso /mnt/iso          # loopback, read-only
ls /mnt/iso                                       # you should see readme.txt
mount | grep /mnt/iso                             # note 'ro' and 'iso9660'
```

Try to write to it — it should fail, because it's read-only (`touch /mnt/iso/x` → "Read-only file system"). Then unmount:

```
sudo umount /mnt/iso
```

Record the ISO mount evidence:

```
echo "=== ISO loopback mount (read-only) ===" >> ~/module11-devices-report.txt
# run this line while the ISO is mounted:
# mount | grep /mnt/iso >> ~/module11-devices-report.txt
```

> If `genisoimage` is unavailable on your image for some reason, write a short paragraph in your report explaining how you *would* mount an ISO read-only (`mount -o loop,ro file.iso /mnt/iso`), why optical filesystems are read-only, and what `iso9660` is. The check accepts either real evidence or this explanation.

**6. Run `fsck` on the UNMOUNTED practice disk.**
`fsck` checks and repairs a filesystem. Running it on a **mounted** filesystem can corrupt it, because the on-disk structures are changing under fsck's feet — so you only ever fsck an **unmounted** (or read-only) filesystem. Your practice disk is already unmounted from step 3/4. Re-attach the loop device if needed and check it:

```
# make sure /mnt/practicedisk is NOT mounted first:
mount | grep practicedisk || echo "not mounted - good"
sudo fsck -f /dev/loopX        # -f forces a check even if it looks clean
```

A clean run reports the filesystem is clean / passes its passes. Record it:

```
echo "=== fsck on the unmounted loop device ===" >> ~/module11-devices-report.txt
sudo fsck -fy /dev/loopX >> ~/module11-devices-report.txt 2>&1
```

> The `-y` auto-answers "yes" to any repair prompts. On a freshly-`mkfs`'d filesystem there's nothing to repair so it doesn't matter, but `-y` is *required* when you redirect output to a file: closing stdin would otherwise make `fsck` exit with `need terminal for interactive repairs` (exit 8) if it finds anything to ask about — leaving an empty `report.txt` block where the evidence was supposed to be.

> **Why unmounted?** A live filesystem has in-memory state (the page cache, open files, the journal) that hasn't been flushed. fsck assumes the on-disk image is static; if the kernel writes while fsck is "fixing," you get the corruption you were trying to prevent. That's why fsck refuses to run on a mounted rw filesystem unless you force it — and forcing it is how people destroy real data.

**7. Finish your report's written section.**
Append the explanations the check looks for (replace every `<...>`):

```
cat >> ~/module11-devices-report.txt <<'EOF'

=== EXPLANATIONS ===
FSTAB FIELDS (in your own words, all six):
<field 1 device/source = ...; field 2 mount point = ...; field 3 type = ...;
 field 4 options (what do loop and noauto do?) = ...; field 5 dump = ...;
 field 6 fsck pass = ...>

WHY FSCK NEEDS AN UNMOUNTED FILESYSTEM:
<your explanation>

DF vs DU (conceptually):
<df reports ...; du reports ...; when would you reach for each?>
EOF
```

Then edit the file (`nano ~/module11-devices-report.txt`) and replace each `<...>` with your real explanation.

---

## Evaluation (Required)

Grade your own work by running the check script inside the VM:

```
bash check-devices.sh
```

Some checks read root-owned state, so run it with `sudo` if it tells you to:

```
sudo bash check-devices.sh
```

Fix any FAILs and re-run until everything passes.

---

## Written Component (submit this)

Your devices report **is** the written component. Beyond the file, answer these two reflection questions in your submission (2–3 sentences each, your own words):

1. You used `loop,noauto` in your fstab line. Explain concretely what could happen at the *next boot* if you had instead written a normal auto-mount line and it contained a typo in the device path. How does `nofail` change that risk?
2. A colleague says "just run `fsck` on the drive, it's faster than unmounting." Explain why that advice is dangerous and what you would do instead.

---

## Submission Requirement

Submit **two things** to Canvas:

1. A **60–90 second screen recording** made per the [Screen Recording Guide](../../docs/05-screen-recording-guide.md) (Alamo Zoom by default; one specific backup per OS if Zoom is broken) (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `bash check-devices.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio.
2. Your **devices report** (`~/module11-devices-report.txt`) plus your answers to the two reflection questions. This is where your reasoning lives, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** You may ask an AI assistant to explain `losetup`, `mkfs`, fstab fields, or `fsck` flags, but include a one-line note of what you asked and what you verified yourself. An AI cannot tell you *which* `/dev/loopN` your machine assigned, *which* UUID `blkid` printed for your practice disk, or what your real `lsblk` tree looks like — those, and the evidence in your report, must come from your own VM.

---

## Finish / Clean Up

You can leave the practice disk and fstab line in place (the `noauto` option means they're harmless). To free resources between sessions:

```
multipass stop labvm
```

If you want to fully tear down the scenario afterward (do this only **after** you've recorded and submitted):

```
sudo umount /mnt/practicedisk 2>/dev/null
sudo umount /mnt/iso 2>/dev/null
sudo sed -i "\#${HOME}/loopdisk.img#d" /etc/fstab        # remove the fstab line
# Detach ONLY the loop devices backing this lab's files (not every loop device
# on the system — `losetup -D` is global and could break unrelated work).
for f in "${HOME}/loopdisk.img" "${HOME}/lab.iso"; do
  for ld in $(losetup -j "$f" 2>/dev/null | cut -d: -f1); do
    sudo losetup -d "$ld"
  done
done
rm -f "${HOME}/loopdisk.img" "${HOME}/lab.iso"
```

Or just restore your `pre-mod11` snapshot. Do **not** delete `labvm` — later labs reuse it.

---

## Final Checklist

- [ ] Took a `pre-mod11` snapshot before starting
- [ ] Ran `setup-devices.sh`
- [ ] Started `~/module11-devices-report.txt` with `hostname` on it
- [ ] Inspected block devices with `lsblk` / `lsblk -f` and recorded the tree
- [ ] Attached `~/loopdisk.img` to a loop device with `losetup` and formatted it with `mkfs -t ext4`
- [ ] Mounted it at `/mnt/practicedisk`, proved it with `df -hT`, wrote a test file, and unmounted it
- [ ] Added a correctly-formatted `loop,noauto` line to `/etc/fstab` and tested it with `mount -a` / mount by name
- [ ] Mounted an ISO read-only via loopback (or explained the procedure)
- [ ] Ran `fsck -f` on the **unmounted** loop device and recorded the result
- [ ] Wrote the explanations (fstab fields, why fsck needs unmounted, df vs du) with no `<...>` placeholders left
- [ ] Ran `check-devices.sh` and all checks PASS
- [ ] Recorded the Zoom screen recording (webcam off; hostname + whoami + passing check)
- [ ] Wrote answers to both reflection questions
- [ ] Submitted screencast + devices report + reflection answers to Canvas

---

### On RHEL this would be…

The core workflow is the same on Red Hat–family systems (RHEL, Rocky, Fedora): `lsblk`, `losetup`, `mount`, `umount`, `/etc/fstab`, and `blkid` are identical. Three differences worth knowing for a certification exam: (1) RHEL defaults to the **XFS** filesystem, so you'd often run `mkfs.xfs` and check it with **`xfs_repair`** rather than `fsck.ext4` (XFS's repair tool is separate, and XFS also requires the filesystem to be unmounted). (2) The ISO tool on RHEL is commonly **`mkisofs`** (or `xorrisofs`) rather than Ubuntu's `genisoimage`, though the package often provides both. (3) RHEL servers lean heavily on **LVM**, so a "new disk" workflow there frequently means `pvcreate` → `vgextend` → `lvcreate` before `mkfs`. The concepts — devices as files, filesystems on devices, mount points, persistent mounts via fstab, fsck only on unmounted filesystems — are universal.
