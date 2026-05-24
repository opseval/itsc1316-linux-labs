# Module 14 Lab: Security & Troubleshooting Foundations (Multipass)

**Hands-on break/fix lab — runs on your own `labvm`. Replaces the former written assignment.**

## Lab Overview

A previous administrator left this system in rough shape: a tool was given dangerous privileges, a sensitive file was left wide open, a "free optimizer" someone installed is pegging the CPU, and a service keeps failing to start. Your job is to **investigate like a responsible administrator** — gather evidence first, then remediate safely — and explain your reasoning. This is the kind of work that fills an entry-level Linux/security job: nobody hands you a labeled problem; you find it.

|  |  |
| --- | --- |
| **Estimated Time** | 50–75 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-security.sh`, `check-security.sh` (pulled into `labvm` from the public repo with curl — see Setup Guide) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-security.sh` passing, plus a short **incident report** (template below) |

## Outcomes

By the end of this lab you will be able to:

- Reduce a system's **attack surface** (the parts of a system an attacker can reach) by removing unnecessary privileges (SUID, world-writable files).
- Apply the principle of least privilege to a real file and a real service.
- Inventory a system's **exposed network services** and reason about which are needed — recognizing that listening services are part of the attack surface.
- Investigate a performance problem with evidence before changing anything.
- Diagnose a failed `systemd` service using logs, and choose a safe remediation.
- Distinguish a configuration error from a resource constraint from possibly-malicious behavior.

---

## Start the Lab Environment

> **SNAPSHOT FIRST — this lab plants real security issues and you'll be running fix commands as root.** Multipass cannot snapshot a running instance, so stop it, snapshot, then start again. From your computer's terminal — **do this now, before running setup**:
>
> ```
> multipass stop labvm
> multipass snapshot --name pre-mod14 labvm
> multipass start labvm
> ```
>
> If you get stuck, you can roll back with: `multipass stop labvm && multipass restore labvm.pre-mod14 && multipass start labvm`.

Start `labvm` and shell into it (from your computer's terminal):

```
multipass start labvm
multipass shell labvm
```

Then **inside `labvm`**, pull this lab's two scripts straight from the public course repo, eyeball them, and plant the scenario:

```
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-14-security-troubleshooting/setup-security.sh
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-14-security-troubleshooting/check-security.sh
# Optional safety review (this is the security module — worth the scan).
# Skim each script for red flags: any 'rm -rf /', any 'curl ... | bash', any URL
# not under raw.githubusercontent.com/opseval/, any unexpected modification of
# /etc/passwd, /etc/shadow, /etc/sudoers.d/, or systemd unit paths outside
# /etc/systemd/system/reportd.service (which IS this lab). The INTEGRITY: VERIFIED
# line the check script prints is the stronger guarantee — this is the human-eye
# supplement. Press q to exit each file.
less setup-security.sh
less check-security.sh
sudo bash setup-security.sh
```

The system now has four problems. You are not told exactly where they all are — part of the lab is finding them.

---

## Your Mission

Work like an administrator responding to a vague ticket: *"This machine feels slow and IT says it might not be secure."* Investigate first, then fix. The four issues, described at the level of symptoms an admin would actually notice:

**1. A tool has been given dangerous privileges.**
Somewhere under `/usr/local/bin` there is a custom helper that runs with **root privileges regardless of who launches it** (the SUID bit). That is a classic **privilege-escalation** risk — a way for an ordinary user to gain root power. Find it and remove the unnecessary privilege.

> Hint: you can list every SUID file on the system with
> `find / -perm -4000 -type f 2>/dev/null`. Most results are legitimate system binaries — your job is to spot the one that does not belong.

**2. A sensitive file is exposed.**
There is payroll data on this system that the previous admin left readable and writable by everyone. Find it and apply least-privilege permissions so that **only root** can read or change it.

> Hint: list every world-writable file on the system:
> ```
> sudo find / -perm -0002 -type f -not -path '/proc/*' -not -path '/sys/*' 2>/dev/null
> ```
> The `-not -path` filters skip kernel files in `/proc` and `/sys` that are world-writable by design.

**3. Something is eating the CPU.**
Users report the machine is sluggish. Investigate with the process tools from Module 10 (`top`, `ps`, `pgrep`). Identify the runaway process — it is a "system optimizer" that should never have been installed — and stop it. (You do not need to permanently uninstall it for the check to pass; stopping it is enough, but think about how you would prevent it from coming back.)

> The `pgrep -f` / `pkill -f` wrapper-shell gotcha from Module 10 applies here too: if you're driving via `multipass exec labvm -- bash -c '...'`, those flags may match the wrapping shell's own command line. Use `pgrep -x` against the executable name, or `ps -eo args | grep "/usr/local/bin/sysoptimizer" | grep -v grep`. If `pkill` makes your `exec` return non-zero, verify the kill worked with a separate `pgrep` rather than trusting the exit code.

**4. A service keeps failing.**
A service called `reportd` was configured to start at boot but it keeps failing. Use `systemctl status reportd` and `journalctl -u reportd` to find out *why* it fails — read the actual error, do not guess. Once you understand the root cause, **stop it and prevent it from auto-starting:**

```
sudo systemctl stop reportd
sudo systemctl disable reportd
```

If `systemctl --failed` still lists `reportd` afterwards, clear the sticky failure marker: `sudo systemctl reset-failed reportd`. In your incident report, state the root cause in one sentence.

> **Why `disable` and not `mask` here?** `mask` blocks a unit by symlinking it to `/dev/null`. That works for distro-shipped units in `/lib/systemd/system/`, but this lab's unit lives at `/etc/systemd/system/reportd.service` — `mask` won't overwrite a real file there. For locally-installed units like this one, `disable` is the right call.

**5. Survey the attack surface (assessment, not a fix).**
A system's exposed network services are part of its attack surface — every service listening on a port is something an attacker could reach. Inventory what is listening:

```
sudo ss -tulpn
```

For each listening service, ask: *does this need to be reachable, and by whom?* You are not changing anything here — you are documenting the exposure, which is the first step of any real hardening review. Record the listening services and a one-line judgment for each in your incident report.

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

5. Attack surface (listening services, from `sudo ss -tulpn`)
   - The listening services you found, and a one-line judgment for each
     (needed? who should reach it?):
   - Which one service, if any, would you investigate first for tightening, and why:
```

---

## Submission Requirement

Submit **two things**:

1. A **60–90 second screen recording** made per the [Screen Recording Guide](../../docs/05-screen-recording-guide.md) (Alamo Zoom by default; one specific backup per OS if Zoom is broken) (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `bash check-security.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio.
2. Your completed **incident report** — this is where you state the root cause of the failed service and your reasoning, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** You may ask an AI assistant to explain `find` flags or how to read `journalctl`, but the investigation, the evidence you cite, and the root-cause statement must be yours. Note anything you asked AI and what you confirmed on your own system. An AI can describe what `reportd` *might* fail from; only your VM's logs tell you what it *actually* failed from — cite the real log line.

---

## Finish / Clean Up

When you are done you can restore your clean snapshot if you want a tidy system for later labs. Restore needs the VM stopped, so `exit` the VM first, then from your computer's terminal:

```
multipass stop labvm
multipass restore labvm.pre-mod14
multipass start labvm
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
- [ ] Surveyed listening services with `ss -tulpn` and judged the attack surface
- [ ] Ran `check-security.sh` and all checks PASS
- [ ] Wrote the incident report
- [ ] Recorded the Zoom screen recording (webcam off)
- [ ] Submitted screencast + incident report

---

### On RHEL this would be…

The investigation commands (`find`, `top`, `ps`, `pgrep`, `systemctl`, `journalctl`, `chmod`) are identical on Red Hat–family systems. Two differences worth knowing for a certification exam: RHEL/Rocky add **SELinux**, which can block actions even when file permissions look correct (you would check `getenforce` and `ausearch`/`sealert`), and on RHEL the firewall tool is **firewalld** (`firewall-cmd`) rather than Ubuntu's `ufw`. The security *principles* — least privilege, minimizing attack surface, evidence-based troubleshooting — are the same everywhere.
