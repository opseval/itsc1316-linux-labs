# Module 1 Lab: First Contact — Explore Your Linux System (Multipass)

**Hands-on lab — runs on your own `labvm`. New hands-on component for the Module 1 discussion + quiz (which had no lab).**

## Lab Overview

Module 1 is full of big ideas: what an operating system actually does, what makes Linux different, what a "distribution" is, and where Linux shows up in industry and the cloud. Those ideas stay abstract until you look at a real Linux system and see them. In this lab you become the administrator of a brand-new machine and do what every admin does on day one with an unfamiliar box: *figure out what you're sitting in front of.* You will identify the distribution, the kernel, the shell, the filesystem layout, and the package manager — then connect each finding back to the concepts from the module. This is the foundation everything else in the course builds on.

|  |  |
| --- | --- |
| **Estimated Time** | 30–45 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-intro.sh`, `check-intro.sh` (pulled into `labvm` from the public repo with curl — see Setup Guide) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-intro.sh` passing, plus your completed `module1-system-report.txt` with its written reflection |
| **Evidence File** | `~/module1-system-report.txt` |

## Outcomes

By the end of this lab you will be able to:

- Explain the purpose of an operating system by pointing to what *this* OS is doing for you.
- Outline key features of Linux (kernel, shell, multi-user, package-managed, often headless).
- Describe where this distribution came from and how to identify it (`/etc/os-release`, `lsb_release`, `hostnamectl`).
- Identify the characteristics of a Linux distribution and the package manager that defines it.
- Explain, with evidence from your own system, why Linux is used heavily in industry and the cloud.

---

## Start the Lab Environment

From your computer's terminal, start `labvm` and shell into it:

```
multipass start labvm
multipass shell labvm
```

Then **inside `labvm`**, pull this lab's two scripts straight from the public course repo, eyeball them, and run the setup:

```
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-01-introduction-to-linux/setup-intro.sh
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-01-introduction-to-linux/check-intro.sh
sudo bash setup-intro.sh
```

This lab does **not** break anything — the setup script only drops a starter template at `~/module1-system-report.txt` for you to fill in. (No snapshot needed; you are only reading the system and writing one text file.)

> **Re-running this lab?** If `~/module1-system-report.txt` already exists, the setup script will leave it alone so your prior work is safe. To start over with a fresh template: `rm ~/module1-system-report.txt && sudo bash setup-intro.sh`.

---

## Instructions

You will run a series of investigation commands and **record the real output** into your evidence file `~/module1-system-report.txt`. Open it in an editor as you go:

```
nano ~/module1-system-report.txt
```

(`nano` saves with **Ctrl+O** then **Enter**, and exits with **Ctrl+X**.) For each step below, run the command in your shell, then paste the real output onto the matching line in the file, replacing the `<run: ...>` placeholder.

**1. Identify yourself and the machine.**
Run `hostname`. This is *your* VM's name and ties the report to you. Record it.

**2. Identify the distribution.**
Run all three and compare what they tell you:

```
cat /etc/os-release
lsb_release -a
hostnamectl
```

Record the distribution's **ID** (the `ID=` line in `/etc/os-release` — it should read `ubuntu`) and its version/description.

> **Why three commands for one fact?** Part of being an admin is knowing more than one way to ask the same question, because not every system has every tool installed. `/etc/os-release` is the most portable.

**3. Identify the kernel.**
Run `uname -r` and then `uname -a`. The kernel is the core of the OS — the part that actually talks to the hardware and manages memory, processes, and devices. Record the **exact** `uname -r` string (something like `5.15.0-XXX-generic`).

> The distribution (Ubuntu) and the kernel (Linux) are *not* the same thing. "Linux" is technically just the kernel; Ubuntu is the distribution wrapped around it.

**4. Identify the shell.**
Run `echo $SHELL` and `cat /etc/shells`. The shell is your text interface to the system — the program reading the commands you type. Record your login shell and a couple of the other shells available.

**5. Confirm this is a headless (no-GUI) server.**
Run `systemctl get-default`. On a fresh server install this is usually `multi-user.target` (text/headless), but some Ubuntu cloud images — including the default Multipass 22.04 build — keep the symlink at `graphical.target` even when no GUI is installed. Record whichever YOUR system prints; both are valid on a headless server because no display manager is wired in.

> **Why headless?** Servers usually run with no graphical desktop at all. A GUI consumes RAM and CPU, adds software that can be attacked, and isn't needed when you administer the box over SSH. This is one of the biggest day-to-day differences from a typical Windows or macOS desktop.

**6. Explore the top of the filesystem.**
Run `ls /`. You'll see directories like `bin`, `etc`, `home`, `usr`, `var`. Everything on a Linux system hangs off this single root (`/`) — there are no drive letters like `C:`. Record the directory names you see.

**7. Confirm the package manager.**
Run `which apt` and then `dpkg -l | wc -l`. `apt` is Ubuntu's package manager — the tool the *distribution* uses to install, update, and remove software. The count from `dpkg -l | wc -l` is roughly how many packages were assembled to make your "Ubuntu." Record both. *(The pipe `|` sends one command's output as input to the next — here, the list from `dpkg -l` is piped into `wc -l`, which counts the lines. See [`docs/07-glossary.md`](../../docs/07-glossary.md) for any other unfamiliar terms.)*

> A distribution is essentially **the Linux kernel + a curated set of packages + a package manager to manage them.** That is what makes Ubuntu *Ubuntu* and not Fedora.

**8. Write your reflection.**
At the bottom of the report, answer both reflection questions in full sentences (see below).

---

## Evaluation (Required)

Grade your own work by running the check script inside the VM:

```
bash check-intro.sh
```

It confirms your report exists, is non-empty, and that the facts you recorded actually match this machine — your real **kernel string**, the distro **ID `ubuntu`**, your real **hostname**, the **shell**, and **apt** — and that you replaced every placeholder and wrote a reflection. Fix any FAILs and run it again until everything passes.

> **Why the check reads your live system:** it compares your report against the output of `uname -r` and `hostname` *on this VM right now*. That means you can't fill the report in from a textbook or an AI — the kernel string and hostname are unique to your machine. That's the point.

---

## Written Reflection (in `module1-system-report.txt`)

Answer both at the bottom of your report, in your own words, a short paragraph each:

1. **What makes this "Linux" and not Windows or macOS?** Point to at least **two** concrete things you found above (for example: the single `/` filesystem root with no drive letters, the absence of a GUI, the kernel name from `uname`, the `apt` package manager, or the multi-user shell). Explain what each one tells you.
2. **Where in industry or the cloud would you expect a system like this one?** Name a realistic place (web/app servers, cloud instances on AWS/Azure/GCP, containers, embedded devices, etc.) and explain *why* Linux is a good fit there — tie it back to something you observed (headless, lightweight, package-managed, free to run on thousands of machines).

---

## Submission Requirement

Submit **two things** to Canvas:

1. A **60–90 second screen recording** made per the [Screen Recording Guide](../../docs/05-screen-recording-guide.md) (Alamo Zoom by default; one specific backup per OS if Zoom is broken) (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `bash check-intro.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio.
2. Your completed **`module1-system-report.txt`**, including the written reflection — this is where your reasoning lives, so the recording does not need narration. (Copy it out of the VM with `multipass transfer labvm:/home/ubuntu/module1-system-report.txt .` from your computer's terminal.)

> **AI policy for this lab: AI-OPEN.** You may ask an AI assistant to explain what any of these commands do — include a one-line note of what you asked and what you verified yourself. But an AI cannot see *your* VM: it doesn't know your kernel build number, your hostname, or how many packages your machine has. The check script compares your report to your live system, so the evidence has to come from running the commands yourself.

---

## Finish / Clean Up

You can leave everything in place. To free up resources between sessions without losing your work:

```
multipass stop labvm
```

Do **not** delete `labvm` — every later lab reuses it.

---

## Final Checklist

- [ ] Ran `setup-intro.sh` to create the report template
- [ ] Recorded the hostname, distro ID, and version
- [ ] Recorded the exact `uname -r` kernel string and `uname -a`
- [ ] Recorded the login shell and available shells
- [ ] Recorded the default target (`multi-user.target` or `graphical.target` — either is valid on a headless cloud image)
- [ ] Listed the top of the filesystem (`ls /`)
- [ ] Recorded the package manager path and the installed-package count
- [ ] Replaced every `<run: ...>` placeholder with real output
- [ ] Wrote both reflection answers
- [ ] Ran `check-intro.sh` and all checks PASS
- [ ] Recorded the Zoom screen recording (webcam off; hostname + whoami + passing check)
- [ ] Submitted the recording + completed report to Canvas

---

### On RHEL this would be…

Almost everything here is identical on a Red Hat–family system (RHEL, Rocky, Fedora): `uname`, `hostname`, `echo $SHELL`, `ls /`, `hostnamectl`, and `systemctl get-default` all work the same. The two differences you'd notice: `/etc/os-release` would show `ID=rhel` (or `rocky`/`fedora`) instead of `ubuntu`, and the **package manager is `dnf`** (older RHEL used `yum`) with the `rpm` database, so you'd count packages with `rpm -qa | wc -l` instead of `dpkg -l | wc -l`. The concept — a distribution is the Linux kernel plus a curated, package-managed software set — is exactly the same; only the tooling brand changes.
