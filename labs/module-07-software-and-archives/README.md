# Module 7 Lab: Software, Packages, and Archives (Multipass)

**Hands-on lab — runs on your own `labvm`. Replaces the former Red Hat Academy Lab 6.07 (Obtaining and Installing Software Packages).**

## Lab Overview

Installing and updating software, and bundling files into archives for backup or transfer, are two of the most routine things a Linux administrator does. In this lab you will use Ubuntu's package manager (APT) the way professionals do: refresh the package index, search for and install a tool from a trusted repository, inspect what it installed and where, then remove it cleanly. You will then do something that is often confused with installing software but is actually a completely separate skill — **archiving**: bundling a directory into a compressed `.tar.gz`, listing what's inside it, and extracting it somewhere else. By the end you'll be able to explain *why* package-managed software is safer than a binary you download off a random website, and when an archive is the right tool instead.

|  |  |
| --- | --- |
| **Estimated Time** | 40–60 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-software.sh`, `check-software.sh` (pulled into `labvm` from the public repo with curl — see Setup Guide) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-software.sh` passing, plus your written component (below) |
| **Key Locations** | `~/projectfiles` (to archive), `~/backup.tar.gz`, `~/module7-software-report.txt` |

## Outcomes

By the end of this lab you will be able to:

- Explain how a Linux distribution provides and manages software through **repositories**, and where Ubuntu lists them (`/etc/apt/sources.list`, `/etc/apt/sources.list.d/`).
- Use a **package manager** (`apt`/`dpkg`) to update the index, search, install, inspect, and remove software.
- Explain why package-managed software is **safer** than manually downloading and running a binary.
- Differentiate **installing software** from **file archiving**, and describe real use cases for compressed archives.
- Create, list, and extract a `tar.gz` archive and compare compressed vs. uncompressed size.

---

## Start the Lab Environment

From your computer's terminal, start `labvm` and shell into it:

```
multipass start labvm
multipass shell labvm
```

Then **inside `labvm`**, pull this lab's two scripts straight from the public course repo, eyeball them, and build the scenario:

```
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-07-software-and-archives/setup-software.sh
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-07-software-and-archives/check-software.sh
sudo bash setup-software.sh
```

This creates a sample project directory at `~/projectfiles` (full of files for you to archive later) and a starter evidence report at `~/module7-software-report.txt`. It does **not** install or remove any packages — that part is yours to do by hand.

> **Tip — snapshot before you experiment.** This lab installs and removes a package and creates files; none of it is dangerous, but a snapshot lets you reset cleanly. From inside the VM type `exit`, then from your computer's terminal:
>
> ```
> multipass stop labvm
> multipass snapshot --name pre-mod07 labvm
> multipass start labvm
> multipass shell labvm
> ```
>
> Roll back any time with `multipass stop labvm && multipass restore labvm.pre-mod07 && multipass start labvm`.

---

## Build your evidence report as you go

Throughout this lab you will paste real command output into `~/module7-software-report.txt`. The fastest way is to append output directly. For example:

```
hostname >> ~/module7-software-report.txt
apt show tree >> ~/module7-software-report.txt 2>&1
```

The check script looks for **your** hostname and **your** archive's contents in that file, so it cannot be filled in by an AI that can't see your VM. Start by recording your hostname:

```
echo "Hostname: $(hostname)" >> ~/module7-software-report.txt
```

---

## Part 1 — Update the package index and look at your repositories

A package manager doesn't magically know what software exists. It reads a local **index** that it downloads from the **repositories** your system is configured to trust. Refresh that index:

```
sudo apt update
```

Now look at where those repositories are defined:

```
cat /etc/apt/sources.list
ls /etc/apt/sources.list.d/
```

> **Why this matters.** Every line in those files is a server your system will trust to deliver software (and cryptographically signed metadata that proves the packages weren't tampered with). This is the foundation of why package management is safe — you're pulling from vetted, signed sources, not a random download link.

## Part 2 — Search for, install, and use a package

Pick **one** small, safe package to install. Any of these work: `tree`, `cowsay`, `htop`, `sl`, `figlet`, `ncdu`. The examples below use `tree`; substitute your choice everywhere.

> Some Multipass Ubuntu images ship with `htop` already installed — check first with `dpkg -l [candidate]` and pick a different package if your candidate is already there. Otherwise you can't demonstrate the install/remove arc.

Search for it, then install it. (`apt search` matches package descriptions too, so it can be noisy — narrow with `apt search ^tree$` or `apt search tree | grep '^tree/'` if you want just the package name. Also: every `apt` command prints `WARNING: apt does not have a stable CLI interface. Use with caution in scripts.` — that's a note for script writers, safe to ignore.)

```
apt search tree
sudo apt install tree
```

Verify it actually installed, and find where the runnable command lives:

```
dpkg -l tree
which tree
```

Now **use** it (prove it works) and capture that in your report:

```
tree ~/projectfiles
echo "=== I installed and used 'tree' ===" >> ~/module7-software-report.txt
dpkg -l tree >> ~/module7-software-report.txt
```

> **Why apt is safer than a random binary.** When you `sudo apt install` something, APT pulls it from a repository, **verifies its cryptographic signature**, tracks every file it installs, resolves its dependencies, and can update or remove it later. A binary you download from a website and `chmod +x` has none of that: no signature check, no dependency tracking, no clean removal, and no idea whether it's malicious. You'll write about this below.

## Part 3 — Inspect the package

See the package's metadata and the exact list of files it dropped onto your system:

```
apt show tree
dpkg -L tree
```

Append both to your report (the check looks for an `apt show`/`dpkg` header line and at least one installed-file path under `/usr`):

```
echo "=== apt show ===" >> ~/module7-software-report.txt
apt show tree >> ~/module7-software-report.txt 2>&1
echo "=== dpkg -L (installed files) ===" >> ~/module7-software-report.txt
dpkg -L tree >> ~/module7-software-report.txt
```

> **Why this matters.** `dpkg -L` shows you precisely what a package put on your system — binaries in `/usr/bin`, man pages and data in `/usr/share`. This is how an admin audits exactly what software is touching the filesystem. A manual install gives you no such record.

## Part 4 — Remove the package cleanly

Now remove it. Clean removal is one of the biggest advantages of a package manager — it knows every file it added:

```
sudo apt remove tree
dpkg -l tree   # after remove, this prints "No packages found matching tree" and exits non-zero — that's the proof it's gone
```

> The check script confirms your chosen package is **no longer installed** *and* that your report names it — proof you installed it, used it, then removed it.

## Part 5 — Archiving (a different skill from installing)

Installing software adds programs to your system. **Archiving** bundles existing files into a single (optionally compressed) file so you can back them up or move them. They are not the same thing — you'll explain the difference below.

**Create** a compressed archive of the project directory the setup script built:

```
cd ~
tar -czf backup.tar.gz projectfiles
```

The flags: `c`reate, g`z`ip-compress, `f`ile (name follows). **List** what's inside without extracting it:

```
tar -tzf backup.tar.gz
```

Append that listing to your report (the check looks for the project paths here):

```
echo "=== Archive contents (tar -tzf) ===" >> ~/module7-software-report.txt
tar -tzf backup.tar.gz >> ~/module7-software-report.txt
```

**Extract** it into a *separate* location (never extract on top of the original — that's how you accidentally overwrite good data):

```
mkdir -p ~/restore
tar -xzf backup.tar.gz -C ~/restore
ls -R ~/restore
```

**Compare** compressed vs. uncompressed size and record it:

```
du -sh ~/projectfiles            # original (uncompressed) size
ls -lh ~/backup.tar.gz           # compressed archive size
echo "=== Size comparison (uncompressed vs compressed) ===" >> ~/module7-software-report.txt
du -sh ~/projectfiles >> ~/module7-software-report.txt
ls -lh ~/backup.tar.gz >> ~/module7-software-report.txt
```

> **Why this matters.** That repetitive log file compresses dramatically — you'll see the `.tar.gz` is a fraction of the directory's size. Archives are how admins take backups, ship logs to support, and move whole directory trees between machines in one transfer.

---

## Evaluation (Required)

Grade your own work by running the check script inside the VM:

```
bash check-software.sh
```

It prints PASS or FAIL for each requirement. Correct any FAILs and run it again until everything passes — exactly what a real administrator does after making a change.

---

## Written Component (submit this)

Answer all three in your own words. Aim for 3–5 sentences each — this is where your reasoning lives, so the recording does not need narration.

```
MODULE 7 WRITTEN COMPONENT
Name:
VM hostname (run `hostname`):

1. Repositories & safety
   - In your own words, what is a software repository, and what role does the
     package manager (apt/dpkg) play in installing, updating, and removing
     software?
   - Explain at least TWO concrete reasons package-managed software is safer
     than downloading a binary from a website and running it. (Think: signing,
     dependencies, clean removal, auditability.)

2. Install vs. archive
   - Explain the difference between INSTALLING software and ARCHIVING files.
     Why are these two separate skills even though both involve "files"?

3. A real archive use case
   - Describe one realistic situation in your future as an admin where you'd
     create a compressed archive (e.g. backing up config before a change,
     shipping logs to support, moving a directory tree to another server).
     Name the file you'd archive and why compression helps.
```

---

## Submission Requirement

Submit **two things** to Canvas:

1. A **60–90 second screen recording** made per the [Screen Recording Guide](../../docs/05-screen-recording-guide.md) (Alamo Zoom by default; one specific backup per OS if Zoom is broken) (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `bash check-software.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio.
2. Your completed **written component** (the three questions above). This is where you explain your reasoning, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** You may use an AI assistant to help you understand `apt`, `dpkg`, or `tar` flags — include a one-line note of anything you asked it and what you verified yourself. An AI cannot see your VM: only you can run `apt`/`tar` on *your* machine, produce *your* archive listing, and capture *your* hostname into the report. The screencast and the report built from your real output are how you show the work is yours.

---

## Finish / Clean Up

You can leave the scenario in place. To free up resources between sessions without losing your work:

```
multipass stop labvm
```

Do **not** delete `labvm` — later labs reuse it.

---

## Final Checklist

- [ ] Ran `setup-software.sh` to build the project directory
- [ ] Ran `sudo apt update` and looked at `/etc/apt/sources.list` + `sources.list.d/`
- [ ] Installed a small package, verified it (`dpkg -l`, `which`), and used it
- [ ] Inspected it with `apt show` and `dpkg -L` and captured the output
- [ ] Removed the package cleanly (`sudo apt remove`)
- [ ] Created `~/backup.tar.gz` of `~/projectfiles` and listed it with `tar -tzf`
- [ ] Extracted a copy into `~/restore` and compared compressed vs. uncompressed size
- [ ] Built `~/module7-software-report.txt` with your hostname + apt + tar output
- [ ] Ran `check-software.sh` and all checks PASS
- [ ] Recorded the Zoom screen recording (webcam off; hostname + whoami + passing check)
- [ ] Wrote the three written-component answers
- [ ] Submitted screencast + written component to Canvas

---

### On RHEL this would be…

The *concepts* are identical — repositories, signed packages, a package manager that installs/inspects/removes software — but the **tools differ**. On Red Hat–family systems (RHEL, Rocky, Fedora) you use **`dnf`** (older systems: `yum`) instead of `apt`, and the low-level package tool is **`rpm`** instead of `dpkg`. Rough translations:

| Task | Ubuntu (this lab) | RHEL / Rocky / Fedora |
| --- | --- | --- |
| Refresh metadata | `sudo apt update` | `sudo dnf check-update` (refresh is automatic) |
| Install | `sudo apt install tree` | `sudo dnf install tree` |
| Remove | `sudo apt remove tree` | `sudo dnf remove tree` |
| Show package info | `apt show tree` | `dnf info tree` |
| List installed files | `dpkg -L tree` | `rpm -ql tree` |
| Is it installed? | `dpkg -l tree` | `rpm -q tree` |
| Repo config lives in | `/etc/apt/sources.list[.d]` | `/etc/yum.repos.d/*.repo` |

The **archiving** half of this lab (`tar`, gzip, compressed `.tar.gz`) is **exactly the same** on every Linux distribution — `tar` is core Linux, not tied to any package manager.
