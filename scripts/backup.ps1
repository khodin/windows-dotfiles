<#
.SYNOPSIS
    Exports current system configurations, winget packages, and VS Code extensions back into the repository.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " [*] Exporting Machine State to Repo    " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$configDir = Join-Path $repoRoot "config"
$dotfilesDir = Join-Path $repoRoot "dotfiles"

# 1. Export Winget packages
Write-Host "`n[*] Exporting Winget package list..." -ForegroundColor Yellow
$wingetExportPath = Join-Path $configDir "winget-export.json"
winget export -o "$wingetExportPath" --accept-source-agreements 2>$null
if (Test-Path $wingetExportPath) {
    Write-Host "[+] Winget export saved to: config\winget-export.json" -ForegroundColor Green
}

# 2. Export VS Code Extensions
Write-Host "`n[*] Exporting VS Code extensions..." -ForegroundColor Yellow
$vscodeExportPath = Join-Path $configDir "vscode-extensions.txt"
if (Get-Command code -ErrorAction SilentlyContinue) {
    $extensions = code --list-extensions
    $content = "# VS Code Extensions Exported on $(Get-Date -Format 'yyyy-MM-dd')`n"
    $content += ($extensions -join "`n")
    Set-Content -Path $vscodeExportPath -Value $content -Encoding utf8
    Write-Host "[+] Exported $($extensions.Count) VS Code extensions to: config\vscode-extensions.txt" -ForegroundColor Green
} else {
    Write-Host "[-] VS Code CLI not available, skipping extension export." -ForegroundColor Gray
}

# 3. Export Dotfiles from User Profile
Write-Host "`n[*] Syncing dotfiles from user profile..." -ForegroundColor Yellow

# PowerShell Profile
if (Test-Path $PROFILE) {
    Copy-Item -Path $PROFILE -Destination (Join-Path $dotfilesDir "Microsoft.PowerShell_profile.ps1") -Force
    Write-Host "[+] Synced PowerShell profile from: $PROFILE" -ForegroundColor Green
}

# .wslconfig
$wslConfigPath = Join-Path $env:USERPROFILE ".wslconfig"
if (Test-Path $wslConfigPath) {
    Copy-Item -Path $wslConfigPath -Destination (Join-Path $dotfilesDir ".wslconfig") -Force
    Write-Host "[+] Synced .wslconfig from: $wslConfigPath" -ForegroundColor Green
}

# Windows Terminal settings
$wtSettings = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wtSettings) {
    $wtDestDir = Join-Path $dotfilesDir "WindowsTerminal"
    if (-not (Test-Path $wtDestDir)) { New-Item -ItemType Directory -Path $wtDestDir -Force | Out-Null }
    Copy-Item -Path $wtSettings -Destination (Join-Path $wtDestDir "settings.json") -Force
    Write-Host "[+] Synced Windows Terminal settings from: $wtSettings" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Export complete! Ready to git commit.  " -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
