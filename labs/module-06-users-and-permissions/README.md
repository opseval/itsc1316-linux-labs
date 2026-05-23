# Module 6 Lab: Users, Ownership, and File Permissions (Multipass)

**Hands-on lab — runs on your own `labvm`. Replaces the former Red Hat Academy Lab 5.05.**

## Lab Overview

In this lab you secure a shared directory for a sales team. You will fix broken ownership, create a file with exact permissions, lock down a script so only its owner can run it, and then prove the script works by generating real output. This mirrors a routine task for any Linux administrator: making sure the right people — and only the right people — can access shared resources.

|  |  |
| --- | --- |
| **Estimated Time** | 30–50 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-users.sh`, `check-users.sh` (in this folder of your cloned repo) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-users.sh` passing, plus your written answers to the two reflection questions |
| **Key Location** | `/salesteam` |

## Outcomes

By the end of this lab you will be able to:

- Explain how Linux uses **users and groups** to control access to files and resources.
- Change file and directory ownership with `chown`, and explain why ownership matters in a multi-user system.
- Set precise permissions with `chmod`, including the difference between owner, group, and others.
- Apply the **principle of least privilege** — grant exactly the access required and no more.
- Identify common **security and usability problems caused by incorrect permissions**.
- Use `sudo` to perform privileged actions safely.
- Reason about *why* a given permission set is correct for a real-world scenario, not just how to type it.

---

## Start the Lab Environment

From your computer's terminal, **at the root of your cloned repo**, start the VM and transfer the two scripts in (do these *before* opening the VM shell — `multipass` doesn't exist inside the VM):

```
multipass start labvm
multipass transfer labs/module-06-users-and-permissions/setup-users.sh labvm:/home/ubuntu/
multipass transfer labs/module-06-users-and-permissions/check-users.sh labvm:/home/ubuntu/
```

Now open a shell inside the VM and build the scenario:

```
multipass shell labvm
sudo bash setup-users.sh
```

This creates a `salesteam` group, two teammates (`avery` and `jordan`), and a `/salesteam` directory containing a `generate_reports.sh` script. The setup deliberately leaves things **misconfigured** — fixing them is the lab.

> **Tip — snapshot before you experiment.** From inside the VM, type `exit` to return to your computer's terminal, then stop the VM and snapshot it (Multipass won't snapshot a running instance), then start it again:
>
> ```
> multipass stop labvm
> multipass snapshot --name pre-mod06 labvm
> multipass start labvm
> multipass shell labvm
> ```
>
> If you paint yourself into a corner, `multipass stop labvm && multipass restore labvm.pre-mod06 && multipass start labvm` rolls back.

---

## The Scenario

The sales team needs a shared folder at `/salesteam`. Right now it is owned by `root`, the report script will not run, and nothing is locked down correctly. Your job is to set it right.

## Instructions

**1. Fix ownership of the shared directory.**
Set the owner of `/salesteam` (and everything inside it) to the `ubuntu` user and the `salesteam` group. Use `sudo` because the directory is currently owned by root.

> Think about *why* group ownership matters here: the whole point is that everyone on the sales team (members of `salesteam`) should be able to collaborate in this folder.

**2. Create a shared notes file with exact permissions.**
Create the file `/salesteam/meeting-highlights.txt`. Make sure its group is **`salesteam`** (a new file inherits *your* group by default, which is `ubuntu` — not the team's group — so you'll need to set it explicitly, or have set the directory's setgid bit beforehand). Set its permissions so that the **owner and the group can read and write it, but everyone else gets nothing** (no read, no write, no execute). Put a line of text in it so it is not empty.

**3. Lock down the report script.**
The file `/salesteam/generate_reports.sh` should be **executable by its owner only** — not by the group, not by others — and **not writable by the group or others either** (a script anyone can rewrite is just as dangerous as a script anyone can execute). Keep it readable. Set ownership to `ubuntu:salesteam` and permissions accordingly.

**4. Run the script and verify its output.**
Run the script using the execute bit you just set — `cd /salesteam && ./generate_reports.sh` — rather than `bash generate_reports.sh` (which would bypass the permission you're trying to test). Confirm that it creates **three quarterly reports** with the `.xls` extension in `/salesteam` (`Q1-report.xls`, `Q2-report.xls`, `Q3-report.xls`).

> **If something does not behave as expected**, re-check ownership first, then the execute bit on the script, then whether any directory permission is blocking access. Most permission problems are one of those three.

---

## Evaluation (Required)

Grade your own work by running the check script inside the VM:

```
bash check-users.sh
```

It prints PASS or FAIL for each requirement. Correct any FAILs and run it again until everything passes. This is exactly what a real administrator does after making a change — re-test until the system is in the desired state.

---

## Reflection Questions (answer in your submission)

Real understanding shows up in *why*, not just *what*. Answer both in 2–3 sentences each, in your own words:

1. You set `meeting-highlights.txt` to `660`. What specifically would change for the user `avery` if you had set it to `640` instead? (You can test this — switch to avery with `sudo su - avery` and try to edit the file.)
2. Why is it risky to make `generate_reports.sh` executable and writable by the group or others? Describe one realistic way that could be abused.

---

## Submission Requirement

Submit **two things** to Canvas:

1. A **60–90 second screen recording** made with your **Alamo Colleges Zoom account** (webcam off; narration optional). It must show, in one continuous take: `hostname` and `whoami` (so we know it is your VM), then `bash check-users.sh` passing all checks. See Part 4 of the Multipass Setup Guide for the Zoom recording and submission steps (a **Zoom Cloud link is preferred**; keep your own `.mp4` copy for a possible portfolio).
2. Your **written answers** to the two reflection questions above (a few sentences each). This is where you explain your reasoning, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** You may use an AI assistant to help you understand commands, but include a one-line note of anything you asked it and what you verified yourself. The screencast and reflection answers are how you demonstrate the work is yours.

---

## Finish / Clean Up

You can leave the scenario in place. To free up resources between sessions without losing your work:

```
multipass stop labvm
```

Do **not** delete `labvm` — later labs reuse it.

---

## Final Checklist

- [ ] Ran `setup-users.sh` to build the scenario
- [ ] Set `/salesteam` ownership to `ubuntu:salesteam`
- [ ] Created `meeting-highlights.txt` with mode `660` and some content
- [ ] Set `generate_reports.sh` to be executable by the owner only
- [ ] Ran the script and confirmed three `.xls` reports were created
- [ ] Ran `check-users.sh` and all checks PASS
- [ ] Recorded the Zoom screen recording (webcam off; hostname + whoami + passing check)
- [ ] Wrote answers to both reflection questions
- [ ] Submitted screencast + written answers to Canvas

---

### On RHEL this would be…

On a Red Hat–family system (RHEL, Rocky, Fedora) every command in this lab is **identical** — `chown`, `chmod`, `useradd`, `groupadd`, and `sudo` are part of core Linux and behave the same way. The only difference you would notice is the default user account name (`ubuntu` here vs. often a name you choose on RHEL) and that RHEL may have **SELinux** enforcing additional context-based restrictions on top of these permissions, which you will meet later in the course.
