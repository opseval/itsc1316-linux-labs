# GitHub & Git Primer (Get Your Own Copy of the Labs)

**Do this once, in the first week, before any lab.** Every lab in this course lives on **GitHub** and runs out of *your* copy of the repo. This guide walks you from "no GitHub account" to "I can clone, edit, commit, and push" in about 20 minutes. No prior git experience is assumed.

> **All of the git/gh/ssh work in this guide happens inside the [workstation VM](06-workstation-vm.md), not on your laptop's host OS.** That keeps the experience identical across macOS, Windows, and Linux. If you haven't set up workstation yet, do the [Workstation VM Guide](06-workstation-vm.md) first — it takes 5 minutes — and then come back here.

> **Why GitHub?** GitHub is the standard place where source code lives — it's where you'll get the lab files, where your own work will be version-controlled, and (if you choose) where it becomes the portfolio piece you show employers. Every Linux/cloud/DevOps job in 2026 expects you to know basic git and GitHub. This is the on-ramp.

---

## Part 1 — Make a GitHub account

You do this in your **laptop's browser**, not in workstation (workstation has no GUI).

1. Go to <https://github.com/signup>.
2. Use your **personal** email (one you'll keep after graduation), not your Alamo email — the account follows your career, not the school.
3. Pick a **professional username**. This is what shows up on every commit, every comment, every portfolio link. `firstname-lastname`, `flastname`, or `firstinitial-lastname` is the safe choice. Avoid joke names; you cannot easily rename later without breaking links.
4. Verify your email.
5. **(Strongly recommended) Enable two-factor authentication** under [Settings → Password and authentication](https://github.com/settings/security). GitHub requires 2FA for many features anyway; doing it now saves friction later.
6. **(Recommended) Apply for the [GitHub Student Developer Pack](https://education.github.com/pack)** with your ACES student email. It's free, comes with hundreds of dollars of developer tools (including DigitalOcean credit you can use for the Module 13 cloud lab's bonus extension), and gives you GitHub Pro free while you're a student.

---

## Part 2 — Get your own copy of the labs (the "Use this template" button)

Still in your **laptop's browser**. The course repo is a **template** — you don't work in the shared one, you make your own copy. This way your commit history is *your* learning record.

1. Open the course repo on GitHub (your instructor will give you the link).
2. Click the green **"Use this template"** button at the top → **"Create a new repository."**
3. Name it `itsc1316-labs-<yourname>` (e.g. `itsc1316-labs-aflores`).
4. Pick **Private** or **Public**:
    - **Private** — only you and people you invite can see it. Pick this if you're not sure yet; you can always make it public later.
    - **Public** — anyone with the link can see it. Pick this if you want it to become a portfolio piece (see [PORTFOLIO.md](../PORTFOLIO.md)).
5. Click **Create repository**.

You now have your own copy on GitHub. Next: get it onto workstation.

---

## Part 3 — Configure git inside workstation (one time)

Open a workstation shell from your host terminal:

```
multipass shell workstation
```

Your prompt is now `ubuntu@workstation:~$`. Tell git who you are — with the **same email you used on GitHub**:

```
git config --global user.name "Your Real Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global pull.rebase false
```

(That last line picks a sensible default for `git pull` so you don't get prompted later.) Verify:

```
git --version
git config --global --list | grep -E 'user\.|init\.|pull\.'
```

You should see your name, email, and the two extra defaults.

> No install needed — `git` was pre-installed when workstation booted. Same goes for `gh`, `ssh`, `ssh-keygen`, `scp`, `nano`, `vim`, and `curl`. That's the whole reason workstation exists.

---

## Part 4 — Log in to the GitHub CLI inside workstation

Still in your workstation shell:

```
gh auth login
```

Pick:
- **GitHub.com** (not GitHub Enterprise)
- **HTTPS** (easier than SSH for now)
- **Yes, authenticate Git with your GitHub credentials**
- **Login with a web browser**

`gh` will print a short code and a URL. **The URL must open in your laptop's browser** (workstation has no graphical browser). Copy the code, paste it on the GitHub page, click Authorize. The CLI on workstation will detect that you completed login and finish.

Verify:

```
gh auth status
```

---

## Part 5 — Clone your copy into workstation

Still in workstation, in your home directory:

```
cd ~
gh repo clone YOUR-USERNAME/itsc1316-labs-yourname
cd itsc1316-labs-yourname
ls labs/
```

You should see all the lab folders. The repo lives at `/home/ubuntu/itsc1316-labs-yourname/` inside workstation. Every later command in any lab that says "from the root of your cloned repo" means here.

> **If you prefer plain git over `gh`** (e.g. you didn't run `gh auth login`), this works too:
> ```
> git clone https://github.com/YOUR-USERNAME/itsc1316-labs-yourname.git
> ```
> The first push will ask you to authenticate. `gh auth login` is the simpler path because it handles that for you.

---

## Part 6 — The daily workflow (inside workstation)

This is the loop you'll run after every meaningful chunk of work — usually after each lab, sometimes after each significant step. **All four of these commands run inside workstation.**

```
git status              # what changed?
git add <file> ...      # stage the changes you want in the next commit
git commit -m "short, specific message"
git push                # send it to GitHub
```

### Examples

After finishing Module 6:

```
git add labs/module-06-users-and-permissions/notes.md PORTFOLIO.md
git commit -m "Module 6 complete: reflection + portfolio entry"
git push
```

After adding a screenshot:

```
git add screenshots/mod6-check-passing.png
git commit -m "Module 6: add evidence screenshot"
git push
```

### Tips

- **Commit messages should be specific.** "stuff" is useless six months from now. "Module 6 reflection: explain why 660 vs 640 matters" is the kind of message future-you will thank present-you for.
- **Commit early and often.** Small commits are easier to read, easier to undo, and tell a better story of your learning.
- **`git add .` is a foot-gun.** It stages everything, including things you didn't mean to commit (temp files, scratch work). Prefer naming the files explicitly until you're comfortable with `git status`.
- **`git status` is your best friend.** Run it before every `add`, before every `commit`, before every `push`.

---

## Part 7 — Things that bite people

- **Do not commit video files.** Zoom recordings are huge and GitHub rejects files over 100 MB. The repo's [`.gitignore`](../.gitignore) already blocks `*.mp4`, `*.mov`, `*.mkv`, etc.; if you want to share a recording, upload it to YouTube (unlisted) or Loom and paste the link in your submission instead.
- **Do not commit private keys or passwords.** The `.gitignore` blocks `id_rsa`, `id_ed25519`, `*.pem`, etc., but check `git status` before every commit. If you accidentally commit a secret, **rotate it immediately** (generate a new key, change the password) — git history is forever, and "deleting" a file just hides it in older commits.
- **Line endings.** Working inside workstation (an Ubuntu VM) means LF everywhere — same as the labs expect. The repo also ships a `.gitattributes` that forces LF for `*.sh`/`*.yaml`, so even if you ever edit on a Windows host the files stay correct.
- **"Permission denied (publickey)" on push.** You're using SSH but `gh auth login` set up HTTPS (or vice versa). Easiest fix: re-run `gh auth login` and pick HTTPS.
- **You forgot to `cd` into the repo.** Every git command must run inside the cloned folder. `git status` outside a repo says "not a git repository."
- **You confused workstation with labvm.** Workstation is for git/gh/editing/ssh. Labvm is for running `setup-*.sh` and `check-*.sh`. If `git status` complains and you're inside labvm by mistake, `exit` to get back to workstation.

---

## Part 8 — Updating from the template (if the instructor changes a lab)

If the course repo gets a bug fix or a new lab after you've already cloned, you can pull the changes into your copy. This is optional and only needed if your instructor announces an update. Run **inside workstation**:

```
git remote add upstream https://github.com/INSTRUCTOR-OR-ORG/itsc1316-linux-labs.git
git fetch upstream
git merge upstream/main
git push
```

You only need the first line (`remote add upstream`) once. After that, just the last three. If there are conflicts (rare for these labs), ask in the Q&A board.

---

## Quick reference card (all inside workstation)

```
# Setup (once)
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
gh auth login

# Get a copy (once)
gh repo clone YOUR-USERNAME/REPO

# Daily workflow
git status
git add path/to/file
git commit -m "short specific message"
git push

# See what's going on
git log --oneline       # recent commits
git diff                # unstaged changes
git diff --cached       # staged changes
```

---

## Where to learn more (optional)

- **[GitHub Docs](https://docs.github.com/en/get-started)** — official, kept current.
- **[Pro Git book](https://git-scm.com/book/en/v2)** — free, deep, the canonical reference.
- **[GitHub Skills](https://skills.github.com/)** — short interactive courses inside GitHub itself.

For these labs you only need Parts 1–6 above. The rest is here when you're curious.
