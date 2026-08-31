<#
.SYNOPSIS
    Deploys dotfiles and configuration templates to the user profile.
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " [03] Deploying Dotfiles & Configs      " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$dotfilesRoot = Join-Path $repoRoot "dotfiles"

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $env:USERPROFILE ".dotfiles_backup\$timestamp"

function Deploy-ConfigFile {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$Description
    )

    if (-not (Test-Path $SourcePath)) {
        Write-Host "[!] Source not found: $SourcePath" -ForegroundColor Yellow
        return
    }

    $destDir = Split-Path -Parent $DestinationPath
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if (Test-Path $DestinationPath) {
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        $fileName = Split-Path -Leaf $DestinationPath
        Copy-Item -Path $DestinationPath -Destination (Join-Path $backupDir $fileName) -Force
        Write-Host "  -> Backed up existing to: .dotfiles_backup\$timestamp\$fileName" -ForegroundColor Gray
    }

    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
    Write-Host "[+] $Description deployed to: $DestinationPath" -ForegroundColor Green
}

# 1. Deploy PowerShell Profile (Windows PowerShell 5.1 & PowerShell 7+)
$psProfileSrc = Join-Path $dotfilesRoot "Microsoft.PowerShell_profile.ps1"
$ps5ProfileDest = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$ps7ProfileDest = Join-Path $env:USERPROFILE "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

Deploy-ConfigFile -SourcePath $psProfileSrc -DestinationPath $ps5ProfileDest -Description "PowerShell 5.1 Profile"
Deploy-ConfigFile -SourcePath $psProfileSrc -DestinationPath $ps7ProfileDest -Description "PowerShell 7+ Profile"

# 2. Deploy .wslconfig
$wslConfigSrc = Join-Path $dotfilesRoot ".wslconfig"
$wslConfigDest = Join-Path $env:USERPROFILE ".wslconfig"
Deploy-ConfigFile -SourcePath $wslConfigSrc -DestinationPath $wslConfigDest -Description "WSL2 Configuration"

# 3. Deploy .gitconfig (Safely preserve user name & email if already configured)
$gitConfigSrc = Join-Path $dotfilesRoot ".gitconfig"
$gitConfigDest = Join-Path $env:USERPROFILE ".gitconfig"

$existingUserName = ""
$existingUserEmail = ""
if (Get-Command git -ErrorAction SilentlyContinue) {
    $existingUserName = (git config --global user.name) 2>$null
    $existingUserEmail = (git config --global user.email) 2>$null
}

Deploy-ConfigFile -SourcePath $gitConfigSrc -DestinationPath $gitConfigDest -Description "Git Configuration"

if ($existingUserName -and $existingUserEmail) {
    git config --global user.name "$existingUserName"
    git config --global user.email "$existingUserEmail"
    Write-Host "[+] Preserved Git identity: $existingUserName <$existingUserEmail>" -ForegroundColor Green
}

# 4. Deploy Windows Terminal Settings
$wtConfigSrc = Join-Path $dotfilesRoot "WindowsTerminal\settings.json"
$wtLocalState = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$wtConfigDest = Join-Path $wtLocalState "settings.json"

if (Test-Path $wtLocalState) {
    Deploy-ConfigFile -SourcePath $wtConfigSrc -DestinationPath $wtConfigDest -Description "Windows Terminal Settings"
} else {
    Write-Host "[*] Windows Terminal package directory not found yet (will apply once Terminal is run)." -ForegroundColor Gray
}

Write-Host "`n[+] Dotfiles deployment complete!`n" -ForegroundColor Green
