# Module 12 Lab: System Initialization & Services (Multipass)

**Hands-on lab — runs on your own `labvm`. Replaces the former written assignment "System Initialization, Services, and Localization."**

## Lab Overview

Every Linux server you will ever administer is, underneath, a carefully ordered startup sequence and a set of background services that `systemd` keeps running. In this lab you step into that machinery: you inspect how your VM boots and what took the longest, you manage a service that is already running, and then — the centerpiece — you **author your own `systemd` service** that runs a small health-check script and reports to the system journal. Finally you set the machine's localization (timezone and locale) the way a real admin would when standing up a box for a specific region. This is build-and-manage work, the daily reality of keeping Linux systems alive — not diagnosing something already broken.

|  |  |
| --- | --- |
| **Estimated Time** | 50–75 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-systemd.sh`, `check-systemd.sh` (pulled into `labvm` from the public repo with curl — see Setup Guide) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-systemd.sh` passing, plus your written report `~/module12-systemd-report.txt` |
| **Key Files** | `/etc/systemd/system/labhealth.service` (you create it), `/usr/local/bin/labhealth.sh` (setup drops it), `~/module12-systemd-report.txt` |

## Outcomes

By the end of this lab you will be able to:

- Explain the Linux init/boot process and the role of `systemd` as the modern init framework.
- Inspect running units and interpret boot performance with `systemd-analyze`, `blame`, and `critical-chain`.
- Explain the default target — `multi-user.target` vs `graphical.target` — and why production servers run headless (no X Windows).
- Start, stop, and inspect an existing service, and read its logs with `journalctl -u`.
- **Create and enable your own `systemd` service** from a unit file, and verify it ran via the journal.
- Inspect and change localization (`timedatectl`, `localectl`) and explain how locale and timezone change program behavior.

---

## Start the Lab Environment

> **Snapshot first.** This lab adds a service and changes the system timezone. Take a *named* restore point before you begin so you can roll back cleanly. Multipass won't snapshot a running instance, so stop it first, then start it again:
>
> ```
> multipass stop labvm
> multipass snapshot --name pre-mod12 labvm
> multipass start labvm
> ```

From your computer's terminal, start `labvm` and shell into it:

```
multipass start labvm
multipass shell labvm
```

Then **inside `labvm`**, pull this lab's two scripts straight from the public course repo, eyeball them, and prepare the lab:

```
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-12-systemd-services/setup-systemd.sh
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-12-systemd-services/check-systemd.sh
sudo bash setup-systemd.sh
```

The setup script does **not** break anything. It drops a tiny, safe health-check script at `/usr/local/bin/labhealth.sh` (the thing your service will run) and removes any leftover `labhealth.service` from a previous attempt so you start from a clean slate. It is fully re-runnable.

---

## Instructions

Work through the five parts in order. Capture your evidence as you go — Part 6 asks you to assemble it all into one report file, and the check looks for specific outputs in it. Keep a terminal open and copy outputs as you produce them.

### Part 1 — Inspect the init system and the default target

`systemd` is the first process the kernel starts (PID 1) and the thing that brings everything else up. Look at what it is running right now:

```
systemctl                           # all loaded units (press q to quit)
systemctl list-units --type=service # just the services, with their state
systemctl get-default               # the target the system boots into
```

> **Why this matters.** A server admin picks **`multi-user.target`** (text-only, headless) over `graphical.target` to save RAM, reduce **attack surface** (fewer services = less to attack), and skip a desktop nobody is sitting in front of. Both values appear on Multipass Ubuntu 22.04 — the image is technically `graphical.target` but no GUI ever runs, because there's no display manager to launch one. Either is fine here. Note in your report which target your VM shows and why a server admin keeps it headless.

### Part 2 — Examine boot performance

Ordered startup is the whole point of an init system: some services must come up before others (network before a web server, for example). See how long your last boot took and what gated it:

```
systemd-analyze                 # total firmware/loader/kernel/userspace time
systemd-analyze blame           # each unit, slowest first
systemd-analyze critical-chain  # the dependency chain that actually gated boot
```

> **Why this matters.** `blame` shows which units took the longest *individually*; `critical-chain` shows the units that were actually *on the critical path* — the chain that had to finish in order before boot completed. A unit can be slow but not on the critical path (nothing waited for it). In your report, name the single slowest unit from `blame` **with its time**, and explain in one or two sentences why ordered startup matters — refer to your own numbers.

### Part 3 — Manage an existing service

Pick a service that is already present on the VM — **`cron`** (the scheduled-task daemon) or **`ssh`** both work. Inspect it, restart it, and read its logs:

```
systemctl status cron           # is it active? enabled? what's its PID?
sudo systemctl restart cron     # stop then start it
systemctl is-active cron        # confirm it came back
journalctl -u cron --no-pager | tail -n 20   # the service's own log lines
```

> **Why this matters.** A service (daemon) is a process `systemd` supervises in the background — it has no controlling terminal, starts on boot, and is restarted by `systemd` if it dies. That is different from a program you launch and watch in your shell. `journalctl -u <service>` is how you read *that one service's* logs, which is the first thing you do when a service misbehaves. Record in your report which service you chose and confirm it was `active` again after the restart.

### Part 4 — Create your own service (the centerpiece)

The setup script left a script at `/usr/local/bin/labhealth.sh` that prints a few health facts and exits. Right now nothing runs it. You will write the `systemd` **unit file** that turns it into a managed service.

**4a.** Create the unit file at `/etc/systemd/system/labhealth.service`. Use `sudo` because that directory is root-owned (`sudo nano /etc/systemd/system/labhealth.service`). It should look like this — read each line and understand it before you save:

```ini
[Unit]
Description=Lab health-check service (ITSC-1316 Module 12)
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/labhealth.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

> **Read the unit, don't just paste it.** `Type=oneshot` says "this runs once and exits" — correct for a health check that does its job and stops, rather than a daemon that stays resident. `RemainAfterExit=yes` tells `systemd` to *consider the unit active* after the script exits 0, so `systemctl status` shows a clean "active (exited)" instead of looking dead. `ExecStart=` is the command to run. `WantedBy=multi-user.target` is what makes `enable` hook it into normal (non-graphical) boot.

**4b.** Tell `systemd` about the new file, then enable and start it in one step:

```
sudo systemctl daemon-reload
sudo systemctl enable --now labhealth.service
```

> `daemon-reload` is required any time you add or edit a unit file — `systemd` caches units and won't see your file until you reload. `enable --now` both enables it (so it starts at boot) **and** starts it right now.

**4c.** Verify it is active and enabled, and read what it logged:

```
systemctl status labhealth.service          # expect: enabled; active (exited)
systemctl is-enabled labhealth.service       # expect: enabled
journalctl -u labhealth.service --no-pager   # your script's output lines
```

> You should see the line `labhealth: health check OK` in the journal — that is your script's own stdout, captured by `systemd` because services log to the journal automatically. If `status` shows `failed` instead, run `journalctl -u labhealth.service` to see why, fix the unit file, then `sudo systemctl daemon-reload && sudo systemctl restart labhealth.service`.

### Part 5 — Localization

Localization controls how the system presents time, language, sorting, currency, and the keyboard. Inspect the current settings, then set the timezone to the course's region.

```
timedatectl                       # current time, timezone, NTP sync
localectl                         # system locale (LANG) and keyboard layout
```

Now set the timezone to **America/Chicago** (Central Time — the region this course runs in) and confirm it. (`set-timezone` is idempotent — if your VM is already on `America/Chicago` from a prior lab or a previous run, re-running the command is a harmless no-op, not an error.)

```
sudo timedatectl set-timezone America/Chicago
timedatectl                       # confirm "Time zone: America/Chicago"
```

> **Why this matters.**
>
> **Timezone** changes what *every* program thinks "now" is — log timestamps, cron schedules, `date` output. A wrong timezone makes your logs lie about when things happened.
>
> **Locale** (`LANG`) changes how programs sort text, format numbers and dates, and which language error messages appear in. A wrong locale can break scripts that parse dates (German date format ≠ US date format) and confuse users who expect their own conventions.
>
> You do **not** need to change the locale here — just inspect it with `localectl`. In your report, explain one concrete way a wrong timezone *or* locale would mislead a user or break a script.

### Part 6 — Assemble your evidence report

Create `~/module12-systemd-report.txt` containing your captured outputs **and** your written explanations. The check script looks for your VM's hostname and specific command outputs in this file. A quick way to seed it with the command outputs (then open it and add your written answers):

```
{
  echo "=== Module 12 Evidence — host: $(hostname), user: $(whoami) ==="
  echo "--- systemctl get-default ---";        systemctl get-default
  echo "--- systemd-analyze ---";              systemd-analyze
  echo "--- systemd-analyze blame (top 10) ---"; systemd-analyze blame | head -n 10
  echo "--- labhealth status ---";             systemctl status labhealth.service --no-pager
  echo "--- labhealth journal ---";            journalctl -u labhealth.service --no-pager
  echo "--- timedatectl ---";                  timedatectl
  echo "--- localectl ---";                    localectl
} > ~/module12-systemd-report.txt
```

Then open the file (`nano ~/module12-systemd-report.txt`) and add your **written answers** (the section below). The check requires real prose, not just pasted output.

---

## Evaluation (Required)

Grade your own work inside the VM. Some checks read root-only `systemd`/journal state, so run it with `sudo` for accurate results:

```
sudo bash check-systemd.sh
```

It prints PASS or FAIL for each requirement. Correct any FAILs and run it again until everything passes — exactly what a real administrator does after a change.

---

## Written Component (submit this)

Add these answers to the bottom of `~/module12-systemd-report.txt`. Answer in your own words; reference your *own* numbers and outputs where asked (this is what an AI cannot fake — it has not seen your VM). A few sentences per item.

```
WRITTEN COMPONENT — Module 12
Name:
VM hostname (run `hostname`):

A. Boot process (your own words)
   In plain English, describe what happens between powering on the VM and
   reaching a usable login prompt. Where does systemd (PID 1) fit in?

B. Why ordered startup matters
   Using your own `systemd-analyze blame` / `critical-chain` output, name the
   slowest unit and its time, and explain why services must start in a
   controlled order. What could go wrong if a service started before something
   it depends on?

C. Your service
   Explain what your labhealth.service does, what `Type=oneshot` and
   `RemainAfterExit=yes` mean, and how you confirmed from the journal that it
   actually ran (quote the line you saw).

D. Graphical vs text environments
   Your VM has no graphical desktop installed (regardless of whether
   `systemctl get-default` reports multi-user.target or graphical.target —
   both are valid on a headless cloud image because no display manager is
   running). Give one advantage and one disadvantage of running a server
   *without* a graphical desktop, and say why most production servers run
   headless.

E. Localization
   You set the timezone to America/Chicago. Describe one concrete way an
   incorrect timezone OR locale (LANG) would mislead a user or break a script.
```

---

## Submission Requirement

Submit **two things** to Canvas:

1. A **60–90 second screen recording** made per the [Screen Recording Guide](../../docs/05-screen-recording-guide.md) (Alamo Zoom by default; one specific backup per OS if Zoom is broken) (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `bash check-systemd.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio.
2. Your completed **written component** (the `~/module12-systemd-report.txt` file, or its contents pasted into a document). This is where your reasoning lives, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** You may use an AI assistant to explain `systemd` concepts, unit-file directives, or `journalctl` flags. If you do, include a one-line note of what you asked and what you verified yourself. An AI can describe what a *typical* boot looks like, but only your VM's real `systemd-analyze` numbers, your service's actual journal output, and your own hostname can fill in this report — those are the parts that prove the work is yours.

---

## Finish / Clean Up

You can leave the service in place — it is harmless. To free resources between sessions without losing your work:

```
multipass stop labvm
```

If you would rather return to a pristine system for later labs, restore the snapshot you took at the start (restore needs the VM stopped, so `exit` the VM first, then from your computer's terminal):

```
multipass stop labvm
multipass restore labvm.pre-mod12
multipass start labvm
```

Do **not** delete `labvm` — later labs reuse it.

---

## Final Checklist

- [ ] Took a snapshot before starting
- [ ] Ran `setup-systemd.sh`
- [ ] Inspected units and the default target (`systemctl get-default`)
- [ ] Examined boot performance (`systemd-analyze`, `blame`, `critical-chain`)
- [ ] Managed an existing service (status / restart / `journalctl -u`)
- [ ] Created `/etc/systemd/system/labhealth.service` and ran `daemon-reload`
- [ ] Enabled and started it (`enable --now`); confirmed `enabled` and `active`
- [ ] Confirmed from the journal that the service ran (`labhealth: health check OK`)
- [ ] Set the timezone to `America/Chicago` and inspected `localectl`
- [ ] Built `~/module12-systemd-report.txt` with outputs + written answers (incl. your hostname)
- [ ] Ran `sudo bash check-systemd.sh` and all checks PASS
- [ ] Recorded the Zoom screen recording (webcam off; hostname + whoami + passing check)
- [ ] Submitted screencast + written component to Canvas

---

### On RHEL this would be…

`systemd` is the init system on Red Hat–family systems (RHEL, Rocky, Fedora) just as it is on Ubuntu, so **every command in this lab — `systemctl`, `systemd-analyze`, `journalctl`, `timedatectl`, `localectl`, and the unit-file syntax — is identical**. The differences are around the edges: RHEL ships `firewalld`/`NetworkManager` rather than Ubuntu's `ufw`/`netplan`, uses `dnf` instead of `apt`, and adds **SELinux**, which assigns a security context to service binaries — a service can fail to start on RHEL even with a correct unit file if its executable has the wrong SELinux label (you would check with `ls -Z` and `ausearch`/`sealert`). The init concepts — targets, units, ordered dependencies, the journal, localization — transfer directly to RHCSA-level certification material.
