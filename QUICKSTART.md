# Quick Start Guide

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
3. Ask where you want to clone repositories
4. Clone all repositories listed in `repositories.txt` (including upstream remotes for forks)

## Common Scenarios

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

## Troubleshooting

### "Cannot be loaded because running scripts is disabled"
Run this command in PowerShell (Admin):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
