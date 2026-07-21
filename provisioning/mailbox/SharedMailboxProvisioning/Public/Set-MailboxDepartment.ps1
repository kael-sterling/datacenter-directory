<#
.SYNOPSIS
Applies the Department attribute to the mailbox's AAD user object.

.DESCRIPTION
Ensures the Department attribute in Azure AD matches the value defined
in the CSV. Drift is corrected using Microsoft Graph.

.PARAMETER PrimarySmtp
The primary SMTP address of the mailbox.

.PARAMETER Department
The department name to assign.

.PARAMETER DryRun
If specified, actions are printed but not executed.

.EXAMPLE
Set-MailboxDepartment -PrimarySmtp "hr@untapped.tech" -Department "HR"

.NOTES
This function uses Microsoft Graph, not Exchange Online.
#>
function Set-MailboxDepartment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PrimarySmtp,

        [string]$Department,

        [switch]$DryRun
    )

    Connect-Graph -Scopes @('User.ReadWrite.All')

    if (-not $Department) { return }

    $current = (Get-MgUser -UserId $PrimarySmtp -ErrorAction SilentlyContinue).Department

    if ($current -ne $Department) {
        if ($DryRun) {
            Write-DryRun ("  ~ Would update Department: '{0}' → '{1}'" -f $current, $Department)
        }
        else {
            Update-MgUser -UserId $PrimarySmtp -Department $Department
        }
    }
}
