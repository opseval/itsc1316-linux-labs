# Screen Recording Guide (Zoom Primary + Limited Backups)

Every lab in this course is submitted with a **60–90 second screen recording**. This guide is the single source of truth for **how** to make that recording: which tool, what must be on screen, how to submit, and what to do if Zoom isn't working.

> **One-line summary.** Use Alamo Colleges Zoom by default (you already have it; the link option is what we want). If Zoom is broken for you, fall back to **one specific tool per platform** listed in [Part 4](#part-4--backups-only-if-zoom-fails). Do not use anything else — unlisted tools waste grader time chasing format problems and may not even be admissible (see [Grading Rubric, Criterion 2](04-grading-rubric.md#criterion-2--screen-recording)).

---

## Part 1 — What every recording must show

Every lab grader is looking for the same three things on screen, in this exact order, in **one continuous take** (no edits, no stitching, no cuts):

1. **`hostname`** — proves it's your VM.
2. **`whoami`** — proves it's you running it.
3. **`bash check-*.sh`** (or `sudo bash check-*.sh` if the lab says so) — runs to completion, prints its **`=== check script integrity ===`** block with a SHA256 visible on screen (the grader verifies this against [`labs/CHECKSUMS.txt`](../labs/CHECKSUMS.txt)), and ends with a **"Passed: N  Failed: 0"** line plus the **"ALL CHECKS PASSED"** banner.

That sequence alone is enough to satisfy [Criterion 2](04-grading-rubric.md#criterion-2--screen-recording) of the rubric. Anything before / after is optional. **Webcam OFF; narration optional.**

> **About the SHA256 line.** The check script prints its own SHA256 right after the title, so the grader can verify you didn't modify the script to hide a failed check. **Do not edit the check script.** If you did by accident, replace it from a fresh `git pull` (inside workstation: `cd ~/itsc1316-labs-yourname && git checkout labs/<lab-folder>/check-*.sh`). A mismatched SHA is graded as academic-integrity and scores the whole submission 0.

> **Why "continuous take"?** A stitched recording could be assembled from multiple machines, multiple runs, or someone else's work. A single take with your live hostname is the simplest credible proof the work happened on your machine just now.

---

## Part 2 — The primary tool: Alamo Colleges Zoom

You already have an enterprise **Zoom** account through Alamo Colleges. Use that account, not a personal Zoom account.

### One-time setup

1. Open the **Zoom desktop app** (download from <https://zoom.us/download> if you don't have it).
2. **Sign In With SSO** → enter `alamo` as the company domain → log in with your **ACES** credentials.
3. Confirm you're signed into the right account: top-right shows your name + the Alamo institutional badge.

### Per-recording workflow

1. **New Meeting** (do not invite anyone).
2. **Turn your webcam OFF.** We do not want video of you, only the screen.
3. **Share Screen** → pick the terminal window where your VM shell is open. Share the **specific window**, not the whole desktop, so personal notifications don't appear in the recording.
4. **Record →** ideally **"Record to the Cloud"** if your Alamo account offers it (gives you a shareable link to submit; no large file to upload).
   - If you only see "Record on this Computer", that's fine — you'll submit the `.mp4`.
5. Run the three required commands in order: `hostname`, `whoami`, `bash check-*.sh`. Wait for the PASS banner.
6. **Stop Recording**, then **End Meeting for All**.

### Submitting (preference order)

1. **Preferred — Zoom Cloud link.** When the recording finishes processing (you'll get an email), open it in Zoom's web UI, copy the **share link**, and paste it into the Canvas assignment. Easiest for everyone; nothing large to upload.
2. **Acceptable — local `.mp4`.** If you recorded to your computer, Zoom saves an `.mp4` when the meeting ends. Upload it to the Canvas assignment.

> **Keep your own copy of the `.mp4` either way.** Cloud recordings can age out of institutional storage; a clip of you fixing or building a real system is exactly the kind of thing you may want later for your [portfolio](../PORTFOLIO.md). Make an "ITSC-1316 recordings" folder on your computer and drop each one in. (Don't commit them to your Git repo — the [`.gitignore`](../.gitignore) blocks `*.mp4` on purpose.)

---

## Part 3 — Privacy check before you hit Record

Anything visible while you record is visible to your grader. Before sharing your screen:

- **Close personal email, messaging apps, and any browser tabs you wouldn't show your boss.**
- **Silence notifications.** macOS: enable Focus / Do Not Disturb. Windows: turn on Focus Assist (Settings → System → Focus Assist → Alarms only). Linux: most desktops have a "Do Not Disturb" toggle in the top bar.
- **Share the terminal window only**, not the full desktop, so anything that pops up elsewhere is not captured.

This is also the habit you'll want at any tech job: don't expose anything in a recording or screenshot that you wouldn't put on a public page.

---

## Part 4 — Backups (only if Zoom fails)

If Zoom is genuinely broken for you (sign-in loop, cloud recording disabled by IT, app won't install, etc.), use **exactly one** of the following — whichever matches your platform. **Do not use any other tool.** The grader has trained on these formats; anything else risks a lower [Criterion 2](04-grading-rubric.md#criterion-2--screen-recording) score because the recording may not play or may not be admissible.

> Before you reach for a backup: try restarting Zoom and re-running the workflow once. Most Zoom problems clear on a restart.

### macOS — QuickTime Player (built-in)

1. Spotlight (⌘ Space) → **QuickTime Player**.
2. Menu: **File → New Screen Recording** (or press ⌘ ⇧ 5).
3. Pick **Selected Window** and click your terminal window. Make sure **Microphone** is OFF (you don't need narration) and **Show Mouse Clicks** is fine either way.
4. Click **Record** → run `hostname`, `whoami`, `bash check-*.sh` → click ⏹ in the menu bar.
5. **File → Save** as `<your-name>-mod<N>.mov` or export as `.mp4`. Upload to Canvas.

### Windows — Xbox Game Bar (built-in, no install)

1. Press **Win + G** to open the Game Bar.
2. In the **Capture** widget, click the **● Record** button (or **Win + Alt + R**) — this records the focused window.
3. Run `hostname`, `whoami`, `bash check-*.sh` in your terminal/PowerShell window.
4. Press **Win + Alt + R** again to stop. The clip is in `C:\Users\<you>\Videos\Captures\` as an `.mp4`.
5. Upload that `.mp4` to Canvas.

> **Game Bar gotcha.** It records the *focused window* — if you click outside the terminal mid-recording, it stops. Stay in the terminal until you press the stop hotkey.

### Linux — OBS Studio (one-time install, reliable)

1. Install OBS:
   ```
   sudo apt update && sudo apt install -y obs-studio        # Ubuntu / Debian / Mint / WSL2-with-GUI
   sudo dnf install -y obs-studio                           # Fedora / RHEL / Rocky
   ```
2. Launch OBS. In **Sources**, click **+** → **Screen Capture (PipeWire)** (or **XSHM** if PipeWire isn't available) → pick your terminal window or full screen.
3. **Settings → Output** → set Recording Format to **mp4**. **Settings → Audio** → disable Mic if you don't want narration.
4. Click **Start Recording**, run `hostname`, `whoami`, `bash check-*.sh`, then **Stop Recording**.
5. The `.mp4` lands in your home directory (or wherever OBS's Output → Recording Path points). Upload it to Canvas.

> **Headless / WSL2 students:** if you can't run a GUI, do the recording on the host that's *displaying* your terminal (Windows for WSL2, the host for SSH-only labs). OBS only captures what's on a screen.

---

## Part 5 — Common problems

### "My Zoom Cloud recording link asks the grader to log in"
Switch the cloud recording's permissions to **"Anyone with the link"** in Zoom's web UI (Settings on the recording → Sharing → "Only authenticated users can view" off). If your Alamo account forbids that, submit the `.mp4` instead.

### "The check passed but the recording is 4 minutes long"
That's fine for grading, but trim if you can — easier for the grader to find the PASS banner. QuickTime and OBS both have a built-in trim. **Do not stitch multiple recordings together**; that drops you from a level-3 to a level-2 on [Criterion 2](04-grading-rubric.md#criterion-2--screen-recording).

### "I made an editing mistake and need to re-record"
**Re-record the whole thing in one take.** Editing/stitching is what costs the level-3 score. Re-recording takes 90 seconds; editing artifacts in a 90-second clip are obvious and graded as if the recording was edited.

### "Zoom recorded to the cloud but I can't find the link"
Zoom emails you when processing finishes — check inbox + spam. You can also browse <https://alamo.zoom.us/recording> while signed in. If after 24 hours the cloud recording still hasn't appeared, fall back to your local `.mp4`.

### "My file is over 100 MB and Canvas rejects it"
Use the Zoom Cloud link instead. If you must upload a local file, lower the bitrate in your tool (QuickTime: File → Export As → 720p; OBS: Settings → Output → Recording Quality → "Indistinguishable Quality"). 90 seconds of a terminal at 720p is comfortably under 100 MB.

### "I'm using the cloud fallback (a real cloud VM, not Multipass)"
Same rules: record your **host computer's** screen showing your SSH terminal into the cloud VM. The cloud VM's hostname will show up in `hostname` and `whoami`. Cloud-fallback recordings look identical to Multipass recordings to the grader.

---

## Part 6 — Quick reference

| If you have… | Do this | Submit as |
| --- | --- | --- |
| Alamo Zoom working | Cloud recording, "Anyone with the link" | Cloud link |
| Alamo Zoom working, no Cloud option | Local recording | `.mp4` upload |
| Zoom broken, on macOS | QuickTime Player (built-in) | `.mp4` upload |
| Zoom broken, on Windows | Xbox Game Bar (Win+Alt+R) | `.mp4` upload |
| Zoom broken, on Linux | OBS Studio | `.mp4` upload |

That's the full menu. If none of these will work for your situation, **post in the Q&A board before the deadline** — the wrong move is to use an unlisted tool and hope the grader accepts it.
