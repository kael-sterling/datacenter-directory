<#
.SYNOPSIS
Sets the Manager attribute for the mailbox's AAD user object.

.DESCRIPTION
Resolves the manager's UPN (built from sAMAccountName + primary domain
during normalization) and ensures the mailbox's Manager attribute matches
the desired value.

.PARAMETER PrimarySmtp
The primary SMTP address of the mailbox.

.PARAMETER ManagerUpn
The manager's UPN (e.g., "kael@untapped.tech").

.PARAMETER DryRun
If specified, actions are printed but not executed.

.EXAMPLE
Set-MailboxManager -PrimarySmtp "it@untapped.tech" -ManagerUpn "itmgr@untapped.tech"

.NOTES
ManagerUpn is resolved in Normalize-MailboxRecord from sAMAccountName.
#>
function Set-MailboxManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PrimarySmtp,

        [string]$ManagerUpn,

        [switch]$DryRun
    )

    Connect-Graph -Scopes @('User.ReadWrite.All')

    if (-not $ManagerUpn) { return }

    $desired = Get-MgUser -UserId $ManagerUpn -ErrorAction SilentlyContinue
    if (-not $desired) {
        Write-Host "  ! Manager not found: $ManagerUpn" -ForegroundColor Red
        return
    }

    $current = Get-MgUserManager -UserId $PrimarySmtp -ErrorAction SilentlyContinue

    if (-not $current -or $current.Id -ne $desired.Id) {
        if ($DryRun) {
            Write-DryRun ("  ~ Would set Manager: {0}" -f $ManagerUpn)
        }
        else {
            # Update-MgUser -UserId $PrimarySmtp -Manager $desired.Id
            # $desired is the manager user object returned by Get-MgUser
            # Set-MgUserManagerByRef -UserId $PrimarySmtp -Id $desired.Id
            # Set-MgUserManagerByRef -UserId $PrimarySmtp -BodyParameter @{'@odata.id' = "https://graph.microsoft.com/v1.0/users/$($desired.Id)" }
            Set-GraphUserManager -UserId $PrimarySmtp -ManagerObjectId $desired.Id -DryRun:$DryRun

            Write-Host "  + Updated manager to $ManagerUpn"

        }
    }
}
