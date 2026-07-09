function Invoke-GroupNesting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Groups,

        [Parameter(Mandatory)]
        [psobject]$Settings
    )

    foreach ($group in $Groups) {

        Write-Log Verbose "Processing group nesting" $group.SamAccountName

        try {
            #
            # Resolve AD group
            #
            $adGroup = Get-ADGroup -Identity $group.SamAccountName -ErrorAction SilentlyContinue

            if (-not $adGroup) {
                Write-Log Warning "Group not found, skipping nesting enforcement" $group.SamAccountName
                continue
            }

            #
            # Desired nested groups from CSV
            #
            $nested = $group.NestedMembers -split ';' | Where-Object { $_ -ne '' }

            Write-Log Debug "Desired nested groups:" $group.SamAccountName
            Write-Log Debug $nested $group.SamAccountName

            #
            # Apply nesting
            #
            foreach ($nestedGroupSam in $nested) {

                Write-Log Verbose "Processing nested group '$nestedGroupSam'" $group.SamAccountName

                $nestedGroup = Get-ADGroup -Identity $nestedGroupSam -ErrorAction SilentlyContinue

                if ($nestedGroup) {
                    Add-ADGroupMember -Identity $adGroup -Members $nestedGroup -ErrorAction Stop
                    Write-Log Info "Nested group '$nestedGroupSam' into '$($group.SamAccountName)'" $group.SamAccountName
                }
                else {
                    Write-Log Warning "Nested group '$nestedGroupSam' not found" $group.SamAccountName
                }
            }
        }
        catch {
            Write-Log Error ("Failed to enforce nesting for group: {0}" -f ($PSItem.Exception?.Message ?? $PSItem)) $group.SamAccountName
            Write-Log Debug $_ $group.SamAccountName
        }
    }
}
