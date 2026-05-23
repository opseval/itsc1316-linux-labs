# ITSC-1316 — Linux Installation & Configuration: Hands-On Labs

Hands-on Linux labs that run on a free virtual machine on **your own computer** using [Canonical Multipass](https://multipass.run). You administer a real Linux system, prove your work with a self-grading script, and — if you choose — build a public portfolio that future employers can see.

> **New here? Do these in order, in week 1:**
> 1. **[Preflight Check](docs/00-preflight-check.md)** — confirms your computer can run the labs.
> 2. **[Multipass Setup Guide](docs/01-multipass-setup-guide.md)** — installs Multipass and launches `labvm` (your one required lab VM).
> 3. **[Grading Rubric](docs/04-grading-rubric.md)** — 4 criteria × 4 levels, explicit point values, no ambiguity.
> 4. Start the labs in [`labs/`](labs/), in module order. Each lab tells you the two `curl` commands that pull its scripts straight into `labvm`.
>
> **Two more guides you'll need within the first week:**
> - **[Screen Recording Guide](docs/05-screen-recording-guide.md)** — Alamo Zoom (primary) + one specific backup per OS (QuickTime / Game Bar / OBS).
> - **[Multipass Troubleshooting Guide](docs/02-multipass-troubleshooting.md)** — for when the VM has no internet, a VPN is in the way, or a launch won't start.
>
> **Optional, only if you want a portfolio:**
> - **[GitHub & Git Primer](docs/03-github-primer.md)** + **[Workstation VM Guide](docs/06-workstation-vm.md)** — make a GitHub account, copy the template into your own repo, and use a second small "workstation" VM as a uniform place to do git/SSH work. Required only for the [PORTFOLIO.md](PORTFOLIO.md) track; the labs themselves run fine without it.

---

## How each lab works

Every lab folder under [`labs/`](labs/) contains:

| File | What it is |
| --- | --- |
| `README.md` | The lab instructions |
| `setup-*.sh` | Builds the lab scenario inside your VM (run once) |
| `check-*.sh` | Self-grades your work — PASS/FAIL per requirement |

You don't clone this repo. Instead, every lab's scripts are pulled straight into `labvm` from this public repo with `curl`. The workflow is the same every time (full details in the [Setup Guide](docs/01-multipass-setup-guide.md)):

```
# from your computer:
multipass shell labvm

# inside labvm — each lab's README gives the exact URLs:
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/<lab>/setup-<name>.sh
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/<lab>/check-<name>.sh
less setup-<name>.sh check-<name>.sh        # inspect before you run anything as root
sudo bash setup-<name>.sh                    # most labs; a few use 'bash' (no sudo) — README says
# ...do the lab...
bash check-<name>.sh                         # or 'sudo bash check-*.sh' per the README
# Fix FAILs and re-run until all PASS.
```

> Each per-lab README gives the exact `curl` URLs and the exact `setup`/`check` commands for that lab. Follow those — the boilerplate above is just the shape.

> **Why `curl` instead of cloning?** It works the same on macOS, Windows, and Linux — all the work happens *inside* Ubuntu (`labvm`), which has `curl` pre-installed. Nothing to configure on your host. Every check script also auto-fetches [`labs/CHECKSUMS.txt`](labs/CHECKSUMS.txt) from the canonical raw URL and self-verifies — it prints `INTEGRITY: VERIFIED` (good), `*** MISMATCH ***` (script edited — academic-integrity 0), or `UNKNOWN` (offline, path missing from `CHECKSUMS.txt`, or no `sha256sum`/`shasum`) at the top, so you (and the grader) know in one glance whether the script has been tampered with. See the [Screen Recording Guide](docs/05-screen-recording-guide.md) for what to do on each.

Then record a short **screen recording** — see the **[Screen Recording Guide](docs/05-screen-recording-guide.md)** (Alamo Zoom by default; one specific backup per OS if Zoom isn't working) — and submit it with whatever the lab asks for. Every lab is scored against the same 4-criterion, 4-level **[Grading Rubric](docs/04-grading-rubric.md)** so you know in advance exactly what counts.

---

## Labs

Every module outside the midterm (8) and final (16) has at least one hands-on lab.

| Module | Lab | Skills |
| --- | --- | --- |
| 1 | [Introduction: First Contact with Linux](labs/module-01-introduction-to-linux/) | OS identity, kernel, shell, distributions, FHS first look |
| 2 | [Accessing a Linux System](labs/module-02-accessing-a-linux-system/) | shell + SSH access, user passwords, time sync, `man`/`--help` |
| 3 | [The Shell: Streams, Pipes & a Real Script](labs/module-03-shell-and-files/) | redirection, pipes, variables, writing a working Bash script |
| 4 | [Filesystem Navigation](labs/module-04-filesystem-navigation/) | FHS, absolute/relative paths, `find`, redirection |
| 5 | [Storage Monitoring](labs/module-05-storage-monitoring/) | `df` vs `du`, finding disk hogs, capacity decisions |
| 6 | [Users, Ownership & Permissions](labs/module-06-users-and-permissions/) | `chown`, `chmod`, groups, `sudo`, least privilege |
| 7 | [Software & Archives](labs/module-07-software-and-archives/) | `apt`, repositories, `dpkg`, `tar`/gzip archives |
| 9 | [Networking Fundamentals](labs/module-09-networking-fundamentals/) | interfaces, IP addressing, default gateway, layered connectivity |
| 10 | [Processes & System Resources](labs/module-10-processes-and-resources/) | `ps`, `top`, signals, `nice`/`renice`, finding a runaway process |
| 11 | [Devices, Mounting & Persistence](labs/module-11-devices-and-mounting/) | `lsblk`, loop devices, `mkfs`, `mount`, `/etc/fstab`, `fsck` |
| 12 | [systemd: Services, Boot & Localization](labs/module-12-systemd-services/) | `systemctl`, writing a unit, `journalctl`, `systemd-analyze`, locale |
| 13 | [Advanced Network Configuration (two-VM)](labs/module-13-advanced-networking/) | routing, `/etc/hosts`, connectivity vs. name resolution, services, runtime vs. persistent |
| 13 | [Cloud Computing with cloud-init](labs/module-13-cloud-computing/) | declarative provisioning, SSH keys, first-boot automation |
| 14 | [Security & Troubleshooting (break/fix)](labs/module-14-security-troubleshooting/) | SUID, attack surface, evidence-based troubleshooting |
| 15 | [Capstone: Inherit & Recover a Server](labs/module-15-capstone/) | integration of all skills; specifications-driven; handover report |

---

## Using AI in this course

Each lab states an **AI category** in its instructions:

- **AI-FREE** — no AI tools (in-class quizzes, practical exams, oral defenses).
- **AI-OPEN** — AI tools allowed; include a one-line note of what you asked and what you verified yourself.
- **AI-REQUIRED** — you must use AI and document where it was wrong.

The labs are designed so an AI can help you *understand* a command, but only your own VM can prove it *worked*. That is intentional. Lean on AI to learn faster — then verify everything on your real system, because that is the job.

---

## Build a portfolio (optional, but recommended)

If you also keep your work in your own GitHub repo (the [GitHub Primer](docs/03-github-primer.md) + [Workstation VM Guide](docs/06-workstation-vm.md) track), it can become a portfolio piece that shows employers you can actually operate Linux — not just pass a quiz. See **[PORTFOLIO.md](PORTFOLIO.md)** for a template and guidance. It is entirely opt-in; the labs themselves don't require it.

---

## License

- **Lab instructions and documentation** (`*.md`): [Creative Commons Attribution 4.0 (CC BY 4.0)](LICENSE) — reuse and adapt with attribution.
- **Scripts** (`*.sh`, `*.ps1`, `*.yaml`): MIT License (see [LICENSE](LICENSE)).

---

## A note on Ubuntu vs. Red Hat

These labs use **Ubuntu** because Multipass makes it free and instant. The CompTIA Linux+ objectives this course follows are distro-neutral, and every lab includes an **“On RHEL this would be…”** note where Red Hat–family systems (RHEL, Rocky, Fedora) differ. The concepts transfer to any Linux and to the certification exams.
