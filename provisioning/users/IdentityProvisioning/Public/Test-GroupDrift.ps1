function Test-GroupDrift {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = "$PSScriptRoot\..\Config"
    )

    Write-Log Info "Starting group drift analysis"

    $config = Invoke-ConfigLoad -ConfigPath $ConfigPath
    $groups = $config.Groups

    $results = @()

    foreach ($group in $groups) {

        Write-Log Verbose "Checking group drift for $($group.SamAccountName)"

        try {
            #
            # Resolve AD group
            #
            $adGroup = Get-ADGroup -Identity $group.SamAccountName -Properties Description -ErrorAction SilentlyContinue

            if (-not $adGroup) {
                $results += [pscustomobject]@{
                    Group            = $group.SamAccountName
                    DriftType        = 'MissingGroup'
                    ExpectedMembers  = $group.Members
                    ActualMembers    = $null
                    DescriptionDrift = $null
                }
                Write-Log Warning "Group missing: $($group.SamAccountName)"
                continue
            }

            #
            # Normalize expected members
            #
            $expectedMembers = @()
            if ($group.Members -is [string]) {
                $expectedMembers = $group.Members -split ';'
            }
            else {
                $expectedMembers = $group.Members
            }

            $expectedMembers = $expectedMembers | Where-Object { $_ -ne '' }

            #
            # Get actual members (users only)
            #
            $actualMembers = (Get-ADGroupMember -Identity $adGroup |
                Where-Object { $_.objectClass -eq 'user' }).SamAccountName

            #
            # Case-insensitive comparison
            #
            $missing = $expectedMembers | Where-Object { $_ -notin $actualMembers }
            $extra = $actualMembers | Where-Object { $_ -notin $expectedMembers }

            #
            # Description drift
            #
            $descriptionDrift = $null
            if ($group.Description -and ($group.Description -ne $adGroup.Description)) {
                $descriptionDrift = @{
                    Expected = $group.Description
                    Actual   = $adGroup.Description
                }
            }

            #
            # Record drift
            #
            if ($missing -or $extra -or $descriptionDrift) {
                $results += [pscustomobject]@{
                    Group            = $group.SamAccountName
                    DriftType        = 'MembershipDrift'
                    MissingMembers   = ($missing -join ';')
                    ExtraMembers     = ($extra -join ';')
                    DescriptionDrift = $descriptionDrift
                }

                Write-Log Warning "Drift detected for $($group.SamAccountName)"
                Write-Log Debug @{
                    Missing     = $missing
                    Extra       = $extra
                    Description = $descriptionDrift
                }
            }
        }
        catch {
            Write-Log Error "Failed to analyze drift for $($group.SamAccountName): $($_.Exception.Message)"
            Write-Log Debug $_
        }
    }

    Write-Log Info "Group drift analysis completed. Drifted groups: $($results.Count)"

    return $results
}
