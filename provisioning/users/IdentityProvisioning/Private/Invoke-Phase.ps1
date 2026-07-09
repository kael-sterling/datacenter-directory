function Invoke-Phase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Action
    )

    Write-Log Info "Starting phase: $Name"

    try {
        & $Action
        Write-Log Info "Completed phase: $Name"
        return $true
    }
    catch {
        Write-Log Error "Phase '$Name' failed: $($_.Exception.Message)"
        Write-Log Debug $_
        return $false
    }
}
