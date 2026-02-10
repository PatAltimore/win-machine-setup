<#
.SYNOPSIS
    Pre-installation preparation script
.DESCRIPTION
    Checks Git repositories for uncommitted changes and exports installed applications
    using WinGet to a JSON file. Run this before reinstalling or migrating to a new machine.
.NOTES
    Requires Windows Package Manager (winget) and Git
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Git repository workspace directory")]
    [string]$GitWorkspaceDirectory = "$env:USERPROFILE\git",
    
    [Parameter(HelpMessage = "Output path for the WinGet export JSON file")]
    [string]$WingetExportPath = (Join-Path $PWD "winget-export.json"),
    
    [Parameter(HelpMessage = "Skip checking Git repositories for uncommitted changes")]
    [switch]$SkipGitCheck
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pre-installation preparation script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for uncommitted changes in Git repositories
if ($SkipGitCheck) {
    Write-Host "[SKIPPED] Git repository check (SkipGitCheck specified)" -ForegroundColor Yellow
} else {

Write-Host "Checking Git repositories for uncommitted changes..." -ForegroundColor Cyan
Write-Host "Workspace: $GitWorkspaceDirectory" -ForegroundColor Gray
Write-Host ""

try {
    git --version 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        if (Test-Path -Path $GitWorkspaceDirectory) {
            $repos = Get-ChildItem -Path $GitWorkspaceDirectory -Directory | Where-Object {
                Test-Path (Join-Path $_.FullName ".git")
            }
            
            if ($repos.Count -eq 0) {
                Write-Host "[WARNING] No Git repositories found in: $GitWorkspaceDirectory" -ForegroundColor Yellow
            } else {
                $reposWithChanges = 0
                $cleanRepos = 0
                
                foreach ($repo in $repos) {
                    try {
                        Push-Location $repo.FullName
                        
                        # Check for uncommitted changes
                        $status = git status --porcelain 2>&1
                        
                        if ($LASTEXITCODE -eq 0 -and $status) {
                            Write-Host "[CHANGES] $($repo.Name)" -ForegroundColor Yellow
                            $status | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                            $reposWithChanges++
                        } elseif ($LASTEXITCODE -eq 0) {
                            Write-Host "[CLEAN] $($repo.Name)" -ForegroundColor Green
                            $cleanRepos++
                        } else {
                            Write-Host "[ERROR] $($repo.Name): Failed to check status" -ForegroundColor Red
                        }
                        
                        Pop-Location
                    } catch {
                        Write-Host "[ERROR] $($repo.Name): $_" -ForegroundColor Red
                        Pop-Location
                    }
                }
                
                Write-Host ""
                Write-Host "Repository status summary:" -ForegroundColor Cyan
                Write-Host "  Clean: $cleanRepos" -ForegroundColor Green
                Write-Host "  With changes: $reposWithChanges" -ForegroundColor Yellow
                
                if ($reposWithChanges -gt 0) {
                    Write-Host ""
                    Write-Host "[WARNING] You have $reposWithChanges repository(ies) with uncommitted changes!" -ForegroundColor Yellow
                    Write-Host "  Commit and push your changes before reinstalling your machine." -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "[WARNING] Git workspace directory not found: $GitWorkspaceDirectory" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[WARNING] Git not available." -ForegroundColor Yellow
    }
} catch {
    Write-Host "[WARNING] Git not available: $_" -ForegroundColor Yellow
}

} # end if -not $SkipGitCheck
Write-Host ""

# Export installed applications using WinGet
Write-Host "Exporting installed applications using WinGet..." -ForegroundColor Cyan
Write-Host "Output file: $WingetExportPath" -ForegroundColor Gray
Write-Host ""

try {
    $null = Get-Command winget -ErrorAction Stop
    
    $output = winget export --output "$WingetExportPath" --accept-source-agreements 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Applications exported successfully to: $WingetExportPath" -ForegroundColor Green
        
        # Show summary of exported applications
        if (Test-Path $WingetExportPath) {
            try {
                $exportData = Get-Content $WingetExportPath | ConvertFrom-Json
                $appCount = $exportData.Sources | ForEach-Object { $_.Packages.Count } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                Write-Host "  Total applications exported: $appCount" -ForegroundColor Gray
            } catch {
                Write-Host "  (Unable to read export summary)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "[ERROR] Failed to export applications (Exit code: $LASTEXITCODE)" -ForegroundColor Red
        if ($output) {
            Write-Host "  Details: $output" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "[ERROR] WinGet is not available: $_" -ForegroundColor Red
    Write-Host "  Please install Windows App Installer from Microsoft Store." -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pre-installation check complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
