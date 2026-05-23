# Setting Up Your Lab Environment with Multipass

**Do this once, in the first week. Every hands-on lab in this course runs on the VM you create here.**

In this course you administer a *real* Linux system — your own — instead of a browser-based sandbox. You will use **Canonical Multipass**, a free tool that spins up Ubuntu virtual machines on your own computer in about a minute. This guide gets you from zero to a working VM and walks you through the workflow you will repeat in every lab.

> **Why your own VM?** A real administrator does not get a reset button. When you break something on your VM, you fix it — and that is where the actual learning happens. Every lab is designed so that an AI assistant can tell you *what* a command does, but only your own VM can tell you whether it *worked*. That is the whole point.

---

## Part 1 — Install Multipass

Multipass runs on macOS, Windows, and Linux. Pick your platform.

### macOS

1. Install [Homebrew](https://brew.sh) if you do not have it, then run:

   ```
   brew install --cask multipass
   ```

   Or download the installer directly from <https://multipass.run/install>.

### Windows

1. Download the installer from <https://multipass.run/install>.
2. Run it. Multipass uses Hyper-V (Windows Pro/Enterprise/Education) or VirtualBox (Windows Home). The installer will guide you.
3. Reboot if prompted.

### Linux

```
sudo snap install multipass
```

### Verify the install

Open a terminal (Terminal on macOS, PowerShell on Windows, your shell on Linux) and run:

```
multipass version
```

You should see a version number. If you get "command not found," the install did not complete — post a screenshot in the Q&A board.

---

## Part 2 — Launch Your Course VM

You will create one long-lived VM named **labvm** that you keep for the whole semester.

```
multipass launch 22.04 --name labvm --cpus 2 --memory 2G --disk 10G
```

This downloads Ubuntu 22.04 LTS the first time (a few minutes) and boots it. When it finishes, confirm it is running:

```
multipass list
```

You should see `labvm` with a state of `Running` and an IP address.

> **Low on resources?** If your laptop struggles with 2 GB RAM, drop to `--memory 1G`. If your machine genuinely cannot run a VM, see **Part 6 — Cloud Fallback** below; you will not be penalized for hardware you do not have.

---

## Part 3 — The Workflow You Will Repeat Every Lab

Every lab follows the same five steps. Learn them once here.

### Step 1 — Get the lab's scripts

Each lab lives in its own folder under `labs/` in your cloned repo (see [GitHub Primer](03-github-primer.md) if you haven't cloned yet). The two files you'll work with are `setup-*.sh` (builds the lab scenario) and `check-*.sh` (grades your work). No downloads needed — they're already on your computer once you've cloned.

### Step 2 — Transfer the scripts into your VM

`multipass transfer` copies files from your computer into the VM. From your computer's terminal, **at the root of your cloned repo** (so the `labs/...` paths resolve), run:

```
multipass transfer labs/<lab-folder>/setup-<name>.sh labvm:/home/ubuntu/
multipass transfer labs/<lab-folder>/check-<name>.sh labvm:/home/ubuntu/
```

For example, for the Module 6 lab:

```
multipass transfer labs/module-06-users-and-permissions/setup-users.sh labvm:/home/ubuntu/
multipass transfer labs/module-06-users-and-permissions/check-users.sh labvm:/home/ubuntu/
```

On Windows, the same commands work in PowerShell (forward slashes are fine in arguments to `multipass`).

### Step 3 — Open a shell inside the VM

```
multipass shell labvm
```

Your prompt changes to `ubuntu@labvm:~$`. You are now *inside* the Linux system. Run the setup script to build the scenario (the lab setup scripts always need root):

```
sudo bash setup-<name>.sh
```

### Step 4 — Do the lab

Follow the lab instructions. Work entirely inside the VM shell.

### Step 5 — Grade yourself and record proof

When you think you are done, run the check script:

```
bash check-<name>.sh
```

It prints a PASS or FAIL for each requirement. Fix any FAILs and run it again until everything passes — exactly like a real admin re-testing after a change.

Then record a short screencast (see Part 4) and submit it with your check output.

---

## Part 4 — Recording Your Screencast with Zoom

Every lab asks for a short **screen recording (about 60–90 seconds)**. This is your proof that *you* did the work on *your* system — something a shared screenshot can't fake.

### Use your Alamo Colleges Zoom account

You already have an enterprise **Zoom** account through Alamo Colleges — that is the tool we use for these recordings, so there is nothing extra to install or sign up for.

1. Open the Zoom app and sign in with your **ACES / Alamo Colleges** account.
2. Start a meeting by yourself (**New Meeting**). You do not invite anyone.
3. **Turn your webcam OFF.** A webcam is not wanted for these recordings — we only need your screen.
4. Click **Share Screen** and share the terminal window where your VM shell is open.
5. Click **Record**. **Choose “Record to the Cloud”** if your Alamo account offers it — that produces a shareable link, which is how we prefer you submit. If you only see “Record on this Computer,” that is fine too.
6. Do the short sequence below, then **Stop Recording** and **End** the meeting.

### How to submit (preference order)

1. **Preferred — Zoom Cloud link.** Once the cloud recording finishes processing (you'll get an email/notification), copy its **share link** and paste that into the Canvas assignment. Easiest for everyone and nothing large to upload.
2. **Fine — local file.** If you recorded to your computer, Zoom saves an `.mp4` when the meeting ends. Upload that `.mp4` to the Canvas assignment.

Either way, **keep your own copy of the `.mp4`.** Cloud recordings can age out of institutional storage, and a clip of you building or fixing a real system is exactly the kind of thing you may want later for your [portfolio](../PORTFOLIO.md). Make a "ITSC-1316 recordings" folder on your computer and drop each one in as you go. (Don't commit these video files to your Git repo — the repo's `.gitignore` blocks them on purpose; link to them instead.)

### What the recording must show

Keep it continuous — one unbroken take on your own VM, not stitched-together clips:

- Run `hostname` and `whoami` so your VM is identifiable as yours.
- Show the key step(s) of the lab happening live.
- Run the check script so we see it **PASS** in real time.

### Voice is optional; your writing carries the "why"

**Narrating out loud is welcome but optional, and a webcam is discouraged.** If you would rather not talk, that is fine — the *reasoning* part of every lab is captured in its written reflection / report / writeup, which you submit alongside the recording. So the recording proves *you operated the system live*, and your writing proves *you understand why*. (If you do narrate, a sentence like "I used 660 here because…" is plenty.)

We are not grading production quality. A plain, continuous screen recording of your real terminal is exactly what we want.

---

## Part 5 — Managing Your VM Between Labs

A few commands you will use throughout the semester:

| Goal | Command |
| --- | --- |
| See your VMs and their state | `multipass list` |
| Open a shell | `multipass shell labvm` |
| Stop the VM (frees resources, keeps your work) | `multipass stop labvm` |
| Start it again | `multipass start labvm` |
| Copy a file in | `multipass transfer FILE labvm:/home/ubuntu/` |
| Copy a file out | `multipass transfer labvm:/home/ubuntu/FILE .` |
| Take a (named) snapshot before risky work | `multipass stop labvm && multipass snapshot --name BEFORE-X labvm && multipass start labvm` |
| Restore a snapshot | `multipass stop labvm && multipass restore labvm.BEFORE-X && multipass start labvm` |

> **Tip — snapshots need the VM stopped.** Multipass refuses to snapshot or restore a *running* instance. The pattern is always: `exit` the VM shell → `multipass stop labvm` → take/restore the snapshot → `multipass start labvm` again. **Name your snapshots** (`--name BEFORE-something`) so you can find them later by name instead of guessing whether `snapshot1` is the right one.

**Do not delete `labvm`** until the semester ends. Some later labs build on earlier state.

---

## Part 6 — Cloud Fallback (if your computer cannot run a VM)

If your laptop genuinely cannot run Multipass, you can complete every lab on a free cloud VM instead. The commands are identical once you are connected by SSH; only the setup differs.

Recommended free options:

- **Oracle Cloud Always Free** — up to 4 ARM cores and 24 GB RAM, free with no time limit. The best free option. Signup requires a credit card for verification (no charge).
- **GitHub Student Developer Pack** — verify with your ACES student email and get $200 in DigitalOcean credit (≈ 4 years of a basic VM).
- **Ask me** — if neither works for you, contact me and we will arrange access. Nobody is blocked from this course for lack of hardware.

Once you have a cloud Ubuntu 22.04 instance, you transfer scripts with `scp` instead of `multipass transfer`, and connect with `ssh` instead of `multipass shell`. Everything inside the VM is the same.

---

## A Note on Ubuntu vs. Red Hat

This course uses **Ubuntu** because Multipass makes it free and instant on your own machine. The CompTIA Linux+ objectives we follow are **distro-neutral** — the concepts transfer to any Linux. Where a command differs meaningfully on Red Hat–family systems (RHEL, Rocky, Fedora — which use `dnf`, `firewalld`, and `/etc/sysconfig` instead of Ubuntu's `apt`, `ufw`, and `netplan`), the lab will include a short **"On RHEL this would be…"** note so you are not surprised on the job or on a certification exam.

---

## Quick Troubleshooting

| Symptom | Fix |
| --- | --- |
| `multipass: command not found` | Install did not complete. Reinstall; reboot. |
| `launch failed: ... not enough memory` | Lower `--memory` to `1G`, or stop other VMs. |
| VM stuck "Starting" | `multipass stop labvm` then `multipass start labvm`. |
| Can't transfer a file | Check the path on your computer is exact; use full paths. |
| Forgot the VM's IP | `multipass list` or, inside the VM, `ip a`. |
| VM has no internet / can't resolve names | Usually a **VPN or firewall** — see the Troubleshooting Guide. |

**For anything this table doesn't cover — especially VPN, corporate-network, or "no internet in the VM" problems — see the full [Multipass Troubleshooting Guide](02-multipass-troubleshooting.md).** It covers all three platforms with fixes and links to Canonical's official docs.

Post anything you can't resolve to the **Q&A Discussion Board** with a screenshot of the exact command and error.
