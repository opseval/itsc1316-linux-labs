# Module 15 Lab: Comprehensive Review — The Inherited Server (Capstone)

**Hands-on capstone — runs on your own `labvm`. Replaces the former Red Hat Academy capstone labs 8.02 (Manipulating Files and Directories) and 8.03 (Working with a Linux System).**

## Lab Overview

You have just inherited a server from an administrator who left in a hurry. Nobody handed you a checklist of what is wrong — that is the point. The directory layout is a mess, a shared folder has dangerous permissions, something is pegging the CPU, the disk is filling up, and a service that is supposed to be running is not. Your job is the most common, most valuable thing a Linux administrator actually does: **take an unknown system, bring it to a defined good state, and write a clear handover report so the next person knows what you found and what you changed.**

This is the capstone. It pulls together everything from the course — files and redirection (M3–M4), `find`, storage and disk usage (M5), users, ownership, and permissions (M6), software and archives (M7), processes (M10), devices and the filesystem (M11), services (M12), and networking (M9/M13). Unlike every other lab, you are given **specifications — the desired end state — not click-by-click steps.** Figuring out *which* commands get the system there is the work.

|  |  |
| --- | --- |
| **Estimated Time** | 90–150 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-capstone.sh`, `check-capstone.sh` (in this folder of your cloned repo) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-capstone.sh` passing, plus your completed **handover report** (`~/module15-handover-report.txt`) |
| **Key Locations** | `/srv/inherited`, `/opt/finance`, the `inheritd` service |

## Outcomes

By the end of this lab you will be able to:

- Apply core Linux commands across files, permissions, processes, storage, services, and networking **in one integrated workflow**, without step-by-step hand-holding.
- Navigate and reorganize a directory tree confidently using `find`, `mv`, `mkdir`, and redirection.
- Interpret system state (`df`, `du`, `ps`, `systemctl`, `stat`) to understand what a machine is doing right now.
- Manage files, permissions, processes, and basic system resources to meet a written specification.
- Practice **evidence-based troubleshooting** — observe first, then change.
- Produce professional handover documentation: what you found, what you changed, why, and what you would check next.

---

## Start the Lab Environment

> **SNAPSHOT FIRST — this lab plants real problems and you will be making sweeping changes.** Multipass cannot snapshot a running instance, so stop it, snapshot, then start again. From your computer's terminal:
>
> ```
> multipass stop labvm
> multipass snapshot --name pre-mod15 labvm
> multipass start labvm
> ```
>
> If you get stuck, you can roll back with: `multipass stop labvm && multipass restore labvm.pre-mod15 && multipass start labvm`.

Start the VM and transfer the scripts (from your computer's terminal, at the **root of your cloned repo**):

```
multipass start labvm
multipass transfer labs/module-15-capstone/setup-capstone.sh labvm:/home/ubuntu/
multipass transfer labs/module-15-capstone/check-capstone.sh labvm:/home/ubuntu/
multipass shell labvm
```

Inside the VM, plant the scenario:

```
sudo bash setup-capstone.sh
```

The setup script is **safe and idempotent** — you can re-run it any time to reset the scenario to its starting state. It only touches the lab's own paths.

---

## The Specifications (your desired end state)

Below is the state the system **must be in** when you are done. You are **not** told exactly which commands to type — choose them yourself, the way you would on the job. The check script verifies each specification. Use the investigation tools you learned all semester (`ls -l`, `stat`, `find`, `ps`, `top`, `df`, `du`, `systemctl`, `journalctl`) to understand the current state *before* you change anything.

### Part 1 — Organize the messy directory tree (`find`, `mkdir`, `mv`, redirection)

The directory `/srv/inherited` is a dumping ground: log files, config files, and report files are all jumbled at the top level, along with some junk temp files.

**Specification:**
- Create three subdirectories: `/srv/inherited/logs`, `/srv/inherited/configs`, and `/srv/inherited/reports`.
- Move every `*.log` file into `logs/`, every `*.conf` file into `configs/`, and every `*.report` file into `reports/`.
- After the move, **no** loose `*.log`, `*.conf`, or `*.report` files remain at the top level of `/srv/inherited`.
- **Delete** the junk temporary files (anything ending in `.tmp`, including hidden ones) anywhere under `/srv/inherited`.

> Why this matters: a predictable layout is the difference between a system the next admin can operate and one they fear. `find` is your friend for locating files by name or type.

### Part 2 — Back up the configuration files (`tar`)

Before anyone touches the configs again, capture a backup.

**Specification:**
- Create a gzip-compressed archive at `~/inherited-backup.tar.gz`.
- It must contain the **three config files** (`web.conf`, `app.conf`, `database.conf`).
- It must **not** contain the large data file (`bigdata.bin`) — back up the configs only, not multi-hundred-megabyte junk.

> Why this matters: backups are about the *right* data, not *all* data. Sweeping a huge file into your config backup wastes space and time.

### Part 3 — Fix the shared `finance` directory (ownership + permissions, least privilege)

`/opt/finance` is meant to be a collaborative space for the `finance` group, but the previous admin left it root-owned and world-open (`777`). It contains a confidential `budget.txt`.

**Specification:**
- The directory `/opt/finance` is **group-owned by the `finance` group**.
- The **group** can read, write, and traverse it (full `rwx`); **others** get **nothing**.
- The directory has the **setgid bit** set, so new files created inside it inherit the `finance` group automatically.
- `budget.txt` is **not readable or writable by others** (the finance group may share it, but outsiders must not see confidential figures). Do **not** delete it — secure it.

> Why this matters: this is least privilege applied to a real shared resource — the exact skill from Module 6. `2770` and `chown :finance` are the kinds of tools you will reach for.

### Part 4 — Find and stop the runaway process (`ps`, `top`, `kill`)

The machine feels sluggish. Something the previous admin left running is burning a CPU core.

**Specification:**
- Identify the runaway process using process tools (`top`, `ps aux`, `pgrep`) — observe the evidence before acting.
- **Stop it.** (You do not have to permanently uninstall it for the check to pass, but think about how you would prevent it from coming back — note that in your report.)

> Why this matters: nobody labels the bad process for you. You read `top`, find the CPU hog, confirm what it is, and stop it.

### Part 5 — Identify what is consuming disk space (`df`, `du`) — report only

The disk is filling up. You need to find the culprit and **document it** (no deletion required — it lives under `/srv/inherited/archive-staging`).

**Specification:**
- Use `df` and `du` to locate the single large file consuming space under `/srv/inherited`.
- Record its name and size in your handover report. (The check looks for `df`/`du` evidence and the filename in your report — see Part 8.)

> Why this matters: `df` tells you a filesystem is filling; `du` tells you *which directory or file* is responsible. Knowing the difference is a core Module 5 skill.

### Part 6 — Bring up the required service (`systemctl`)

A service named `inheritd` is installed but the previous admin never started or enabled it. It is supposed to run continuously.

**Specification:**
- The `inheritd.service` is **active** (running now).
- The `inheritd.service` is **enabled** (will start automatically on boot).

> Why this matters: "installed" is not "running." A required service that isn't enabled silently disappears after the next reboot.

### Part 7 — Verify network reachability and name resolution — report only

Confirm the box can still reach the outside world and resolve names, and record what you found.

**Specification:**
- Verify reachability and/or DNS resolution using tools from Modules 9/13 (e.g. `ping -c 3 8.8.8.8`, `getent hosts ubuntu.com`, `dig`, `resolvectl status`).
- Record the result in your handover report (Part 8). (No system change is required if it already works — the deliverable is the evidence.)

### Part 8 — Write the handover report (the written component)

Create `~/module15-handover-report.txt`. This is the document you would hand the next administrator. It must include **your VM's hostname**, name the large disk file you found, show your disk (`df`/`du`) and network evidence, and have **every section filled in with your own words** (no `<placeholder>` text, no `TODO`s). A fill-in template is provided below.

> Why this matters: the report is half the job. An undocumented fix is a future outage. The check requires a substantial report (~200+ words of real reasoning), not just pasted command output.

---

## Evaluation (Required)

Grade your work inside the VM. Several checks read root-owned files and live `systemd` state, so run it **with sudo**:

```
sudo bash check-capstone.sh
```

It prints PASS or FAIL for each specification, with a hint on each FAIL. Fix the FAILs and re-run until everything passes. Re-running `setup-capstone.sh` resets the scenario if you want a clean start.

---

## Handover Report Template

Copy this into `~/module15-handover-report.txt` and replace **every** `<...>` with your own content. Leaving any `<...>`, `TODO`, or `FIXME` in the file will fail the check.

```
=========================================================
HANDOVER REPORT — Module 15 Capstone (Inherited Server)
=========================================================
Administrator (your name): <your name>
VM hostname (paste output of `hostname`): <hostname>
Date: <date>

--- STATE FOUND ---
<Describe the condition the server was in when you inherited it: the messy
directory, the wrong permissions on /opt/finance, the runaway process, the
disk usage, and the stopped service. A short paragraph.>

--- ACTIONS TAKEN ---
<List, in order, what you changed and the commands you used to get the system
to the required end state. Cover the directory reorg + cleanup, the config
backup, the /opt/finance permissions, stopping the runaway process, and
bringing up the inheritd service.>

--- DISK USAGE FINDINGS ---
<Paste the df and du command output you used to find the disk hog. Name the
large file and its size. Example commands: df -h ; du -ah /srv/inherited | sort -h | tail>

--- NETWORK VERIFICATION ---
<Paste the result of your reachability / name-resolution check (e.g. ping -c 3,
getent hosts, dig, resolvectl). State whether the box can reach the network
and resolve names.>

--- REASONING ---
<Explain WHY your permission choices satisfy least privilege, why you backed up
only the configs, and why a stopped runaway process and an enabled service
matter. This is where you show understanding, not just commands.>

--- WHAT I WOULD CHECK NEXT ---
<If you had more time, what would you investigate or harden next, and how would
you stop the runaway "datacruncher" from coming back after a reboot?>
=========================================================
```

---

## Submission Requirement

Submit **two things** to Canvas:

1. A **60–90 second screen recording** made per the [Screen Recording Guide](../../docs/05-screen-recording-guide.md) (Alamo Zoom by default; one specific backup per OS if Zoom is broken) (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `sudo bash check-capstone.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio.
2. Your completed **handover report** (`~/module15-handover-report.txt`) — this is the written component, where your reasoning and evidence live, so the recording does not need narration.

> **AI policy for this capstone: AI-OPEN — but read this first.** You may use an AI assistant to recall a flag or explain a command, and if you do, include a one-line note of what you asked and what you verified yourself. **But this lab is your integration practice for the cumulative final, and the entire value is in doing it yourself.** No AI can see your VM's actual `top` output, your real `du` numbers, or your live `systemctl` state — the evidence you put in the handover report must come from *your* machine. If you let an AI drive, you will not be ready for the final, where there is no AI and no check script. Treat this as the dress rehearsal.

---

## Finish / Clean Up

When you are done you can restore your clean snapshot for a tidy system, or just stop the VM. Restore needs the VM stopped, so `exit` the VM first, then from your computer's terminal:

```
multipass stop labvm
multipass restore labvm.pre-mod15   # optional — only if you want to roll back
multipass start labvm
```

Or simply `multipass stop labvm` to leave your finished work in place. Do **not** delete `labvm`.

---

## Final Checklist

- [ ] Took a snapshot (`pre-mod15`) before starting
- [ ] Ran `setup-capstone.sh`
- [ ] Organized `/srv/inherited` into `logs/`, `configs/`, `reports/` and removed the `.tmp` junk
- [ ] Created `~/inherited-backup.tar.gz` with the three config files (and not `bigdata.bin`)
- [ ] Fixed `/opt/finance` to `finance`-group ownership, group `rwx`, no access for others, setgid set
- [ ] Secured `budget.txt` from others
- [ ] Found and stopped the runaway `datacruncher` process
- [ ] Identified the disk hog with `df`/`du` and recorded it
- [ ] Started **and** enabled `inheritd.service`
- [ ] Verified network reachability / name resolution and recorded it
- [ ] Filled in the entire handover report (hostname + all sections, no placeholders)
- [ ] Ran `sudo bash check-capstone.sh` and all checks PASS
- [ ] Recorded the Zoom screen recording (webcam off; hostname + whoami + passing check)
- [ ] Submitted screencast + handover report to Canvas

---

### On RHEL this would be…

Almost everything in this capstone is identical on a Red Hat–family system (RHEL, Rocky, Fedora): `find`, `mv`, `mkdir`, `tar`, `chown`, `chmod`, `ps`, `top`, `kill`, `df`, `du`, `systemctl`, and `journalctl` are core Linux and behave the same. The differences you would meet for certification: software is managed with **`dnf`** instead of `apt`; the firewall is **firewalld** (`firewall-cmd`) rather than Ubuntu's `ufw`; networking is configured through **NetworkManager** (`nmcli`) rather than `netplan`; and **SELinux** can deny access even when your file permissions look correct (you would check `getenforce`, `ls -Z`, and `ausearch`/`sealert`). The administrative *judgment* this lab builds — read the state, meet the spec, document the handover — is exactly the same on any Linux system.
