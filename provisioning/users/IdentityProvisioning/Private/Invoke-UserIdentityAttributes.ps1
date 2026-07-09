function Invoke-UserIdentityAttributes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Users,

        [Parameter(Mandatory)]
        [psobject]$Settings
    )

    foreach ($user in $Users) {

        Write-Log Verbose "Enforcing identity attributes" $user.SamAccountName

        try {
            #
            # Resolve AD user
            #
            $adUser = Get-ADUser -Filter "SamAccountName -eq '$($user.SamAccountName)'" -Properties * -ErrorAction SilentlyContinue

            if (-not $adUser) {
                Write-Log Warning "User not found, skipping identity enforcement" $user.SamAccountName
                continue
            }

            #
            # Build identity map (always overwritten)
            #
            $identityMap = @{
                GivenName   = $user.GivenName
                MiddleName  = $user.MiddleName
                SN          = $user.Surname
                DisplayName = ($user.DisplayName ? $user.DisplayName : "$($user.GivenName) $($user.Surname)")
                Gecos       = (Resolve-Gecos -User $user)
                Initials    = (Resolve-Initials -User $user)
                mail        = $adUser.UserPrincipalName
                Department  = $user.Department
                Title       = $user.Title
                Company     = ($user.Company ? $user.Company : $Settings.DefaultCompany)
            }


            # $gecos = Resolve-Gecos -User $user
            # if ($gecos) {
            #     $identityMap.Gecos = $gecos
            # }

            # $initials = Resolve-Initials -User $user
            # if ($initials) {
            #     $identityMap.initials = $initials
            # }

            #
            # Manager (soft enforcement)
            #
            if ($user.ManagerSamAccountName -and $user.ManagerSamAccountName -ne '') {

                Write-Log Verbose "Resolving manager '$($user.ManagerSamAccountName)'" $user.SamAccountName

                $manager = Get-ADUser -Filter "SamAccountName -eq '$($user.ManagerSamAccountName)'" -ErrorAction SilentlyContinue

                if ($manager) {
                    $identityMap.manager = $manager.DistinguishedName
                }
                else {
                    Write-Log Warning "Manager '$($user.ManagerSamAccountName)' not found. Soft skip." $user.SamAccountName
                }
            }

            #
            # Debug dump of identity map
            #
            Write-Log Debug "Identity attribute map:" $user.SamAccountName
            # Write-Log Debug $identityMap $user.SamAccountName

            $requiredIdentity = @('GivenName', 'SN', 'Department', 'Title')

            $identityMap = ConvertTo-ADAttributeMap -Map $identityMap -RequiredAttributes $requiredIdentity -Context $user.SamAccountName

            #
            # Single atomic write
            #
            Set-Attribute -AdUser $adUser -Attributes $identityMap

            Write-Log Info "Identity attributes enforced" $user.SamAccountName
        }
        catch {
            Write-Log Error ("Failed to apply identity attributes: {0}" -f $_.Exception.Message) $user.SamAccountName
            Write-Log Debug $_ $user.SamAccountName
        }
    }
}
