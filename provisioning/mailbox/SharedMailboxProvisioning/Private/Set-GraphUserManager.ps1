function Set-GraphUserManager {
    param(
        [Parameter(Mandatory)]
        [string]$UserId,

        [Parameter(Mandatory)]
        [string]$ManagerObjectId,

        [switch]$DryRun
    )

    # Detect installed Graph SDK major version
    $graphModule = Get-Module Microsoft.Graph.Users -ListAvailable |
    Sort-Object Version -Descending |
    Select-Object -First 1

    if (-not $graphModule) {
        throw "Microsoft.Graph.Users module is not installed."
    }

    $major = $graphModule.Version.Major

    # Universal @odata.id reference (works for all versions)
    $ref = @{
        '@odata.id' = "https://graph.microsoft.com/v1.0/users/$ManagerObjectId"
    }

    if ($DryRun) {
        Write-Host "  ~ Would update manager (Graph SDK major version: $major)"
        return
    }

    #
    # Two-path logic:
    #   - Graph 2.x → use -RefObjectId
    #   - Graph 1.x → use -BodyParameter
    #

    if ($major -ge 2) {
        Write-Host "  ~ Using Graph SDK 2.x method (-RefObjectId)"
        Set-MgUserManagerByRef -UserId $UserId -RefObjectId $ManagerObjectId
    }
    else {
        Write-Host "  ~ Using Graph SDK 1.x method (-BodyParameter)"
        Set-MgUserManagerByRef -UserId $UserId -BodyParameter $ref
    }
}
