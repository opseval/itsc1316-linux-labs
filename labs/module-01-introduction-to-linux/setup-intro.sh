#!/usr/bin/env bash
#
# setup-intro.sh  —  Module 1: Introduction to Linux
#
# Builds the lab scenario inside your Multipass VM. Run it ONCE with sudo:
#     sudo bash setup-intro.sh
#
# Module 1 is a "first contact" lab: you investigate the system you are
# actually running and connect what you find to the concepts from the
# module (what an OS does, what makes Linux unique, distributions, the
# kernel, the shell, and where Linux is used). This setup script does NOT
# break anything — it only drops a starter template for your evidence
# file so you have a place to record your findings. The investigating and
# writing are the lab.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo bash setup-intro.sh"
  exit 1
fi

# Figure out who the real lab user is (the account that invoked sudo),
# so the template lands in their home directory, not root's.
LAB_USER="${SUDO_USER:-ubuntu}"
LAB_HOME="$(getent passwd "$LAB_USER" | cut -d: -f6)"
REPORT="${LAB_HOME}/module1-system-report.txt"

echo "[setup] Preparing your evidence-file template at ${REPORT}"

# Idempotent: only write the template if the student has not already
# started filling one in. We never overwrite real work.
if [[ -e "$REPORT" ]]; then
  echo "[setup] ${REPORT} already exists — leaving it alone so your work is safe."
else
  cat > "$REPORT" <<'EOF'
================================================================
 MODULE 1 SYSTEM REPORT
 Fill in each line by running the command shown and pasting in
 the REAL output from YOUR vm. Do not guess — the check script
 compares several of these against your live system.
================================================================

# --- Identity (so we know this is your VM) ---
HOSTNAME:           <run: hostname>

# --- The distribution (the "Linux" someone packaged for you) ---
DISTRO_ID:          <run: cat /etc/os-release  -- copy the ID= value, e.g. ubuntu>
DISTRO_VERSION:     <run: lsb_release -a 2>/dev/null | grep Description>
HOSTNAMECTL_OS:     <run: hostnamectl | grep "Operating System">

# --- The kernel (the core of the OS that talks to the hardware) ---
KERNEL_RELEASE:     <run: uname -r  -- paste the EXACT string>
UNAME_ALL:          <run: uname -a>

# --- The shell (your text interface to the system) ---
LOGIN_SHELL:        <run: echo $SHELL>
AVAILABLE_SHELLS:   <run: cat /etc/shells  -- list a couple>

# --- Headless / no GUI (why servers run this way) ---
GUI_PRESENT:        <run: systemctl get-default  -- is it multi-user.target or graphical.target?>

# --- The filesystem top level ---
TOP_OF_FILESYSTEM:  <run: ls /  -- paste the directory names you see>

# --- The package manager (how the distribution delivers software) ---
PACKAGE_MANAGER:    <run: which apt  -- paste the path>
PACKAGES_INSTALLED: <run: dpkg -l | wc -l  -- paste the number>

================================================================
 REFLECTION (write in full sentences, your own words):

 1) What did you find that makes this "Linux" and not Windows
    or macOS? Point to at least two concrete things from above.

 2) Based on the module, name one place in industry or in the
    cloud where you would expect to find a system like this one,
    and say why Linux is a good fit there.
================================================================
EOF
  chown "$LAB_USER":"$LAB_USER" "$REPORT"
  chmod 644 "$REPORT"
  echo "[setup] Template created and owned by ${LAB_USER}."
fi

echo
echo "[setup] Done. Now open ${REPORT} in an editor (nano is fine),"
echo "        run each command shown, and replace each <...> with the"
echo "        REAL output from this VM. Then write your reflection."
echo "        When finished, grade yourself with:  bash check-intro.sh"
