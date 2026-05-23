# Module 2 Lab: Accessing a Linux System (Multipass)

**Hands-on lab — runs on your own `labvm`. Replaces the former Red Hat Academy Lab 2.05 (Accessing a Linux System).**

## Lab Overview

Before you can administer a server you have to get *into* it — and on a real system there is rarely just one door. In this lab you access your VM two different ways (the local Multipass shell and a remote SSH session), then do the kind of account housekeeping every admin handles on a new machine: setting passwords for two new user accounts and confirming the system's clock is synchronized with a time server. Along the way you practice the single most important survival skill in Linux — finding out what a command does from the system's own built-in documentation — and you reason about how to leave a session safely. This mirrors RHA Lab 2.05, adapted to Ubuntu and Multipass with the same rigor.

|  |  |
| --- | --- |
| **Estimated Time** | 40–60 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-access.sh`, `check-access.sh` (in this folder of your cloned repo) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-access.sh` passing, plus your completed `module2-access-notes.txt` with its written reflection |
| **New Accounts** | `devops1`, `devops2` |
| **Evidence File** | `~/module2-access-notes.txt` |

## Outcomes

By the end of this lab you will be able to:

- Differentiate GUI vs CLI access and judge when each is appropriate.
- Access a Linux system more than one way (local console and remote SSH) and open a terminal session.
- Execute basic Bash commands safely and interpret their output and errors.
- Manage user passwords with `sudo passwd` and switch users with `su -`.
- Verify and explain time synchronization with `timedatectl`.
- Locate and use built-in documentation with `man`, `--help`, and `type`.
- Log out and shut down properly, and explain the difference.

---

## Start the Lab Environment

From your computer's terminal, **at the root of your cloned repo**, start the VM and transfer the two scripts in (do these *before* opening the VM shell):

```
multipass start labvm
multipass transfer labs/module-02-accessing-a-linux-system/setup-access.sh labvm:/home/ubuntu/
multipass transfer labs/module-02-accessing-a-linux-system/check-access.sh labvm:/home/ubuntu/
```

Open a shell inside the VM and build the scenario:

```
multipass shell labvm
sudo bash setup-access.sh
```

This creates two extra users — `devops1` and `devops2` — whose passwords are **deliberately left locked/unset**. Setting them is part of the lab. It also drops a notes template at `~/module2-access-notes.txt` and makes sure the time daemon is running. (No snapshot needed; nothing destructive happens here.)

---

## Instructions

Fill in your real output/answers in `~/module2-access-notes.txt` as you go (`nano ~/module2-access-notes.txt`; save with Ctrl+O, exit with Ctrl+X).

**1. Access the VM two different ways.**
You're already in `labvm` via the local Multipass shell — confirm it by running `who` and noting your session. Now you'll set up SSH access so you can log in like a remote admin from your **workstation VM**. Multipass injects its *own* SSH key into `labvm` (which is what makes `multipass shell` work), but it does **not** trust the workstation's key — so a bare `ssh ubuntu@labvm` from workstation will be refused. You have to authorize workstation's key on labvm first.

If you haven't already done the one-time bootstrap from the [Workstation VM Guide](../../docs/06-workstation-vm.md#part-3--reaching-the-other-lab-vms-from-workstation), do it now (these two commands run on your **host computer's terminal**, not inside any VM — they need access to `multipass`):

```
multipass transfer workstation:/home/ubuntu/.ssh/id_ed25519.pub labvm:/tmp/ws.pub
multipass exec labvm -- bash -c \
  'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat /tmp/ws.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/ws.pub'
```

(If you've never generated `id_ed25519` inside workstation, do `multipass shell workstation` and run `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519` first, then come back and run the two host commands.)

Then, in a **second terminal on your computer**, enter workstation and SSH from there into labvm:

```
multipass shell workstation                # in the new terminal
# inside workstation:
multipass_labvm_ip=$(getent hosts labvm 2>/dev/null | awk '{print $1}')
echo "labvm IP from workstation: ${multipass_labvm_ip:-<run 'multipass list' on host>}"
ssh ubuntu@labvm                            # uses workstation's key — no password
```

> If `getent hosts labvm` returns nothing inside workstation, Multipass hasn't registered the name in workstation's DNS. Get labvm's IP from your **host** terminal (`multipass list`) and use the IP directly: `ssh ubuntu@10.x.x.x`.

Once connected over SSH, run `who` on labvm — you should see *two* sessions: the original Multipass shell session AND a `pts/` line for the SSH session from workstation. Record the IP you connected to and paste the `who` line that shows the SSH session.

> **Why bother?** `multipass shell` is a special case — it's like sitting at the machine's console because Multipass owns the box. SSH is how you actually reach any real server, on any cloud, anywhere on the internet. The three pieces — generate a key, authorize it on the server, then connect — are the same on every Linux box you will ever administer, including the Module 13 cloud lab where you do this on a real cloud instance.

**2. Set passwords for the two new users.**
The setup left `devops1` and `devops2` with locked passwords. Set each one:

```
sudo passwd devops1
sudo passwd devops2
```

Then confirm each password is now **set** (status `P`):

```
sudo passwd -S devops1
sudo passwd -S devops2
```

The second field of that output is the status: **`P`** = password set, **`L`** = locked, **`NP`** = none. Record both status lines.

Now practice switching users with `su -` (this is how you become another account):

```
su - devops1
whoami
exit          # returns you to your own session
```

Record one line about what `su - devops1` did and how you returned.

> **Why `su -` (with the dash)?** The dash gives you a *login* shell — devops1's environment, home directory, and PATH — instead of just changing your user ID while keeping your own environment. It is the difference between visiting as that user properly versus halfway.

**3. Verify and explain time synchronization.**
Run:

```
timedatectl
timedatectl show | grep -i ntp
```

Confirm the clock is synchronized — you want to see **`System clock synchronized: yes`** and **`NTP service: active`** (and `NTPSynchronized=yes` in the `show` output). If it isn't on, enable it with `sudo timedatectl set-ntp true`, wait a few seconds, and check again. Record the relevant lines.

> **Why a server cares about time:** logs, scheduled jobs, TLS certificates, Kerberos tickets, and distributed systems all assume an accurate clock. A drifted clock can make certificates appear expired, break authentication, and scramble the order of events across machines — which is a nightmare during an incident.

**4. Use the system's built-in documentation.**
Pick any command you're curious about (say `cp`). Learn about it three ways and record what each tells you:

```
type cp           # is it a shell builtin or an external program? where does it live?
cp --help         # quick usage summary
man cp            # the full manual page — read the NAME and a few options
```

Record the command you chose, whether `type` says it's a builtin or external, one useful line from `--help`, and the one-line NAME description from `man`.

> **Why this is the most important skill in the course:** you will never memorize every option of every command. Knowing how to ask the system itself — `man`, `--help`, `type` — is what separates someone who can work on an unfamiliar box from someone who is stuck.

**5. Logout vs. shutdown — understand the difference (don't power off yet).**
You end a session with `logout` or `exit`; you turn the whole machine off with `sudo poweroff` (or `sudo shutdown`). On a server those are *very* different acts: logging out leaves the machine and all its services running for everyone else, while powering off takes the entire system — and everyone depending on it — down. **Do not actually power off mid-lab.** Just record, in one sentence, the difference.

---

## Evaluation (Required)

This check reads `/etc/shadow` (through `passwd -S`) to verify the passwords are really set, so it needs root. Run it with sudo inside the VM:

```
sudo bash check-access.sh
```

It prints PASS/FAIL for: both users existing, both passwords actually set (status `P`), NTP synchronization active, and your evidence file containing the required tokens (including this VM's hostname). Fix any FAILs and run it again until everything passes.

> **Why the check needs your live system:** it doesn't trust your notes for the security-relevant facts — it checks `/etc/shadow` directly and queries `timedatectl` on the running machine. You can't fake a set password or an active NTP sync in a text file.

---

## Written Reflection (in `module2-access-notes.txt`)

Answer all three at the bottom of your notes, in your own words, a few sentences each:

1. **GUI vs CLI:** describe one situation where the command line is clearly the right tool and one where a GUI is, and explain why for each.
2. **Time sync:** why does keeping a server's clock synchronized with a time server actually matter? Give one concrete consequence of a wrong clock.
3. **Docs:** for the command you researched in Task 4, name one thing you learned from `man` or `--help` that you didn't already know.

---

## Submission Requirement

Submit **two things** to Canvas:

1. A **60–90 second screen recording** made per the [Screen Recording Guide](../../docs/05-screen-recording-guide.md) (Alamo Zoom by default; one specific backup per OS if Zoom is broken) (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `sudo bash check-access.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio.
2. Your completed **`module2-access-notes.txt`**, including the written reflection — this is where your reasoning lives, so the recording does not need narration. (Copy it out with `multipass transfer labvm:/home/ubuntu/module2-access-notes.txt .` from your computer's terminal.)

> **AI policy for this lab: AI-OPEN.** You may ask an AI assistant how `ssh`, `passwd`, `su`, or `timedatectl` work — include a one-line note of what you asked and what you verified yourself. But an AI can't connect to *your* VM, can't see your real IP, can't set a password in your `/etc/shadow`, and can't read your clock's sync state. The check confirms those on the live system, so the work has to be yours.

---

## Finish / Clean Up

Leave everything in place. To free resources between sessions without losing your work:

```
multipass stop labvm
```

Do **not** delete `labvm` — later labs reuse it (including the accounts you just configured).

---

## Final Checklist

- [ ] Ran `setup-access.sh` to create `devops1`/`devops2` and the notes template
- [ ] Accessed the VM via `multipass shell` AND via `ssh ubuntu@<ip>`, with evidence of each
- [ ] Set passwords for `devops1` and `devops2` with `sudo passwd`
- [ ] Confirmed both show status `P` with `sudo passwd -S`
- [ ] Practiced `su - devops1` and returned with `exit`
- [ ] Verified time sync with `timedatectl` (`System clock synchronized: yes`)
- [ ] Researched a command with `type`, `--help`, and `man` and recorded it
- [ ] Recorded the logout-vs-shutdown distinction (without powering off)
- [ ] Replaced every `<...>` placeholder in the notes file
- [ ] Wrote all three reflection answers
- [ ] Ran `sudo bash check-access.sh` and all checks PASS
- [ ] Recorded the Zoom screen recording (webcam off; hostname + whoami + passing check)
- [ ] Submitted the recording + completed notes to Canvas

---

### On RHEL this would be…

The access and account commands are identical on Red Hat–family systems (RHEL, Rocky, Fedora): `ssh`, `who`, `passwd`, `passwd -S`, `su -`, `man`, `--help`, `type`, `timedatectl`, `logout`, and `poweroff` all behave the same. Two differences worth knowing for a certification exam: on a cloud RHEL image the default login account is often **`ec2-user`**, **`cloud-user`**, or **`rocky`** rather than Ubuntu's `ubuntu`; and where Multipass auto-injects your SSH key, on RHEL you typically supply the key yourself (`ssh -i key.pem ...`) or run `ssh-copy-id`. Time sync on modern RHEL is usually handled by **`chronyd`** (checked with `chronyc sources`) in addition to `timedatectl`, whereas Ubuntu uses `systemd-timesyncd` — but `timedatectl` reports the synchronized state on both.
