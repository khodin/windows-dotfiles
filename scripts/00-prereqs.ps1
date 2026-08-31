<#
.SYNOPSIS
    Prerequisite checks and initial environment bootstrap.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " [00] Checking System Prerequisites     " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Check Execution Policy
$currentPolicy = Get-ExecutionPolicy -Scope Process
if ($currentPolicy -ne "Bypass" -and $currentPolicy -ne "Unrestricted") {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    Write-Host "[+] Execution Policy set to Bypass for current process." -ForegroundColor Green
}

# 2. Check Admin Rights
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "[+] Running with Administrator privileges." -ForegroundColor Green
} else {
    Write-Host "[!] Note: Running as standard user. Some installers requiring system-wide changes may prompt for UAC." -ForegroundColor Yellow
}

# 3. Check Winget
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $wingetVer = (winget --version) 2>$null
    Write-Host "[+] Winget is available (Version: $wingetVer)." -ForegroundColor Green
    Write-Host "[*] Updating Winget sources..." -ForegroundColor Gray
    try {
        winget source update --accept-source-agreements | Out-Null
        Write-Host "[+] Winget sources updated." -ForegroundColor Green
    } catch {
        Write-Host "[!] Warning: Winget source update returned non-zero exit, continuing..." -ForegroundColor Yellow
    }
} else {
    Write-Error "Winget is not found on this system. Please install the App Installer from the Microsoft Store or GitHub release: https://github.com/microsoft/winget-cli/releases"
}

# 4. Ensure standard workspace directories exist
$dirsToCreate = @(
    "$env:USERPROFILE\code",
    "$env:USERPROFILE\Documents\WindowsPowerShell",
    "$env:USERPROFILE\Documents\PowerShell",
    "$env:USERPROFILE\.ssh"
)

foreach ($dir in $dirsToCreate) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "[+] Created directory: $dir" -ForegroundColor Green
    }
}

Write-Host "`n[+] Prerequisites verified successfully!`n" -ForegroundColor Green
