<#
.SYNOPSIS
    Installs configured applications using Winget.
.PARAMETER Categories
    Specific categories to install (e.g. core_tools, development, productivity_security, audio_multimedia, browsers).
.PARAMETER All
    Install all enabled packages across all categories.
#>
[CmdletBinding()]
param(
    [string[]]$Categories,
    [switch]$All
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " [01] Installing Windows Applications  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$configPath = Join-Path $repoRoot "config\packages.json"

if (-not (Test-Path $configPath)) {
    Write-Error "Could not find package config at: $configPath"
    return
}

$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
$categoryKeys = $config.categories.PSObject.Properties.Name

if (-not $All -and (-not $Categories -or $Categories.Count -eq 0)) {
    Write-Host "`nAvailable package categories:" -ForegroundColor Yellow
    $index = 1
    $catMap = @{}
    foreach ($catKey in $categoryKeys) {
        $cat = $config.categories.$catKey
        Write-Host " [$index] $($cat.name) ($catKey) - $($cat.packages.Count) apps" -ForegroundColor White
        $catMap[$index] = $catKey
        $index++
    }
    Write-Host " [A] All Categories" -ForegroundColor White
    $selection = Read-Host "`nEnter numbers to install (comma-separated, e.g. 1,2) or 'A' for all"

    if ($selection -match "^[Aa]") {
        $selectedKeys = $categoryKeys
    } else {
        $selectedKeys = @()
        $parts = $selection -split ","
        foreach ($p in $parts) {
            $num = [int]$p.Trim()
            if ($catMap.ContainsKey($num)) {
                $selectedKeys += $catMap[$num]
            }
        }
    }
} elseif ($All) {
    $selectedKeys = $categoryKeys
} else {
    $selectedKeys = $Categories
}

$installedList = @()
$skippedList = @()
$failedList = @()

foreach ($catKey in $selectedKeys) {
    if (-not $config.categories.$catKey) {
        Write-Host "[!] Skipping unknown category: $catKey" -ForegroundColor Yellow
        continue
    }

    $category = $config.categories.$catKey
    Write-Host "`n>>> Processing Category: $($category.name) <<<" -ForegroundColor Cyan

    foreach ($pkg in $category.packages) {
        if ($pkg.enabled -ne $true) {
            Write-Host "[-] Skipping disabled: $($pkg.name) ($($pkg.id))" -ForegroundColor DarkGray
            continue
        }

        Write-Host "[*] Checking: $($pkg.name)..." -NoNewline

        # Check for manual download packages (e.g. DaVinci Resolve)
        if ($pkg.type -eq "manual_download") {
            if ($pkg.checkPath -and (Test-Path $pkg.checkPath)) {
                Write-Host " [ALREADY INSTALLED]" -ForegroundColor Green
                $skippedList += $pkg.name
            } else {
                Write-Host " [MANUAL DOWNLOAD]" -ForegroundColor Yellow
                Write-Host "  -> Please download & run installer from: $($pkg.url)" -ForegroundColor Cyan
            }
            continue
        }

        # Check if already installed via Winget
        $check = winget list --id "$($pkg.id)" --exact --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0 -and $check -match [regex]::Escape($pkg.id)) {
            Write-Host " [ALREADY INSTALLED]" -ForegroundColor Green
            $skippedList += $pkg.name
            continue
        }

        Write-Host " [INSTALLING]" -ForegroundColor Yellow
        $installArgs = @(
            "install",
            "--id", $pkg.id,
            "--exact",
            "--accept-package-agreements",
            "--accept-source-agreements",
            "--silent"
        )

        $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -NoNewWindow -PassThru

        if ($process.ExitCode -eq 0) {
            Write-Host "[+] Successfully installed $($pkg.name)" -ForegroundColor Green
            $installedList += $pkg.name
        } else {
            Write-Host "[!] Failed or requires elevation for $($pkg.name) (Exit code: $($process.ExitCode))" -ForegroundColor Red
            $failedList += $pkg.name
        }
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Summary: Application Installation     " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Installed : $($installedList.Count)" -ForegroundColor Green
Write-Host " Skipped   : $($skippedList.Count)" -ForegroundColor Gray
Write-Host " Failed    : $($failedList.Count)" -ForegroundColor $(if ($failedList.Count -gt 0) { "Red" } else { "Green" })
if ($failedList.Count -gt 0) {
    Write-Host " Failed packages: $($failedList -join ', ')" -ForegroundColor Yellow
}
Write-Host "========================================`n" -ForegroundColor Cyan
