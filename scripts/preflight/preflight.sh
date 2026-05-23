#!/usr/bin/env bash
#
# preflight.sh  —  ITSC-1316 environment check (macOS / Linux / WSL)
#
# Run this on YOUR COMPUTER (not inside a VM) in week 1. It launches a tiny
# throwaway VM, transfers a file into it, runs a command inside it, and
# deletes it — proving the entire lab workflow works on your machine.
#
#   bash preflight.sh
#
# It cleans up after itself. Total time: a few minutes (longer the first
# time, while Ubuntu downloads).
#
set -uo pipefail

VM="preflight-test"
TMPFILE="$(mktemp 2>/dev/null || echo /tmp/preflight-token.txt)"
TOKEN="itsc1316-$(date +%s)"
pass=0; fail=0; warn=0
ok()   { echo "  [PASS] $1"; pass=$((pass+1)); }
no()   { echo "  [FAIL] $1"; fail=$((fail+1)); }
note() { echo "  [INFO] $1"; }

print_summary() {
  echo
  echo "=================================================="
  echo "  Passed: $pass    Failed: $fail    Warnings: $warn"
  if (( fail == 0 && pass > 0 )); then
    echo "  RESULT: Your computer is READY for the labs."
    echo "  Submit a screenshot of this summary for the Week 1 check-in."
  else
    echo "  RESULT: Something needs attention — see the [FAIL] lines above,"
    echo "  then post them in the Q&A board with this output."
  fi
  echo "=================================================="
}

cleanup() {
  echo
  echo ">> Cleaning up the throwaway VM..."
  multipass delete "$VM" >/dev/null 2>&1 || true
  multipass purge       >/dev/null 2>&1 || true
  rm -f "$TMPFILE"      >/dev/null 2>&1 || true
  echo ">> Cleanup done."
  # Always show the summary block, even on early exit — students are told to
  # screenshot it for the Week 1 check-in, so it can't be skipped on failure.
  print_summary
}
trap cleanup EXIT

echo "=================================================="
echo " ITSC-1316 Preflight Check (macOS / Linux / WSL)"
echo "=================================================="
echo

# --- 1. OS / arch info (informational) ---
note "Operating system: $(uname -s)  Architecture: $(uname -m)"

# --- 2. Multipass installed? ---
if command -v multipass >/dev/null 2>&1; then
  ok "Multipass is installed ($(multipass version 2>/dev/null | head -1))"
else
  no "Multipass is NOT installed. See docs/01-multipass-setup-guide.md, then re-run."
  echo
  echo "Stopping early — install Multipass first."
  exit 1
fi

# --- 3. Launch a throwaway VM ---
echo
echo ">> Launching a small test VM (this can take a few minutes the first time)..."
if multipass launch 22.04 --name "$VM" --cpus 1 --memory 1G --disk 5G >/dev/null 2>&1; then
  ok "Launched a test VM successfully"
else
  no "Could not launch a VM. Common causes: virtualization disabled in BIOS,"
  echo "         not enough free RAM/disk, or Hyper-V/VirtualBox not set up on Windows."
  echo "         Try: multipass launch 22.04 --name $VM   (to see the full error)"
  exit 1
fi

# --- 4. Transfer a file IN ---
echo "$TOKEN" > "$TMPFILE"
if multipass transfer "$TMPFILE" "$VM:/home/ubuntu/preflight-token.txt" >/dev/null 2>&1; then
  ok "Transferred a file into the VM"
else
  no "File transfer into the VM failed"
fi

# --- 5. Run a command INSIDE the VM and read the file back ---
got="$(multipass exec "$VM" -- cat /home/ubuntu/preflight-token.txt 2>/dev/null | tr -d '\r\n')"
if [[ "$got" == "$TOKEN" ]]; then
  ok "Ran a command inside the VM and read the file back correctly"
else
  no "Could not verify command execution inside the VM (got: '$got')"
fi

# --- 6. Confirm sudo works inside the VM ---
if multipass exec "$VM" -- sudo whoami 2>/dev/null | grep -q root; then
  ok "sudo works inside the VM (you can perform admin tasks)"
else
  no "sudo did not return root inside the VM"
fi

# --- 7. Network from inside the VM (needed for apt installs in labs) ---
# This is a real FAIL, not a warning: every later lab assumes the VM can
# resolve names and reach the package mirrors, so a green READY result here
# without working DNS would be a false negative.
if multipass exec "$VM" -- bash -c "getent hosts ubuntu.com >/dev/null 2>&1"; then
  ok "The VM has working internet name resolution"
else
  no "The VM could not resolve ubuntu.com — labs that install packages will fail. Check your network/VPN (especially work/campus restrictions)."
fi

# --- 8. Host resource snapshot (informational) ---
echo
note "VM list right now:"
multipass list 2>/dev/null | sed 's/^/        /'

# Summary block is printed by the EXIT trap (print_summary) so it appears
# both on the happy path and on any early exit.
