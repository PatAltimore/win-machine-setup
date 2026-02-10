# Quick Start Guide

## Pre-Installation (Before Migration)

Before reinstalling Windows or migrating to a new machine, run the pre-installation script:

```powershell
.\preinstall.ps1
```

This will:
1. Check all Git repositories for uncommitted changes
2. Export your installed applications to `winget-export.json`

Optional parameters:
```powershell
# Use a custom Git directory
.\preinstall.ps1 -GitWorkspaceDirectory "D:\Projects"

# Specify a custom export path
.\preinstall.ps1 -WingetExportPath "C:\backup\my-apps.json"

# Skip Git repository check (only export installed applications)
.\preinstall.ps1 -SkipGitCheck
```

## For First-Time Users

### Step 1: Download the Script
1. Download or clone this repository to your Windows machine
2. Extract to a folder (e.g., `C:\machine-setup`)

### Step 2: Open PowerShell as Administrator
1. Press `Win + X` and select "Windows PowerShell (Admin)" or "Terminal (Admin)"
2. Navigate to the script folder:
   ```powershell
   cd C:\machine-setup
   ```

### Step 3: Review and Customize Configuration Files

Before running the script, you can customize the following files as needed:

- `winget.txt`: List of applications to install via Winget. Modify this file to add or remove applications.
- `git-config.txt`: Git configuration settings. Update this file with your desired Git user name
    and email.
- `repositories.txt`: List of Git repositories to clone. Add the URLs of the repositories you want to clone.

### Step 4: Run the Script

```powershell
 # Set the execution policy to allow script running
 Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

.\setup-windows-machine.ps1
```

The script will:
1. Install all applications listed in `winget.txt`
2. Configure Git using settings in `git-config.txt`
3. Clone all repositories listed in `repositories.txt` to `%USERPROFILE%\git` (or a custom directory if specified)
4. Set up upstream remotes for forked repositories

## Common Scenarios

### Preparing for a fresh install or new machine
```powershell
.\preinstall.ps1
```
Commit any uncommitted changes, then copy the exported `winget-export.json` to your new machine.

### I only want to export installed applications (skip Git check)
```powershell
.\preinstall.ps1 -SkipGitCheck
```

### I only want to install applications
```powershell
.\setup-windows-machine.ps1 -SkipGitConfig -SkipRepoClone
```

### I already installed apps, just configure Git
```powershell
.\setup-windows-machine.ps1 -SkipInstall -SkipRepoClone
```

### I already have everything, just clone repos
```powershell
.\setup-windows-machine.ps1 -SkipInstall -SkipGitConfig
```

### Use a custom directory for repositories
```powershell
# Clone repos to D:\MyProjects instead of default %USERPROFILE%\git
.\setup-windows-machine.ps1 -GitWorkspaceDirectory "D:\MyProjects"
```

## After Installation

1. **Restart your computer** or at least your terminal
2. Open a new PowerShell/Terminal window to verify installations:
   ```powershell
   git --version
   code --version
   docker --version
   go version
   az --version
   ```
