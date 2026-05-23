# Module 9 Lab: Networking Fundamentals (Multipass)

**Hands-on lab — runs on your own `labvm`. Your first real look at how a Linux machine lives on a network.**

## Lab Overview

Before you can configure or troubleshoot networking, you have to be able to answer three basic questions about any machine: *What is my address? How does my traffic get out? Can I actually reach things?* In this lab you investigate your own VM to answer all three, and you learn to test connectivity in layers so that when something breaks later, you know exactly where to look. This is the foundation the advanced networking lab (Module 13) builds on.

|  |  |
| --- | --- |
| **Estimated Time** | 30–45 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-netfund.sh`, `check-netfund.sh` (in this folder of your cloned repo) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-netfund.sh` passing, plus your completed network report |

## Outcomes

By the end of this lab you will be able to:

- Explain the role of networking on a Linux system in plain terms.
- Identify how a machine is addressed on a network: its **interface**, **IP address**, and **hostname**.
- Find the **default gateway** and explain how traffic leaves the machine.
- Test connectivity in **layers** (local network → internet by IP → name resolution) to localize a problem.
- Name common causes of connectivity issues and describe how you'd check each.

---

## Start the Lab Environment

If your VM is not running, start it and transfer the scripts (from your computer's terminal):

```
multipass start labvm
multipass transfer labs/module-09-networking-fundamentals/setup-netfund.sh labvm:/home/ubuntu/
multipass transfer labs/module-09-networking-fundamentals/check-netfund.sh labvm:/home/ubuntu/
multipass shell labvm
```

Inside the VM, create your report template:

```
bash setup-netfund.sh
```

This drops `~/module9-network-report.txt`. Fill it in as you work through the parts below.

---

## Part A — Identify this machine on the network

Every device on a network needs a unique address. Find yours:

```
ip a
hostname
hostname -I
```

In `ip a`, look past the `lo` (loopback) interface for your real interface (often `ens3`, `enp0s2`, or similar) and the `inet` line — that is your **IPv4 address**. Record your interface name and IP in the report.

> **Why a unique address?** Two devices with the same address on the same network is like two houses with the same street address — the mail (packets) can't be delivered reliably.

## Part B — How traffic leaves this machine

```
ip route
```

Find the line that starts with `default`. The address after `via` is your **default gateway** — the router your machine sends traffic to when the destination isn't on your local network. Record it, and write one sentence explaining what the default route does.

## Part C — Test connectivity in layers

This is the most important habit in the lab. Test from closest to farthest, so a failure tells you *where* the problem is:

```
ping -c 3 <your-default-gateway>     # 1. local network reachable?
ping -c 3 1.1.1.1                     # 2. internet reachable by IP?
ping -c 3 ubuntu.com                  # 3. name resolution working?
```

Paste one result line from each into your report. Think about what each *rules out*:

- If (1) fails, the problem is local (interface, cable/virtual network, gateway).
- If (1) works but (2) fails, you can reach your LAN but not the internet (routing/gateway/upstream).
- If (2) works but (3) fails, the network is fine — it's **DNS / name resolution** that's broken.

## Part D — Reasoning (write this up)

In the report, answer:

1. If `ping 1.1.1.1` succeeds but `ping ubuntu.com` fails, what is broken and what is fine?
2. Name two common causes of "I can't reach the network" and how you'd check each.

---

## Evaluation (Required)

Inside the VM:

```
bash check-netfund.sh
```

Fix any FAILs and re-run until everything passes.

---

## Submission Requirement

1. A **60–90 second screen recording** made per the [Screen Recording Guide](../../docs/05-screen-recording-guide.md) (Alamo Zoom by default; one specific backup per OS if Zoom is broken) (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `bash check-netfund.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio.
2. Your completed **network report** (`~/module9-network-report.txt`) — this is where your reasoning lives, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** AI can explain what `ip route` output means, but the interface name, IP, and gateway in your report must be *your VM's* — an AI can't see them. Note anything you asked AI and what you verified.

---

## Finish / Clean Up

```
multipass stop labvm
```

Do not delete `labvm` — later labs reuse it.

---

## Final Checklist

- [ ] Ran `setup-netfund.sh` to create the report template
- [ ] Recorded your interface name and IP address (Part A)
- [ ] Identified your default gateway and explained the default route (Part B)
- [ ] Ran all three layered connectivity tests and recorded the results (Part C)
- [ ] Answered both Part D reasoning questions
- [ ] Ran `check-netfund.sh` and all checks PASS
- [ ] Recorded the Zoom screen recording (webcam off)
- [ ] Submitted recording + completed report

---

### On RHEL this would be…

`ip a`, `ip route`, `ping`, `hostname`, and `getent` are identical on Red Hat–family systems (RHEL, Rocky, Fedora) — these are core Linux tools. The differences appear only when you make *persistent* changes, which you'll meet in Module 13: Ubuntu uses **netplan**, while RHEL/Rocky use **NetworkManager** (`nmcli`). The layered-troubleshooting habit you built here — test local, then internet-by-IP, then by-name — is universal and is exactly what the Linux+ exam expects.
