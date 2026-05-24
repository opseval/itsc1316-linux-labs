# Module 10 Lab: Processes and System Resources (Multipass)

**Hands-on lab — runs on your own `labvm`. Replaces the processes/resources half of the former Red Hat Academy Lab 7.07 (Linux Networking and System Resources).**

## Lab Overview

When a server "feels slow," the cause is almost always a **process** doing too much — eating CPU, exhausting memory, or just stuck in a loop. The single most valuable troubleshooting skill an entry-level Linux admin has is the ability to look at a running system, *see* what every process is doing, identify the one that's misbehaving, and stop it safely. In this lab you'll inspect the process list and the process tree, monitor live CPU/memory/load with the standard tools, and then respond to a real incident: the setup script plants a **runaway process that pegs a CPU**, and your job is to find it from its resource usage, identify its PID, and kill it. You'll also practice controlling process **priority** with `nice`/`renice`, and connect what you've learned to how Linux manages long-running **services**.

|  |  |
| --- | --- |
| **Estimated Time** | 45–65 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-processes.sh`, `check-processes.sh` (pulled into `labvm` from the public repo with curl — see Setup Guide) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-processes.sh` passing, plus your written component (below) |
| **Key Items** | Runaway process `labhog-runaway`; evidence file `~/module10-process-report.txt` |

## Outcomes

By the end of this lab you will be able to:

- Explain what a **process** is and how Linux tracks each one (PID, PPID, owner).
- List and interpret processes with `ps aux`, `ps -ef`, and the tree view `pstree`.
- Monitor live resource use with `top`, `free -h`, and `uptime`, and interpret **CPU%**, **MEM%**, and **load average**.
- Diagnose a resource-contention problem: find a runaway process by its CPU usage and stop it.
- Send signals to processes with `kill`, and explain the difference between **SIGTERM** and **SIGKILL**.
- Adjust process priority with `nice` and `renice`, and explain what niceness does.
- Relate processes to **services** (a service is a managed background process under `systemctl`).

---

## Start the Lab Environment

> **Snapshot first.** This lab launches a CPU-burning process for you to find and stop. It's harmless and dies when the VM stops, but a snapshot lets you reset cleanly if you want to practise the hunt again. From your computer's terminal — Multipass won't snapshot a running instance, so stop it first:
>
> ```
> multipass stop labvm
> multipass snapshot --name pre-mod10 labvm
> multipass start labvm
> ```

From your computer's terminal, start `labvm` and shell into it:

```
multipass start labvm
multipass shell labvm
```

Then **inside `labvm`**, pull this lab's two scripts straight from the public course repo, eyeball them, and plant the scenario:

```
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-10-processes-and-resources/setup-processes.sh
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-10-processes-and-resources/check-processes.sh
sudo bash setup-processes.sh
```

This launches a **runaway process** that burns one CPU core, and drops a starter evidence report at `~/module10-process-report.txt`. You are intentionally **not** told the process's PID — finding it is the lab.

> Roll back any time with `multipass stop labvm && multipass restore labvm.pre-mod10 && multipass start labvm`.

---

## Build your evidence report as you go

You'll paste real output into `~/module10-process-report.txt`. Append directly, e.g.:

```
echo "Hostname: $(hostname)" >> ~/module10-process-report.txt
free -h >> ~/module10-process-report.txt
```

The check looks for **your** hostname and **your** investigation notes in that file, so an AI that can't see your VM can't fill it in. Start by recording your hostname now.

---

## Part 1 — See what's running (processes, PIDs, owners)

Every running program is a **process**, and the kernel gives each one a numeric **PID** (process ID). Each process also records the PID of the process that started it — its **PPID** (parent PID) — and the user that **owns** it. List them three ways:

```
ps aux              # every process: USER, PID, %CPU, %MEM, COMMAND
ps -ef              # same idea, different columns: UID, PID, PPID, CMD
pstree              # the parent/child tree — who launched whom
```

Pick any one process from the list and note its **PID**, **PPID**, and **owner**. Capture a snapshot of the process list into your report:

```
echo "=== ps aux (top of list) ===" >> ~/module10-process-report.txt
ps aux | head >> ~/module10-process-report.txt
```

> **Why this matters.** Every troubleshooting session starts here. If you can read `ps aux`, you can see exactly what the machine is doing and who is responsible for it. PPID matters because killing a parent often cleans up its children; owner matters because it tells you whose process — and whether you need `sudo`.

## Part 2 — Monitor live resource use

`ps` is a snapshot. To watch resources **live**, use `top` (press `q` to quit). While it's running, read the header (load average and CPU/memory totals) and the per-process **%CPU** and **%MEM** columns. Then capture two quick non-interactive snapshots:

```
top                 # interactive: watch %CPU sort; press 'q' to quit
free -h             # memory: total / used / free, human-readable
uptime              # load average over 1, 5, and 15 minutes
```

Record memory and load into your report:

```
echo "=== free -h ===" >> ~/module10-process-report.txt
free -h >> ~/module10-process-report.txt
echo "=== uptime (load average) ===" >> ~/module10-process-report.txt
uptime >> ~/module10-process-report.txt
```

> **Interpreting the numbers.** **%CPU** is how much of a core a process is using (100% = one full core). **%MEM** is the share of RAM it holds. **Load average** is roughly the number of processes wanting the CPU, averaged over 1/5/15 minutes — on a 1-CPU VM, a sustained load above ~1.0 means something is saturating the processor. A runaway loop shows up as one process glued to ~100% CPU and a load average climbing toward 1.

## Part 3 — Find and stop the runaway process (the incident)

Users report the VM is sluggish. **Investigate before you act.** Run `top` and watch the top of the list sorted by CPU — one process pegged near 100% CPU is the runaway. Confirm it and get its **PID** several ways:

```
top                              # the hog sits at the top by %CPU
ps aux | grep labhog-runaway     # shows the owner and PID
pgrep -af labhog-runaway         # PID + full command line
```

> In `top`'s default view the COMMAND column shows `bash`, not `labhog-runaway`, because the runaway is a *shell script* and `top` shows its interpreter. Press `c` inside `top` to toggle the full command line and you'll see `bash /usr/local/bin/labhog-runaway`. `ps aux` and `pgrep -af` show the full command line by default — that's why those flush out the script's name even though `top` looked uninformative at first.

Record what you found *before* killing it:

```
echo "=== Runaway process I found ===" >> ~/module10-process-report.txt
pgrep -af labhog-runaway >> ~/module10-process-report.txt
```

Now stop it. First try a polite **SIGTERM** (the default signal — asks the process to shut down cleanly); fall back to **SIGKILL** (`-9`) only if it ignores you:

```
sudo kill [PID]          # sends SIGTERM (signal 15) — the polite request
# if it's still there after a moment:
sudo kill -9 [PID]       # sends SIGKILL (signal 9) — forced, non-negotiable
```

(Because this hog is a tight `while true` loop, SIGTERM stops it fine — but you should understand both.) Verify it's gone:

```
pgrep -af labhog-runaway     # no output = it's stopped
```

> **`pgrep -f` / `pkill -f` gotcha — skip unless you're driving labvm from outside.**
>
> If you ran the `pgrep`/`pkill` above by typing them inside `multipass shell labvm`, this doesn't affect you. It only bites when you drive the VM through a wrapping shell — `multipass exec labvm -- bash -c '...'`, `ssh -T`, or an automation script.
>
> **The problem:** the search string (`labhog-runaway`) appears in the wrapping shell's own command line, so `pgrep -af` matches the wrapper itself and reports a false hit. Worse, `pkill -f` may *signal the wrapping shell*, killing your `multipass exec` and making it return non-zero — even though the real target was killed correctly.
>
> **The fix:** use `pgrep -x labhog-runaway` (exact match against the executable name), or `ps -eo args | grep "/usr/local/bin/labhog-runaway" | grep -v grep`. If `pkill` returns non-zero, verify the kill worked with a separate `pgrep` rather than trusting the exit code.

In your report, fill in the **process name**, its **PID**, and the **command you used to find it**.

> **SIGTERM vs SIGKILL.** SIGTERM (15) asks a process to terminate; the process can run cleanup first (flush files, close connections) — this is the right default. SIGKILL (9) cannot be caught or ignored; the kernel kills the process instantly, so it can leave temp files or corrupt data behind. Always try SIGTERM first; reach for SIGKILL only when a process is hung and ignoring it. You'll explain this below.

## Part 4 — Control priority with nice and renice

Not every busy process should be killed — sometimes you just want it to **yield** to more important work. That's what **niceness** does: a higher niceness (up to +19) means "be nicer to others, take CPU only when it's idle"; a lower/negative value means "give me priority." Start a harmless background task with a high niceness, then change it:

```
nice -n 10 sleep 300 &        # start a process with niceness +10
jobs -l                       # note its PID (or use: pgrep -af 'sleep 300')
ps -o pid,ni,cmd -p [PID]     # confirm the NI (niceness) column shows 10
sudo renice -n 15 -p [PID]    # raise its niceness to +15
```

Capture the nice/renice evidence:

```
echo "=== nice / renice ===" >> ~/module10-process-report.txt
ps -o pid,ni,cmd -p [PID] >> ~/module10-process-report.txt
sudo renice -n 15 -p [PID] >> ~/module10-process-report.txt
```

(`renice` prints a line like `old priority 10, new priority 15`.) You can let the `sleep` finish on its own or `kill` it when done.

> **Why this matters.** On a busy server you often have a backup job or a report generator that's important but not urgent. Running it `nice` keeps it from starving the database the customers are hitting. Niceness is the polite way to manage contention without killing anything.

## Part 5 — From processes to services

A **service** (or daemon) is just a long-running background process that the system manages for you — started at boot, restarted if it crashes, and controlled through **systemd**. Take a quick look:

```
systemctl list-units --type=service --state=running   # running services
systemctl status ssh                                   # one service's process + PID
```

Notice that `systemctl status` shows you the service's **main PID** — the same kind of PID you've been working with all lab. A service is a process with a manager wrapped around it. (You'll go deep on `systemctl` in Module 12; this is just the connection.)

> **Why this matters.** When a service misbehaves, you diagnose it with the exact tools from this lab (`ps`, `top`, its PID), then manage it with `systemctl` instead of raw `kill`, so the system doesn't just restart it on you.

---

## Evaluation (Required)

Grade your own work by running the check script inside the VM:

```
bash check-processes.sh
```

It prints PASS or FAIL for each requirement. Correct any FAILs and run it again until everything passes.

---

## Written Component (submit this)

Answer all three in your own words. Aim for 3–5 sentences each — this is where your reasoning lives, so the recording does not need narration.

```
MODULE 10 WRITTEN COMPONENT
Name:
VM hostname (run `hostname`):

1. What is a process?
   - In your own words, what is a process, and what do the PID, PPID, and
     owner tell an administrator? Why is the owner important when deciding how
     to stop a process?

2. SIGTERM vs SIGKILL
   - Explain the difference between SIGTERM (kill) and SIGKILL (kill -9).
     When should you use each, and what risk comes with reaching for -9 too
     soon?

3. How you diagnosed the resource hog
   - Walk through how you found the runaway process: which command(s) you ran,
     what evidence pointed to it (e.g. %CPU near 100%, climbing load average),
     its name and PID, and how you stopped it. This should match the notes in
     your report.
```

---

## Submission Requirement

Submit **two things** to Canvas:

1. A **60–90 second screen recording** made per the [Screen Recording Guide](../../docs/05-screen-recording-guide.md) (Alamo Zoom by default; one specific backup per OS if Zoom is broken) (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `bash check-processes.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio.
2. Your completed **written component** (the three questions above). This is where you explain your reasoning, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** You may ask an AI assistant to explain `ps`/`top` columns, signals, or niceness — include a one-line note of what you asked and what you verified yourself. An AI cannot see your VM: only you can watch *your* `top`, read *your* load average, find the real PID of the hog on *your* machine, and capture it into the report. The screencast and the report built from your real output are how you show the work is yours.

---

## Finish / Clean Up

If you killed the runaway process, the system is already healthy. To free up resources between sessions without losing your work:

```
multipass stop labvm
```

Do **not** delete `labvm` — later labs reuse it.

---

## Final Checklist

- [ ] Took a snapshot before starting
- [ ] Ran `setup-processes.sh` to plant the scenario
- [ ] Listed processes with `ps aux`, `ps -ef`, and `pstree`; identified a PID/PPID/owner
- [ ] Monitored resources with `top`, `free -h`, and `uptime`
- [ ] Found the runaway `labhog-runaway` process by %CPU and recorded its PID
- [ ] Stopped it with `kill` (understood SIGTERM vs SIGKILL) and verified it's gone
- [ ] Practised `nice` and `renice` and captured the output
- [ ] Looked at a running service with `systemctl status` (process ↔ service link)
- [ ] Built `~/module10-process-report.txt` with hostname + how-I-found-it + ps/free/uptime + nice/renice
- [ ] Ran `check-processes.sh` and all checks PASS
- [ ] Recorded the Zoom screen recording (webcam off; hostname + whoami + passing check)
- [ ] Wrote the three written-component answers
- [ ] Submitted screencast + written component to Canvas

---

### On RHEL this would be…

Everything in this lab is **identical** on Red Hat–family systems (RHEL, Rocky, Fedora): `ps`, `top`, `pstree`, `free`, `uptime`, `kill`, `nice`, `renice`, and the signals SIGTERM/SIGKILL are all core Linux and behave the same way. `systemctl`/`journalctl` are the same too — RHEL and Ubuntu both use **systemd**. The only thing you might add on a RHEL server is the newer interactive monitor **`top`** alternative many admins install (`htop`), and on minimal RHEL installs `pstree` may need installing (`sudo dnf install psmisc`). The *concepts* — PID/PPID/owner, CPU vs. memory vs. load, evidence-based diagnosis, polite-then-forceful termination, niceness — transfer to every Linux distribution and to the certification exams unchanged.
