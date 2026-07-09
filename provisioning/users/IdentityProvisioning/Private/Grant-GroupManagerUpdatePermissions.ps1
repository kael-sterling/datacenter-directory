function Grant-GroupManagerUpdatePermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$GroupSamAccountName,

        [Parameter(Mandatory)]
        [string]$ManagerSamAccountName
    )

    Write-Log Verbose "Granting group manager update permissions" $GroupSamAccountName

    try {
        Write-Log Verbose "Resolving group" $GroupSamAccountName
        $group = Get-ADGroup -Identity $GroupSamAccountName -ErrorAction Stop
        $groupDN = $group.DistinguishedName

        Write-Log Verbose "Resolving manager" $ManagerSamAccountName
        $manager = Get-ADUser -Identity $ManagerSamAccountName -ErrorAction Stop
        $managerNT = New-Object System.Security.Principal.NTAccount($manager.SamAccountName)

        Write-Log Verbose "Loading ACL for group" $GroupSamAccountName
        $acl = Get-ACL "AD:$groupDN"

        # GUID for the "member" attribute
        $memberGuid = [Guid]"bf9679c0-0de6-11d0-a285-00aa003049e2"

        # WriteProperty on "member"
        $rights = [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty
        $inheritance = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::None

        Write-Log Debug "Building access rule" $GroupSamAccountName
        Write-Log Debug @{
            ManagerNT = $managerNT.Value
            Rights    = $rights.ToString()
            Guid      = $memberGuid.ToString()
            Inherit   = $inheritance.ToString()
        } $GroupSamAccountName

        $rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $managerNT,
            $rights,
            "Allow",
            $memberGuid,
            $inheritance
        )

        Write-Log Verbose "Applying ACE to group" $GroupSamAccountName
        $acl.AddAccessRule($rule)
        Set-ACL -Path "AD:$groupDN" -AclObject $acl

        Write-Log Info "Granted membership update rights to $ManagerSamAccountName on $GroupSamAccountName" $GroupSamAccountName
    }
    catch {
        Write-Log Error "Failed to grant membership update permissions: $($_.Exception.Message)" $GroupSamAccountName
        Write-Log Debug $_ $GroupSamAccountName
    }
}
