# 💻 Windows Workstation Setup & Dotfiles

A modular, reproducible, Infrastructure-as-Code setup for Windows 11 / 10 workstations. Designed to quickly rebuild and configure your complete environment after an OS reinstall or machine migration.

---

## ⚡ Quickstart (Fresh Machine Recovery)

On a clean Windows installation, open **PowerShell as Administrator** and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/khodin/windows-dotfiles/main/bootstrap.ps1 | iex
```

*(Replace `<YOUR_GITHUB_USERNAME>` with your GitHub username once the repository is pushed).*

---

## 🗂️ Repository Structure

```text
windows-dotfiles/
├── bootstrap.ps1              # 1-liner remote recovery bootstrapper
├── setup.ps1                  # Main interactive & unattended orchestrator
├── config/
│   ├── packages.json          # Curated & categorized Winget packages
│   ├── vscode-extensions.txt  # VS Code extensions list
│   └── winget-export.json     # Machine package state backup
├── dotfiles/
│   ├── .wslconfig             # Optimized WSL2 memory/CPU limits
│   ├── .gitconfig             # Standard Git global configuration
│   ├── Microsoft.PowerShell_profile.ps1 # Enhanced PowerShell profile
│   └── WindowsTerminal/
│       └── settings.json      # Windows Terminal styling & settings
├── scripts/
│   ├── 00-prereqs.ps1         # Policy, Admin & Winget source checks
│   ├── 01-install-apps.ps1    # Automated Winget package installer
│   ├── 02-windows-tweaks.ps1  # Explorer, Dark mode & Developer tweaks
│   ├── 03-apply-dotfiles.ps1  # Deploys dotfiles & backs up previous configs
│   ├── 04-dev-tools.ps1       # PS modules, Git identity & VS Code extensions
│   └── backup.ps1             # Live export of current machine state into repo
└── agy_setup.ps1              # Antigravity CLI installer
```

---

## 🚀 Usage

### 1. Interactive Menu

Run `setup.ps1` from an elevated PowerShell window:

```powershell
.\setup.ps1
```

You'll get an interactive menu to choose which steps to execute:
- `[1]` Full Setup (Runs all stages)
- `[2]` Install Applications (Winget packages)
- `[3]` Apply Windows Settings & Tweaks
- `[4]` Deploy Dotfiles (PowerShell, WSL, Terminal)
- `[5]` Configure Developer Environment (Git, VS Code)
- `[6]` Export Current Machine State (Backup)

### 2. Command Line Switches (Unattended)

```powershell
# Run the complete setup unattended:
.\setup.ps1 -All

# Run specific stages:
.\setup.ps1 -Apps
.\setup.ps1 -Tweaks
.\setup.ps1 -Dotfiles
.\setup.ps1 -Dev

# Install specific package categories only:
.\setup.ps1 -Apps -Categories core_tools,development
```

---

## 📦 Managing Applications (`config/packages.json`)

All applications are defined in [`config/packages.json`](file:///C:/Users/klebe/code/windows_setup/config/packages.json).

You can easily enable or disable apps by toggling `"enabled": true` / `"enabled": false`, or add new Winget packages:

```json
{
  "id": "Google.Chrome",
  "name": "Google Chrome",
  "enabled": true
}
```

To search for the ID of a new package to add:
```powershell
winget search "app name"
```

---

## 🔄 Live Machine State Sync (`scripts/backup.ps1`)

Whenever you install new apps or update your terminal / shell / WSL configs and want to save them back to your repository:

```powershell
.\scripts\backup.ps1
```

This will automatically:
1. Re-export installed Winget packages to `config/winget-export.json`.
2. Re-export installed VS Code extensions to `config/vscode-extensions.txt`.
3. Copy your current PowerShell profile, `.wslconfig`, and Windows Terminal settings into `dotfiles/`.

Then simply commit and push your changes to GitHub:

```powershell
git add .
git commit -m "Update system configuration & packages"
git push
```

---

## 🛠️ Step-by-Step: Pushing This Repository to GitHub

1. Create a new repository named `windows-dotfiles` on [GitHub](https://github.com/new) (public or private).
2. In PowerShell, navigate to this directory and run:

```powershell
cd C:\Users\klebe\code\windows_setup

# Initialize git (if not already done)
git init
git branch -M main

# Add all files and commit
git add .
git commit -m "Initial commit: Automated Windows setup & dotfiles"

# Link to your remote GitHub repository
git remote add origin https://github.com/khodin/windows-dotfiles.git

# Push to GitHub
git push -u origin main
```
