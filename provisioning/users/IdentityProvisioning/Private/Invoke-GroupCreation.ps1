function Invoke-GroupCreation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Groups,

        [Parameter(Mandatory)]
        [psobject]$Settings
    )

    foreach ($group in $Groups) {

        Write-Log Verbose "Processing group" $group.SamAccountName

        $existing = $null

        #
        # Check if group exists
        #
        try {
            $existing = Get-ADGroup -Identity $group.SamAccountName -Properties * -ErrorAction SilentlyContinue

            if ($existing) {
                Write-Log Verbose "Group exists, skipping creation step" $group.SamAccountName
            }
        }
        catch {
            # Get-ADGroup may throw even with SilentlyContinue; ignore
        }

        try {
            #
            # Resolve ManagedBy DN
            #
            $managedByDN = $null

            if ($group.ManagedBy) {
                Write-Log Verbose "Resolving manager '$($group.ManagedBy)'" $group.SamAccountName

                $manager = Get-ADUser -Filter "SamAccountName -eq '$($group.ManagedBy)'" -ErrorAction SilentlyContinue

                if ($manager) {
                    $managedByDN = $manager.DistinguishedName
                }
                else {
                    Write-Log Warning "Manager '$($group.ManagedBy)' not found" $group.SamAccountName
                }
            }

            #
            # If group exists → update it
            #
            if ($existing) {

                Write-Log Verbose "Updating existing group attributes" $group.SamAccountName

                $update = @{}

                if ($group.Description -and $group.Description -ne $existing.Description) {
                    $update.Description = $group.Description
                }

                if ($managedByDN -and $managedByDN -ne $existing.ManagedBy) {
                    $update.ManagedBy = $managedByDN
                }

                if ($group.Category -and $group.Category -ne $existing.GroupCategory) {
                    $update.GroupCategory = $group.Category
                }

                if ($group.Scope -and $group.Scope -ne $existing.GroupScope) {
                    $update.GroupScope = $group.Scope
                }

                if ($update.Count -gt 0) {
                    Write-Log Debug "Updating group attributes:" $group.SamAccountName
                    Write-Log Debug $update $group.SamAccountName

                    Set-ADGroup -Identity $existing @update
                }
                else {
                    Write-Log Verbose "No attribute changes detected" $group.SamAccountName
                }

                if ($managedByDN) {
                    Write-Log Verbose "Applying manager update permissions" $group.SamAccountName
                    Grant-GroupManagerUpdatePermissions -GroupSamAccountName $group.SamAccountName -ManagerSamAccountName $group.ManagedBy
                }

                continue
            }

            #
            # Group does not exist → create it
            #
            Write-Log Verbose "Creating new group" $group.SamAccountName

            $params = @{
                Name           = $group.Name
                SamAccountName = $group.SamAccountName
                GroupScope     = $group.Scope
                GroupCategory  = $group.Category
                Path           = $Settings.GroupsOU
                Description    = $group.Description
            }

            if ($managedByDN) {
                $params.ManagedBy = $managedByDN
            }

            Write-Log Debug "New-ADGroup parameters:" $group.SamAccountName
            Write-Log Debug $params $group.SamAccountName

            New-ADGroup @params

            Write-Log Info "Created group $($group.SamAccountName)" $group.SamAccountName

            if ($managedByDN) {
                Write-Log Verbose "Applying manager update permissions" $group.SamAccountName
                Grant-GroupManagerUpdatePermissions -GroupSamAccountName $group.SamAccountName -ManagerSamAccountName $group.ManagedBy
            }
        }
        catch {
            Write-Log Error "Failed to create or update group $($group.SamAccountName): $($_.Exception.Message)" $group.SamAccountName
            Write-Log Debug $_ $group.SamAccountName
        }
    }
}
