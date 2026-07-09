function Invoke-UserProxyAddresses {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Users,

        [Parameter(Mandatory)]
        [psobject]$Settings
    )

    foreach ($user in $Users) {

        Write-Log Verbose "Enforcing proxyAddresses" $user.SamAccountName

        try {
            #
            # Resolve AD user
            #
            $adUser = Get-ADUser -Filter "SamAccountName -eq '$($user.SamAccountName)'" `
                -Properties proxyAddresses `
                -ErrorAction SilentlyContinue

            if (-not $adUser) {
                Write-Log Warning "User not found, skipping proxyAddresses enforcement" $user.SamAccountName
                continue
            }

            $proxyAddresses = Resolve-ProxyAddresses `
                -SamAccountName $User.SamAccountName `
                -CanonicalName $User.CanonicalName `
                -PrimaryLoginDomain $Settings.PrimaryLoginDomain `
                -PrimaryMailDomain $Settings.PrimaryMailDomain `
                -SecondaryMailDomains $Settings.SecondaryMailDomains


            if ($proxyAddresses) {
                Set-Attribute -AdUser $adUser -AttributeName "proxyAddresses" -Value $proxyAddresses
            }


            Write-Log Info "Proxy addresses enforced" $user.SamAccountName
        }
        catch {
            Write-Log Error ("Failed to set proxyAddresses: {0}" -f $_.Exception.Message) $user.SamAccountName
            Write-Log Debug $_ $user.SamAccountName
        }
    }
}
