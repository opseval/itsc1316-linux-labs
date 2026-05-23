<#
  preflight.ps1  -  ITSC-1316 environment check (Windows / PowerShell)

  Run this on YOUR COMPUTER (not inside a VM) in week 1. It launches a tiny
  throwaway VM, transfers a file into it, runs a command inside it, and
  deletes it - proving the entire lab workflow works on your machine.

  How to run:
    1. Open PowerShell (search "PowerShell" in the Start menu).
    2. Change to this folder, e.g.:  cd $HOME\Downloads
    3. Run:  powershell -ExecutionPolicy Bypass -File .\preflight.ps1

  It cleans up after itself. Total time: a few minutes (longer the first
  time, while Ubuntu downloads).
#>

$VM     = "preflight-test"
$Token  = "itsc1316-$(Get-Date -UFormat %s)"
$TmpDir = [System.IO.Path]::GetTempPath()
$TmpFile = Join-Path $TmpDir "preflight-token.txt"
$pass = 0; $fail = 0; $warn = 0

function Ok($m)   { Write-Host "  [PASS] $m"; $script:pass++ }
function No($m)   { Write-Host "  [FAIL] $m"; $script:fail++ }
function Note($m) { Write-Host "  [INFO] $m" }

function Cleanup {
  Write-Host ""
  Write-Host ">> Cleaning up the throwaway VM..."
  # Use --purge to permanently remove ONLY this script's VM. A plain
  # 'multipass purge' would also delete any OTHER instances the student
  # had in the "deleted" pending-purge state - a real data-loss risk.
  multipass delete --purge $VM 2>$null | Out-Null
  Remove-Item $TmpFile -ErrorAction SilentlyContinue
  Write-Host ">> Cleanup done."
}

function Print-Summary {
  Write-Host ""
  Write-Host "=================================================="
  Write-Host "  Passed: $pass    Failed: $fail    Warnings: $warn"
  if ($fail -eq 0 -and $pass -gt 0) {
    Write-Host "  RESULT: Your computer is READY for the labs."
    Write-Host "  Submit a screenshot of this summary for the Week 1 check-in."
  } else {
    Write-Host "  RESULT: Something needs attention - see the [FAIL] lines above,"
    Write-Host "  then post them in the Q&A board with this output."
  }
  Write-Host "=================================================="
}

Write-Host "=================================================="
Write-Host " ITSC-1316 Preflight Check (Windows / PowerShell)"
Write-Host "=================================================="
Write-Host ""

try {
  # 1. Multipass installed?
  if (Get-Command multipass -ErrorAction SilentlyContinue) {
    $ver = (multipass version | Select-Object -First 1)
    Ok "Multipass is installed ($ver)"
  } else {
    No "Multipass is NOT installed. See docs/01-multipass-setup-guide.md, then re-run."
    Write-Host ""
    Write-Host "Stopping early - install Multipass first."
    return
  }

  # 2. Launch a throwaway VM
  Write-Host ""
  Write-Host ">> Launching a small test VM (this can take a few minutes the first time)..."
  multipass launch 22.04 --name $VM --cpus 1 --memory 1G --disk 5G 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Ok "Launched a test VM successfully"
  } else {
    No "Could not launch a VM. Common causes on Windows: virtualization disabled"
    Write-Host "         in BIOS/UEFI, Hyper-V not enabled (Pro/Enterprise) or VirtualBox"
    Write-Host "         not installed (Home edition), or not enough free RAM/disk."
    Write-Host "         Try running:  multipass launch 22.04 --name $VM   to see the full error."
    return  # finally{} below runs Cleanup + Print-Summary
  }

  # 3. Transfer a file IN
  # -Encoding ASCII so Windows PowerShell 5.1 doesn't emit UTF-16-LE (with BOM),
  # which would garble what 'cat' reads back inside the Linux VM.
  Set-Content -Path $TmpFile -Value $Token -NoNewline -Encoding ASCII
  multipass transfer $TmpFile "$($VM):/home/ubuntu/preflight-token.txt" 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "Transferred a file into the VM" }
  else { No "File transfer into the VM failed" }

  # 4. Run a command INSIDE the VM and read the file back.
  # Wrap in "$(...)" so a null result (failed exec) is coerced to '' instead
  # of crashing .Trim() with "method on a null-valued expression".
  $got = "$(multipass exec $VM -- cat /home/ubuntu/preflight-token.txt 2>$null)".Trim()
  if ($got -eq $Token) { Ok "Ran a command inside the VM and read the file back correctly" }
  else { No "Could not verify command execution inside the VM (got: '$got')" }

  # 5. sudo works inside the VM
  $who = "$(multipass exec $VM -- sudo whoami 2>$null)".Trim()
  if ($who -eq "root") { Ok "sudo works inside the VM (you can perform admin tasks)" }
  else { No "sudo did not return root inside the VM" }

  # 6. Network from inside the VM (real FAIL — labs install packages).
  # Calling getent directly avoids PowerShell 5.1's native-arg parsing eating
  # the quotes around 'bash -c "..."' and breaking shell-side redirection.
  multipass exec $VM -- getent hosts ubuntu.com 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "The VM has working internet name resolution" }
  else { No "The VM could not resolve ubuntu.com - labs that install packages will fail. Check your network/VPN (especially work/campus restrictions)." }

  # 7. VM list snapshot
  Write-Host ""
  Note "VM list right now:"
  multipass list | ForEach-Object { "        $_" }
}
finally {
  Cleanup
  # Always show the summary, even on early return — students are told to
  # screenshot it for the Week 1 check-in, so it can't be skipped on failure.
  Print-Summary
}
