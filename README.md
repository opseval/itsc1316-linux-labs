# ITSC-1316 — Linux Installation & Configuration: Hands-On Labs

Hands-on Linux labs that run on a free virtual machine on **your own computer** using [Canonical Multipass](https://multipass.run). You administer a real Linux system, prove your work with a self-grading script, and — if you choose — build a public portfolio that future employers can see.

> **New here? Do these four things in order:**
> 1. Run the **[Preflight Check](docs/00-preflight-check.md)** to confirm your computer can run the labs (week 1).
> 2. Follow the **[GitHub & Git Primer](docs/03-github-primer.md)** to make a GitHub account and get your own copy of this repo onto your computer.
> 3. Follow the **[Multipass Setup Guide](docs/01-multipass-setup-guide.md)** to build your course VM.
> 4. Start with the labs in [`labs/`](labs/), in module order.
>
> Hitting problems — no internet in the VM, a VPN in the way, a launch that won't start? See the **[Multipass Troubleshooting Guide](docs/02-multipass-troubleshooting.md)**.

---

## Get your own copy (do this first)

This repository is a **template**. You do not work in this shared repo — you make your own copy. If you have never used GitHub before, **the [GitHub & Git Primer](docs/03-github-primer.md) walks the whole thing step by step**, including making an account and installing git.

The 30-second version for people who already use git:

1. Click the green **“Use this template”** button at the top of the GitHub page, then **“Create a new repository.”**
2. Name it something like `itsc1316-labs-yourname`. You can make it **private** (just for you and your instructor) or **public** (so it can become a portfolio — see below).
3. Clone *your* copy to your computer:
   ```
   git clone https://github.com/YOUR-USERNAME/itsc1316-labs-yourname.git
   cd itsc1316-labs-yourname
   ```

Working in your own copy means you get real version history of *your* learning — which is exactly what makes it valuable to an employer later.

---

## How each lab works

Every lab folder under [`labs/`](labs/) contains:

| File | What it is |
| --- | --- |
| `README.md` | The lab instructions |
| `setup-*.sh` | Builds the lab scenario inside your VM (run once) |
| `check-*.sh` | Self-grades your work — PASS/FAIL per requirement |

The workflow is the same every time (full details in the [Setup Guide](docs/01-multipass-setup-guide.md)):

```
# from your computer
multipass transfer labs/<lab>/setup-*.sh   labvm:/home/ubuntu/
multipass transfer labs/<lab>/check-*.sh   labvm:/home/ubuntu/
multipass shell labvm
# inside the VM
sudo bash setup-*.sh      # build the scenario
# ...do the lab...
bash check-*.sh           # grade yourself; fix FAILs; repeat until all PASS
```

Then record a short **screen recording** (use your Alamo Colleges Zoom account — see the [Setup Guide](docs/01-multipass-setup-guide.md), Part 4) and submit it with whatever the lab asks for. A continuous recording of you working live on your own VM — webcam off, narration optional — is what proves the work is yours. The "why" lives in each lab's written reflection.

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

If you make your repo public, the work you do here can become a portfolio piece that shows employers you can actually operate Linux — not just pass a quiz. See **[PORTFOLIO.md](PORTFOLIO.md)** for a template and guidance. It is entirely opt-in; nobody is required to make their work public.

---

## License

- **Lab instructions and documentation** (`*.md`): [Creative Commons Attribution 4.0 (CC BY 4.0)](LICENSE) — reuse and adapt with attribution.
- **Scripts** (`*.sh`, `*.ps1`, `*.yaml`): MIT License (see [LICENSE](LICENSE)).

---

## A note on Ubuntu vs. Red Hat

These labs use **Ubuntu** because Multipass makes it free and instant. The CompTIA Linux+ objectives this course follows are distro-neutral, and every lab includes an **“On RHEL this would be…”** note where Red Hat–family systems (RHEL, Rocky, Fedora) differ. The concepts transfer to any Linux and to the certification exams.
