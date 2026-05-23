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

### Step 1 — Download the lab's scripts

Each lab in Canvas includes two files: a **setup script** (`setup-*.sh`) that builds the lab scenario, and a **check script** (`check-*.sh`) that grades your work. Download both to your computer (they will land in your Downloads folder).

### Step 2 — Transfer the scripts into your VM

`multipass transfer` copies files from your computer into the VM. From your computer's terminal:

```
multipass transfer ~/Downloads/setup-example.sh labvm:/home/ubuntu/
multipass transfer ~/Downloads/check-example.sh labvm:/home/ubuntu/
```

On Windows the path looks like `C:\Users\YOU\Downloads\setup-example.sh` instead of `~/Downloads/...`.

### Step 3 — Open a shell inside the VM

```
multipass shell labvm
```

Your prompt changes to `ubuntu@labvm:~$`. You are now *inside* the Linux system. Run the setup script to build the scenario:

```
bash setup-example.sh
```

### Step 4 — Do the lab

Follow the lab instructions. Work entirely inside the VM shell.

### Step 5 — Grade yourself and record proof

When you think you are done, run the check script:

```
bash check-example.sh
```

It prints a PASS or FAIL for each requirement. Fix any FAILs and run it again until everything passes — exactly like a real admin re-testing after a change.

Then record a short screencast (see Part 4) and submit it with your check output.

---

## Part 4 — Recording Your Screencast

Every lab asks for a **60–90 second screencast**. This is your proof that *you* did the work and understand it — not a screenshot anyone could share.

In the screencast you will: run `hostname` and `whoami` (so your VM is identifiable), run the check script so we see it pass, and **narrate one choice you made in your own voice** ("I set this to 750 instead of 770 because…").

Free tools for recording:

- **macOS:** QuickTime Player → File → New Screen Recording. Or press Cmd+Shift+5.
- **Windows:** Xbox Game Bar (Win+G) or the Snipping Tool's record feature.
- **Any platform:** [OBS Studio](https://obsproject.com) (free), or [Loom](https://www.loom.com) (free tier).
- **Terminal-only option:** `asciinema` records your terminal session as a shareable link — ask if you want to use this instead of video.

Keep it short. We are not grading production quality; we are listening for whether you understand what you did.

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
| Take a snapshot before risky work | `multipass snapshot labvm` |
| Restore a snapshot | `multipass restore labvm.snapshot1` |

> **Tip:** Before any lab that involves "breaking" the system (troubleshooting labs especially), take a snapshot first: `multipass snapshot labvm`. If you paint yourself into a corner, you can restore instead of rebuilding.

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

Post anything this table does not cover to the **Q&A Discussion Board** with a screenshot of the exact command and error.
