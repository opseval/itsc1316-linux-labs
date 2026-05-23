# ITSC-1316 — Linux Installation & Configuration: Hands-On Labs

Hands-on Linux labs that run on a free virtual machine on **your own computer** using [Canonical Multipass](https://multipass.run). You administer a real Linux system, prove your work with a self-grading script, and — if you choose — build a public portfolio that future employers can see.

> **New here? Do these three things in order:**
> 1. Run the **[Preflight Check](docs/00-preflight-check.md)** to confirm your computer can run the labs (week 1).
> 2. Follow the **[Multipass Setup Guide](docs/01-multipass-setup-guide.md)** to build your course VM.
> 3. Start with the labs in [`labs/`](labs/), in module order.

---

## Get your own copy (do this first)

This repository is a **template**. You do not work in this shared repo — you make your own copy:

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

| Module | Lab | Skills |
| --- | --- | --- |
| 6 | [Users, Ownership & Permissions](labs/module-06-users-and-permissions/) | `chown`, `chmod`, groups, `sudo`, least privilege |
| 9 / 13 | [Networking (two-VM)](labs/module-09-13-networking/) | routing, `/etc/hosts`, connectivity vs. name resolution |
| 13 | [Cloud Computing with cloud-init](labs/module-13-cloud-computing/) | declarative provisioning, SSH keys, first-boot automation |
| 14 | [Security & Troubleshooting (break/fix)](labs/module-14-security-troubleshooting/) | SUID, attack surface, evidence-based troubleshooting |

*(More labs are added as the course progresses.)*

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
