function Resolve-CanonicalName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$User
    )

    Write-Log Verbose "Resolving canonical name" $User.SamAccountName

    #
    # Base canonical name
    #
    $base = ($User.GivenName + "." + $User.Surname).ToLower()

    Write-Log Debug "Base canonical name candidate: $base" $User.SamAccountName

    #
    # Check for collision
    #
    $existing = Get-ADUser -Filter "sAMAccountName -eq '$base'" -ErrorAction SilentlyContinue

    if (-not $existing) {
        Write-Log Verbose "Canonical name resolved (no collision)" $User.SamAccountName
        return $base
    }

    Write-Log Warning "Canonical name collision detected for '$base'" $User.SamAccountName

    #
    # Try middle initial
    #
    if ($User.MiddleName -and $User.MiddleName -ne '') {

        $middleInitial = $User.MiddleName.Substring(0, 1).ToLower()
        $withMiddle = ($User.GivenName + "." + $middleInitial + "." + $User.Surname).ToLower()

        Write-Log Debug "Middle-initial canonical name candidate: $withMiddle" $User.SamAccountName

        $existing2 = Get-ADUser -Filter "sAMAccountName -eq '$withMiddle'" -ErrorAction SilentlyContinue

        if (-not $existing2) {
            Write-Log Verbose "Canonical name resolved using middle initial" $User.SamAccountName
            return $withMiddle
        }

        Write-Log Warning "Middle-initial canonical name also collides: '$withMiddle'" $User.SamAccountName
    }

    #
    # Still collision → require manual override
    #
    Write-Log Error "CanonicalName collision for $($User.GivenName) $($User.Surname). Manual override required in CSV." $User.SamAccountName

    return $null
}
