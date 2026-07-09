function Invoke-GroupMembership {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Groups,

        [Parameter(Mandatory)]
        [psobject]$Settings
    )

    foreach ($group in $Groups) {

        Write-Log Verbose "Processing group membership" $group.SamAccountName

        try {
            #
            # Resolve AD group
            #
            $adGroup = Get-ADGroup -Identity $group.SamAccountName -ErrorAction SilentlyContinue

            if (-not $adGroup) {
                Write-Log Warning "Group not found, skipping membership enforcement" $group.SamAccountName
                continue
            }

            #
            # Desired members from CSV
            #
            $members = $group.Members -split ';' | Where-Object { $_ -ne '' }

            #
            # Current members (SamAccountName)
            #
            $currentMembers = (Get-ADGroupMember -Identity $adGroup -ErrorAction SilentlyContinue).SamAccountName

            Write-Log Debug "Desired vs current membership:" $group.SamAccountName
            Write-Log Debug @{
                Desired = $members
                Current = $currentMembers
            } $group.SamAccountName

            #
            # ADD missing members
            #
            foreach ($member in $members) {
                if ($member -notin $currentMembers) {

                    Write-Log Verbose "Adding missing member '$member'" $group.SamAccountName

                    # Try user first
                    $adMember = Get-ADUser -Filter "SamAccountName -eq '$member'" -ErrorAction SilentlyContinue

                    # Try group second
                    if (-not $adMember) {
                        $adMember = Get-ADGroup -Filter "SamAccountName -eq '$member'" -ErrorAction SilentlyContinue
                    }

                    if ($adMember) {
                        Add-ADGroupMember -Identity $adGroup -Members $adMember -ErrorAction Stop
                        Write-Log Info "Added $member to group" $group.SamAccountName
                    }
                    else {
                        Write-Log Warning "Member '$member' not found as user or group" $group.SamAccountName
                    }
                }
            }

            #
            # REMOVE extra members (strict mode)
            #
            foreach ($member in $currentMembers) {
                if ($member -notin $members) {

                    Write-Log Verbose "Removing extra member '$member'" $group.SamAccountName

                    # Try user first
                    $adMember = Get-ADUser -Filter "SamAccountName -eq '$member'" -ErrorAction SilentlyContinue

                    # Try group second
                    if (-not $adMember) {
                        $adMember = Get-ADGroup -Filter "SamAccountName -eq '$member'" -ErrorAction SilentlyContinue
                    }

                    if ($adMember) {
                        Remove-ADGroupMember -Identity $adGroup -Members $adMember -Confirm:$false -ErrorAction Stop
                        Write-Log Info "Removed $member from group" $group.SamAccountName
                    }
                }
            }
        }
        catch {
            Write-Log Error "Failed to enforce membership for group: $($_.Exception.Message)" $group.SamAccountName
            Write-Log Debug $_ $group.SamAccountName
        }
    }
}
