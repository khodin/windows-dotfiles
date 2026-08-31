# ==============================================================================
# PowerShell Profile - windows_setup
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. PSReadLine & Autocompletion Enhancements
# ------------------------------------------------------------------------------
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    try {
        # Modern PSReadLine 2.2+ features
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction Stop
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
    } catch {
        # Fallback for older PSReadLine versions
    }
    Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key Tab -Function Complete -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------------------------
# 2. Terminal Icons (if installed)
# ------------------------------------------------------------------------------
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# ------------------------------------------------------------------------------
# 3. Prompt (Starship or custom fallback)
# ------------------------------------------------------------------------------
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
} else {
    function prompt {
        $path = ($pwd.Path).Replace($env:USERPROFILE, "~")
        $gitBranch = ""
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $branch = git rev-parse --abbrev-ref HEAD 2>$null
            if ($branch) {
                $gitBranch = " [$branch]"
            }
        }
        Write-Host "PS " -NoNewline -ForegroundColor Green
        Write-Host $path -NoNewline -ForegroundColor Cyan
        if ($gitBranch) {
            Write-Host $gitBranch -NoNewline -ForegroundColor Yellow
        }
        return "> "
    }
}

# ------------------------------------------------------------------------------
# 4. Aliases & Shortcuts
# ------------------------------------------------------------------------------
Set-Alias -Name g -Value git -ErrorAction SilentlyContinue
Set-Alias -Name ll -Value Get-ChildItem -ErrorAction SilentlyContinue
Set-Alias -Name grep -Value Select-String -ErrorAction SilentlyContinue

function which ($command) {
    Get-Command $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

function touch ($file) {
    "" | Out-File -FilePath $file -Encoding utf8
}

function reload-profile {
    & $PROFILE
    Write-Host "PowerShell profile reloaded." -ForegroundColor Green
}

function setup-repo {
    Set-Location "$env:USERPROFILE\code\windows-dotfiles"
}

# ------------------------------------------------------------------------------
# 5. Environment & Paths
# ------------------------------------------------------------------------------
# Ensure Local AppData bin & Scripts are in path
$customPaths = @(
    "$env:LOCALAPPDATA\Programs\Git\cmd",
    "$env:LOCALAPPDATA\agy\bin",
    "$env:USERPROFILE\.cargo\bin",
    "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts",
    "$env:LOCALAPPDATA\Programs\Python\Python312"
)

foreach ($p in $customPaths) {
    if ((Test-Path $p) -and ($env:Path -notlike "*$p*")) {
        $env:Path = "$p;$env:Path"
    }
}
