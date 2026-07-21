<#
.SYNOPSIS
    Updates the DisplayName field of an Entra ID / Microsoft 365 user.

.DESCRIPTION
    Sets the DisplayName attribute on a mailbox user using Microsoft Graph.
    This function is part of the SharedMailboxProvisioning pipeline and
    supports drift detection and dry-run execution.

.PARAMETER PrimarySmtp
    The primary SMTP address (UPN) of the mailbox user whose DisplayName should be updated.

.PARAMETER DisplayName
    The desired DisplayName value. Must be a non-empty string.

.PARAMETER DryRun
    When specified, the function reports the intended change without applying it.

.EXAMPLE
    Set-MailboxDisplayName -PrimarySmtp "dept-finance@contoso.com" -DisplayName "Finance Department"

    Updates the DisplayName field for the mailbox.

.EXAMPLE
    Set-MailboxDisplayName -PrimarySmtp "dept-hr@contoso.com" -DisplayName "HR Shared Mailbox" -DryRun

    Shows what would be changed without applying it.

.NOTES
    Requires Microsoft Graph permissions: User.ReadWrite.All
    Uses Set-GraphUserDisplayName for version-adaptive Graph SDK behavior.
#>
function Set-MailboxDisplayName {
    [CmdletBinding()]
    param(
        # Mailbox identity (UPN / Primary SMTP)
        [Parameter(Mandatory)]
        [string]$PrimarySmtp,

        # Desired DisplayName value (must be non-empty)
        [Parameter(Mandatory)]
        [string]$DisplayName,

        # Preview mode
        [switch]$DryRun
    )

    # Connect to Graph (Device Code auth, no banner)
    Connect-Graph -Scopes @('User.ReadWrite.All')

    # Lookup mailbox user
    $user = Get-MgUser -UserId $PrimarySmtp -ErrorAction SilentlyContinue
    if (-not $user) {
        Write-Host "  ! User not found: $PrimarySmtp" -ForegroundColor Red
        return
    }

    # ----------------------------------------------------------------------
    # Drift detection: Only update when the DisplayName differs
    # ----------------------------------------------------------------------
    if ($user.DisplayName -ne $DisplayName) {
        if ($DryRun) {
            Write-Host "  ~ Would update DisplayName: '$($user.DisplayName)' → '$DisplayName'"
        }
        else {
            Set-Mailbox -Identity $PrimarySmtp -DisplayName $DisplayName
            Write-Host "  + Updated DisplayName to '$DisplayName'"
        }
    }
}
