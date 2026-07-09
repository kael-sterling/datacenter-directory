function Invoke-UserPreProvisioning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Users,

        [Parameter(Mandatory)]
        [psobject]$Settings
    )

    foreach ($user in $Users) {

        Write-Log Verbose "Pre-provisioning user" $user.SamAccountName

        try {
            #
            # Auto-generation: DisplayName
            #
            if ([string]::IsNullOrWhiteSpace($user.DisplayName)) {
                if ($user.GivenName -and $user.Surname) {
                    $user.DisplayName = "$($user.GivenName) $($user.Surname)"
                }
                elseif ($user.SamAccountName) {
                    $user.DisplayName = $user.SamAccountName
                }
            }

            #
            # Auto-generation: CanonicalName
            #
            if ([string]::IsNullOrWhiteSpace($user.CanonicalName)) {
                $resolved = Resolve-CanonicalName -User $user

                if ($resolved) {
                    $user.CanonicalName = $resolved
                }
                else {
                    Write-Log Error "CanonicalName could not be resolved; manual override required" $user.SamAccountName
                    continue
                }
            }


            #
            # Auto-generation: sAMAccountName
            #
            if ([string]::IsNullOrWhiteSpace($user.SamAccountName)) {
                $user.SamAccountName = $user.CanonicalName
            }

            #
            # Auto-generation: UPN
            #
            if ([string]::IsNullOrWhiteSpace($user.UserPrincipalName)) {
                $user.UserPrincipalName = "$($user.CanonicalName)@$($Settings.PrimaryLoginDomain)"
            }

            #
            # Enabled flag
            #
            $enabled = $false
            if ($null -ne $user.Enabled -and $user.Enabled -ne '') {
                $enabled = [bool]$user.Enabled
            }

            #
            # Check if user already exists
            #
            $existing = Get-ADUser -Filter "SamAccountName -eq '$($user.SamAccountName)'" -ErrorAction SilentlyContinue

            if ($existing) {
                Write-Log Verbose "User already exists, skipping pre-provisioning" $user.SamAccountName
                continue
            }

            #
            # Build attribute map for New-ADUser
            #
            $userAttributes = @{
                SamAccountName    = $user.SamAccountName
                UserPrincipalName = $user.UserPrincipalName
                EmailAddress      = $user.UserPrincipalName
                GivenName         = $user.GivenName
                SN                = $user.Surname
                Name              = $user.DisplayName
                DisplayName       = $user.DisplayName
                Enabled           = $enabled
                Path              = $Settings.UsersOU
                accountPassword   = (ConvertTo-SecureString $Settings.DefaultUserPassword -AsPlainText -Force)
            }

            Write-Log Debug "Pre-provisioning attribute map:" $user.SamAccountName
            Write-Log Debug $userAttributes $user.SamAccountName

            #
            # Create user
            #
            New-ADUser $userAttributes

            Write-Log Info "Pre-provisioned user" $user.SamAccountName
        }
        catch {
            Write-Log Error "Failed to pre-provision user: $($_.Exception.Message)" $user.SamAccountName
            Write-Log Debug $_ $user.SamAccountName
        }
    }
}
