# Module 14 Lab: Security & Troubleshooting Foundations (Multipass)

**Hands-on break/fix lab — runs on your own `labvm`. Replaces the former written assignment.**

## Lab Overview

A previous administrator left this system in rough shape: a tool was given dangerous privileges, a sensitive file was left wide open, a "free optimizer" someone installed is pegging the CPU, and a service keeps failing to start. Your job is to **investigate like a responsible administrator** — gather evidence first, then remediate safely — and explain your reasoning. This is the kind of work that fills an entry-level Linux/security job: nobody hands you a labeled problem; you find it.

|  |  |
| --- | --- |
| **Estimated Time** | 50–75 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-security.sh`, `check-security.sh` (in this folder of your cloned repo) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-security.sh` passing, plus a short **incident report** (template below) |

## Outcomes

By the end of this lab you will be able to:

- Reduce a system's attack surface by removing unnecessary privileges (SUID, world-writable files).
- Apply the principle of least privilege to a real file and a real service.
- Investigate a performance problem with evidence before changing anything.
- Diagnose a failed `systemd` service using logs, and choose a safe remediation.

---

## Start the Lab Environment

> **Snapshot first.** This lab deliberately breaks things. From your computer's terminal, take a *named* restore point before you begin (so you can find it later, even if you've taken other snapshots):
>
> ```
> multipass snapshot --name pre-mod14 labvm
> ```

Start the VM and transfer the scripts (from your computer's terminal, at the **root of your cloned repo**):

```
multipass start labvm
multipass transfer labs/module-14-security-troubleshooting/setup-security.sh labvm:/home/ubuntu/
multipass transfer labs/module-14-security-troubleshooting/check-security.sh labvm:/home/ubuntu/
multipass shell labvm
```

Inside the VM, plant the scenario:

```
sudo bash setup-security.sh
```

The system now has four problems. You are not told exactly where they all are — part of the lab is finding them.

---

## Your Mission

Work like an administrator responding to a vague ticket: *"This machine feels slow and IT says it might not be secure."* Investigate first, then fix. The four issues, described at the level of symptoms an admin would actually notice:

**1. A tool has been given dangerous privileges.**
Somewhere under `/usr/local/bin` there is a custom helper that runs with **root privileges regardless of who launches it** (the SUID bit). That is a classic privilege-escalation risk. Find it and remove the unnecessary privilege.

> Hint: you can list every SUID file on the system with
> `find / -perm -4000 -type f 2>/dev/null`. Most results are legitimate system binaries — your job is to spot the one that does not belong.

**2. A sensitive file is exposed.**
There is payroll data on this system that the previous admin left readable and writable by everyone. Find it and apply least-privilege permissions so that **only root** can read or change it.

> Hint: `find / -perm -0002 -type f 2>/dev/null` lists world-writable files.

**3. Something is eating the CPU.**
Users report the machine is sluggish. Investigate with the process tools from Module 10 (`top`, `ps`, `pgrep`). Identify the runaway process — it is a "system optimizer" that should never have been installed — and stop it. (You do not need to permanently uninstall it for the check to pass; stopping it is enough, but think about how you would prevent it from coming back.)

**4. A service keeps failing.**
A service called `reportd` was configured to start at boot but it keeps failing. Use `systemctl status reportd` and `journalctl -u reportd` to find out *why* it fails — read the actual error, do not guess. Once you understand the root cause, **stop it and prevent it from auto-starting** (disable or mask it). In your incident report, state the root cause in one sentence.

> **Methodology matters.** For each issue, collect evidence *before* you change anything. "Trying random fixes" is how administrators turn a small problem into an outage. Symptoms tell you where to look; the root cause tells you what to fix.

---

## Evaluation (Required)

Grade your remediation inside the VM:

```
bash check-security.sh
```

Fix any FAILs and re-run until everything passes.

---

## Incident Report (submit this)

Real security work is documented. Fill in this short report (a few sentences per box) and submit it with your screencast:

```
INCIDENT REPORT — Module 14
Investigator (your name):
VM hostname (run `hostname`):

1. SUID tool
   - Which file? How did you find it?
   - Why is an unnecessary SUID-root binary dangerous? (one realistic abuse)
   - What did you do?

2. Exposed payroll file
   - Path and the original permissions you found:
   - The permissions you set, and why that satisfies least privilege:

3. Runaway process
   - Process name and how you identified it (which command, what evidence):
   - How you stopped it:
   - One sentence: how would you stop it from returning?

4. Failed service
   - Root cause (from the logs, in one sentence):
   - How you remediated it, and why "reinstalling everything" would have been the wrong first move:
```

---

## Submission Requirement

Submit **two things**:

1. A **60–90 second screen recording** made with your **Alamo Colleges Zoom account** (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `bash check-security.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio. See Setup Guide, Part 4.
2. Your completed **incident report** — this is where you state the root cause of the failed service and your reasoning, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** You may ask an AI assistant to explain `find` flags or how to read `journalctl`, but the investigation, the evidence you cite, and the root-cause statement must be yours. Note anything you asked AI and what you confirmed on your own system. An AI can describe what `reportd` *might* fail from; only your VM's logs tell you what it *actually* failed from — cite the real log line.

---

## Finish / Clean Up

When you are done you can restore your clean snapshot if you want a tidy system for later labs:

```
multipass restore labvm.pre-mod14
```

Or just `multipass stop labvm` to leave it as-is. Do not delete `labvm`.

---

## Final Checklist

- [ ] Took a snapshot before starting
- [ ] Ran `setup-security.sh`
- [ ] Found and removed the unnecessary SUID privilege
- [ ] Located the payroll file and applied least-privilege permissions
- [ ] Identified and stopped the runaway process (with evidence)
- [ ] Diagnosed the failed service from its logs and disabled/masked it
- [ ] Ran `check-security.sh` and all checks PASS
- [ ] Wrote the incident report
- [ ] Recorded the Zoom screen recording (webcam off)
- [ ] Submitted screencast + incident report

---

### On RHEL this would be…

The investigation commands (`find`, `top`, `ps`, `pgrep`, `systemctl`, `journalctl`, `chmod`) are identical on Red Hat–family systems. Two differences worth knowing for a certification exam: RHEL/Rocky add **SELinux**, which can block actions even when file permissions look correct (you would check `getenforce` and `ausearch`/`sealert`), and on RHEL the firewall tool is **firewalld** (`firewall-cmd`) rather than Ubuntu's `ufw`. The security *principles* — least privilege, minimizing attack surface, evidence-based troubleshooting — are the same everywhere.
