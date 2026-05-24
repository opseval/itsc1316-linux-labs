# Module 13 Lab: Advanced Network Configuration (Multipass, Two VMs)

**Hands-on multi-machine lab. Replaces the former written assignment. You will run two VMs that talk to each other.**

## Lab Overview

So far you have worked on one machine. Real networks are about machines *finding and reaching each other*. In this lab you launch a second VM, prove your main VM can reach it, and then untangle a classic problem: a host that is reachable by IP address but **not** by name. Separating "can I connect?" from "can I look up the name?" is one of the most important troubleshooting skills a Linux administrator has.

|  |  |
| --- | --- |
| **Estimated Time** | 50–75 minutes |
| **Environment** | Your `labvm` **plus** a second VM named `fileserver` (you create it in this lab) |
| **Scripts** | `setup-net.sh`, `check-net.sh` (pulled into `labvm` from the public repo with curl — see Setup Guide) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-net.sh` passing, plus a short troubleshooting writeup |

## Outcomes

By the end of this lab you will be able to:

- Identify a system's network interfaces and IP addresses, and read a routing table to find the default gateway.
- Distinguish a **connectivity** problem from a **name-resolution** problem using evidence.
- Configure persistent local name resolution with `/etc/hosts`.
- Inventory the **network services** listening on a host and explain what each is for.
- Distinguish a **runtime** network change from a **persistent** one, and explain where persistent config lives on Ubuntu.
- Reason about why a host can be reachable one way and not another, and apply a structured troubleshooting process.

---

## Start the Lab Environment

### 1. Launch a second VM

From **your computer's terminal** (not inside a VM), create a second machine called `fileserver`:

```
multipass launch 22.04 --name fileserver --cpus 1 --memory 1G
multipass list
```

`multipass list` now shows two VMs, each with its own IP address. **Write down the IP of `fileserver`** — you will need it. (It will look something like `10.x.x.x` or `192.168.x.x`.)

### 2. Open a shell into labvm and pull this lab's scripts

From your computer's terminal:

```
multipass start labvm                                                       # in case it's stopped
multipass shell labvm
```

Then **inside `labvm`**, pull this lab's two scripts straight from the public course repo and eyeball them:

```
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-13-advanced-networking/setup-net.sh
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-13-advanced-networking/check-net.sh
```

### 3. Plant the scenario (inside labvm)

```
sudo bash setup-net.sh
```

This adds a deliberately **wrong** `/etc/hosts` entry claiming `fileserver` lives at `192.0.2.123`.

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
   ping -c 3 [fileserver-ip]
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

   It returns `192.0.2.123`, the bogus address from the setup. **Conclusion to record:** this is a *name-resolution* problem, not a connectivity problem. The network is fine; the system is just being told the wrong address for the name.

3. **Fix the mapping.** Edit `/etc/hosts` with `sudo` and replace the wrong address with `fileserver`'s real IP:

   ```
   sudo nano /etc/hosts
   ```

   Change the `192.0.2.123 fileserver` line so the IP matches what `multipass list` shows for `fileserver`. Save and exit.

4. **Verify the fix:**

   ```
   getent hosts fileserver
   ping -c 3 fileserver
   ```

   Now both the lookup and the ping should work.

> **Why `/etc/hosts`?** It is the system's local, persistent name-to-IP map, checked before DNS. It survives reboots — unlike a route you add by hand at the command line, which disappears. Understanding what is persistent vs. runtime is exactly the kind of thing that bites administrators when "it worked until I rebooted."

> **About the `manage_etc_hosts:` header in `/etc/hosts`.** On a Multipass Ubuntu cloud image, the top of `/etc/hosts` may say something like `# Your system has configured 'manage_etc_hosts' as True. As a result, if you wish for changes to this file to persist then you will need to either …`. On these images the cloud-init module typically only manages the loopback (`127.0.0.1`) and FQDN lines, so your added `fileserver` line below those *does* persist across reboot — but if you ever see your `/etc/hosts` edit reverted after `multipass restart`, look at `/etc/cloud/cloud.cfg.d/*.cfg` to see what cloud-init is configured to manage.

---

## Part C — Confirm DNS still works

Your fix to `/etc/hosts` should not have affected normal internet name resolution. Confirm:

```
getent hosts ubuntu.com
ping -c 2 ubuntu.com
```

`getent` is the authoritative test — if it returns IPs, your global DNS is healthy and your `/etc/hosts` change was correctly scoped to just `fileserver`.

> **Heads-up — Multipass on macOS drops outbound ICMP.** If `ping -c 2 ubuntu.com` returns 100% loss but the `PING ubuntu.com (185.x.x.x)` header line shows a resolved IP, that's the same macOS-NAT ICMP-filter you saw in Module 9 — not a DNS failure. The lab still passes because the check uses `getent`. Add a one-line note in your writeup that ICMP was filtered.

---

## Part D — Network services, and runtime vs. persistent configuration

A networked machine doesn't just *reach* other hosts — it also *offers* services that others reach. Knowing which services are listening is core networking knowledge (and, as you'll see in the security module, every listening service is part of your attack surface).

1. **See what services are listening on your VM:**

   ```
   sudo ss -tulpn
   ```

   This lists every TCP/UDP port that has a program listening on it. Identify at least one service and the program behind it (for example, `sshd` listening on port 22 is what let you SSH in during Part A). In your writeup, name two listening services and say, in plain language, what each is *for*.

2. **Runtime vs. persistent — see the difference directly.** Add a temporary route at the command line, confirm it exists, then understand that it will not survive a reboot:

   ```
   sudo ip route add 198.51.100.0/24 via [your-default-gateway]
   ip route | grep 198.51.100
   sudo ip route del 198.51.100.0/24 via [your-default-gateway]
   ```

   That `ip route add` is a **runtime** change — gone on reboot. Contrast it with the `/etc/hosts` edit you made in Part B, which is **persistent** because it lives in a config file. On Ubuntu, persistent interface configuration lives in **netplan** (`/etc/netplan/*.yaml`); look at that file (`sudo cat /etc/netplan/*.yaml` — needs sudo because netplan files can contain credentials, so they're mode `0600 root:root` by default) but do **not** edit it in this lab — a bad netplan change can cut off your VM's network.

> **Why this matters:** "It worked until I rebooted" is one of the most common networking tickets. It almost always means someone made a runtime change and never made it persistent. Knowing which changes survive a reboot — and where persistent config lives — is exactly the judgment this distinction builds.

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
5. Two services listening on your VM (from `sudo ss -tulpn`) and what each is for:
6. In your own words: the difference between a RUNTIME network change (like
   `ip route add`) and a PERSISTENT one (like editing /etc/hosts or netplan),
   and why "it worked until I rebooted" usually points to a runtime change:
```

---

## Submission Requirement

1. A **60–90 second screen recording** made per the [Screen Recording Guide](../../docs/05-screen-recording-guide.md) (Alamo Zoom by default; one specific backup per OS if Zoom is broken) (webcam off; narration optional), showing in one continuous take: `hostname`, `multipass list` (or `ip a`), and `bash check-net.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio.
2. Your completed **troubleshooting writeup** — this is where you explain the difference between the IP test and the name test, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** AI is fine for understanding `ip route` output or `/etc/hosts` syntax, but the playbook and your evidence must come from your own two VMs. Note anything you asked AI and what you verified. An AI cannot know your `fileserver`'s real IP — only your `multipass list` can.

---

## Finish / Clean Up

To free resources between sessions (keeps both VMs and their state):

```
multipass stop labvm fileserver
```

You can keep `fileserver` for later networking labs, or remove it when the course's networking modules are done. Use `delete --purge` so this only affects `fileserver` (a plain `multipass purge` is global and would wipe any other deleted instances):

```
multipass delete --purge fileserver
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
- [ ] Listed listening services with `sudo ss -tulpn` and identified two
- [ ] Saw a runtime route change vs. the persistent `/etc/hosts` edit, and looked at netplan
- [ ] Ran `check-net.sh` and all checks PASS
- [ ] Wrote the troubleshooting writeup
- [ ] Recorded the Zoom screen recording (webcam off)
- [ ] Submitted screencast + writeup

---

### On RHEL this would be…

`ip a`, `ip route`, `ping`, `getent`, and `/etc/hosts` are identical on Red Hat–family systems. The differences appear when you make **persistent interface** changes: Ubuntu uses **netplan** (`/etc/netplan/*.yaml`), while RHEL/Rocky use **NetworkManager** (`nmcli`) with config in `/etc/NetworkManager/`. The concept you practiced here — local name resolution via `/etc/hosts`, checked before DNS, and the discipline of separating connectivity from name resolution — is the same on every Linux system and on the Linux+ exam.
