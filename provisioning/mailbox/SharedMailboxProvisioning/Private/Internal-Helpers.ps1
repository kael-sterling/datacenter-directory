function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-DryRun {
    param([string]$Message)
    Write-Host $Message -ForegroundColor DarkYellow
}
