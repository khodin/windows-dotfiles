<#
.SYNOPSIS
    Configures WSL2 and automatically installs the Ubuntu distribution.
.DESCRIPTION
    Ensures WSL is installed and enabled, sets the default version to WSL2,
    automatically installs the Ubuntu distribution (without blocking on first-launch setup),
    configures Ubuntu as the default distribution, and verifies operational status.
.PARAMETER Distro
    The WSL distribution name to install and configure (defaults to 'Ubuntu').
.PARAMETER Force
    Forces distribution re-installation or update.
#>
[CmdletBinding()]
param(
    [string]$Distro = "Ubuntu",
    [switch]$Force
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " [05] Configuring WSL & $Distro Distro " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Helper to retrieve currently installed distributions safely
function Get-InstalledWslDistros {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        return @()
    }
    $raw = wsl.exe --list --quiet 2>$null
    if (-not $raw) {
        return @()
    }
    return @($raw | ForEach-Object { $_ -replace "\x00", "" } | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() })
}

# 2. Check WSL subsystem availability
Write-Host "`n--- Checking WSL Subsystem ---" -ForegroundColor Yellow
$hasWsl = [bool](Get-Command wsl.exe -ErrorAction SilentlyContinue)

if (-not $hasWsl) {
    Write-Host "[*] wsl.exe was not found. Attempting to install Microsoft WSL via Winget..." -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $wslProc = Start-Process -FilePath "winget" -ArgumentList @(
            "install",
            "--id", "Microsoft.WSL",
            "--exact",
            "--accept-package-agreements",
            "--accept-source-agreements",
            "--silent"
        ) -Wait -NoNewWindow -PassThru

        if ($wslProc.ExitCode -eq 0) {
            Write-Host "[+] Microsoft.WSL package installed successfully." -ForegroundColor Green
        } else {
            Write-Host "[!] Winget install returned exit code $($wslProc.ExitCode)." -ForegroundColor Yellow
        }
    } else {
        Write-Error "wsl.exe is not available and Winget is not installed. Cannot proceed with WSL setup."
        return
    }
} else {
    Write-Host "[+] WSL CLI (wsl.exe) is available." -ForegroundColor Green
}

# 3. Ensure WSL default version is 2
Write-Host "`n--- Configuring WSL2 Default Version ---" -ForegroundColor Yellow
try {
    wsl.exe --set-default-version 2 2>$null
    Write-Host "[+] WSL default version set to 2." -ForegroundColor Green
} catch {
    Write-Host "[!] Note: Could not set default version to 2: $_" -ForegroundColor Yellow
}

# 4. Check & Install Distribution
Write-Host "`n--- Checking Distribution: $Distro ---" -ForegroundColor Yellow
$installedDistros = Get-InstalledWslDistros
$isDistroInstalled = ($installedDistros -contains $Distro) -or ($installedDistros -match "^$Distro$")

if ($isDistroInstalled -and -not $Force) {
    Write-Host "[+] WSL distribution '$Distro' is already installed." -ForegroundColor Green
} else {
    Write-Host "[*] Installing WSL distribution: $Distro..." -ForegroundColor Yellow
    Write-Host "    Downloading and registering '$Distro' in WSL (this may take several minutes)..." -ForegroundColor Gray

    $installArgs = @("--install", "-d", $Distro, "--no-launch")
    $installProc = Start-Process -FilePath "wsl.exe" -ArgumentList $installArgs -Wait -NoNewWindow -PassThru

    if ($installProc.ExitCode -eq 0) {
        Write-Host "[+] Successfully installed WSL distribution: $Distro" -ForegroundColor Green
    } elseif ($installProc.ExitCode -eq 3010 -or $installProc.ExitCode -eq 1641) {
        Write-Host "[!] WSL installation completed, but a system reboot is required." -ForegroundColor Yellow
    } else {
        Write-Host "[!] Primary install command returned code $($installProc.ExitCode). Trying alternative syntax..." -ForegroundColor Yellow
        $retryArgs = @("--install", $Distro, "--no-launch")
        $retryProc = Start-Process -FilePath "wsl.exe" -ArgumentList $retryArgs -Wait -NoNewWindow -PassThru
        if ($retryProc.ExitCode -eq 0) {
            Write-Host "[+] Successfully installed WSL distribution: $Distro" -ForegroundColor Green
        } else {
            Write-Host "[!] Failed to install $Distro (Exit code: $($retryProc.ExitCode))." -ForegroundColor Red
            Write-Host "    Manual install command: wsl.exe --install -d $Distro" -ForegroundColor Cyan
        }
    }
}

# 5. Set as Default Distribution
$updatedDistros = Get-InstalledWslDistros
if ($updatedDistros -contains $Distro -or $updatedDistros -match "^$Distro$") {
    try {
        wsl.exe --set-default $Distro 2>$null
        Write-Host "[+] Set '$Distro' as default WSL distribution." -ForegroundColor Green
    } catch {}
}

# 6. Display WSL Status & Distribution List
Write-Host "`n--- WSL Status & Distributions ---" -ForegroundColor Yellow
try {
    wsl.exe --list --verbose 2>$null
} catch {}

# 7. Post-install instructions
Write-Host "`n[*] Usage & Quickstart:" -ForegroundColor Cyan
Write-Host "  - Open Ubuntu terminal: run 'wsl' in PowerShell, or open an 'Ubuntu' tab in Windows Terminal." -ForegroundColor White
Write-Host "  - First launch: Ubuntu will complete initialization and prompt for your UNIX username and password." -ForegroundColor White
Write-Host "  - VS Code integration: run 'code .' from inside Ubuntu, or use 'Connect to WSL' in VS Code." -ForegroundColor White

Write-Host "`n[+] WSL environment configuration complete!`n" -ForegroundColor Green
