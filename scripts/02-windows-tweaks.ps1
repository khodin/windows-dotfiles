<#
.SYNOPSIS
    Applies recommended Windows preferences and developer tweaks.
#>
[CmdletBinding()]
param(
    [switch]$RestartExplorer
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " [02] Applying Windows Settings & Tweaks" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Set-RegistryValueSafe {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$PropertyType = "DWord",
        [string]$Description
    )

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $PropertyType -Force -ErrorAction Stop | Out-Null
        Write-Host "[+] $Description" -ForegroundColor Green
    } catch {
        Write-Host "[-] Skipped: $Description (Requires Administrator elevation)" -ForegroundColor Yellow
    }
}

# 1. File Explorer Tweaks (User level)
Write-Host "`n--- File Explorer Tweaks ---" -ForegroundColor Yellow
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "HideFileExt" -Value 0 -Description "Show file extensions for known file types"

Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "Hidden" -Value 1 -Description "Show hidden files and folders"

Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "LaunchTo" -Value 1 -Description "Open File Explorer to 'This PC'"

Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "NavPaneExpandToCurrentFolder" -Value 1 -Description "Expand File Explorer navigation pane to current folder"

# 2. Theme Tweaks (Dark Mode)
Write-Host "`n--- System Theme Tweaks ---" -ForegroundColor Yellow
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
    -Name "AppsUseLightTheme" -Value 0 -Description "Enable Dark Mode for Applications"

Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
    -Name "SystemUsesLightTheme" -Value 0 -Description "Enable Dark Mode for Windows System"

# 3. Start Menu Search (Disable Bing web results)
Write-Host "`n--- Start Menu Search Tweaks ---" -ForegroundColor Yellow
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
    -Name "AllowSearchBoxSuggestions" -Value 0 -Description "Disable Search Box Suggestions"

Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
    -Name "BingSearchEnabled" -Value 0 -Description "Disable Bing Search Integration"

# 4. Developer / System-wide Tweaks (Requires Admin)
Write-Host "`n--- System-wide & Developer Tweaks ---" -ForegroundColor Yellow
Set-RegistryValueSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
    -Name "LongPathsEnabled" -Value 1 -Description "Enable NTFS Long File Paths (> 260 chars)"

Set-RegistryValueSafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" `
    -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Description "Enable Windows Developer Mode"

if ($RestartExplorer) {
    Write-Host "`n[*] Restarting Windows Explorer to apply visual changes..." -ForegroundColor Yellow
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer
}

Write-Host "`n[+] Windows settings applied successfully!`n" -ForegroundColor Green
