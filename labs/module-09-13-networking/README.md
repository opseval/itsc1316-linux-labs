# Module 13 Lab: Advanced Network Configuration (Multipass, Two VMs)

**Hands-on multi-machine lab. Replaces the former written assignment. You will run two VMs that talk to each other.**

## Lab Overview

So far you have worked on one machine. Real networks are about machines *finding and reaching each other*. In this lab you launch a second VM, prove your main VM can reach it, and then untangle a classic problem: a host that is reachable by IP address but **not** by name. Separating "can I connect?" from "can I look up the name?" is one of the most important troubleshooting skills a Linux administrator has.

|  |  |
| --- | --- |
| **Estimated Time** | 50–75 minutes |
| **Environment** | Your `labvm` **plus** a second VM named `fileserver` (you create it in this lab) |
| **Scripts** | `setup-net.sh`, `check-net.sh` (download from Canvas) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-net.sh` passing, plus a short troubleshooting writeup |

## Outcomes

By the end of this lab you will be able to:

- Read a routing table and identify the default gateway and per-interface routes.
- Distinguish a **connectivity** problem from a **name-resolution** problem using evidence.
- Configure persistent local name resolution with `/etc/hosts`.
- Reason about why a host can be reachable one way and not another.

---

## Start the Lab Environment

### 1. Launch a second VM

From **your computer's terminal** (not inside a VM), create a second machine called `fileserver`:

```
multipass launch 22.04 --name fileserver --cpus 1 --memory 1G
multipass list
```

`multipass list` now shows two VMs, each with its own IP address. **Write down the IP of `fileserver`** — you will need it. (It will look something like `10.x.x.x` or `192.168.x.x`.)

### 2. Transfer scripts into labvm and open a shell

```
multipass transfer ~/Downloads/setup-net.sh labvm:/home/ubuntu/
multipass transfer ~/Downloads/check-net.sh labvm:/home/ubuntu/
multipass shell labvm
```

### 3. Plant the scenario (inside labvm)

```
sudo bash setup-net.sh
```

This adds a deliberately **wrong** `/etc/hosts` entry claiming `fileserver` lives at `10.99.99.99`.

---

## Part A — Map Your Network (investigate before you touch anything)

Run these inside `labvm` and study the output:

```
ip a
ip route
```

Answer in your writeup:

1. What is your **default gateway**, and what does the default route actually mean in plain English?
2. Which **interface** carries your traffic, and what IP address does `labvm` have on it?

---

## Part B — Connectivity vs. Name Resolution (the core of the lab)

You are going to see the same host succeed one way and fail another. Pay attention — this distinction is the whole lesson.

1. **Reach `fileserver` by its real IP** (use the IP you wrote down from `multipass list`):

   ```
   ping -c 3 <fileserver-ip>
   ```

   This should succeed. **Conclusion to record:** basic network connectivity between the two VMs is fine.

2. **Now try to reach it by name:**

   ```
   ping -c 3 fileserver
   ```

   This will fail or hang — but notice *how*. Look at what IP the name resolves to:

   ```
   getent hosts fileserver
   ```

   It returns `10.99.99.99`, the bogus address from the setup. **Conclusion to record:** this is a *name-resolution* problem, not a connectivity problem. The network is fine; the system is just being told the wrong address for the name.

3. **Fix the mapping.** Edit `/etc/hosts` with `sudo` and replace the wrong address with `fileserver`'s real IP:

   ```
   sudo nano /etc/hosts
   ```

   Change the `10.99.99.99 fileserver` line so the IP matches what `multipass list` shows for `fileserver`. Save and exit.

4. **Verify the fix:**

   ```
   getent hosts fileserver
   ping -c 3 fileserver
   ```

   Now both the lookup and the ping should work.

> **Why `/etc/hosts`?** It is the system's local, persistent name-to-IP map, checked before DNS. It survives reboots — unlike a route you add by hand at the command line, which disappears. Understanding what is persistent vs. runtime is exactly the kind of thing that bites administrators when "it worked until I rebooted."

---

## Part C — Confirm DNS still works

Your fix to `/etc/hosts` should not have affected normal internet name resolution. Confirm:

```
getent hosts ubuntu.com
ping -c 2 ubuntu.com
```

If external names resolve, your global DNS is healthy and your `/etc/hosts` change was correctly scoped to just `fileserver`.

---

## Evaluation (Required)

Make sure `fileserver` is still running, then inside `labvm`:

```
bash check-net.sh
```

Fix any FAILs and re-run until everything passes.

---

## Troubleshooting Writeup (submit this)

A few sentences per item, in your own words:

```
TROUBLESHOOTING WRITEUP — Module 13
Name:
labvm hostname (run `hostname`):

1. Default gateway and what the default route means:
2. fileserver's real IP (from multipass list):
3. The evidence that told you this was a NAME-RESOLUTION problem and not a
   connectivity problem (be specific about which commands and outputs):
4. A 5-step troubleshooting playbook for the report "the server is reachable
   by IP but not by hostname" (your own words, in order):
```

---

## Submission Requirement

1. A **60–90 second screen recording** made with your **Alamo Colleges Zoom account** (webcam off; narration optional), showing in one continuous take: `hostname`, `multipass list` (or `ip a`), and `bash check-net.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio. See Setup Guide, Part 4.
2. Your completed **troubleshooting writeup** — this is where you explain the difference between the IP test and the name test, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** AI is fine for understanding `ip route` output or `/etc/hosts` syntax, but the playbook and your evidence must come from your own two VMs. Note anything you asked AI and what you verified. An AI cannot know your `fileserver`'s real IP — only your `multipass list` can.

---

## Finish / Clean Up

To free resources between sessions (keeps both VMs and their state):

```
multipass stop labvm fileserver
```

You can keep `fileserver` for later networking labs, or remove it when the course's networking modules are done:

```
multipass delete fileserver && multipass purge
```

Do not delete `labvm`.

---

## Final Checklist

- [ ] Launched the second VM `fileserver` and noted its IP
- [ ] Ran `setup-net.sh` inside labvm
- [ ] Read `ip route` and identified the default gateway
- [ ] Confirmed connectivity by pinging fileserver's IP
- [ ] Showed name resolution was broken (`getent hosts fileserver` → bogus IP)
- [ ] Corrected the `/etc/hosts` entry to the real IP
- [ ] Verified ping-by-name now works and external DNS still works
- [ ] Ran `check-net.sh` and all checks PASS
- [ ] Wrote the troubleshooting writeup
- [ ] Recorded the Zoom screen recording (webcam off)
- [ ] Submitted screencast + writeup

---

### On RHEL this would be…

`ip a`, `ip route`, `ping`, `getent`, and `/etc/hosts` are identical on Red Hat–family systems. The differences appear when you make **persistent interface** changes: Ubuntu uses **netplan** (`/etc/netplan/*.yaml`), while RHEL/Rocky use **NetworkManager** (`nmcli`) with config in `/etc/NetworkManager/`. The concept you practiced here — local name resolution via `/etc/hosts`, checked before DNS, and the discipline of separating connectivity from name resolution — is the same on every Linux system and on the Linux+ exam.
