<#
.SYNOPSIS
    Remote bootstrap script for a fresh Windows installation.
.DESCRIPTION
    Installs Git and Winget prerequisites, clones the windows-dotfiles repository,
    and initiates the full setup workflow.
.EXAMPLE
    irm https://raw.githubusercontent.com/khodin/windows-dotfiles/main/bootstrap.ps1 | iex
#>

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "   Windows Setup & Dotfiles - Fresh Machine Bootstrap  " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# 1. Ensure Execution Policy
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# 2. Check Admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Warning: Running without Administrator rights." -ForegroundColor Yellow
    Write-Host "    Some installers might require elevation prompts." -ForegroundColor Yellow
}

# 3. Check / Install Winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "Winget is not available. Please install App Installer from Microsoft Store or update Windows."
}

# 4. Check / Install Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[*] Installing Git via Winget..." -ForegroundColor Yellow
    winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements --silent
    $env:Path = "$env:LOCALAPPDATA\Programs\Git\cmd;$env:ProgramFiles\Git\cmd;$env:Path"
}

# 5. Determine Target Repo
$targetDir = "$env:USERPROFILE\code\windows-dotfiles"

if (-not (Test-Path "$env:USERPROFILE\code")) {
    New-Item -ItemType Directory -Path "$env:USERPROFILE\code" -Force | Out-Null
}

if (-not (Test-Path "$targetDir\.git")) {
    $repoUrl = "https://github.com/khodin/windows-dotfiles.git"
    Write-Host "[*] Cloning setup repository to: $targetDir..." -ForegroundColor Yellow
    git clone $repoUrl $targetDir
} else {
    Write-Host "[+] Repository already cloned at: $targetDir" -ForegroundColor Green
    Set-Location $targetDir
    git pull 2>$null
}

# 6. Launch Setup
Set-Location $targetDir
Write-Host "`n[*] Starting main setup orchestrator...`n" -ForegroundColor Green
& "$targetDir\setup.ps1"
