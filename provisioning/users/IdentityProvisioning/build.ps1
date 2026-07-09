<#
.SYNOPSIS
Build script for the module. Runs formatting checks, loads the module,
executes Pester tests, and prepares the module for packaging.

.DESCRIPTION
This script is intended for local development and CI pipelines. It performs:

1. Module import (fresh)
2. Script analysis (PSScriptAnalyzer)
3. Pester test execution
4. Optional packaging step (disabled by default)

It is not included in the published module package.
#>

param(
    [switch]$SkipTests,
    [switch]$SkipAnalysis
)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleManifest = Join-Path $root "IdentityProvisioning.psd1"

Write-Host "=== Build Started ===" -ForegroundColor Cyan

# ScriptAnalyzer
if (-not $SkipAnalysis) {
    Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Yellow

    if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
        Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
    }

    $analysis = Invoke-ScriptAnalyzer -Path $root -Recurse

    if ($analysis) {
        Write-Host "ScriptAnalyzer found issues:" -ForegroundColor Red
        $analysis | Format-Table
        throw "ScriptAnalyzer failed."
    }

    Write-Host "ScriptAnalyzer passed." -ForegroundColor Green
}

# Load module fresh
Write-Host "Importing module..." -ForegroundColor Yellow

Remove-Module IdentityProvisioning -ErrorAction SilentlyContinue
Import-Module $moduleManifest -Force

Write-Host "Module imported successfully." -ForegroundColor Green

# Run Pester
if (-not $SkipTests) {
    Write-Host "Running Pester tests..." -ForegroundColor Yellow

    if (-not (Get-Module -ListAvailable Pester)) {
        Install-Module Pester -Force -Scope CurrentUser
    }

    $config = @{
        Run    = @{
            Path  = Join-Path $root "Tests"
            Throw = $true
        }
        Output = @{
            Verbosity = "Detailed"
        }
    }

    Invoke-Pester -Configuration $config

    Write-Host "Pester tests passed." -ForegroundColor Green
}


# ------------------------------------------------------------
# Step 4: Packaging (optional)
# ------------------------------------------------------------
# Write-Host "Packaging module..." -ForegroundColor Yellow
# New-ModuleManifest -Path "$root\dist\YourModule.psd1" -RootModule "YourModule.psm1"
# Copy-Item "$root\Public" "$root\dist\Public" -Recurse
# Copy-Item "$root\Private" "$root\dist\Private" -Recurse
# Write-Host "Packaging complete." -ForegroundColor Green

Write-Host "=== Build Complete ===" -ForegroundColor Cyan
