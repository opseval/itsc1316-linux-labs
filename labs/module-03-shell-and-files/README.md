# Module 3 Lab: Working with the Shell — Streams, Pipes, Variables, and Scripts (Multipass)

**Hands-on lab — runs on your own `labvm`. Replaces both the former Red Hat Academy Lab 3.07 (Managing Files in Linux) and the written "Understanding the Linux Shell" assignment.**

## Lab Overview

The shell is the single most important tool a Linux administrator uses, and almost everything an admin does is built from a few small ideas: programs read from **standard input** and write to **standard output** and **standard error**; those streams can be **redirected** into files or **piped** into other programs; **variables** hold values, and it matters whether a variable lives only in your shell or is **exported** into the environment your programs inherit; and when a task is too long to type by hand, you capture it in a **script** with variables, tests, and loops. In this lab you will do all of that for real on your own VM — redirect output and errors to separate files, build a pipeline, prove the difference between a shell variable and an environment variable, and then write a working Bash script that reports facts about *your* machine. You will also learn to find your own answers using `man`, `--help`, and `type`. This is the foundation every later lab assumes.

|  |  |
| --- | --- |
| **Estimated Time** | 60–90 minutes |
| **Environment** | Your Multipass `labvm` (Ubuntu 22.04) |
| **Scripts** | `setup-shell.sh`, `check-shell.sh` (in this folder of your cloned repo) |
| **Deliverable** | A 60–90 second Zoom screen recording (webcam off) showing `check-shell.sh` passing, plus your written component (short answers below) |
| **Key Location** | `~/mod03` (lab files) and `~/sysreport.sh` (the script you write) |

## Outcomes

By the end of this lab you will be able to:

- Distinguish **stdout** (FD 1), **stderr** (FD 2), and **stdin** (FD 0), and redirect each one independently (`>`, `2>`, `>>`, `<`).
- Build a **pipeline** with `|` and explain why a pipe is better than a temporary file for chaining commands.
- Set a **shell variable** and an **exported environment variable**, and show, with evidence, why a child process sees one but not the other.
- Write and run a real **Bash script** that uses a variable, takes an argument, makes a decision with an `if` test, repeats work with a `for` loop, and writes output to a file.
- Find authoritative help on your own using `man` (and its section numbers), `--help`, and `type` (to tell a shell **builtin** from an **external** command).

---

## Start the Lab Environment

From your computer's terminal, **at the root of your cloned repo**, start the VM and transfer the two scripts in (do these *before* opening the VM shell — `multipass` doesn't exist inside the VM):

```
multipass start labvm
multipass transfer labs/module-03-shell-and-files/setup-shell.sh labvm:/home/ubuntu/
multipass transfer labs/module-03-shell-and-files/check-shell.sh labvm:/home/ubuntu/
```

Now open a shell inside the VM and seed the lab files:

```
multipass shell labvm
sudo bash setup-shell.sh
```

This creates `~/mod03/` containing `servers.csv` (a small fake server inventory) and `existing.txt`. Nothing here is broken — this lab is about *doing* shell work, so the setup just hands you real files to operate on.

> **Tip — work in the lab directory.** Most steps assume you are in `~/mod03`. Start with `cd ~/mod03`. The script you write in Part 4 lives in your home directory (`~/sysreport.sh`), so you will `cd ~` for that part.

---

## Instructions

You will produce several files. The check script looks for them by name and inspects their **contents**, so type the commands on *your* VM and let your machine generate the output — you cannot fabricate this from memory.

### Part 1 — Standard streams and redirection

Every command has three streams: input comes in on **stdin** (file descriptor 0), normal output goes out on **stdout** (FD 1), and error messages go out on **stderr** (FD 2). They are separate on purpose, so you can capture results without mixing in the errors.

**1a. Generate both streams at once.** From `~/mod03`, run a single `ls` that names one file that exists and one that does not:

```
cd ~/mod03
ls -l servers.csv nope-does-not-exist.txt
```

You will see the listing for `servers.csv` (that went to **stdout**) and a "No such file or directory" message (that went to **stderr**). They printed together on your screen, but they are different streams.

**1b. Split the streams into two files.** Run the same command, but send stdout to one file and stderr to another:

```
ls -l servers.csv nope-does-not-exist.txt > out.txt 2> err.txt
```

Now `cat out.txt` (the successful listing) and `cat err.txt` (the error). Notice your screen showed *nothing* — both streams were redirected. `2>` specifically redirects file descriptor 2, stderr.

**1c. Append instead of overwrite.** `>` replaces a file's contents; `>>` adds to the end. Append a second error to the same error file by running a command that fails again:

```
ls -l another-missing-file >> out.txt 2>> err.txt
```

Confirm with `cat err.txt` that it now contains **two** error lines, and `out.txt` still has the original listing (appending did not erase it).

> **Why this matters:** when you run a long job overnight, you redirect its output to a log and its errors to a separate error log. In the morning you read the short error log first. Mixing them would bury the one line that mattered.

### Part 2 — Pipes

A **pipe** (`|`) connects the stdout of one command directly to the stdin of the next, with no file in between. Build this pipeline from `~/mod03` to count how many distinct roles appear in the inventory, then save the count:

```
cut -d, -f2 servers.csv | tail -n +2 | sort | uniq | wc -l > role-count.txt
```

Read it back with `cat role-count.txt`. Then build a second pipeline that lists the **usernames** on your own system and counts them, saving the number:

```
cat /etc/passwd | cut -d: -f1 | sort | wc -l > user-count.txt
```

`cat role-count.txt` and `cat user-count.txt` should each show a single number.

> **Why a pipe beats a temp file:** you *could* do this in stages — write `cut` output to a temp file, `sort` that into another temp file, and so on — but each temp file is extra disk I/O, extra cleanup, and a chance to leave junk behind. A pipe streams the data through memory in one line, and the OS runs the stages concurrently. You will use this idea constantly.

### Part 3 — Shell variable vs. environment variable

A plain assignment creates a **shell variable** — it exists only in your current shell. `export` turns it into an **environment variable**, which every child process (a script, another shell, a program you launch) inherits. Prove the difference.

**3a.** Set one of each:

```
SHELLONLY="i-live-only-here"
export ENVVAR="i-get-inherited"
```

**3b.** Launch a *child* Bash shell and ask it what it can see:

```
bash -c 'echo "child sees ENVVAR=[$ENVVAR] and SHELLONLY=[$SHELLONLY]"'
```

The child prints a value for `ENVVAR` but an **empty** `SHELLONLY` — because the shell variable was never exported into the environment the child inherited.

**3c.** Capture this evidence to a file the checker will read. Re-export the variable in the same command line so the file reflects a true run:

```
export ENVVAR="i-get-inherited"
bash -c 'echo "ENVVAR=$ENVVAR"; echo "SHELLONLY=$SHELLONLY"' > ~/mod03/varproof.txt
cat ~/mod03/varproof.txt
```

`varproof.txt` should show `ENVVAR=i-get-inherited` on one line and `SHELLONLY=` (empty) on the other.

> **Why this matters:** misconfigured environment variables are one of the most common reasons "it works when I type it but the script can't find it." If your script needs a value, the value must be *exported* (or set inside the script), not just typed at your prompt.

### Part 4 — Write a real Bash script (the centerpiece)

You will write `~/sysreport.sh`. When run, it writes a **one-line CSV** of facts about *this* machine — its hostname, kernel version, and the current date — to an output file. It must use a variable, accept an argument, make a decision with an `if` test, and use a `for` loop. Open it in an editor (`nano ~/sysreport.sh`) and write something like the following. **Type it yourself** — you learn the shell by writing it, and you will be asked in the writeup what it does.

```bash
#!/usr/bin/env bash
# sysreport.sh — write a one-line CSV of facts about THIS machine.
# Usage: ./sysreport.sh [output-file]
# If no output file is given, it defaults to ~/sysreport.csv

# A variable holds the default output path.
OUTFILE="${HOME}/sysreport.csv"

# Read an argument: if the user passed a filename, use it instead (if-test).
if [[ -n "$1" ]]; then
  OUTFILE="$1"
fi

# Gather real facts about this machine.
HOST="$(hostname)"
KERNEL="$(uname -r)"
TODAY="$(date '+%Y-%m-%d')"

# Write the CSV header and one data row.
echo "hostname,kernel,date" > "$OUTFILE"
echo "${HOST},${KERNEL},${TODAY}" >> "$OUTFILE"

# A for-loop: confirm each field is non-empty and report.
for field in "$HOST" "$KERNEL" "$TODAY"; do
  if [[ -z "$field" ]]; then
    echo "WARNING: a field came back empty" >&2
  fi
done

echo "Wrote report for ${HOST} to ${OUTFILE}"
```

Make it executable and run it using its execute bit (not `bash sysreport.sh`, which would bypass the permission you set):

```
chmod +x ~/sysreport.sh
cd ~
./sysreport.sh
cat ~/sysreport.csv
```

`sysreport.csv` should contain a header line and one data row whose first field is **your VM's real hostname** (the same value `hostname` prints). The checker compares them.

> **Why this matters:** a script captures a procedure once so it runs the same way every time, on any machine, without you retyping it. The `if` lets it adapt (use a custom output file if asked); the `for` lets it check every field without copy-paste; the variable means you change the default in one place. That is the difference between *typing commands* and *automating a task*.

### Part 5 — Finding help (documentation)

Administrators look things up constantly. Practice the three core ways, and record what you find into an evidence file.

**5a.** Read a manual page and note its **section number**. The `passwd` name appears in two sections — the command (section 1) and the file format (section 5). Open the file-format page explicitly:

```
man 5 passwd
```

(Press `q` to quit.) The header shows `PASSWD(5)`. The number in parentheses is the man section: 1 = user commands, 5 = file formats, 8 = admin commands.

**5b.** Use `--help` for a quick summary instead of the full manual:

```
ls --help | head -n 5
```

**5c.** Use `type` to tell a **builtin** from an **external** command. `cd` is built into the shell; `ls` is a separate program on disk:

```
type cd
type ls
```

`type cd` reports that `cd` is a shell builtin; `type ls` reports a path like `/usr/bin/ls` (or an alias to it). Now write your evidence file in one command:

```
{ echo "=== Module 3 docs evidence ==="; \
  echo "hostname: $(hostname)"; \
  echo "man section for the passwd FILE format: 5"; \
  echo "--- type cd ---"; type cd; \
  echo "--- type ls ---"; type ls; } > ~/mod03/docs-evidence.txt
cat ~/mod03/docs-evidence.txt
```

This `docs-evidence.txt` must contain your real hostname and the output of `type cd` (showing it is a builtin). The checker verifies both.

> **Why builtin vs. external matters:** `cd` *has* to be a builtin — it changes the current directory of the shell itself, and an external program can't reach back and change its parent's directory. Knowing whether a command is a builtin tells you where to read its docs (`help cd` for builtins, `man ls` for externals).

---

## Evaluation (Required)

Grade your own work by running the check script inside the VM:

```
bash check-shell.sh
```

It prints PASS or FAIL for each requirement. Correct any FAILs and run it again until everything passes. This is exactly what an administrator does after writing a script — run it, read the result, fix, re-run.

---

## Written Component (submit this)

This replaces the conceptual "Understanding the Linux Shell" assignment, so it is where your reasoning lives. Answer each in 2–4 sentences, **in your own words**:

```
WRITTEN COMPONENT — Module 3
Your name:
VM hostname (run `hostname`):

1. Streams vs. pipes.
   Explain the difference between standard output and standard error, and
   give a concrete reason (from Part 1) you would want them in separate
   files. Then explain what a pipe (`|`) does that redirecting to a temp
   file does not.

2. Shell variable vs. environment variable.
   Using your Part 3 result (varproof.txt), explain why the child shell
   could see ENVVAR but not SHELLONLY. What does `export` actually do?

3. What your script does that manual typing does not.
   Describe what ~/sysreport.sh does, and name two things it gives you that
   typing the same commands by hand each time would not (think: the if-test,
   the for-loop, the variable, repeatability).

4. Finding help.
   What is the difference between a shell builtin and an external command,
   and how did `type` let you tell `cd` from `ls`? Why does the man page
   section number (e.g. passwd(1) vs passwd(5)) matter?

5. AI note (required by the AI policy below):
   One line — what (if anything) you asked an AI, and what you verified
   yourself on your VM.
```

---

## Submission Requirement

Submit **two things** to Canvas:

1. A **60–90 second screen recording** made with your **Alamo Colleges Zoom account** (webcam off; narration optional), showing in one continuous take: `hostname`, `whoami`, and `bash check-shell.sh` passing. Submit the **Zoom Cloud link** if available (otherwise the `.mp4`); keep your own copy for a possible portfolio. See Setup Guide, Part 4.
2. Your completed **written component** (the five answers above) — this is where you explain your reasoning, so the recording does not need narration.

> **AI policy for this lab: AI-OPEN.** You may use an AI assistant to explain a redirection operator, a pipe, or a Bash construct — include a one-line note of what you asked and what you verified yourself (answer 5 above). An AI cannot see your VM's real output: it does not know your machine's hostname, how many users are in *your* `/etc/passwd`, or what `type ls` resolves to on *your* system. The checker reads those real values out of your files, and the screencast shows them coming from your machine — that is how we know the work is yours.

---

## Finish / Clean Up

You can leave the scenario in place. To free up resources between sessions without losing your work:

```
multipass stop labvm
```

Do **not** delete `labvm` — later labs reuse it.

---

## Final Checklist

- [ ] Ran `setup-shell.sh` to seed `~/mod03`
- [ ] Part 1: created `out.txt` and `err.txt` with stdout and stderr separated, and appended a second error
- [ ] Part 2: created `role-count.txt` and `user-count.txt` from pipelines
- [ ] Part 3: created `varproof.txt` showing ENVVAR set and SHELLONLY empty in the child shell
- [ ] Part 4: wrote `~/sysreport.sh`, made it executable, ran it, and produced `~/sysreport.csv` with your real hostname
- [ ] Part 5: created `~/mod03/docs-evidence.txt` containing your hostname and `type cd` output
- [ ] Ran `check-shell.sh` and all checks PASS
- [ ] Recorded the Zoom screen recording (webcam off; hostname + whoami + passing check)
- [ ] Wrote answers to all five written-component questions
- [ ] Submitted screencast + written component to Canvas

---

### On RHEL this would be…

Everything in this lab is core Linux and behaves **identically** on Red Hat–family systems (RHEL, Rocky, Fedora): the streams, `>`/`2>`/`>>`, pipes, `export`, `if`/`for`, `man`, `--help`, and `type` are all part of Bash and the GNU coreutils, which ship on both. The main thing you would notice is the **default shell and login files**: Ubuntu and RHEL both default to Bash, but RHEL's per-user file is `~/.bash_profile` (read at login) in addition to `~/.bashrc`, whereas Ubuntu leans on `~/.bashrc` via `~/.profile`. If you ever land on a system whose login shell is **zsh** (the macOS default, and an option on Linux), the same redirection and pipe operators work, but variable-export syntax and startup files (`~/.zshrc`) differ — which is exactly why knowing *which* shell you are in (`echo $0`, `type`) matters.
