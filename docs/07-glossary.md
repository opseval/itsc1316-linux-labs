# Glossary — terms you'll meet in the ITSC 1316 labs

This is a one-line-definition reference for technical terms the lab READMEs use without explanation. If you hit a term you don't recognize while working a lab, check here before reaching for Google or AI — it covers most of the vocabulary that comes up in Modules 1–15.

Terms are listed alphabetically. The "see Module X" references point at the lab that first uses the term.

---

## A

**apt** — Ubuntu's package manager command (the program you use to install, update, and remove software). Example: `sudo apt install tree`. *See: Module 7.*

**append (`>>`)** — Shell redirection that adds output to the end of a file instead of overwriting it. Contrast with `>`, which replaces the file's contents. *See: Module 3.*

**argument** — A value you type after a command name to tell it what to act on. In `ls /etc`, `/etc` is the argument. *See: Module 3.*

**attack surface** — Everything on a system that an attacker could try to interact with (open ports, world-writable files, SUID binaries). Less is better. *See: Module 14.*

## B

**background process** — A process you start with `&` so the shell gives your prompt back instead of waiting for the program to finish. *See: Module 10.*

**Bash** — The default shell on Ubuntu — the program that reads the commands you type and runs them. Short for "Bourne Again SHell." *See: Module 1.*

**block device** — A storage device the kernel addresses in fixed-size chunks (blocks): a disk, a partition, a loop device, an SSD. `lsblk` lists them. *See: Module 11.*

**builtin** — A command implemented inside the shell itself (like `cd`) rather than as a separate program on disk (like `ls`). Use `type <name>` to tell which. *See: Module 3.*

## C

**CIDR notation** — The `/24` suffix on an IP like `192.168.252.17/24` — it says how many leading bits of the address identify the network. /24 means "first three numbers are the network." *See: Module 9.*

**cloud-init** — The tool that runs the very first time a cloud VM boots and configures it from a YAML "user-data" file (creates users, installs packages, writes files). *See: Module 13b.*

**command substitution (`$(...)`)** — Bash syntax that runs a command and replaces the `$(...)` with whatever the command printed. Example: `HOST="$(hostname)"` stores your machine's name in `HOST`. *See: Module 3.*

## D

**daemon** — A background service program that runs continuously without a user typing at it (web servers, schedulers, the SSH service). The trailing `d` in names like `sshd`, `cron`, `multipassd` is short for "daemon." *See: Module 1.*

**default gateway** — The router your machine sends traffic to when the destination is not on your local network. Find it with `ip route` (the line starting with `default`). *See: Module 9.*

**dependency** — A package or service that another package or service needs in order to work. *See: Module 7.*

**device file** — A special file under `/dev` (like `/dev/sda1` or `/dev/loop3`) that represents a piece of hardware or a virtual device to the kernel. *See: Module 11.*

**DHCP** — A protocol that hands out IP addresses automatically when a machine joins a network, so you do not have to configure one by hand. *See: Module 9.*

**distribution (distro)** — A complete Linux operating system bundle: the Linux kernel plus a chosen set of packages plus a package manager. Ubuntu, RHEL, Fedora, and Debian are all distributions. *See: Module 1.*

**DNS** — Domain Name System — the service that translates human names like `ubuntu.com` into numeric IP addresses. *See: Module 9.*

**dpkg** — The lower-level Debian/Ubuntu package tool that `apt` uses under the hood. `dpkg -l` lists installed packages; `dpkg -L pkg` lists the files a package owns. *See: Module 7.*

## E

**environment variable** — A variable that has been `export`ed so that any child process (a script, another shell) inherits it. Contrast with a plain shell variable, which only exists in your current shell. *See: Module 3.*

**exit code** — A small number a command returns when it finishes (0 means success, anything else means some kind of failure). Inspect with `echo $?`. *See: Module 3.*

**ext4** — The default filesystem format on most Ubuntu installs — the on-disk layout that organizes files and directories on a block device. *See: Module 11.*

## F

**FHS (Filesystem Hierarchy Standard)** — The convention that says where things live on a Linux system (`/etc` for config, `/var` for variable data, `/usr/bin` for programs, etc.). Same layout on Ubuntu, RHEL, and most other distros. *See: Module 4.*

**file descriptor** — A small number the kernel uses to identify an open stream: 0 is stdin, 1 is stdout, 2 is stderr. *See: Module 3.*

**filesystem** — Two related meanings: (1) the on-disk format that organizes data (ext4, iso9660), and (2) the mounted tree of directories you actually use. Context tells you which. *See: Modules 4, 11.*

**flag** — A short option you pass to a command, usually starting with `-` (like `-l` in `ls -l`) or `--` (like `--help`). *See: Module 1.*

**fsck** — Filesystem check — the utility that verifies and (with `-y`) repairs a filesystem. Run it on an unmounted device. *See: Module 11.*

**fstab** — `/etc/fstab`, the table of filesystems the system mounts automatically at boot. *See: Module 11.*

## G

**gateway** — See **default gateway**.

**getent** — A command that looks up entries from system databases (hosts, users, groups) the same way regular programs do. `getent hosts ubuntu.com` does DNS resolution without using `ping`. *See: Module 9.*

**group** — A named collection of users; files have a group owner, and group members can be granted shared access. *See: Module 6.*

## H

**headless** — A server with no graphical desktop installed — you administer it entirely through a text terminal over SSH. The default for most server-class Linux. *See: Module 1.*

**heredoc (`<<EOF ... EOF`)** — Shell syntax that feeds a block of multi-line text into a command as input, ending at the marker word you chose (`EOF` by convention). *See: Module 12.*

**hostname** — The short name your machine answers to (`labvm`, `fileserver`). Run `hostname` to print it. *See: Module 1.*

**hypervisor** — The software layer that runs virtual machines (Multipass uses QEMU on Apple Silicon Macs, Hyper-V on Windows Pro, KVM on Linux). *See: Setup Guide.*

## I

**ICMP** — Internet Control Message Protocol — the network protocol that `ping` and `traceroute` use. It is *separate* from TCP/UDP (web, SSH, DNS), so a network can drop ICMP while everything else still works (Multipass on macOS does exactly this). *See: Module 9.*

**idempotent** — An operation that produces the same result whether you apply it once or many times. Most setup scripts in this course are written to be idempotent so re-running is safe. *See: Module 7.*

**init system** — The very first process the kernel starts after boot (PID 1). On modern Linux it is **systemd**, which then starts everything else. *See: Module 12.*

**inode** — The on-disk record that holds a file's metadata (permissions, owner, size, block locations) — everything about the file except its name. *See: Module 5.*

**interface** — A network connection point on your machine (like `enp0s1` or `lo`). `ip a` lists them. *See: Module 9.*

**IPv4** — The classic four-number IP address format like `192.168.252.17`. Contrast with IPv6 (much longer, hex-colon notation). *See: Module 9.*

## J

**journal** — The log database systemd writes to. Query it with `journalctl` (e.g., `journalctl -u nginx.service` for one service's logs). *See: Module 12.*

## K

**kernel** — The core of the operating system — the part that talks to hardware and manages memory, processes, and devices. "Linux" technically refers to *just* the kernel; Ubuntu is the distribution wrapped around it. *See: Module 1.*

**key pair (SSH)** — Two matched cryptographic files: a **private key** (no extension, never share, lives in `~/.ssh/`) and a **public key** (`.pub`, safe to share, gets installed on servers that should trust you). *See: Module 2.*

## L

**load average** — Three numbers showing how busy the system has been over the last 1, 5, and 15 minutes. Roughly: "how many processes are wanting CPU on average." *See: Module 10.*

**localhost / loopback** — `127.0.0.1` (or the `lo` interface) — a fake network that points back at the same machine. Used for testing or for processes that only talk to themselves. *See: Module 9.*

**loop device** — A virtual block device backed by a regular file, so a file can be treated as if it were a disk. `losetup --find --show file.img` attaches one. *See: Module 11.*

## M

**man page** — The built-in reference manual for a command. `man ls` opens it; `q` quits. The number in `passwd(5)` is the section: 1 = user commands, 5 = file formats, 8 = admin commands. *See: Module 3.*

**mask (systemd)** — A stronger form of `disable` for a service: it symlinks the unit to `/dev/null` so the service cannot be started at all, even by accident or by a dependency. *See: Module 14.*

**mkfs** — "Make filesystem" — the command that formats a block device with a chosen filesystem type. **Destructive** — it erases anything that was on the device. *See: Module 11.*

**mount / mount point** — Attaching a filesystem to a directory in the existing tree, so its contents appear "under" that directory. The directory is the mount point. Unlike Windows drive letters, every filesystem on Linux is mounted somewhere under `/`. *See: Module 11.*

**Multipass** — Canonical's free tool for spinning up Ubuntu virtual machines on macOS, Windows, and Linux. This course's lab environment. *See: Setup Guide.*

## N

**name resolution** — Translating a name (`ubuntu.com`) into an IP address. Usually done via DNS, but `/etc/hosts` is checked first. *See: Modules 9, 13a.*

**netplan** — Ubuntu's network configuration tool — YAML files under `/etc/netplan/` that describe the persistent network setup. (RHEL uses NetworkManager / `nmcli` instead.) *See: Module 13a.*

**nice / niceness** — A "politeness" number from -20 (greediest) to 19 (most polite) that hints to the scheduler how much CPU a process should get when others want some. Change with `renice`. *See: Module 10.*

## O

**owner** — The user account that owns a file (the first name in `ls -l` output). Files also have a group owner. Change with `chown` / `chgrp`. *See: Module 6.*

## P

**package** — A bundle of files (a program plus its config and docs) that the package manager installs as a single unit. *See: Module 7.*

**package manager** — The tool that installs, updates, and removes packages and tracks what is installed (`apt` on Ubuntu, `dnf` on RHEL). *See: Module 7.*

**permissions (mode)** — The three-digit number on a file (like `640`, `755`, `2770`) that controls who can read, write, and execute it. Each digit is owner / group / other; r=4, w=2, x=1. *See: Module 6.*

**PID** — Process ID — a number the kernel assigns to each running process. PID 1 is always `init` (systemd on Ubuntu). *See: Module 10.*

**pipe (`|`)** — A shell construct that sends one command's standard output directly into the next command's standard input, with no temp file in between. Example: `dpkg -l | wc -l` counts installed packages by piping the list into a line-counter. *See: Module 1.*

**ports** — Numbers (0–65535) that identify a specific service on a machine — port 22 is SSH, 80 is HTTP, 443 is HTTPS. `ss -tulpn` shows what's listening. *See: Module 13a.*

**PPID** — Parent process ID — the PID of the process that started this one. Use `pstree` to see parent/child relationships visually. *See: Module 10.*

**principle of least privilege** — Give every user, process, and file exactly the access it needs to do its job and no more. The reason 600 beats 666. *See: Module 14.*

**process** — A running instance of a program. Every running program (your shell, every daemon, every command in flight) is a process with a PID. *See: Module 10.*

**prompt** — The text the shell shows before each command — `ubuntu@labvm:~$`. The `$` (or `#` for root) is the "your turn to type" signal. *See: Module 1.*

## R

**redirection (`>`, `>>`, `<`, `2>`)** — Shell syntax that sends a command's output to a file (`>` overwrite, `>>` append) or sends a file in as input (`<`). `2>` specifically redirects stderr. *See: Module 3.*

**repository** — A server full of packages the package manager downloads from. Ubuntu's defaults live in `/etc/apt/sources.list`. *See: Module 7.*

**root** — The all-powerful administrator user (UID 0). The `#` in the shell prompt means you are root. You usually become root via `sudo` rather than logging in as root directly. *See: Module 2.*

**root directory (`/`)** — The single directory at the top of the Linux filesystem tree. Everything else hangs off it. Not to be confused with the root user or `/root` (the root user's home directory). *See: Module 4.*

## S

**service** — A long-running program managed by systemd (a web server, SSH, cron). Started, stopped, and queried with `systemctl`. *See: Module 12.*

**setgid bit** — A permission bit on a directory (`chmod g+s`) that makes new files inside the directory inherit the directory's group instead of the creator's group — useful for shared team folders. *See: Module 6.*

**setuid (SUID) bit** — A permission bit on an executable (the `s` in `-rwsr-xr-x`) that makes the program run as the file's owner regardless of who launched it. `/usr/bin/passwd` is SUID-root so any user can change their own password file. *See: Modules 4, 14.*

**shebang (`#!`)** — The first line of a script that tells the kernel which interpreter to use. `#!/usr/bin/env bash` means "run me with bash." *See: Module 3.*

**shell** — The program that reads the commands you type and runs them. Your text interface to the system. Ubuntu's default is bash. *See: Module 1.*

**shell variable** — A name=value pair that exists only in your current shell. Promote it to an environment variable with `export`. *See: Module 3.*

**signal** — A small message the kernel can send to a process: SIGTERM (15, "please exit"), SIGKILL (9, "die now"), SIGHUP (1, "reload"). Send with `kill <PID>`. *See: Module 10.*

**snapshot** — A point-in-time copy of a VM's state you can roll back to. Take one before any risky lab: `multipass stop labvm && multipass snapshot --name BEFORE-X labvm && multipass start labvm`. *See: Setup Guide, Module 10.*

**SSH** — Secure Shell — the encrypted protocol used to log into and run commands on a remote machine. *See: Module 2.*

**stderr** — Standard error (file descriptor 2) — the stream a program writes errors and diagnostic messages to, separate from its normal output. *See: Module 3.*

**stdin** — Standard input (file descriptor 0) — the stream a program reads input from (usually your keyboard, or a pipe, or a redirected file). *See: Module 3.*

**stdout** — Standard output (file descriptor 1) — the stream a program writes its normal output to (usually your terminal, or a pipe, or a redirected file). *See: Module 3.*

**sudo** — "Substitute user, do" — run one command as another user (almost always root). Prompts for *your* password, then runs the command with elevated privileges. *See: Module 1.*

**`su -`** — "Switch user" — log in as another user (a full login shell). Prompts for the **target** user's password (different from `sudo`, which asks for yours). *See: Module 2.*

**systemctl** — The command you use to talk to systemd (start, stop, enable, disable, query the status of services). *See: Module 12.*

**systemd** — The init system on modern Ubuntu and RHEL — PID 1, the manager that starts, supervises, and stops every service on the box. *See: Module 12.*

## T

**tar** — The archiver that bundles a directory tree into a single file (`tar -czf archive.tar.gz dir/` to create, `tar -tzf` to list, `tar -xzf` to extract). The `z` adds gzip compression. *See: Module 7.*

**target (systemd)** — A grouping of units roughly equivalent to an old-style "runlevel." `multi-user.target` = text-only multi-user system; `graphical.target` = same plus a GUI. *See: Module 12.*

**TCP / UDP** — The two main transport protocols above IP. TCP is connection-oriented (HTTP, SSH); UDP is connectionless (DNS, NTP). Both are separate from ICMP. *See: Module 9.*

**test operator (`[[ -n "$X" ]]`, `[[ -z "$X" ]]`)** — Bash test syntax used in `if` statements. `-n` is true if the string is **n**on-empty; `-z` is true if it is **z**ero-length (empty); `-e` true if a file exists; `-f` true if it's a regular file. *See: Module 3.*

**TEST-NET-1 (`192.0.2.0/24`)** — An IPv4 range reserved by RFC 5737 for documentation and examples — guaranteed not to collide with real hosts. *See: Module 13a.*

**tmpfs** — A filesystem that lives in RAM, not on disk. Used for `/tmp`, `/run`, and other places that should be fast and disappear on reboot. *See: Module 5.*

**tty / pts** — Terminal device names. `tty1` is a physical console; `pts/0`, `pts/1` are pseudo-terminals (SSH sessions, terminal-app windows). `who` shows who is on which. *See: Module 2.*

## U

**unit (systemd)** — A configuration file that describes one thing systemd manages — a service, a target, a timer, a mount. The most common is a `.service` unit. *See: Module 12.*

**user-data** — The YAML file you hand to cloud-init at first boot to declare what the VM should look like (users, packages, files, services). *See: Module 13b.*

**UUID** — Universally Unique Identifier — a long random-looking string used to refer to a filesystem (in `/etc/fstab`) instead of an unstable `/dev/sdaN` path. *See: Module 11.*

## V

**variable** — A name that holds a value in the shell or in a script. Set with `NAME=value` (no spaces around `=`), read with `$NAME` or `${NAME}`. The `${...}` braces are required when the name is touching letters or digits: `${USER}_log` works; `$USER_log` would look for a variable named `USER_log`. *See: Module 3.*

**virtual machine (VM)** — A complete computer simulated in software, running its own kernel and OS on top of your real machine. Multipass creates Ubuntu VMs. *See: Setup Guide.*

## W

**world-writable** — A file with the `o+w` permission bit set (the last digit of its mode includes 2 or 6 or 7) — any user on the system can modify it. Almost always a mistake. *See: Module 14.*

## Y

**YAML** — A human-readable data format used for cloud-init, netplan, Kubernetes manifests, and many other configs. Uses indentation (spaces, not tabs) for nesting and `- ` for list items. *See: Modules 13a, 13b.*
