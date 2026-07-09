function Resolve-Gecos {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$User
    )

    Write-Log Verbose "Resolving gecos" $User.SamAccountName

    try {
        $resolved = if ($User.DisplayName -and $User.DisplayName -ne '') {
            $User.DisplayName
        }
        else {
            "$($User.GivenName) $($User.Surname)"
        }

        Write-Log Debug "Resolved gecos: $resolved" $User.SamAccountName
        return $resolved
    }
    catch {
        Write-Log Error "Failed to resolve gecos: $($_.Exception.Message)" $User.SamAccountName
        Write-Log Debug $_ $User.SamAccountName
        return $null
    }
}
