function Resolve-Initials {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$User
    )

    Write-Log Verbose "Resolving initials" $User.SamAccountName

    try {
        $first = $User.GivenName
        $middle = $User.MiddleName
        $last = $User.Surname

        if (-not $first -or -not $last) {
            Write-Log Warning "Cannot resolve initials; missing first or last name" $User.SamAccountName
            return $null
        }

        $initials = $first.Substring(0, 1)

        if ($middle -and $middle -ne '') {
            $initials += $middle.Substring(0, 1)
        }

        $initials += $last.Substring(0, 1)

        # Uppercase, remove punctuation
        $initials = ($initials -replace '[^A-Za-z]', '').ToUpper()

        Write-Log Debug "Resolved initials: $initials" $User.SamAccountName
        return $initials
    }
    catch {
        Write-Log Error "Failed to resolve initials: $($_.Exception.Message)" $User.SamAccountName
        Write-Log Debug $_ $User.SamAccountName
        return $null
    }
}
