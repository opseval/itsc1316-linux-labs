# Multipass Troubleshooting Guide (All Platforms)

When Multipass misbehaves it's almost always one of a handful of things: a VPN or corporate network, a firewall/antivirus, the background service needing a restart, or virtualization not being enabled. This guide walks them in order. Start at the top — most problems are solved in the first two sections.

> **Reading order:** run the [Preflight Check](00-preflight-check.md) first. If a step there FAILed, jump to the matching section below. If you get stuck, the **"How to ask for help"** section at the bottom tells you exactly what to post.

**Official documentation (authoritative, kept current by Canonical):**
- Troubleshooting hub: <https://documentation.ubuntu.com/multipass/latest/how-to-guides/troubleshoot/>
- Troubleshoot launch/start issues: <https://documentation.ubuntu.com/multipass/latest/how-to-guides/troubleshoot/troubleshoot-launch-start-issues/>
- Troubleshoot networking: <https://documentation.ubuntu.com/multipass/latest/how-to-guides/troubleshoot/troubleshoot-networking/>
- Access logs: <https://documentation.ubuntu.com/multipass/latest/how-to-guides/troubleshoot/access-logs/>
- Install guide: <https://documentation.ubuntu.com/multipass/latest/how-to-guides/install-multipass/>

---

## 1. First response — the 3 things to try before anything else

Most "it stopped working" problems clear up with these, in order:

1. **Check the basics.** From your computer's terminal (not inside a VM):
   ```
   multipass version       # is Multipass installed and responding?
   multipass list          # what VMs exist and what state are they in?
   multipass info labvm    # detail on one VM (IP, mounts, resources)
   ```
2. **Stop and start the VM** (fixes a surprising amount, especially after your computer sleeps):
   ```
   multipass stop labvm
   multipass start labvm
   ```
3. **Restart the Multipass background service** (see [section 3](#3-restart-the-multipass-service)). The service — `multipassd` — does the actual work; if it's wedged, every command misbehaves.

If all three fail the same way, move to the symptom that matches below.

---

## 2. VPN and corporate-network problems (the #1 cause)

If your VM **launches but has no internet**, or `multipass launch` hangs and then reports it **can't determine the IP address**, suspect your VPN first. This is the single most common issue for students on school or work networks.

### Why VPNs break Multipass

A VPN client (Cisco AnyConnect, Palo Alto GlobalProtect, Zscaler, OpenVPN, most corporate clients) reroutes your traffic and often replaces your DNS settings. Multipass gives your VM a small private NAT network on your computer; when the VPN takes over routing and DNS, the VM's traffic has nowhere to go and name resolution stops. On **Windows**, this is sharper because Multipass relies on the Hyper-V **"Default Switch"** and Windows **Internet Connection Sharing** for the VM's DHCP/DNS — a full-tunnel VPN conflicts directly with that.

Typical symptom inside the VM:
```
ping -c2 1.1.1.1        # works (or also fails)
getent hosts ubuntu.com # FAILS  -> DNS/VPN problem
```

### Fixes, least-invasive first

1. **Launch with the VPN disconnected, connect the VPN afterward.** Bring up `labvm` first, *then* connect your VPN. The VM usually keeps the network it already has. This alone fixes most cases.
2. **If the VM lost its network after you connected the VPN:** disconnect the VPN, **restart the Multipass service** (section 3), then `multipass start labvm` again.
3. **Enable split tunneling** if your VPN allows it, excluding the Multipass subnet (the `10.x` / `192.168.x` network shown in `multipass list`). Note: many school/corporate VPNs forbid split tunneling by policy — if so, skip to option 5.
4. **macOS + Cisco AnyConnect specifically:** AnyConnect is well known for hijacking routing in a way Multipass can't work around. If your situation allows it, the friendlier `OpenConnect` client (`brew install openconnect`) often coexists with Multipass; otherwise use option 5.
5. **Do the labs off the VPN.** If you don't need the VPN for the lab itself, disconnect it while you work, then reconnect. Nothing in these labs requires the campus/work VPN.
6. **Last resort — use the cloud fallback.** If you can't get a working VM behind a mandatory always-on VPN, do the labs on a free cloud instance instead (see [Setup Guide, Part 6](01-multipass-setup-guide.md)). The lab commands are identical there.

> The Preflight Check's "internet name resolution" test exists specifically to catch this in week 1 — long before it can affect a grade. If that test fails, work through this section before assignments begin.

### Firewall / antivirus

Third-party firewalls and antivirus (and sometimes Windows Defender Firewall) can block the virtual network adapter or the `multipassd` service. If toggling the VPN doesn't help, temporarily disable the third-party firewall/AV, retry `multipass launch`, and if that fixes it, add an exception for Multipass rather than leaving protection off. See Canonical's [networking troubleshooting](https://documentation.ubuntu.com/multipass/latest/how-to-guides/troubleshoot/troubleshoot-networking/).

---

## 3. Restart the Multipass service

When commands hang or error for no clear reason, restart the daemon. Use the command for your platform (you'll need administrator rights):

| Platform | Command |
| --- | --- |
| **macOS** | `sudo launchctl kickstart -k system/com.canonical.multipassd` |
| **Windows** (PowerShell **as Administrator**) | `Restart-Service Multipass` |
| **Linux** (snap install) | `sudo snap restart multipass` |

Then re-run `multipass list` and try your VM again. If the service won't start at all, check the logs (section 4).

---

## 4. Read the logs

When you need to see *why* something failed (or when posting for help), the logs are the source of truth. Full, current paths are in Canonical's [Access logs](https://documentation.ubuntu.com/multipass/latest/how-to-guides/troubleshoot/access-logs/) guide; the common locations:

| Platform | Where the daemon log lives |
| --- | --- |
| **macOS** | `/Library/Logs/Multipass/multipassd.log` |
| **Windows** | `C:\Windows\System32\config\systemprofile\AppData\Local\multipassd\multipassd.log` |
| **Linux** | `journalctl --unit snap.multipass.multipassd` |

On macOS/Linux you can watch the log live while you reproduce the problem:
```
# macOS
tail -f /Library/Logs/Multipass/multipassd.log
# Linux
journalctl --unit snap.multipass.multipassd -f
```

---

## 5. By symptom

### `multipass: command not found`
Multipass isn't installed or isn't on your PATH. Reinstall from the [install guide](https://documentation.ubuntu.com/multipass/latest/how-to-guides/install-multipass/) and reboot. On Windows, open a **new** terminal after installing so the PATH refreshes.

### `launch failed` / hangs then times out / "unable to determine IP address"
Almost always VPN/firewall (section 2) or virtualization not enabled (see platform notes, section 6). To see the real error, run the launch without hiding output:
```
multipass launch 22.04 --name labvm
```
and read the message. Canonical's [launch/start troubleshooting](https://documentation.ubuntu.com/multipass/latest/how-to-guides/troubleshoot/troubleshoot-launch-start-issues/) lists the specific messages and fixes.

### VM is `Running` but has no internet, or can't resolve names
VPN/DNS — section 2. Confirm from inside the VM with `getent hosts ubuntu.com`.

### `launch failed: ... not enough memory` / disk
Lower the VM size (`--memory 1G --disk 5G`), close other VMs, or free disk space. Check current usage with `multipass info labvm`.

### Stuck in `Starting`, or unresponsive after the computer slept
`multipass stop labvm` then `multipass start labvm`. If that hangs, restart the service (section 3). Laptops that sleep often need this.

### `multipass transfer` fails
Check the path on **your computer** is exact (use full paths), and that the VM is `Running`. The destination is `labvm:/home/ubuntu/`.

### Can't `ssh` into the VM (in the cloud lab)
Make sure you used your key (`ssh -i ~/.ssh/id_ed25519 clouduser@<ip>`), the VM is running, and the IP from `multipass list` is current (it can change across restarts).

---

## 6. Platform-specific notes

### macOS
- Requires **macOS 13.3 (Ventura) or later**; works on both Apple Silicon (M-series) and Intel. The backend is QEMU on Apple's Hypervisor framework — no extra setup.
- If macOS blocks something the first time, approve Multipass under **System Settings → Privacy & Security**.
- After a **major macOS upgrade**, networking can break until you restart the service (section 3) or reinstall Multipass.
- Cisco AnyConnect routing issues: see section 2, option 4.

### Windows
- Requires **Windows 10/11 Pro, Enterprise, or Education** for the Hyper-V backend. **Windows Home does not include Hyper-V** — install Multipass with the **VirtualBox** backend instead (the installer offers this), or upgrade your edition.
- **Virtualization must be enabled in BIOS/UEFI.** If launch fails immediately, reboot into firmware settings and enable Intel VT-x / AMD-V (sometimes labeled "SVM" or "Virtualization Technology").
- The Hyper-V **Default Switch** provides the VM's IP/DNS via Internet Connection Sharing; it's the piece VPNs conflict with (section 2). Restarting the `Multipass` service after toggling a VPN usually restores it.
- Conflicts with other Hyper-V users (Docker Desktop, WSL2) are rare but possible — if you suspect one, reboot and try Multipass first.

### Linux
- Installed as a **snap** (`sudo snap install multipass`); needs `snapd`.
- Uses KVM/QEMU — your CPU must support virtualization and it must be enabled. Verify with `kvm-ok` (from the `cpu-checker` package).
- If `multipass` commands give permission errors, ensure your user can reach the daemon socket (log out/in after install, or check group membership per the install guide).

---

## 7. How to ask for help (so we can actually fix it fast)

Post in the **Q&A Discussion Board** with all of the following — it's the difference between a one-reply fix and three days of back-and-forth:

1. Your **platform and version** (e.g., "Windows 11 Home", "macOS 14.4 Apple Silicon", "Ubuntu 24.04").
2. Whether you are on a **VPN** or a school/work network, and whether you tried section 2.
3. The **exact command** you ran and the **exact error** (copy the text or screenshot it).
4. The output of `multipass version` and `multipass list`.
5. What you've already tried from this guide.

If the issue is clearly environmental and you've exhausted section 2, remember the **cloud fallback** in [Setup Guide, Part 6](01-multipass-setup-guide.md) — you will never be blocked from coursework by a laptop or a VPN.

---

*Authoritative source for everything in this guide: Canonical's official Multipass documentation at <https://documentation.ubuntu.com/multipass/latest/>.*
