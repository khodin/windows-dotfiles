<#
.SYNOPSIS
    Main setup orchestrator for Windows workstation configuration.
.DESCRIPTION
    Automates package installation, Windows settings, dotfile deployment,
    and developer environment configuration.
.PARAMETER All
    Runs all setup stages sequentially.
.PARAMETER Apps
    Runs the application installation stage.
.PARAMETER Tweaks
    Applies Windows settings and registry tweaks.
.PARAMETER Dotfiles
    Deploys dotfiles (PowerShell profile, .wslconfig, Terminal, etc.).
.PARAMETER Dev
    Configures developer tools and VS Code extensions.
.PARAMETER WSL
    Configures WSL2 and automatically installs/verifies the Ubuntu distribution.
.PARAMETER Backup
    Exports current machine state back to the repository.
.PARAMETER Elevate
    Restarts the script in an elevated Administrator session.
#>
[CmdletBinding()]
param(
    [switch]$All,
    [switch]$Apps,
    [switch]$Tweaks,
    [switch]$Dotfiles,
    [switch]$Dev,
    [switch]$WSL,
    [switch]$Backup,
    [switch]$Elevate,
    [string[]]$Categories
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Elevation check & self-elevation
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($Elevate -and -not $isAdmin) {
    Write-Host "[*] Relaunching setup with Administrator privileges..." -ForegroundColor Yellow
    $argsList = @("-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$($MyInvocation.MyCommand.Path)`"")
    if ($All) { $argsList += "-All" }
    if ($Apps) { $argsList += "-Apps" }
    if ($Tweaks) { $argsList += "-Tweaks" }
    if ($Dotfiles) { $argsList += "-Dotfiles" }
    if ($Dev) { $argsList += "-Dev" }
    if ($WSL) { $argsList += "-WSL" }
    Start-Process -FilePath "powershell.exe" -ArgumentList $argsList -Verb RunAs
    return
}

# 2. Stage execution functions
function Invoke-Prereqs {
    & (Join-Path $scriptDir "scripts\00-prereqs.ps1")
}

function Invoke-Apps {
    $script = Join-Path $scriptDir "scripts\01-install-apps.ps1"
    if ($Categories) {
        & $script -Categories $Categories
    } elseif ($All) {
        & $script -All
    } else {
        & $script
    }
}

function Invoke-Tweaks {
    & (Join-Path $scriptDir "scripts\02-windows-tweaks.ps1") -RestartExplorer
}

function Invoke-Dotfiles {
    & (Join-Path $scriptDir "scripts\03-apply-dotfiles.ps1")
}

function Invoke-Dev {
    & (Join-Path $scriptDir "scripts\04-dev-tools.ps1")
}

function Invoke-WSL {
    & (Join-Path $scriptDir "scripts\05-wsl-setup.ps1")
}

function Invoke-Backup {
    & (Join-Path $scriptDir "scripts\backup.ps1")
}

# 3. Direct switch routing
if ($All) {
    Invoke-Prereqs
    Invoke-Apps
    Invoke-Tweaks
    Invoke-Dotfiles
    Invoke-Dev
    Invoke-WSL
    Write-Host "`n=======================================================" -ForegroundColor Green
    Write-Host "  FULL SETUP COMPLETE! Please restart your terminal.   " -ForegroundColor Green
    Write-Host "=======================================================`n" -ForegroundColor Green
    return
}

$hasCustomFlag = $Apps -or $Tweaks -or $Dotfiles -or $Dev -or $WSL -or $Backup

if ($hasCustomFlag) {
    Invoke-Prereqs
    if ($Apps) { Invoke-Apps }
    if ($Tweaks) { Invoke-Tweaks }
    if ($Dotfiles) { Invoke-Dotfiles }
    if ($Dev) { Invoke-Dev }
    if ($WSL) { Invoke-WSL }
    if ($Backup) { Invoke-Backup }
    return
}

# 4. Interactive Menu
Clear-Host
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "        Windows Workstation Setup & Dotfiles           " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
if (-not $isAdmin) {
    Write-Host " [!] Status: Standard User (Tip: Run with -Elevate for Admin)" -ForegroundColor Yellow
} else {
    Write-Host " [+] Status: Administrator" -ForegroundColor Green
}
Write-Host "-------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " [1] Full Setup (Runs all stages below)" -ForegroundColor White
Write-Host " [2] Install Applications (Winget packages)" -ForegroundColor White
Write-Host " [3] Apply Windows Settings & Tweaks" -ForegroundColor White
Write-Host " [4] Deploy Dotfiles (PowerShell, WSL, Terminal)" -ForegroundColor White
Write-Host " [5] Configure Developer Environment (Git, VS Code)" -ForegroundColor White
Write-Host " [6] Install & Configure WSL (Ubuntu Distribution)" -ForegroundColor White
Write-Host " [7] Export Current Machine State (Backup to repo)" -ForegroundColor White
Write-Host " [E] Restart in Elevated Administrator Mode" -ForegroundColor Yellow
Write-Host " [0] Exit" -ForegroundColor DarkGray
Write-Host "=======================================================" -ForegroundColor Cyan

$choice = Read-Host "`nSelect an option"

switch ($choice) {
    "1" {
        Invoke-Prereqs
        Invoke-Apps
        Invoke-Tweaks
        Invoke-Dotfiles
        Invoke-Dev
        Invoke-WSL
        Write-Host "`n[+] Full setup complete!" -ForegroundColor Green
    }
    "2" {
        Invoke-Prereqs
        Invoke-Apps
    }
    "3" {
        Invoke-Tweaks
    }
    "4" {
        Invoke-Dotfiles
    }
    "5" {
        Invoke-Dev
    }
    "6" {
        Invoke-WSL
    }
    "7" {
        Invoke-Backup
    }
    "E" {
        & "$($MyInvocation.MyCommand.Path)" -Elevate
    }
    "0" {
        Write-Host "Exiting setup." -ForegroundColor Gray
    }
    default {
        Write-Host "Invalid option selected." -ForegroundColor Red
    }
}
