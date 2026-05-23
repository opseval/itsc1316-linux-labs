# Module 13 Lab: Cloud Computing with cloud-init (Multipass)

**Hands-on cloud lab. You will provision a server the way real cloud platforms do — declaratively, with no manual setup — and it will configure itself on first boot.**

## Lab Overview

In the cloud, nobody installs a server by hand and clicks through menus. You hand the provider a **declarative config** describing the server you want, and the machine builds itself on first boot: creates users, installs SSH keys, installs software, starts services. The standard for this is **cloud-init**, and the same file format works on AWS, Google Cloud, Azure, Oracle Cloud, DigitalOcean — and Multipass. That is what you will use here.

You will write a cloud-init config that, on first boot, creates a key-only login user, installs a web server, and serves a page you personalized — all automatically. Then (optionally) you will prove it is truly platform-agnostic by running the *exact same config* on a real free-tier cloud instance.

|  |  |
| --- | --- |
| **Estimated Time** | 50–80 minutes (plus optional cloud extension) |
| **Environment** | A fresh Multipass VM named `cloudvm`, launched from your cloud-init file |
| **Files** | `cloud-init.yaml` (you edit it), `check-cloud.sh` (you `curl` and edit them inside `labvm` — see Setup Guide) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-cloud.sh` passing and your served page, plus a short writeup |

## Outcomes

By the end of this lab you will be able to:

- Explain what cloud-init / user-data is and why every major cloud uses it.
- Provision a Linux server declaratively instead of by hand.
- Configure SSH key-based authentication (the standard for cloud access).
- Recognize the "immutable / reproducible infrastructure" pattern used across the industry.

---

## Background: why this matters

When you click "launch instance" on AWS, GCP, Azure, or Oracle Cloud, there is a box labeled **"user data."** Whatever you put there is handed to cloud-init, which runs once on first boot. This is how real fleets of servers are built identically and automatically. Learning cloud-init is learning the actual mechanism behind cloud provisioning — not a toy version of it.

---

## Part A — Create an SSH key (the cloud way to log in)

Cloud servers do not use passwords; they use **key pairs**. You keep a private key secret on the machine you connect from; the server holds your public key. In this lab the machine you connect from is your laptop's host OS (macOS, Linux, or Windows 10+ — all ship with `ssh-keygen` and `ssh`). If you already created `~/.ssh/id_ed25519` for Module 2, that same key works here — skip to Part B.

**On your host computer's terminal** (skip the key-creation steps if you already made `~/.ssh/id_ed25519` for Module 2 — that same key works here):

**macOS / Linux:**

```
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "itsc1316"
```

**Windows (PowerShell):**

```
New-Item -ItemType Directory -Force -Path ~/.ssh | Out-Null
ssh-keygen -t ed25519 -f $HOME\.ssh\id_ed25519 -C "itsc1316"
# When it asks "Enter passphrase", press Enter twice to leave it empty.
```

(Windows OpenSSH manages `~/.ssh` permissions via ACLs — no `chmod` needed. PowerShell's `mkdir` doesn't accept `-p`, so we use `New-Item -Force`. We skip `-N ""` because PowerShell's argument-passing rules can strip or corrupt the empty quoted value depending on the version; pressing Enter twice at the interactive prompt is foolproof.) Then print your **public** key:

```
cat ~/.ssh/id_ed25519.pub
```

Copy the entire line (it starts with `ssh-ed25519` and ends with your comment). You will paste it into `cloud-init.yaml` next.

> **Never share or commit your *private* key** (`id_ed25519`, no `.pub`). The `.gitignore` in this repo blocks it; only the `.pub` (public) key goes into configs.

---

## Part B — Pull and edit the cloud-init template inside `labvm`

You'll edit the template *inside* `labvm` (which has `nano` and `curl` ready to go), then ferry the edited file out to your host so the next step's `multipass launch` can read it.

From your **host computer's terminal**:

```
multipass shell labvm
```

Inside `labvm`, fetch a fresh copy of the template:

```
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-13-cloud-computing/cloud-init.yaml
nano cloud-init.yaml
```

Make three edits in the file:

1. Replace **`PASTE_YOUR_PUBLIC_KEY_HERE`** with the public key you printed in Part A.
2. Replace both **`YOUR_NAME_HERE`** placeholders with your actual name.
3. Save with Ctrl+O, exit with Ctrl+X.

Read the comments in the file as you go — each block (`users`, `packages`, `write_files`, `runcmd`) maps to a real provisioning task.

When you're done editing, leave the file at `/home/ubuntu/cloud-init.yaml` inside `labvm` and return to your host:

```
exit
```

---

## Part C — Launch a server that builds itself

The `multipass launch` command runs on your **host** (multipass is a host tool), but your edited file lives in `labvm`. Copy it out into your current directory, then launch:

```
multipass transfer labvm:/home/ubuntu/cloud-init.yaml ./cloud-init.yaml
multipass launch 22.04 --name cloudvm --cpus 1 --memory 1G --cloud-init ./cloud-init.yaml
```

> **Why `./cloud-init.yaml` instead of `/tmp/cloud-init.yaml`?** A bare filename in the current directory works identically on macOS, Linux, and Windows PowerShell. `/tmp` is a POSIX-only path; on Windows it doesn't exist and the transfer would fail.

Multipass hands your file to cloud-init inside the new VM, exactly as a cloud provider would. Give it a minute to finish provisioning, then open a shell:

```
multipass shell cloudvm
```

Watch it confirm it provisioned itself:

```
cloud-init status --long
```

---

## Part D — Verify your self-built server

Inside `cloudvm`:

1. Confirm the user was created and is key-only:
   ```
   id clouduser
   sudo passwd -S clouduser     # should show the password is Locked
   ```
2. Confirm the web server installed itself and is serving your page:
   ```
   systemctl is-active nginx
   curl http://localhost/
   ```
   You should see your personalized HTML — the server you never touched by hand.
3. Pull and run the check script — same curl pattern as every other lab:
   ```
   curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/module-13-cloud-computing/check-cloud.sh
   bash check-cloud.sh
   ```

Fix any FAILs. **Note:** cloud-init runs only on *first* boot, so if you need to change the config, the cleanest fix is to delete and relaunch (re-edit `/home/ubuntu/cloud-init.yaml` inside `labvm`, then re-do the Part C transfer + launch):

```
# from your host:
multipass delete --purge cloudvm
multipass transfer labvm:/home/ubuntu/cloud-init.yaml ./cloud-init.yaml
multipass launch 22.04 --name cloudvm --cloud-init ./cloud-init.yaml
```

This "throw it away and rebuild it from config" loop is itself a core cloud habit — servers are cattle, not pets.

---

## Part E — Connect with your SSH key (prove key auth works)

Find cloudvm's IP from your **host terminal**: `multipass list`. Then from your host (where your private key lives), connect to `cloudvm` as `clouduser` — no password:

```
ssh -i ~/.ssh/id_ed25519 clouduser@<cloudvm-ip>
```

(The first time, SSH asks "are you sure you want to continue connecting?" — answer `yes`.) If you land in a shell without being asked for a password, you have configured key-based authentication exactly like a real cloud login.

---

## Optional Extension — Do it for real on free-tier cloud (bonus)

Want to prove the "platform-agnostic" claim with your own eyes? Spin up a real instance on a free tier and paste the **same** `cloud-init.yaml` into its **"user data"** box:

- **Oracle Cloud Always Free** — generous always-free ARM instance.
- **Google Cloud** — `e2-micro` free-tier instance, or use the $300 trial credit.
- **AWS** — `t2.micro`/`t3.micro` free tier (12 months).
- **DigitalOcean** — via the GitHub Student Pack credit.

Every one of these has a user-data field that feeds cloud-init. Your config will build the same server on their hardware. Open the instance's public IP in a browser and you should see your page on the public internet. **Tear it down when you are done** so you do not burn credits. Capture a screenshot for bonus credit and your portfolio.

> **Cost safety:** stay within free-tier limits, and **destroy the instance** when finished. Never leave a public instance running unattended.

---

## Evaluation (Required)

Inside `cloudvm`:

```
bash check-cloud.sh
```

All checks must pass.

---

## Writeup (submit this)

A few sentences each, in your own words:

```
CLOUD PROVISIONING WRITEUP — Module 13
Name:
cloudvm hostname (run `hostname`):

1. In your own words, what does cloud-init do, and why do cloud providers
   use it instead of having admins configure each server by hand?
2. Why do cloud servers use SSH keys instead of passwords? What is the risk
   of password login on an internet-facing server?
3. You rebuilt the server by deleting it and relaunching from the same config.
   Why is "rebuild from config" safer and more reliable than "log in and fix
   it by hand"?
4. (If you did the bonus) What was different, if anything, about running your
   config on a real cloud provider?
```

---

## Submission Requirement

1. A **60–90 second screen recording** made per the [Screen Recording Guide](../../docs/05-screen-recording-guide.md) (Alamo Zoom by default; one specific backup per OS if Zoom is broken) (webcam off; narration optional), showing in one continuous take: `hostname`, `cloud-init status`, `curl http://localhost/` displaying YOUR personalized page, and `bash check-cloud.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio.
2. Your completed **writeup** — this is where you explain what cloud-init did and why, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** AI is great for understanding cloud-init syntax — but your key, your name on the page, and your running server are yours. Note anything you asked AI and what you verified.

---

## Finish / Clean Up

```
multipass stop cloudvm
# or, to reclaim space once the cloud module is done:
multipass delete --purge cloudvm
```

Keep `labvm` (your main VM) — only `cloudvm` is disposable here.

---

## Final Checklist

- [ ] Generated an SSH key pair
- [ ] Edited `cloud-init.yaml` with your public key and your name (placeholders removed)
- [ ] Launched `cloudvm` with `--cloud-init`
- [ ] Confirmed `clouduser` exists and password login is locked
- [ ] Confirmed nginx installed itself and serves your personalized page
- [ ] Connected over SSH using your key (no password prompt)
- [ ] Ran `check-cloud.sh` and all checks PASS
- [ ] (Optional) Ran the same config on a real free-tier instance and tore it down
- [ ] Wrote the writeup
- [ ] Recorded the Zoom screen recording (webcam off)
- [ ] Submitted screencast + writeup

---

### On RHEL this would be…

cloud-init is **the same tool** on Red Hat–family systems — RHEL, Rocky, and Fedora cloud images all ship with it, and the user-data format is identical. The only differences you would adjust in the config: the package name might differ (`nginx` is the same, but some packages are named differently across `apt` and `dnf`), and on RHEL you would typically open the firewall with `firewall-cmd` rather than relying on Ubuntu defaults. The provisioning *model* — declarative config, first-boot automation, key-based access, rebuild-don't-repair — is universal across clouds and distros, and it is exactly what the Linux+ and cloud-adjacent certifications expect you to understand.
