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

# 1. cloud-init actually ran and finished
if command -v cloud-init >/dev/null 2>&1 && cloud-init status 2>/dev/null | grep -qE 'done|disabled'; then
  ok "cloud-init reports it finished"
else
  no "cloud-init did not finish cleanly (check: cloud-init status --long)"
fi

# 2. The clouduser was created by cloud-init
if id clouduser >/dev/null 2>&1; then
  ok "user 'clouduser' exists (created declaratively, not by hand)"
else
  no "user 'clouduser' was not created — check the 'users:' block in your cloud-init.yaml"
fi

# 3. clouduser has an SSH key installed (key-based auth configured)
if [[ -s /home/clouduser/.ssh/authorized_keys ]]; then
  if grep -q 'PASTE_YOUR_PUBLIC_KEY_HERE' /home/clouduser/.ssh/authorized_keys; then
    no "clouduser's authorized_keys still contains the placeholder — paste your REAL public key"
  else
    ok "clouduser has an SSH public key installed (key-based auth is set up)"
  fi
else
  no "clouduser has no authorized_keys — the ssh_authorized_keys block did not apply"
fi

# 4. clouduser password login is locked (cloud servers don't use passwords)
if passwd -S clouduser 2>/dev/null | grep -qE ' L | LK '; then
  ok "clouduser password login is locked (key-only access, the cloud way)"
else
  # Not all images report identically; treat as a soft check.
  echo "  INFO  could not confirm password is locked (lock_passwd) — verify with: sudo passwd -S clouduser"
fi

# 5. nginx is installed and running (a package installed on first boot)
if systemctl is-active --quiet nginx; then
  ok "nginx is installed and running (installed automatically at first boot)"
else
  no "nginx is not running — check the 'packages:' and 'runcmd:' blocks"
fi

# 6. The custom page is being served AND was personalized (placeholder removed)
page="$(curl -s http://localhost/ 2>/dev/null)"
if [[ -z "$page" ]]; then
  no "nothing is being served on http://localhost/ — is nginx up?"
elif echo "$page" | grep -q 'YOUR_NAME_HERE'; then
  no "your landing page still says YOUR_NAME_HERE — personalize it in cloud-init.yaml"
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
