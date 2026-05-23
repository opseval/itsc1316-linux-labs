# Module 4 Lab: Filesystems & Directory Navigation (Multipass)

**Hands-on lab — runs on your own `labvm`. Replaces the former Red Hat Academy Lab 4.09 (File Systems Overview).**

## Lab Overview

Every Linux system organizes its files the same way, following the **Filesystem Hierarchy Standard (FHS)**. Because that layout is standardized, an administrator who walks up to *any* Linux machine already knows where to look: configuration in `/etc`, user data in `/home`, logs and spools in `/var`, installed programs in `/usr`. In this lab you will explore those real directories on your own VM and record what each holds, then build and organize a proper directory structure of your own under `~/Documents` — creating, copying, and moving files into place the way you would lay out a project. You will navigate to the same location two different ways (by **absolute** and by **relative** path), use `find` to locate files and redirect the results, and finish by reasoning about a file's *purpose* just from *where it lives*. That last skill — reading a system by its layout — is what separates someone who memorized commands from someone who understands the OS.

|  |  |
| --- | --- |
| **Estimated Time** | 45–70 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-filesystem.sh`, `check-filesystem.sh` (in this folder of your cloned repo) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-filesystem.sh` passing, plus your written reflection (below) |
| **Key Location** | `~/Documents` (the structure you build) and `~/results` (your `find` output) |

## Outcomes

By the end of this lab you will be able to:

- Explain the **FHS** and why a standardized layout helps an administrator.
- Identify **`/`** as the root of the single directory tree, and describe the roles of **`/etc`**, **`/home`**, **`/var`**, and **`/usr`** with a real example file from each.
- Build, organize, and reorganize a directory structure, moving and copying files into the right place.
- Navigate to a location using both an **absolute path** (from `/`) and a **relative path** (from where you are).
- Use **`find`** to locate files by name and redirect its output and errors to separate places.
- **Infer a file's administrative purpose from its location** in the tree.

---

## Start the Lab Environment

From your computer's terminal, **at the root of your cloned repo**, start the VM and transfer the two scripts in (do these *before* opening the VM shell — `multipass` doesn't exist inside the VM):

```
multipass start labvm
multipass transfer labs/module-04-filesystem-navigation/setup-filesystem.sh labvm:/home/ubuntu/
multipass transfer labs/module-04-filesystem-navigation/check-filesystem.sh labvm:/home/ubuntu/
```

Now open a shell inside the VM and seed the lab files:

```
multipass shell labvm
sudo bash setup-filesystem.sh
```

This creates `~/mod04-staging/` holding four unsorted files (`backup.sh`, `diskcheck.sh`, `old-backup.log`, `utilities-readme.txt`). Part of the lab is putting them where they belong.

---

## Instructions

You will explore real system directories and then build a structure of your own. The check script inspects your real directory tree, the contents of `~/results`, and an evidence file — so do the work on *your* VM.

### Part 1 — Explore the FHS

Linux has **one** directory tree, starting at the root, `/`. Everything hangs off it. Look at four of the most important branches and find a real example file in each. Run these and read the output:

```
ls /            # the top of the tree — note /etc, /home, /var, /usr and more
ls /etc | head  # system-wide configuration files
ls /home        # each user's home directory
ls /var/log     # logs and other variable data that grows over time
ls /usr/bin | head  # installed programs (binaries)
```

For each of the four directories below, find **one real file** that lives there (the example commands suggest one). You will record these in your evidence file in Part 5.

| Directory | Role | Find an example with |
| --- | --- | --- |
| `/etc`  | System-wide configuration | `ls /etc/hostname` (the file naming this machine) |
| `/home` | Users' personal directories | `ls -d "$HOME"` (your own home directory, e.g. `/home/ubuntu` on Multipass) |
| `/var`  | Variable data: logs, spools, caches | `ls /var/log/dpkg.log` |
| `/usr`  | Installed software and its support files | `ls /usr/bin/ls` (the `ls` program itself) |

> **Why this matters:** because every Linux system uses this same layout, you never have to guess. Configuration is in `/etc`; if a service misbehaves, its logs are in `/var/log`. That predictability is the whole point of a standard.

### Part 2 — Build and organize a directory structure under ~/Documents

Now lay out a small project structure of your own. Create three subdirectories under `~/Documents`, then put the staged files where they belong.

**2a. Make the structure** (one command with `-p` creates all of it):

```
mkdir -p ~/Documents/utilities ~/Documents/scripts ~/Documents/backups
```

**2b. Move the two shell scripts into `scripts/`** (a *move* — they leave staging):

```
mv ~/mod04-staging/backup.sh ~/Documents/scripts/
mv ~/mod04-staging/diskcheck.sh ~/Documents/scripts/
```

**2c. Move the old log into `backups/`:**

```
mv ~/mod04-staging/old-backup.log ~/Documents/backups/
```

**2d. Copy (don't move) the readme into `utilities/`** — keep the original in staging so you can see the difference between `cp` and `mv`:

```
cp ~/mod04-staging/utilities-readme.txt ~/Documents/utilities/
```

**2e. Create a new file directly in `utilities/`** describing the folder:

```
echo "This folder holds small admin utilities." > ~/Documents/utilities/notes.txt
```

Verify the result:

```
ls -R ~/Documents
```

You should see `backup.sh` and `diskcheck.sh` in `scripts/`, `old-backup.log` in `backups/`, and `utilities-readme.txt` plus `notes.txt` in `utilities/`.

> **Why this matters:** moving (`mv`) relocates a file; copying (`cp`) duplicates it. Choosing the right one matters when you reorganize a server — moving a config file out from under a running service can break it, while copying leaves the original safely in place.

### Part 3 — Absolute vs. relative paths

An **absolute path** starts at the root (`/`) and works from anywhere. A **relative path** starts from your current location (`.` = here, `..` = up one). Reach `~/Documents/scripts` two different ways and confirm with `pwd` each time.

**3a. By absolute path** (works no matter where you start). The portable form uses `$HOME` so it works whether your account is `ubuntu` (Multipass) or something else (cloud fallback):

```
cd "$HOME/Documents/scripts"      # equivalent to /home/<your-user>/Documents/scripts
pwd
```

**3b. By relative path** (start at home, then descend):

```
cd ~
cd Documents/scripts
pwd
```

Both `pwd` outputs are identical — but only the relative one depends on where you started. Try the relative `cd Documents/scripts` from `/tmp` and watch it fail; that is the difference.

> **Why this matters:** scripts that use relative paths break when run from an unexpected directory; absolute paths are predictable. But relative paths (`../config`) make a project portable. Knowing which to use, and when, prevents a whole class of "works on my machine" bugs.

### Part 4 — Find files and redirect the results

`find` walks the tree looking for matches. Searching from `/` will hit directories you cannot read and print "Permission denied" errors — you will send those errors somewhere separate so they do not clutter your results.

**4a.** Find every `*.sh` file under your home directory and save the list to `~/results`:

```
find ~ -name "*.sh" > ~/results
```

`cat ~/results` should list at least the two scripts you moved into `~/Documents/scripts`.

**4b.** Now search the whole system for files named `hostname`, sending **results** to your file (appending) and **errors** to a separate place so permission-denied noise does not mix in:

```
find / -name "hostname" >> ~/results 2> ~/find-errors.log
```

`cat ~/results` now also includes `/etc/hostname` (and possibly others). `cat ~/find-errors.log` shows the permission errors that were kept out of your results — the same stdout/stderr separation idea from Module 3, applied to a real search.

> **Why this matters:** real searches generate noise. Redirecting errors away from results is how you get a clean list you can act on, instead of one buried in "Permission denied".

### Part 5 — Infer purpose from location, and write your evidence file

You can often tell what a file is *for* just from where it lives. Look at these real paths on your VM and think about each:

```
ls -l /etc/ssh/sshd_config     # configuration for...?
ls -l /var/log/auth.log        # a log of...?
ls -l /usr/bin/passwd          # a program that...?
```

`/etc/ssh/sshd_config` is in `/etc`, so it is **configuration**, and the path says it configures the SSH daemon. `/var/log/auth.log` is in `/var/log`, so it is a **log**, and the name says it records authentication events. `/usr/bin/passwd` is in `/usr/bin`, so it is an **installed program** — the one that changes passwords. You inferred all three from location alone.

Now write your evidence file in one command. It must contain your real hostname and your four FHS example notes:

```
{ echo "=== Module 4 FHS evidence ==="; \
  echo "hostname: $(hostname)"; \
  echo "/etc  example: $(ls /etc/hostname)  (system configuration)"; \
  echo "/home example: $(ls -d "$HOME")  (a user's home directory)"; \
  echo "/var  example: $(ls /var/log/dpkg.log)  (variable data / a log)"; \
  echo "/usr  example: $(ls /usr/bin/ls)  (an installed program)"; \
} > ~/Documents/fhs-evidence.txt
cat ~/Documents/fhs-evidence.txt
```

The checker reads your real hostname and these four example lines out of `fhs-evidence.txt`.

---

## Evaluation (Required)

Grade your own work by running the check script inside the VM:

```
bash check-filesystem.sh
```

It prints PASS or FAIL for each requirement. Correct any FAILs and run it again until everything passes.

---

## Written Reflection (submit this)

Answer each in 2–4 sentences, **in your own words**:

```
WRITTEN REFLECTION — Module 4
Your name:
VM hostname (run `hostname`):

1. Why does the FHS being standardized help an administrator? Give a
   concrete example of a task that is faster because you already know
   where things live.

2. Inferring purpose from location: pick ONE path you looked at in Part 5
   (or another real path on your VM) and explain how its location in the
   tree tells you what it is for — without opening the file.

3. Absolute vs. relative paths, in your own words: what is the difference,
   and give one situation where you would deliberately choose each.

4. AI note (required by the AI policy below): one line — what (if anything)
   you asked an AI, and what you verified yourself on your VM.
```

---

## Submission Requirement

Submit **two things** to Canvas:

1. A **60–90 second screen recording** made with your **Alamo Colleges Zoom account** (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `bash check-filesystem.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio. See Setup Guide, Part 4.
2. Your completed **written reflection** (the four answers above) — this is where you explain your reasoning, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** You may ask an AI assistant what a directory is for or how `find` flags work — include a one-line note of what you asked and what you verified yourself (answer 4 above). An AI cannot see your VM: it does not know your machine's hostname, what is actually in *your* `/var/log`, or where *you* put the staged files. The checker reads your real directory tree and your real hostname out of your files, and the screencast shows them on your machine — that is how we know the work is yours.

---

## Finish / Clean Up

You can leave the scenario in place. To free up resources between sessions without losing your work:

```
multipass stop labvm
```

Do **not** delete `labvm` — later labs reuse it.

---

## Final Checklist

- [ ] Ran `setup-filesystem.sh` to seed `~/mod04-staging`
- [ ] Part 1: explored `/etc`, `/home`, `/var`, `/usr` and noted an example file in each
- [ ] Part 2: created `~/Documents/{utilities,scripts,backups}` and moved/copied the staged files into place
- [ ] Part 3: reached `~/Documents/scripts` by both absolute and relative path
- [ ] Part 4: created `~/results` (find output) and `~/find-errors.log` (errors), with results and errors separated
- [ ] Part 5: created `~/Documents/fhs-evidence.txt` containing your hostname and the four FHS examples
- [ ] Ran `check-filesystem.sh` and all checks PASS
- [ ] Recorded the Zoom screen recording (webcam off; hostname + whoami + passing check)
- [ ] Wrote answers to all four reflection questions
- [ ] Submitted screencast + written reflection to Canvas

---

### On RHEL this would be…

The FHS is exactly that — a *standard* — so `/`, `/etc`, `/home`, `/var`, and `/usr` mean the same thing on Red Hat–family systems (RHEL, Rocky, Fedora) as on Ubuntu, and `cd`, `ls`, `mkdir`, `cp`, `mv`, `find`, and `pwd` are identical. A few specifics differ: the default user's home is whatever account you created (not `/home/ubuntu`); the package log in `/var/log` is `dnf.log`/`yum.log` rather than Ubuntu's `dpkg.log`; and `/etc` will hold Red Hat–style config (e.g. `/etc/sysconfig/`) you won't see on Ubuntu. The skill that transfers everywhere is the one this lab trains: knowing the *shape* of the tree so you can find what you need on a machine you've never touched.
