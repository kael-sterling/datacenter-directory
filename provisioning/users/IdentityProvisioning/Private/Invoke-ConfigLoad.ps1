function Invoke-ConfigLoad {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    Write-Log Verbose "Loading provisioning configuration" $ConfigPath

    $usersPath = Join-Path $ConfigPath 'users.csv'
    $groupsPath = Join-Path $ConfigPath 'groups.csv'
    $identityPath = Join-Path $ConfigPath 'identity.json'

    Write-Log Verbose "Loading users.csv" $ConfigPath
    $users = Import-Csv -Path $usersPath

    Write-Log Verbose "Loading groups.csv" $ConfigPath
    $groups = Import-Csv -Path $groupsPath

    Write-Log Verbose "Loading identity.json" $ConfigPath
    $identity = Get-Content -Path $identityPath -Raw | ConvertFrom-Json

    Write-Log Debug "Identity Provisioning Configuration:" $ConfigPath
    Write-Log Debug $identity $ConfigPath

    Write-Log Verbose "Configuration loaded" $ConfigPath

    [pscustomobject]@{
        Users    = $users
        Groups   = $groups
        Identity = $identity
    }
}
