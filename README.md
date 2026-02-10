# Set Up Windows Machine

Automated Windows machine setup script for fresh installations. This script uses Windows Package Manager (winget) to install essential development tools and applications, configure Git, and clone repositories.

## Features

- **Pre-installation Check**: Check for uncommitted Git changes and export installed applications before migration
- **Automated Installation**: Installs multiple applications with a single command
- **Git Configuration**: Sets up Git with your user information and sensible defaults
- **Repository Cloning**: Automatically clones all repositories from `repositories.txt` including upstream remotes
- **Flexible Options**: Skip any section using command-line parameters
- **Easy Customization**: Modify repositories by editing the `repositories.txt` file, applications by editing `winget.txt`, and Git settings by editing `git-config.txt`


## Prerequisites

- Administrator privileges
- PowerShell 5.1 or later

## Customization

### Application Installation

You can provide applications to install in two ways:

#### Option 1: Using winget.txt (Default)

Edit the `winget.txt` file to customize the applications installed by the script. Each line should contain the application name and its winget ID, separated by a `|`.

Example format:
```
# Application Name | Winget ID
Git | Git.Git
Visual Studio Code | Microsoft.VisualStudioCode
```

#### Option 2: Using a Winget Export JSON File

Export your current winget packages and use the JSON file directly:

```powershell
# Export your current packages
winget export -o exported-packages.json

# Use the exported file with the script
.\setup-windows-machine.ps1 -WingetJsonFile "exported-packages.json"
```

This method is useful for replicating an existing machine's configuration.

### Git Configuration

Edit the `git-config.txt` file to customize Git settings. Each line should contain a key-value pair in the format `key = value`.

Example format:
```
user.name = Your Name
user.email = your.email@users.noreply.github.com
```

### Repository Configuration

Edit the `repositories.txt` file to customize which repositories are cloned.
Each line should contain the repository information in the format `repository_url|upstream_url` (upstream_url is optional).

Example format:
```
# repository_url|upstream_url
https://github.com/yourusername/yourrepo.git|https://github.com/originalowner/originalrepo.git
```

## Usage

### Pre-installation (Before Migration)

Before reinstalling Windows or migrating to a new machine, run the pre-installation script to check for uncommitted changes and export your installed applications:

```powershell
.\preinstall.ps1
```

This will:
1. Scan all Git repositories in `%USERPROFILE%\git` for uncommitted changes
2. Export your installed applications to `winget-export.json`

You can customize the behavior with parameters:

```powershell
# Use a custom Git directory
.\preinstall.ps1 -GitWorkspaceDirectory "D:\Projects"

# Specify a custom export path
.\preinstall.ps1 -WingetExportPath "C:\backup\my-apps.json"

# Skip Git repository check (only export installed applications)
.\preinstall.ps1 -SkipGitCheck
```

### Installation (Fresh Setup)

1. Open PowerShell as Administrator
2. Navigate to the script directory
3. Run the script:

```powershell
.\setup-windows-machine.ps1
```

The script will:
1. Install all applications listed in `winget.txt`
2. Configure Git using settings in `git-config.txt`
3. Clone all repositories listed in `repositories.txt`

## Advanced Usage

Skip specific sections using parameters:

```powershell
# Skip application installation
.\setup-windows-machine.ps1 -SkipInstall

# Skip Git configuration
.\setup-windows-machine.ps1 -SkipGitConfig

# Skip repository cloning
.\setup-windows-machine.ps1 -SkipRepoClone

# Combine multiple skip flags
.\setup-windows-machine.ps1 -SkipGitConfig -SkipRepoClone
```

Use a winget export JSON file instead of winget.txt:

```powershell
# Use a winget export JSON file
.\setup-windows-machine.ps1 -WingetJsonFile "exported-packages.json"

# Use with absolute path
.\setup-windows-machine.ps1 -WingetJsonFile "C:\path\to\exported-packages.json"
```

Customize the workspace directory for cloned repositories:

```powershell
# Use a custom workspace directory (default is %USERPROFILE%\git)
.\setup-windows-machine.ps1 -GitWorkspaceDirectory "C:\Dev"

# Combine with other parameters
.\setup-windows-machine.ps1 -GitWorkspaceDirectory "C:\Dev" -SkipInstall

# Combine JSON import with custom workspace
.\setup-windows-machine.ps1 -WingetJsonFile "exported-packages.json" -GitWorkspaceDirectory "C:\git"
```

## Troubleshooting

### Winget Not Found
If winget is not available, install it from the Microsoft Store:
- Search for "App Installer" and install/update it

### Permission Denied
- Ensure you're running PowerShell as Administrator
- Right-click PowerShell and select "Run as Administrator"

### Execution Policy Error
If you get an execution policy error, you may need to allow script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Applications Not Installing
- Check your internet connection
- Verify the application is available in winget: `winget search <app-name>`
- Some applications may require manual installation

### Git Not Found After Installation
- Restart your terminal or computer
- Git is typically installed to `C:\Program Files\Git\cmd` which should be added to PATH automatically

## License

This project is open source and available for personal and commercial use.
