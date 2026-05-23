# Grading Rubric (All Labs)

This is the **single rubric** every lab in this course is graded against. It is intentionally short and concrete: each level is something the grader can verify in seconds, and you can self-grade yourself against the same words before you submit.

> **For students.** If a level says "all `<...>` placeholders replaced," that means: open the file, search for `<`, see if any remain. Not "looks good." If you can't tell which level you're at, ask in the Q&A board before the deadline.
>
> **For graders.** Use these exact levels and the exact point values shown. If a submission falls between two levels, score the lower one and note in the comment which criterion's wording isn't met. Don't invent intermediate points.

---

## How scoring works

Every standard lab has **4 criteria**, each with **4 levels** and a fixed point value per level. Maximum total is **36 points**.

| Criterion | Max | Level 3 | Level 2 | Level 1 | Level 0 |
| --- | --- | --- | --- | --- | --- |
| 1 — Check Script Results | 9 | **9** | 6 | 3 | 0 |
| 2 — Screen Recording | 6 | **6** | 4 | 2 | 0 |
| 3 — Written Component | 12 | **12** | 8 | 4 | 0 |
| 4 — Submission Hygiene & Integrity | 9 | **9** | 6 | 3 | 0 |

Total possible: **36 / 36**. The Written Component is the biggest single criterion on purpose — **a passing check script with no reasoning is not learning.** Capstone (Module 15) has different per-criterion maximums; see the bottom of this document.

> Canvas may display the lab as worth a different point total (50, 100, etc.). That's just a scaling factor the instructor applies; the rubric below is what determines your share of that total.

---

## Criterion 1 — Check Script Results

**Max: 9 points.** What the grader runs: opens your screen recording and counts the `FAIL` lines in the `check-*.sh` output.

**Grader's first step — verify the check script wasn't modified.** Every check script auto-fetches [`labs/CHECKSUMS.txt`](../labs/CHECKSUMS.txt) from GitHub and prints a self-verification block as the first output:
```
=== check script integrity ===
  Script:      check-XX.sh
  Local SHA:   <hex>
  Canonical:   <hex>
  INTEGRITY:   VERIFIED (matches canonical CHECKSUMS.txt)
```
The grader looks at the **INTEGRITY:** line. `VERIFIED` means the script is untampered. `*** MISMATCH ***` means the student edited the check script — this is an academic-integrity violation and the entire submission is graded **0** under [Criterion 4](#criterion-4--submission-hygiene--integrity), regardless of how the rest looks. `UNKNOWN` (e.g., the canonical fetch failed because the VM was offline) is treated as a re-record-and-resubmit, not a violation — the grader will ask the student to re-run with network so VERIFIED can be confirmed.

| Points | Standard (objective — count the FAILs) |
| --- | --- |
| **9** | The check script ran to completion, the recording shows `INTEGRITY: VERIFIED`, and **every check is PASS** (zero FAIL lines). |
| **6** | `INTEGRITY: VERIFIED`; one single FAIL line, **everything else PASS**. (Near-complete.) |
| **3** | `INTEGRITY: VERIFIED`; two or more FAILs, but at least one PASS. (Substantial attempt.) |
| **0** | The check script wasn't run, the recording doesn't show its output, or every check FAILed. (If the recording shows `INTEGRITY: *** MISMATCH ***`, see the academic-integrity note above — Criterion 4 forces the whole submission to 0.) |

---

## Criterion 2 — Screen Recording

**Max: 6 points.** What the grader looks for: a single recording file or link in the Canvas submission.

| Points | Standard (all conditions must hold for the higher score) |
| --- | --- |
| **6** | One continuous take recorded with the lab's primary or backup tool (see [Screen Recording Guide](05-screen-recording-guide.md)); the recording **shows, on screen**, the output of `hostname`, the output of `whoami`, and the `check-*.sh` run with its final PASS lines. |
| **4** | All three on-screen items above are present, but the take is stitched/edited together OR one of the three (`hostname` or `whoami`) is missing. |
| **2** | A recording is present but the `check-*.sh` PASS lines aren't visible on screen, OR it was made with a tool not listed in the Screen Recording Guide, OR it is so short / fragmented the grader can't follow the work. |
| **0** | No recording submitted, the link is broken or restricted, or the file is unreadable. |

> **Why "on screen, in the recording"?** Anyone can paste check output into a text file. The point of the recording is that the check script ran *on your machine, just now*, with *your* hostname.

---

## Criterion 3 — Written Component

**Max: 12 points.** What "written component" means depends on the lab:

| Lab(s) | Written deliverable |
| --- | --- |
| M1, M6 | Written reflection (answers to specific questions) |
| M2, M3, M4, M5, M7, M9, M10, M11, M12 | A report file the lab tells you to create (`~/moduleN-…-report.txt` etc.) |
| M13-adv, M13-cloud | A writeup (troubleshooting writeup or cloud writeup) |
| M14 | An incident report |
| M15 | A handover report (graded under the **Capstone overrides** at the bottom) |

Each lab's README spells out its specific written deliverable; this criterion grades whatever that lab requires.

| Points | Standard |
| --- | --- |
| **12** | All required sections present; **zero `<...>` placeholders or `TODO`/`FIXME` markers remain**; the answers reference the student's own evidence (real hostname, real IP, real output) rather than generic descriptions; each required question is answered in its own complete sentences. |
| **8** | All sections present and placeholders replaced, **but** reasoning is shallow (one-line answers where multi-sentence is asked for) OR one section uses generic prose instead of evidence from the student's own VM. |
| **4** | The component was submitted but is **missing one or more required sections**, OR contains leftover `<placeholder>` text, OR is just pasted command output with no written explanation. |
| **0** | The written component is missing entirely. |

> The check scripts already verify "no placeholders left, hostname appears, sections exist" mechanically — so a 12-point written component is essentially: passes the check, *plus* the prose sounds like a person who did the work, not a person typing what they think the grader wants to read.

---

## Criterion 4 — Submission Hygiene & Integrity

**Max: 9 points.** What the grader looks at: the Canvas submission as a whole, plus any AI-use disclosure.

| Points | Standard |
| --- | --- |
| **9** | All required artifacts (recording + written component, per the lab's "Submission Requirement" block) are attached; if the lab is **AI-OPEN** or **AI-REQUIRED**, a one-line AI-use disclosure is included; submission is on time. |
| **6** | All artifacts attached, **but** missing the AI disclosure (when required), OR submitted late but within the lab's stated grace window. |
| **3** | One required artifact is missing (e.g. the writeup was submitted but no recording was attached). |
| **0** | More than one artifact is missing, **OR** there is evidence of an academic-integrity violation — the recording shows a different machine than the writeup describes, the hostname in the report doesn't match the one in the recording, identical text was submitted by multiple students, the recording was reused from another semester, **or the check script's integrity line in the recording shows `INTEGRITY: *** MISMATCH ***` against [`labs/CHECKSUMS.txt`](../labs/CHECKSUMS.txt) (the student edited the check script)**. Academic-integrity violations are **always a 0**; they do not partial-credit. |

> **AI disclosure expectation, in one line:** "Used <tool> to <ask what>; verified <how> on my own VM." That's the whole bar. The check scripts make most AI shortcuts visible anyway (the hostname / kernel / IP cannot be faked), but the disclosure is what the academic-integrity scoring relies on. If the lab is **AI-FREE**, no disclosure is needed (and AI use is itself the violation).

---

## Capstone overrides (Module 15 only)

The capstone is worth more and grades reasoning heaviest. Same 4 criteria, same 4-level structure, different per-level point values:

| Criterion | Max | Level 3 | Level 2 | Level 1 | Level 0 |
| --- | --- | --- | --- | --- | --- |
| 1 — Check Script Results | 12 | **12** | 8 | 4 | 0 |
| 2 — Screen Recording | 6 | **6** | 4 | 2 | 0 |
| 3 — Written Component (Handover Report) | 18 | **18** | 12 | 6 | 0 |
| 4 — Submission Hygiene & Integrity | 9 | **9** | 6 | 3 | 0 |

Total possible: **45 / 45**. Level definitions are identical to the standard labs above — only the numbers change.

---

## Worked example — Module 6 submission

A student submits:
- A Zoom Cloud link, 78 seconds, continuous take, shows `hostname` → `whoami` → `bash check-users.sh`. The check script's integrity block is visible at the top of the output and reads `INTEGRITY: VERIFIED`. The run ends in `Passed: 4  Failed: 0`.
- A text file with both reflection questions answered, ~3 sentences each, no `<...>` placeholders, references `avery` by name.
- Attached on Canvas before the deadline.
- The lab is AI-OPEN; the student included: "Asked Claude to explain the difference between 660 and 640 for the file mode; verified by running `sudo su - avery` and trying to edit `meeting-highlights.txt` myself."

Scoring:
- Criterion 1: **9** (all PASS).
- Criterion 2: **6** (continuous take with hostname/whoami/passing check visible).
- Criterion 3: **12** (both sections present, no placeholders, references real lab evidence).
- Criterion 4: **9** (all artifacts, AI disclosure present, on time).

Total: 9 + 6 + 12 + 9 = **36 / 36**.

---

## How to self-grade before you submit

Run through these in order; if you can't say "yes" to all, fix the gap first:

- [ ] **Crit 1 (9 pts).** I just ran `bash check-*.sh` (or `sudo bash check-*.sh` if the lab says so) and saw **0 FAILs** — AND the integrity line at the top reads `INTEGRITY: VERIFIED`. (If it reads `MISMATCH`, you edited the check script — refetch it fresh: `rm check-*.sh && curl -fsSLO https://raw.githubusercontent.com/opseval/itsc1316-linux-labs/main/labs/<lab>/check-<name>.sh` — a `MISMATCH` is graded as academic-integrity, not a partial-credit issue. If it reads `UNKNOWN`, your VM couldn't reach GitHub; re-run after fixing the network so the line reads `VERIFIED`. See [docs/05-screen-recording-guide.md](05-screen-recording-guide.md) for the full recipe.)
- [ ] **Crit 2 (6 pts).** My recording is a single continuous take. In it you can see the integrity block (reading `VERIFIED`), `hostname`, `whoami`, and the check ending in PASS — all without me pausing or editing.
- [ ] **Crit 3 (12 pts).** My written file has every section the lab asked for, zero `<...>` placeholders, and at least one reference to my own VM's specific output (hostname, IP, file path, etc.).
- [ ] **Crit 4 (9 pts).** I attached both the recording (or link) and the written file. If AI was permitted and I used it, I added the one-line disclosure.

If all four are checked, you'd give yourself 36 / 36. The grader will too.
