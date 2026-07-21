function Connect-Graph {
    [CmdletBinding()]
    param(
        [string[]]$Scopes = @('User.ReadWrite.All')
    )

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Import-Module Microsoft.Graph.Users -ErrorAction Stop

    $ctx = Get-MgContext
    if (-not $ctx) {
        Connect-MgGraph -Scopes $Scopes -UseDeviceCode -NoWelcome | Out-Null
    }
}
