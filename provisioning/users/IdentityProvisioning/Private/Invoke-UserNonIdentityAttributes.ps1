function Invoke-UserNonIdentityAttributes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Users,

        [Parameter(Mandatory)]
        [psobject]$Settings
    )

    $globalOverwrite = $Settings.OverwriteNonIdentityAttributes

    foreach ($user in $Users) {

        Write-Log Verbose "Enforcing non-identity attributes" $user.SamAccountName

        try {
            #
            # Resolve AD user
            #
            $adUser = Get-ADUser -Filter "SamAccountName -eq '$($user.SamAccountName)'" -Properties * -ErrorAction SilentlyContinue

            if (-not $adUser) {
                Write-Log Warning "User not found, skipping non-identity enforcement" $user.SamAccountName
                continue
            }

            #
            # Determine overwrite mode
            #
            $userOverwrite = $globalOverwrite -or ([bool]$user.OverwriteNonIdentity)

            Write-Log Debug "Overwrite mode: $userOverwrite" $user.SamAccountName

            #
            # Build non-identity attribute map
            #
            $nonIdentityMap = @{
                physicalDeliveryOfficeName = $user.Office
                StreetAddress              = $user.StreetAddress
                PostOfficeBox              = $user.PostOfficeBox
                l                          = $user.City
                ST                         = $user.State
                PostalCode                 = $user.PostalCode
                CO                         = ($user.Country ? $user.Country : $Settings.DefaultCountry)
                TelephoneNumber            = $user.TelephoneNumber
                Mobile                     = $user.MobileNumber
            }

            Write-Log Debug "Non-identity attribute map:" $user.SamAccountName
            # Write-Log Debug $nonIdentityMap $user.SamAccountName
            # $requiredNonIdentity = @('StreetAddress', 'l', 'ST', 'PostalCode')

            # $nonIdentityMap = ConvertTo-ADAttributeMap -Map $nonIdentityMap -RequiredAttributes $requiredNonIdentity -Context $user.SamAccountName
            $nonIdentityMap = ConvertTo-ADAttributeMap -Map $nonIdentityMap -RequiredAttributes @() -Context $user.SamAccountName
            #
            # Apply attributes
            #
            if ($userOverwrite) {
                Write-Log Verbose "Overwriting non-identity attributes" $user.SamAccountName
                Set-Attribute -AdUser $adUser -Attributes $nonIdentityMap
            }
            else {
                Write-Log Verbose "Setting non-identity attributes only where empty" $user.SamAccountName
                Set-IfEmpty -AdUser $adUser -Attributes $nonIdentityMap
            }

            Write-Log Info "Non-identity attributes enforced" $user.SamAccountName
        }
        catch {
            Write-Log Error ("Failed to enforce non-identity attributes: {0}" -f $_.Exception.Message) $user.SamAccountName
            Write-Log Debug $_ $user.SamAccountName
        }
    }
}
