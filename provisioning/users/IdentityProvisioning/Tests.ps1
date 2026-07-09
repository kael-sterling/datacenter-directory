<#
.SYNOPSIS
Runs all Pester tests in the Tests/ directory.

.DESCRIPTION
This script is a simple test runner for local development and CI pipelines.
It loads the module from the repository root, then invokes Pester using a
clean configuration block.

It is not included in the published module package.
#>

# Resolve repo root
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# Ensure module is loaded fresh
$moduleManifest = Join-Path $root "IdentityProvisioning.psd1"
if (Test-Path $moduleManifest) {
    Remove-Module IdentityProvisioning -ErrorAction SilentlyContinue
    Import-Module $moduleManifest -Force
}

# Build Pester configuration
$configuration = @{
    Run    = @{
        Path  = Join-Path $root "Tests"
        Throw = $true
    }
    Output = @{
        Verbosity = "Detailed"
    }
}

Write-Host "Running Pester tests..." -ForegroundColor Cyan

Invoke-Pester -Configuration $configuration
