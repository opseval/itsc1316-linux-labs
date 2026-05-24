# Lab Zero: Preflight Check (Week 1)

**Do this in the first week, before any graded lab. It takes about ten minutes and saves you from discovering in week 6 that your laptop can't run the labs.**

This check confirms that your computer can do everything the labs require: launch a virtual machine, copy files into it, run commands inside it, and reach the internet from it. You will run one script that spins up a tiny throwaway VM, tests the whole workflow, and deletes it automatically.

---

## Step 1 — Install Multipass

If you have not already, install Multipass for your platform using the **[Multipass Setup Guide](01-multipass-setup-guide.md)** (Part 1). Come back here when `multipass version` works in your terminal.

---

## Step 2 — Get the preflight script

Fetch the script for your OS straight from the course repo (no clone needed — these one-liners drop the file into your current directory):

### macOS / Linux / WSL

```
curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/scripts/preflight/preflight.sh
```

### Windows (PowerShell)

```
curl.exe -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/scripts/preflight/preflight.ps1
```

> **Why `curl.exe` and not `curl` on Windows?** Windows 10/11 ships actual curl as `curl.exe`, but PowerShell aliases the bare word `curl` to its own `Invoke-WebRequest`, which doesn't understand `-fsSLO`. Using `curl.exe` explicitly bypasses the alias and gets you the real tool.

---

## Step 3 — Run it

### macOS / Linux / WSL

In the same terminal you just downloaded into:

```
bash preflight.sh
```

### Windows

In the same PowerShell window:

```
powershell -ExecutionPolicy Bypass -File .\preflight.ps1
```

The first run downloads Ubuntu, so give it a few minutes. You will see a series of `[PASS]` / `[FAIL]` lines and a summary at the end. The script **cleans up the test VM automatically** — you do not need to delete anything.

---

## Step 4 — Submit your result

Take a **screenshot of the summary block** at the end (the part that says `Passed: … Failed: …` and `RESULT: …`) and submit it to the Week 1 Preflight Check assignment in Canvas.

- **All PASS** → you are ready. 
- **Any FAIL** → check the **[Multipass Troubleshooting Guide](02-multipass-troubleshooting.md)** first (the FAIL table below points you to the right section — VPN issues are the most common). If that doesn't resolve it, post the full output in the **Q&A Discussion Board** right away. We will sort it out together long before it can affect a grade. This is exactly what the first week is for.

---

## What each check means (and what to do if it fails)

| Check | What it proves | If it FAILs |
| --- | --- | --- |
| Multipass installed | The tool every lab uses is present | Re-do Part 1 of the Setup Guide; reboot. |
| Launched a test VM | Your machine can run virtual machines | Most common on Windows: enable virtualization in BIOS/UEFI, or enable Hyper-V (Pro) / install VirtualBox (Home). On any machine: free up RAM/disk. |
| Transferred a file in | You can move lab scripts into the VM | Usually a transient issue — re-run. If it persists, post the output. |
| Ran a command inside | You can operate the VM | Re-run; if it persists, the VM may not have booted fully. |
| sudo works | You can perform admin tasks the labs require | Rare; post the output. |
| Internet from the VM | Labs that install packages will work | Often a VPN or restricted network. Try off the campus/work VPN. |

---

## If your computer simply can't run a VM

Some machines — locked-down work laptops, very old hardware, certain Chromebooks — genuinely cannot run Multipass. **You are not stuck and you will not be penalized.** Go to **Part 7 — Cloud Fallback** in the [Setup Guide](01-multipass-setup-guide.md): you can do every lab on a free cloud VM instead, using the same commands. If the cloud options do not work for you either, contact your instructor in week 1 to discuss options. The only wrong move is to wait until the work is due to find out.
