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

## Part 2 — Launch Your Course VMs

This course runs on **two long-lived VMs** you keep for the whole semester:

- **`labvm`** — where you run the lab `setup-*.sh` / `check-*.sh` scripts and do the exercises.
- **`workstation`** — a small, pre-configured Ubuntu VM with `git`, `gh`, `ssh-keygen`, `scp`, `nano`, `vim`, etc., where you do every host-side task (so the experience is identical for everyone, regardless of laptop OS).

### 2a. Launch `labvm`

```
multipass launch 22.04 --name labvm --cpus 2 --memory 2G --disk 10G
```

This downloads Ubuntu 22.04 LTS (the first time only — a few minutes) and boots it.

### 2b. Launch `workstation`

From the **root of your cloned repo** (so the cloud-init path resolves):

```
multipass launch 22.04 --name workstation --cpus 1 --memory 1G --disk 5G \
    --cloud-init scripts/workstation/cloud-init.yaml
```

The `--cloud-init` flag tells Multipass to run a one-time first-boot setup that installs the dev tools. The full walk-through (first-boot config, `gh auth login`, cloning your fork, daily workflow, reaching `labvm` over SSH) lives in **[Workstation VM Guide](06-workstation-vm.md)**.

### 2c. Confirm both are up

```
multipass list
```

You should see `labvm` and `workstation`, each `Running`, each with an IP address.

> **Low on resources?** Drop labvm to `--memory 1G` if your laptop struggles with 2 GB. Workstation already sits at 1 GB. If your machine genuinely cannot run two VMs, see **Part 6 — Cloud Fallback** below; you will not be penalized for hardware you do not have.

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

Your prompt changes to `ubuntu@labvm:~$`. You are now *inside* the Linux system. Run the setup script to build the scenario — **each lab's README says whether to run setup/check with `sudo`.** Most labs use:

```
sudo bash setup-<name>.sh
```

…but a few labs intentionally run setup as your normal user (it's a read-only or per-user setup), and a few labs need `sudo` on the *check* too. Always follow each lab README's exact command.

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

## Part 4 — Recording Your Submission (see the dedicated guide)

Every lab asks for a short **60–90 second screen recording** (Alamo Zoom by default, with a small per-platform backup list if Zoom isn't working). The full recipe — sign-in, record-to-cloud, submission preference order, privacy checklist, and the QuickTime / Game Bar / OBS backups — lives in **[Screen Recording Guide](05-screen-recording-guide.md)**.

The short version: one continuous take with **`hostname`** → **`whoami`** → **`bash check-*.sh`** showing the PASS banner on screen. Webcam off, narration optional. Submit the Zoom Cloud link if you have one, otherwise the `.mp4`.

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
