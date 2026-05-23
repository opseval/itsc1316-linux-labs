#!/usr/bin/env bash
#
# check-storage.sh  —  Module 5: Linux Filesystem Management (Storage Monitoring)
#
# Self-grades your work. Run it (no sudo needed):
#     bash check-storage.sh
#
# Prints PASS/FAIL for each requirement. Exit code is 0 only if everything
# passes. The checks are anchored to YOUR VM's real state (its hostname, the
# planted large file) plus the report you wrote, so the work can't be faked.
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

REPORT="${HOME}/module5-storage-report.txt"
HOG_DIR="${HOME}/bigdata"
BIG_FILE="${HOG_DIR}/hog.img"
MANY_DIR="${HOG_DIR}/manyfiles"

echo "=== Module 5 Lab Check: Storage Monitoring ==="
echo

# 0. The scenario must still exist (so the student investigated real state).
if [[ -f "$BIG_FILE" ]]; then
  ok "the planted large file exists at ~/bigdata/hog.img (scenario intact)"
else
  no "~/bigdata/hog.img is missing — run 'bash setup-storage.sh' first (and don't delete it before grading)"
fi

# 1. The report file exists and is non-empty.
if [[ -s "$REPORT" ]]; then
  ok "storage report exists at ~/module5-storage-report.txt"
else
  no "~/module5-storage-report.txt is missing or empty — create it as the instructions describe"
  # Without a report there is nothing else to grade; summarize and exit.
  echo
  echo "-----------------------------------------------"
  echo "  Passed: $pass    Failed: $fail"
  echo "  Not done yet — create the report and run me again."
  echo "-----------------------------------------------"
  exit 1
fi

# 2. The report begins with THIS VM's real hostname (proves it's the student's
#    own system). We require the actual hostname to appear in the report.
this_host="$(hostname)"
if grep -qxF "$this_host" "$REPORT" || grep -qF "$this_host" "$REPORT"; then
  ok "report contains this VM's real hostname ('$this_host')"
else
  no "report does not contain this VM's hostname ('$this_host') — start it with:  hostname > ~/module5-storage-report.txt"
fi

# 3. The report contains df output. We look for a df-style header/line: a
#    'Filesystem' header AND a percentage column value, which df produces and
#    a hand-typed sentence almost certainly would not.
if grep -qi 'Filesystem' "$REPORT" && grep -Eq '[0-9]+%' "$REPORT"; then
  ok "report contains df output (Filesystem header and a Use% value present)"
else
  no "report is missing df output — append it with:  df -hT >> ~/module5-storage-report.txt"
fi

# 4. The report contains du output for the bigdata directory. du -h prints a
#    size token (e.g. 200M, 2.4M) immediately followed by a path that includes
#    'bigdata'. Require a size+bigdata path on the same line.
if grep -Eq '^[0-9.]+[KMG][[:space:]]+.*bigdata' "$REPORT"; then
  ok "report contains du output referencing ~/bigdata (directory-level usage captured)"
else
  no "report is missing du output for ~/bigdata — append it with:  du -h --max-depth=1 ~ | sort -h >> ~/module5-storage-report.txt"
fi

# 5. The report correctly identifies the large file's LOCATION. It must name
#    the planted file's path (hog.img). We accept the basename or full path.
if grep -q 'hog\.img' "$REPORT"; then
  ok "report identifies the large file by name (hog.img)"
else
  no "report does not name the planted large file — locate it with 'find ~ -type f -size +100M' and record its path (hog.img)"
fi

# 6. The report correctly identifies the large file's SIZE. The file is ~200M.
#    Accept a du/ls-style size token of 200M (du -h rounds 200 MiB to '200M')
#    or a value clearly in the 190-210 MB range, or the byte count.
size_ok=0
# du -h / ls -lh style: a standalone token like 200M (allow 190M-210M and .x variants)
if grep -Eqi '\b(19[0-9]|20[0-9]|210)[.,]?[0-9]*M\b' "$REPORT"; then size_ok=1; fi
# raw bytes (fallocate makes exactly 209715200; allow a little slack)
if grep -Eq '\b20[0-9][0-9]{6}\b' "$REPORT"; then size_ok=1; fi
if (( size_ok == 1 )); then
  ok "report records the large file's size (~200M)"
else
  no "report does not record the large file's ~200M size — capture it with:  du -h ~/bigdata/hog.img >> ~/module5-storage-report.txt"
fi

# 7. The report accounts for the many-small-files directory by recording the
#    real count. setup-storage.sh creates 600 files; the student should pipe
#    `find ~/bigdata/manyfiles -type f | wc -l` into the report. Require the
#    word 'manyfiles' AND a 3-digit count in the 500-699 range on a nearby
#    line (allows a bit of slack but rejects an arbitrary number like a load
#    average or a date).
if grep -q 'manyfiles' "$REPORT" && grep -B2 -A2 'manyfiles' "$REPORT" | grep -Eq '\b(5[0-9]{2}|6[0-9]{2})\b'; then
  ok "report records the 'manyfiles' directory and its file count (near the expected ~600)"
elif grep -q 'manyfiles' "$REPORT"; then
  no "report mentions 'manyfiles' but no plausible count is near it — capture 'find ~/bigdata/manyfiles -type f | wc -l' into the report"
else
  no "report does not account for ~/bigdata/manyfiles and its file count — record it as the instructions describe"
fi

# 8. The analysis/recommendation section is present and FILLED IN. We require
#    the three section headers AND that no '<...>' placeholder remains AND that
#    each section has some real prose after its header.
analysis_present=0
if grep -qi 'RECOMMENDED ACTION' "$REPORT" \
   && grep -qi 'WHAT IS CONSUMING SPACE' "$REPORT" \
   && grep -qi 'WHAT I WOULD CHECK NEXT' "$REPORT"; then
  analysis_present=1
fi

# Detect leftover placeholders of the form <...>.
placeholder_left=0
if grep -Eq '<[^>]+>' "$REPORT"; then placeholder_left=1; fi

# Require the RECOMMENDED ACTION section to actually contain words (>= 15
# non-space chars somewhere after the header), so an empty section fails.
rec_filled=0
rec_body="$(awk 'tolower($0) ~ /recommended action/{flag=1; next} flag' "$REPORT" \
            | tr -d '[:space:]')"
if (( ${#rec_body} >= 15 )); then rec_filled=1; fi

if (( analysis_present == 1 && placeholder_left == 0 && rec_filled == 1 )); then
  ok "analysis & recommendation section is complete (all three parts present, no placeholders)"
elif (( analysis_present == 0 )); then
  no "analysis section incomplete — it needs all three headers: WHAT IS CONSUMING SPACE / WHAT I WOULD CHECK NEXT / RECOMMENDED ACTION"
elif (( placeholder_left == 1 )); then
  no "the report still contains '<...>' placeholders — replace every <...> with your own analysis"
else
  no "your RECOMMENDED ACTION section is empty — write your recommendation (and note you would not delete system files blindly)"
fi

echo
echo "-----------------------------------------------"
echo "  Passed: $pass    Failed: $fail"
if (( fail == 0 )); then
  echo "  ALL CHECKS PASSED. Record your Zoom screen recording and submit."
  echo "-----------------------------------------------"
  exit 0
else
  echo "  Not done yet — fix the FAILs above and run me again."
  echo "-----------------------------------------------"
  exit 1
fi
