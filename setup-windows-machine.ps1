#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Machine Setup Script
.DESCRIPTION
    Automates the installation of applications and configuration for a fresh Windows installation.
    Uses winget to install applications and configures Git for development work.
.NOTES
    Requires Windows Package Manager (winget) and Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Skip application installation")]
    [switch]$SkipInstall,
    
    [Parameter(HelpMessage = "Skip Git configuration")]
    [switch]$SkipGitConfig,
    
    [Parameter(HelpMessage = "Skip repository cloning")]
    [switch]$SkipRepoClone,
    
    [Parameter(HelpMessage = "Git repository workspace directory")]
    [string]$GitWorkspaceDirectory = "$env:USERPROFILE\git",
    
    [Parameter(HelpMessage = "Path to winget export JSON file (alternative to winget.txt)")]
    [string]$WingetJsonFile
)

# Error handling
$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows machine setup script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to install an application using winget
function Install-Application {
    param(
        [string]$Name,
        [string]$WingetId
    )
    
    Write-Host "Installing $Name..." -ForegroundColor Yellow
    try {
        # Check if winget is available
        $null = Get-Command winget -ErrorAction Stop
        
        $output = winget install --id $WingetId --silent --accept-package-agreements --accept-source-agreements 2>&1
        
        switch ($LASTEXITCODE) {
            0 { 
                Write-Host "[SUCCESS] $Name installed successfully" -ForegroundColor Green 
            }
            -1978335189 { 
                Write-Host "[WARNING] $Name is already installed" -ForegroundColor Yellow 
            }
            -1978335212 { 
                Write-Host "[WARNING] $Name installation cancelled or failed - no package found" -ForegroundColor Yellow 
            }
            default { 
                Write-Host "[WARNING] $Name installation completed with warnings (Exit code: $LASTEXITCODE)" -ForegroundColor Yellow
                if ($output) {
                    Write-Host "Details: $output" -ForegroundColor Gray
                }
            }
        }
    } catch {
        Write-Host "[ERROR] Failed to install $Name : $_" -ForegroundColor Red
        if ($_.Exception.Message -like "*winget*not*found*") {
            Write-Host "  Winget is not available. Please install Windows App Installer from Microsoft Store." -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Install applications
if (-not $SkipInstall) {
    Write-Host "Starting application installations..." -ForegroundColor Cyan
    Write-Host ""

    # Check if using winget export JSON file
    if ($WingetJsonFile) {
        $jsonPath = if ([System.IO.Path]::IsPathRooted($WingetJsonFile)) {
            $WingetJsonFile
        } else {
            Join-Path $PSScriptRoot $WingetJsonFile
        }

        if (Test-Path $jsonPath) {
            Write-Host "Using winget import with JSON file: $jsonPath" -ForegroundColor Cyan
            try {
                Write-Host "Importing packages from JSON file..." -ForegroundColor Yellow
                $output = winget import --import-file "$jsonPath" --accept-package-agreements --accept-source-agreements 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[SUCCESS] Packages imported successfully" -ForegroundColor Green
                } else {
                    Write-Host "[WARNING] Import completed with warnings (Exit code: $LASTEXITCODE)" -ForegroundColor Yellow
                    if ($output) {
                        Write-Host "Details: $output" -ForegroundColor Gray
                    }
                }
            } catch {
                Write-Host "[ERROR] Failed to import from JSON file: $_" -ForegroundColor Red
                if ($_.Exception.Message -like "*winget*not*found*") {
                    Write-Host "  Winget is not available. Please install Windows App Installer from Microsoft Store." -ForegroundColor Red
                }
            }
            Write-Host ""
        } else {
            Write-Host "[ERROR] JSON file not found: $jsonPath" -ForegroundColor Red
            Write-Host ""
        }
    } else {
        # Read application list from winget.txt
        $wingetFile = Join-Path $PSScriptRoot "winget.txt"
        if (Test-Path $wingetFile) {
            Write-Host "Using winget.txt file: $wingetFile" -ForegroundColor Cyan
            try {
                $appLines = Get-Content $wingetFile | Where-Object {
                    $_.Trim() -and $_.Trim() -notmatch '^#'
                } | ForEach-Object { $_.Trim() }

                foreach ($line in $appLines) {
                    $parts = $line -split '\|', 2
                    $appName = $parts[0].Trim()
                    $wingetId = if ($parts.Length -gt 1) { $parts[1].Trim() } else { $null }

                    if ($appName -and $wingetId) {
                        Install-Application -Name $appName -WingetId $wingetId
                    } else {
                        Write-Host "[WARNING] Invalid entry in winget.txt: $line" -ForegroundColor Yellow
                    }
                }
            } catch {
                Write-Host "[ERROR] Failed to read winget.txt: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "[WARNING] winget.txt file not found in script directory" -ForegroundColor Yellow
            Write-Host "  Expected location: $wingetFile" -ForegroundColor Gray
        }
        Write-Host ""
    }

    Write-Host "Application installations completed!" -ForegroundColor Green
    Write-Host ""
    
    # Refresh Git path in the current session
    Write-Host "Refreshing environment variables..." -ForegroundColor Cyan
    $gitPaths = @(
        "$env:ProgramFiles\Git\cmd",
        "${env:ProgramFiles(x86)}\Git\cmd",
        "$env:LOCALAPPDATA\Programs\Git\cmd"
    )
    
    foreach ($gitPath in $gitPaths) {
        if (Test-Path $gitPath) {
            if ($env:PATH -notlike "*$gitPath*") {
                $env:PATH = "$gitPath;$env:PATH"
                Write-Host "[SUCCESS] Added Git to session PATH: $gitPath" -ForegroundColor Green
            }
        }
    }
    Write-Host ""
} else {
    Write-Host "Skipping application installation (SkipInstall flag set)" -ForegroundColor Yellow
    Write-Host ""
}

# Configure Git
if (-not $SkipGitConfig) {
    Write-Host "Configuring Git..." -ForegroundColor Cyan
    Write-Host ""

    # Check if Git is available
    try {
        $gitVersion = git --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $gitVersion) {
            Write-Host "Git version: $gitVersion" -ForegroundColor Green

            # Read Git configuration from git-config.txt
            $gitConfigFile = Join-Path $PSScriptRoot "git-config.txt"
            if (Test-Path $gitConfigFile) {
                try {
                    $configLines = Get-Content $gitConfigFile | Where-Object {
                        $_.Trim() -and $_.Trim() -notmatch '^#'
                    } | ForEach-Object { $_.Trim() }

                    foreach ($line in $configLines) {
                        $parts = $line -split '=', 2
                        $key = $parts[0].Trim()
                        $value = if ($parts.Length -gt 1) { $parts[1].Trim() } else { $null }

                        if ($key -and $value) {
                            try {
                                git config --global $key "$value" 2>$null
                                if ($LASTEXITCODE -ne 0) { throw "Failed to set $key" }
                                Write-Host "[SUCCESS] Set $key to $value" -ForegroundColor Green
                            } catch {
                                Write-Host "[ERROR] Failed to set $key`: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        } else {
                            Write-Host "[WARNING] Invalid entry in git-config.txt: $line" -ForegroundColor Yellow
                        }
                    }
                } catch {
                    Write-Host "[ERROR] Failed to read git-config.txt: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "[WARNING] git-config.txt file not found in script directory" -ForegroundColor Yellow
                Write-Host "  Expected location: $gitConfigFile" -ForegroundColor Gray
            }

            Write-Host "Git configuration completed!" -ForegroundColor Green
            Write-Host ""
        } else {
            Write-Host "[WARNING] Git not found. Please restart the script after Git installation completes." -ForegroundColor Yellow
            Write-Host ""
        }
    } catch {
        Write-Host "[WARNING] Git not found or not in PATH. You may need to restart your terminal or computer." -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "Skipping Git configuration (SkipGitConfig flag set)" -ForegroundColor Yellow
    Write-Host ""
}

# Clone repositories
if (-not $SkipRepoClone) {
    Write-Host "Repository Cloning" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if Git is available
    try {
        git --version 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            # Use the workspace directory from parameter
            $workspace = $GitWorkspaceDirectory
            
            # Validate workspace path
            try {
                # Convert to absolute path and validate
                $workspace = [System.IO.Path]::GetFullPath($workspace)
                
                # Check for invalid characters
                $invalidChars = [System.IO.Path]::GetInvalidPathChars()
                if ($workspace.IndexOfAny($invalidChars) -ge 0) {
                    throw "Workspace path contains invalid characters"
                }
                
                # Ensure path is within reasonable bounds (not root or system directories)
                $rootDrives = @('C:\', 'D:\', 'E:\', 'F:\', 'G:\')
                if ($workspace -in $rootDrives) {
                    throw "Cannot use root drive as workspace directory"
                }
                
                # Check if path starts with system directories
                $systemDirs = @('C:\Windows', 'C:\Program Files', 'C:\Program Files (x86)', 'C:\System')
                foreach ($sysDir in $systemDirs) {
                    if ($workspace.StartsWith($sysDir, [System.StringComparison]::OrdinalIgnoreCase)) {
                        throw "Cannot use system directory as workspace"
                    }
                }
                
            } catch {
                Write-Host "[ERROR] Invalid workspace path: $_" -ForegroundColor Red
                Write-Host "Using default workspace: $GitWorkspaceDirectory" -ForegroundColor Yellow
                $workspace = $GitWorkspaceDirectory
            }
            
            # Create workspace directory if it doesn't exist
            if (-not (Test-Path -Path $workspace)) {
                New-Item -ItemType Directory -Path $workspace -Force | Out-Null
                Write-Host "[SUCCESS] Created workspace directory: $workspace" -ForegroundColor Green
            }
            
            # Prompt for repositories to clone
            Write-Host ""
            
            # Read default repositories from repositories.txt file
            $repositoriesFile = Join-Path $PSScriptRoot "repositories.txt"
            $defaultRepos = @()
            
            if (Test-Path $repositoriesFile) {
                try {
                    $repoLines = Get-Content $repositoriesFile | Where-Object { 
                        $_.Trim() -and $_.Trim() -notmatch '^#' 
                    } | ForEach-Object { $_.Trim() }
                    
                    # Parse each line to extract repo URL and optional upstream URL
                    foreach ($line in $repoLines) {
                        $parts = $line -split '\|', 2
                        $repoUrl = $parts[0].Trim()
                        $upstreamUrl = if ($parts.Length -gt 1) { $parts[1].Trim() } else { $null }
                        
                        $defaultRepos += @{
                            Url = $repoUrl
                            Upstream = $upstreamUrl
                        }
                    }
                    
                    if ($defaultRepos.Count -eq 0) {
                        Write-Host "[WARNING] repositories.txt file is empty or contains no valid repositories" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "[ERROR] Failed to read repositories.txt: $_" -ForegroundColor Red
                    $defaultRepos = @()
                }
            } else {
                Write-Host "[WARNING] repositories.txt file not found in script directory" -ForegroundColor Yellow
                Write-Host "  Expected location: $repositoriesFile" -ForegroundColor Gray
            }
            
            if ($defaultRepos.Count -gt 0) {
                Write-Host "Default repositories that will be cloned:" -ForegroundColor Cyan
                foreach ($defaultRepo in $defaultRepos) {
                    Write-Host "  - $($defaultRepo.Url)" -ForegroundColor White
                    if ($defaultRepo.Upstream) {
                        Write-Host "    upstream: $($defaultRepo.Upstream)" -ForegroundColor Gray
                    }
                }
            } else {
                Write-Host "No default repositories configured." -ForegroundColor Yellow
            }
            Write-Host ""
            
            # Use repositories from the file
            $repos = $defaultRepos
            
            if ($repos.Count -gt 0) {
                $originalLocation = Get-Location
                try {
                    Push-Location $workspace
                    Write-Host ""
                    $successCount = 0
                    $failCount = 0
                    
                    foreach ($repo in $repos) {
                        $repoUrl = $repo.Url
                        $upstreamUrl = $repo.Upstream
                        
                        Write-Host "Cloning $repoUrl..." -ForegroundColor Yellow
                        
                        # Validate repository URL format
                        if (-not ($repoUrl -match '^https?://.*\.git$|^git@.*:.*\.git$|^https?://github\.com/.*$')) {
                            Write-Host "[WARNING] Invalid repository URL format: $repoUrl" -ForegroundColor Yellow
                            $failCount++
                            Write-Host ""
                            continue
                        }
                        
                        try {
                            $cloneOutput = git clone $repoUrl 2>&1
                            
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "[SUCCESS] Cloned successfully" -ForegroundColor Green
                                $successCount++
                                
                                # Add upstream remote if specified
                                if ($upstreamUrl) {
                                    try {
                                        # Extract repository name from URL for directory name
                                        $repoName = [System.IO.Path]::GetFileNameWithoutExtension(($repoUrl -split '/')[-1])
                                        $repoPath = Join-Path $workspace $repoName
                                        
                                        if (Test-Path $repoPath) {
                                            Push-Location $repoPath
                                            $upstreamOutput = git remote add upstream $upstreamUrl 2>&1
                                            
                                            if ($LASTEXITCODE -eq 0) {
                                                Write-Host "  [SUCCESS] Added upstream remote: $upstreamUrl" -ForegroundColor Green
                                            } else {
                                                Write-Host "  [WARNING] Failed to add upstream remote: $upstreamOutput" -ForegroundColor Yellow
                                            }
                                            Pop-Location
                                        }
                                    } catch {
                                        Write-Host "  [WARNING] Failed to add upstream remote: $_" -ForegroundColor Yellow
                                    }
                                }
                            } else {
                                Write-Host "[ERROR] Clone failed (Exit code: $LASTEXITCODE)" -ForegroundColor Red
                                if ($cloneOutput) {
                                    Write-Host "  Error details: $cloneOutput" -ForegroundColor Gray
                                }
                                $failCount++
                            }
                        } catch {
                            Write-Host "[ERROR] Failed to clone: $_" -ForegroundColor Red
                            $failCount++
                        }
                        Write-Host ""
                    }
                    
                    # Summary
                    Write-Host "Repository cloning summary:" -ForegroundColor Cyan
                    Write-Host "  Successful: $successCount" -ForegroundColor Green
                    Write-Host "  Failed: $failCount" -ForegroundColor Red
                    
                } catch {
                    Write-Host "[ERROR] Error during repository operations: $_" -ForegroundColor Red
                } finally {
                    # Ensure we always return to original location
                    try {
                        Pop-Location
                    } catch {
                        Set-Location $originalLocation
                    }
                }
            }
        } else {
            Write-Host "[WARNING] Git not available. Skipping repository cloning." -ForegroundColor Yellow
            Write-Host ""
        }
    } catch {
        Write-Host "[WARNING] Git not available. Skipping repository cloning." -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "Skipping repository cloning (SkipRepoClone flag set)" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
