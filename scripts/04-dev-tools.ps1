<#
.SYNOPSIS
    Configures developer tools, PowerShell modules, Git identity, and VS Code extensions.
#>
[CmdletBinding()]
param(
    [string]$GitUserName,
    [string]$GitUserEmail
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " [04] Configuring Developer Environment " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot

# 1. Install Helpful PowerShell Modules
Write-Host "`n--- PowerShell Modules ---" -ForegroundColor Yellow

try {
    if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue | Out-Null
} catch {}

$modules = @("PSReadLine", "Terminal-Icons", "posh-git")

foreach ($mod in $modules) {
    Write-Host "[*] Checking module: $mod..." -NoNewline
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Host " [INSTALLING]" -ForegroundColor Yellow
        try {
            Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber -Repository PSGallery -ErrorAction Stop
            Write-Host "[+] Installed module: $mod" -ForegroundColor Green
        } catch {
            Write-Host "[!] Failed to install $mod : $_" -ForegroundColor Red
        }
    } else {
        Write-Host " [ALREADY INSTALLED]" -ForegroundColor Green
    }
}

# 2. Configure Git Identity
Write-Host "`n--- Git Identity Configuration ---" -ForegroundColor Yellow
if (Get-Command git -ErrorAction SilentlyContinue) {
    $currentName = (git config --global user.name) 2>$null
    $currentEmail = (git config --global user.email) 2>$null

    if (-not $currentName -or -not $currentEmail) {
        if ($GitUserName -and $GitUserEmail) {
            git config --global user.name "$GitUserName"
            git config --global user.email "$GitUserEmail"
            Write-Host "[+] Git configured: $GitUserName <$GitUserEmail>" -ForegroundColor Green
        } elseif ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
            Write-Host "[*] Git user identity not set." -ForegroundColor Yellow
            $inputName = Read-Host "Enter your Git Name (or press Enter to skip)"
            if ($inputName) {
                $inputEmail = Read-Host "Enter your Git Email"
                if ($inputEmail) {
                    git config --global user.name "$inputName"
                    git config --global user.email "$inputEmail"
                    Write-Host "[+] Git configured: $inputName <$inputEmail>" -ForegroundColor Green
                }
            }
        }
    } else {
        Write-Host "[+] Git identity is already configured: $currentName <$currentEmail>" -ForegroundColor Green
    }
} else {
    Write-Host "[!] Git command not found in PATH yet." -ForegroundColor Yellow
}

# 3. Install VS Code Extensions
Write-Host "`n--- VS Code Extensions ---" -ForegroundColor Yellow
$extensionsFile = Join-Path $repoRoot "config\vscode-extensions.txt"

if (Get-Command code -ErrorAction SilentlyContinue) {
    if (Test-Path $extensionsFile) {
        $installedExtensions = (code --list-extensions) 2>$null
        $exts = Get-Content $extensionsFile | Where-Object { $_ -and -not $_.StartsWith("#") }

        foreach ($ext in $exts) {
            $trimmed = $ext.Trim()
            if (-not $trimmed) { continue }

            if ($installedExtensions -contains $trimmed) {
                Write-Host "[-] Extension already installed: $trimmed" -ForegroundColor DarkGray
            } else {
                Write-Host "[*] Installing extension: $trimmed..." -ForegroundColor Yellow
                code --install-extension $trimmed --force | Out-Null
                Write-Host "[+] Installed extension: $trimmed" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "[*] VS Code ('code' CLI) not in PATH. Skipping VS Code extensions installation." -ForegroundColor Gray
}

Write-Host "`n[+] Developer environment configuration complete!`n" -ForegroundColor Green
