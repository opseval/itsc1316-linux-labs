#!/usr/bin/env bash
#
# check-cloud.sh  —  Module 13: Cloud Computing with cloud-init
#
# Run this INSIDE your cloudvm:   bash check-cloud.sh
# It verifies that the server provisioned itself correctly from your
# cloud-init user-data.
#
pass=0
fail=0
ok() { echo "  PASS  $1"; pass=$((pass+1)); }
no() { echo "  FAIL  $1"; fail=$((fail+1)); }

echo "=== Module 13 Lab Check: Cloud Provisioning with cloud-init ==="
echo

# --- Integrity self-check (the grader will verify this SHA against labs/CHECKSUMS.txt) ---
echo "=== check script integrity ==="
if command -v sha256sum >/dev/null 2>&1; then
  echo "  This script: $(basename "$0")"
  echo "  SHA256:      $(sha256sum "$0" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  echo "  This script: $(basename "$0")"
  echo "  SHA256:      $(shasum -a 256 "$0" | awk '{print $1}')"
else
  echo "  This script: $(basename "$0")"
  echo "  SHA256:      (no sha256sum or shasum available)"
fi
echo "  Expected:    see labs/CHECKSUMS.txt in the repo"
echo

# 1. cloud-init actually ran AND the user-data from cloud-init.yaml was
#    applied. cloud-init status alone says "done" even for a stock Multipass
#    launch with no --cloud-init flag, so we look for the marker file the
#    lab's cloud-init.yaml writes to /etc/itsc1316-cloud-init-applied.
if command -v cloud-init >/dev/null 2>&1 && cloud-init status 2>/dev/null | grep -qE 'done|disabled'; then
  if [[ -f /etc/itsc1316-cloud-init-applied ]]; then
    ok "cloud-init reports it finished AND the ITSC-1316 user-data was applied"
  else
    no "cloud-init ran but the ITSC-1316 marker is missing — did you launch with '--cloud-init labs/module-13-cloud-computing/cloud-init.yaml'?"
  fi
else
  no "cloud-init did not finish cleanly (check: cloud-init status --long)"
fi

# 2. The clouduser was created by cloud-init
if id clouduser >/dev/null 2>&1; then
  ok "user 'clouduser' exists (created declaratively, not by hand)"
else
  no "user 'clouduser' was not created — check the 'users:' block in your cloud-init.yaml"
fi

# 3. clouduser has an SSH key installed (key-based auth configured).
#    /home/clouduser/.ssh/ is mode 700 owned by clouduser, so we need sudo
#    to peek at it from the ubuntu user that 'multipass shell' lands in.
#    Validation is layered:
#      - The placeholder must be gone.
#      - The file must NOT contain a "BEGIN ... PRIVATE KEY" marker — a
#        pasted private key is a security incident, not a valid key.
#        (ssh-keygen -l -f alone happily fingerprints private keys.)
#      - At least one line must start with a recognized public-key type.
#      - ssh-keygen -l -f must succeed as a final sanity check.
if sudo test -s /home/clouduser/.ssh/authorized_keys; then
  if sudo grep -q 'PASTE_YOUR_PUBLIC_KEY_HERE' /home/clouduser/.ssh/authorized_keys; then
    no "clouduser's authorized_keys still contains the placeholder — paste your REAL public key"
  elif sudo grep -qE 'BEGIN ([A-Z]+ )?PRIVATE KEY' /home/clouduser/.ssh/authorized_keys; then
    no "DANGER: clouduser's authorized_keys looks like a PRIVATE key — paste ~/.ssh/id_ed25519.pub (the .pub file), and rotate your private key since it was exposed"
  elif ! sudo grep -qE '^(ssh-(ed25519|rsa|dss)|ecdsa-sha2-nistp(256|384|521)|sk-(ssh-ed25519|ecdsa-sha2-nistp256)@openssh\.com) ' /home/clouduser/.ssh/authorized_keys; then
    no "clouduser's authorized_keys has no line starting with a recognized public-key type (ssh-ed25519, ssh-rsa, etc.) — make sure you pasted the .pub file"
  elif ! sudo ssh-keygen -l -f /home/clouduser/.ssh/authorized_keys >/dev/null 2>&1; then
    no "ssh-keygen could not parse clouduser's authorized_keys — there's something malformed in the line you pasted"
  else
    ok "clouduser has a valid SSH public key installed (key-based auth is set up)"
  fi
else
  no "clouduser has no authorized_keys — the ssh_authorized_keys block did not apply"
fi

# 4. clouduser password login is locked (cloud servers don't use passwords).
#    passwd -S reads /etc/shadow, which is root-only on Ubuntu. Ubuntu 22.04
#    reports L (locked) or LK reliably — earlier we treated this as a soft
#    INFO, but a student with lock_passwd:false in cloud-init would silently
#    pass. Treat as a real check.
if sudo passwd -S clouduser 2>/dev/null | grep -qE ' L | LK '; then
  ok "clouduser password login is locked (key-only access, the cloud way)"
else
  no "clouduser password login is NOT locked — set 'lock_passwd: true' under the clouduser users: entry in cloud-init.yaml"
fi

# 5. nginx is installed and running (a package installed on first boot)
if systemctl is-active --quiet nginx; then
  ok "nginx is installed and running (installed automatically at first boot)"
else
  no "nginx is not running — check the 'packages:' and 'runcmd:' blocks"
fi

# 6. The custom page is being served AND was personalized (placeholder removed
#    AND a name actually filled in, not blanked out)
page="$(curl -s http://localhost/ 2>/dev/null)"
if [[ -z "$page" ]]; then
  no "nothing is being served on http://localhost/ — is nginx up?"
elif echo "$page" | grep -q 'YOUR_NAME_HERE'; then
  no "your landing page still says YOUR_NAME_HERE — personalize it in cloud-init.yaml"
elif ! echo "$page" | grep -Eq 'provisioned by [^[:space:]<]'; then
  no "your landing page does not show a name after 'provisioned by' — fill in your name, don't just delete the placeholder"
elif echo "$page" | grep -q 'It works'; then
  ok "your custom landing page is being served and is personalized"
else
  no "a page is served but it is not your custom cloud-init page"
fi

echo
echo "-----------------------------------------------"
echo "  Passed: $pass    Failed: $fail"
if (( fail == 0 )); then
  echo "  ALL CHECKS PASSED. Record your Zoom screen recording and submit."
  echo "-----------------------------------------------"
  exit 0
else
  echo "  Not done yet — fix the FAILs (usually in your cloud-init.yaml,"
  echo "  then relaunch the VM) and run me again."
  echo "-----------------------------------------------"
  exit 1
fi
