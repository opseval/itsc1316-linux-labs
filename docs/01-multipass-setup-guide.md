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

## Part 2 — Launch Your Lab VM

The required VM for every lab is **`labvm`**. You keep it for the whole semester.

### 2a. Launch `labvm`

From your computer's terminal:

```
multipass launch 22.04 --name labvm --cpus 2 --memory 2G --disk 10G
```

This downloads Ubuntu 22.04 LTS (the first time only — a few minutes) and boots it. Confirm it's running:

```
multipass list
```

You should see `labvm` as `Running` with an IPv4 address.

> **Low on resources?** Drop to `--memory 1G` if your laptop struggles with 2 GB. If your machine genuinely cannot run a VM at all, see **Part 6 — Cloud Fallback** below; you will not be penalized for hardware you do not have.

### 2b. (Optional) Launch the `workstation` VM — only if you want the portfolio/git track

Skip this entirely if you're not planning to do the [PORTFOLIO.md](../PORTFOLIO.md) track. The labs themselves do **not** require a workstation VM — every lab fetches its scripts straight from this public repo into `labvm` with `curl`.

If you *are* doing the portfolio track (recommended but optional), launch a second small VM where `git`, `gh`, `ssh-keygen`, `scp`, `nano`, etc. are pre-installed so the git/SSH experience is identical regardless of your laptop's OS. Fetch the cloud-init file first, then point Multipass at the local copy — that form works on every Multipass version and every shell:

**macOS / Linux:**

```
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/scripts/workstation/cloud-init.yaml
multipass launch 22.04 --name workstation --cpus 1 --memory 1G --disk 5G --cloud-init ./cloud-init.yaml
```

**Windows (PowerShell)** — use `curl.exe`, not `curl`; the bare word is an alias for Invoke-WebRequest, which doesn't speak `-fsSLO`:

```
curl.exe -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/scripts/workstation/cloud-init.yaml
multipass launch 22.04 --name workstation --cpus 1 --memory 1G --disk 5G --cloud-init ./cloud-init.yaml
```

> Newer Multipass builds (1.13+) also accept an HTTPS URL passed directly to `--cloud-init` (so you can skip the curl step), but the two-step form above is the only one guaranteed to work on every build that's currently in the wild — and it leaves the YAML on disk so you can inspect or re-launch from it.

The full walk-through (first-boot config, `gh auth login`, cloning your fork, daily git workflow, reaching `labvm` over SSH) lives in **[Workstation VM Guide](06-workstation-vm.md)**.

---

## Part 3 — The Workflow You Will Repeat Every Lab

Every lab follows the same four steps. Learn them once here.

### Step 1 — Open a shell inside `labvm`

From your computer's terminal:

```
multipass shell labvm
```

Your prompt changes to `ubuntu@labvm:~$`. You are now *inside* the Linux system. Everything else in this workflow happens here.

### Step 2 — Pull the lab's scripts straight from the public repo

Each per-lab README tells you the exact two `curl` commands for that lab. They look like this (the example is Module 6):

```
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-06-users-and-permissions/setup-users.sh
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-06-users-and-permissions/check-users.sh
```

The `-O` writes each file with its remote name (e.g. `setup-users.sh`); `-fsSL` makes curl quiet on success, loud on failure, and follow any redirects.

> **Always inspect before you `sudo`.** A setup script may run as root. Read it first:
>
> ```
> less setup-<name>.sh check-<name>.sh
> ```
>
> Press `q` to exit `less`. The check script also prints its own SHA256 when you run it; the grader compares that against [`labs/CHECKSUMS.txt`](../labs/CHECKSUMS.txt) to confirm nothing's been tampered with.

### Step 3 — Run setup → do the lab → run check

**Each lab's README states the exact `setup` and `check` commands** (whether they need `sudo`). Most labs use:

```
sudo bash setup-<name>.sh
# ...do the lab...
bash check-<name>.sh
```

…but a few labs intentionally run setup as your normal user (read-only or per-user setup), and a few labs need `sudo` on the *check* too. Always follow the per-lab README, not the boilerplate.

The check prints PASS or FAIL for each requirement. Fix any FAILs and run it again until everything passes — exactly like a real admin re-testing after a change.

### Step 4 — Record proof and submit

Record a short screencast (see Part 4) showing `hostname`, `whoami`, and the check passing. Submit per the rubric.

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
| Pull a lab script from the public repo (run *inside* labvm) | `curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/<lab>/<script>.sh` |
| Copy a notes/report file out (for Canvas upload) | `multipass transfer labvm:/home/ubuntu/FILE .` |
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

Once you have a cloud Ubuntu 22.04 instance, you connect with `ssh` instead of `multipass shell`, and the per-lab `curl` commands work exactly the same way (they're fetching from `raw.githubusercontent.com`, which any Linux box can reach). Everything inside the VM is identical.

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
| `curl: (6) Could not resolve host: raw.githubusercontent.com` (inside `labvm`) | The VM has no internet — almost always a VPN or corporate proxy on your host. See the Troubleshooting Guide. |
| `curl: (22) The requested URL returned error: 404` | The path or filename is wrong. Check the spelling against the lab's README; the path is case-sensitive. |
| Forgot the VM's IP | `multipass list` or, inside the VM, `ip a`. |
| VM has no internet / can't resolve names | Usually a **VPN or firewall** — see the Troubleshooting Guide. |

**For anything this table doesn't cover — especially VPN, corporate-network, or "no internet in the VM" problems — see the full [Multipass Troubleshooting Guide](02-multipass-troubleshooting.md).** It covers all three platforms with fixes and links to Canonical's official docs.

Post anything you can't resolve to the **Q&A Discussion Board** with a screenshot of the exact command and error.
