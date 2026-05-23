# Workstation VM (One Place for All Host-Side Work)

**Set this up once, in the first week, right after the Multipass Setup Guide.** Every student in this course does host-side work — generating SSH keys, configuring git, running the GitHub CLI, editing files, cloning the repo — inside the same pre-built **workstation** VM, regardless of whether their laptop is macOS, Windows, or Linux. The only thing that lives on your laptop is **Multipass** (for managing the VMs) and a terminal.

> **Why a separate workstation VM?** Because the tools every lab needs (`git`, `gh`, `ssh-keygen`, `scp`, `nano`, etc.) install differently — and sometimes badly — on every host OS, and we want every student looking at the same prompt and the same commands. The workstation comes up the same way, with the same tools at the same paths, every time.

---

## The two-VM model

This course uses **two Multipass VMs** that play different roles:

| VM | Role | What you do there |
| --- | --- | --- |
| **`workstation`** | Dev box | Edit files, generate SSH keys, configure git, run `gh`, clone your repo, `ssh`/`scp` to other VMs |
| **`labvm`** | Lab target | Run lab `setup-*.sh` / `check-*.sh` scripts, do the actual exercises |

A few labs add a third VM (Module 13-adv adds `fileserver`; Module 13-cloud adds `cloudvm`). Workstation is always there, always with the same tools, and is *not* itself a lab target.

> **You only run Multipass commands on your host computer.** Inside any VM, there's no Multipass — that's a host concept. The workstation VM does *not* manage other VMs; it just gives you a uniform place to run developer tools.

---

## Part 1 — Launch the workstation VM (once)

This is a one-time setup. After this, you'll just `multipass shell workstation` to enter it.

From your computer's terminal, **at the root of your cloned repo** (so the cloud-init path resolves):

```
multipass launch 22.04 --name workstation --cpus 1 --memory 1G --disk 5G \
    --cloud-init scripts/workstation/cloud-init.yaml
```

This downloads Ubuntu 22.04 LTS (the first time) and runs cloud-init on first boot — installing `git`, `gh`, `ssh-keygen`, `scp`, `nano`, `vim`, `curl`, and the GitHub CLI keyring. Total time on a typical connection: 2–4 minutes.

Confirm both VMs are up:

```
multipass list
```

You should see `workstation` and `labvm`, each `Running` with an IP.

Enter your workstation:

```
multipass shell workstation
```

Your prompt changes to `ubuntu@workstation:~$`. You're inside. From here on, almost everything you do — git, gh, ssh-keygen, editing files, cloning the repo, SSHing into lab VMs — happens here.

> **Wait for cloud-init.** If you opened a shell immediately after launching and packages aren't there yet (e.g., `gh --version` says "command not found"), wait 30 seconds and try again. You can also check `cloud-init status --long` to see if first-boot setup is finished.

---

## Part 2 — First-time configuration inside workstation

Run these **inside workstation** (after `multipass shell workstation`).

### Configure git identity

```
git config --global user.name "Your Real Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global pull.rebase false
```

Use the same email you'll use on GitHub.

### Log in to the GitHub CLI

```
gh auth login
```

Pick:
- **GitHub.com**
- **HTTPS**
- **Yes, authenticate Git with your GitHub credentials**
- **Login with a web browser**

It will print a code and a URL. **Copy the URL and open it in your laptop's browser** (workstation has no GUI). Paste the code, click Authorize. The CLI will detect it and finish login.

Verify:

```
gh auth status
```

### Clone your fork of the course repo

(Walked through fully in the [GitHub Primer](03-github-primer.md). The short version, inside workstation:)

```
gh repo clone YOUR-USERNAME/itsc1316-labs-yourname
cd itsc1316-labs-yourname
```

You're now ready to do the labs. The cloned repo lives at `/home/ubuntu/itsc1316-labs-yourname/` inside workstation.

---

## Part 3 — Reaching the other lab VMs from workstation

Multipass puts every VM on the same virtual network, so workstation can talk to labvm/fileserver/cloudvm directly over SSH **once you've authorized your key on the target VM**. There's one small bootstrap step the first time, run from your **host** terminal (because that's where `multipass transfer` and `multipass exec` live):

### One-time: push workstation's SSH key into labvm

Inside workstation, generate a key if you don't already have one:

```
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
```

Then from **your host computer's terminal** (not inside any VM), run this single bootstrap to copy workstation's public key into labvm:

```
multipass transfer workstation:/home/ubuntu/.ssh/id_ed25519.pub labvm:/tmp/ws.pub
multipass exec labvm -- bash -c \
  'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat /tmp/ws.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/ws.pub'
```

That's it. Workstation can now SSH to labvm. Verify, from inside workstation:

```
ssh ubuntu@$(getent hosts labvm 2>/dev/null | awk '{print $1}' || echo labvm)
```

If you launched a `fileserver` or `cloudvm` later, repeat the same two `multipass transfer` + `multipass exec` lines with that VM name instead of `labvm`.

> **Why bootstrap from the host?** Multipass adds *its own* daemon key to each VM, but it doesn't trust the workstation's key — workstation isn't a Multipass-managed identity, just another VM. The two `multipass` commands on your host are the one-time handshake; after that, workstation talks to lab VMs over plain SSH.

---

## Part 4 — Daily workflow (where each command runs)

The pattern, end-to-end, for a typical lab:

```
# On your HOST computer's terminal:
multipass start workstation labvm        # if either is stopped
multipass shell workstation              # enter workstation

# Inside WORKSTATION:
cd ~/itsc1316-labs-yourname              # your cloned repo
git pull                                 # if you've pushed from elsewhere
nano labs/module-XX/...                  # edit, if needed

# Push the lab's setup + check scripts to labvm. There are two paths:
#   (a) Use multipass transfer from your host (works always):
#       (in another terminal on your host)
#       multipass transfer labs/module-XX/setup-*.sh labvm:/home/ubuntu/
#       multipass transfer labs/module-XX/check-*.sh labvm:/home/ubuntu/
#   (b) Use scp from workstation to labvm (after the Part 3 bootstrap):
scp labs/module-XX/setup-*.sh ubuntu@labvm:/home/ubuntu/
scp labs/module-XX/check-*.sh ubuntu@labvm:/home/ubuntu/

# SSH into labvm and do the lab:
ssh ubuntu@labvm
# … inside labvm …
sudo bash setup-XX.sh
# … fix things …
bash check-XX.sh                         # or 'sudo bash check-XX.sh' per the lab README
exit                                     # back to workstation

# Back in WORKSTATION, commit and push:
git add ...
git commit -m "Module XX: done"
git push

# On your HOST: record your screen showing labvm's final check run
# (see docs/05-screen-recording-guide.md), then upload to Canvas.
```

The host gets used for: launching/stopping VMs, the file-transfer fallback in path (a), and screen recording. **Everything else lives inside workstation.**

---

## Part 5 — Resource sizing & turning workstation off

Workstation is small (1 CPU, 1 GB RAM, 5 GB disk). Even with `workstation` + `labvm` + `fileserver` all running at once (the Module 13-adv setup), total memory pressure is around 4 GB — comfortable on any laptop with 8 GB RAM.

When you're done for the session, stop both to free resources:

```
multipass stop workstation labvm
```

The next session: `multipass start workstation labvm && multipass shell workstation`.

> **Don't delete `workstation`** until the course is over. Your cloned repo, your SSH keys, and your `gh` authentication all live inside it — recreating that takes 20 minutes.

---

## Part 6 — When things go wrong

| Symptom | Fix |
| --- | --- |
| `multipass launch ... --cloud-init scripts/workstation/cloud-init.yaml` says "No such file" | Run the command from the **root of your cloned repo**, not from inside another folder. |
| `gh: command not found` inside workstation right after launch | cloud-init is still finishing. Wait 30s and try again, or check `cloud-init status --long`. |
| `ssh: connect to host labvm port 22: Connection refused` from workstation | Did you do the Part 3 bootstrap from the host? Without it, workstation can't authenticate to labvm. |
| `getent hosts labvm` returns nothing inside workstation | Multipass VMs aren't auto-registered as DNS names. Use the IP from `multipass list` (from host) directly: `ssh ubuntu@10.x.x.x`. |
| Workstation VM stuck in `Starting` after a host sleep | Same fix as labvm: `multipass stop workstation && multipass start workstation`. See [Multipass Troubleshooting Guide](02-multipass-troubleshooting.md). |
| I need to rebuild workstation from scratch | `multipass delete --purge workstation` then re-run the launch command. You'll lose your cloned repo and gh auth — back up anything important first. |

If something here doesn't cover it, the [Multipass Troubleshooting Guide](02-multipass-troubleshooting.md) applies to workstation exactly the same way it applies to labvm.

---

## Why this exists (the design rationale, for the curious)

The alternative is per-OS install instructions for `git`, `gh`, `ssh-keygen`, file editors, etc. — `brew install` on macOS, `winget` on Windows, `apt`/`dnf` on Linux, plus all the path / shell / line-ending differences that come with each. That's been tried; it generates the bulk of week-1 support tickets.

A workstation VM costs one extra `multipass launch` and ~1 GB of RAM, and in return:

- Every student sees the same prompt, the same tools, the same paths.
- The instructor demos work for everyone byte-for-byte.
- A working SSH/git/gh stack is one `multipass launch` away from any laptop that can run Multipass at all.
- You build the "host is for managing VMs; real work happens in a VM" mental model that real cloud admins live in.

It's the same trade Docker-for-development made a decade ago, just simpler.
