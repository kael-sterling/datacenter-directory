<#
.SYNOPSIS
Applies mailbox permissions (add-only) for FullAccess, SendAs, and SendOnBehalf.

.DESCRIPTION
Ensures all permissions defined in the CSV exist on the mailbox. Missing
permissions are added. Existing permissions not defined in the CSV are
ignored. Removal is handled by Enforce-MailboxPermissions.

.PARAMETER PrimarySmtp
The primary SMTP address of the mailbox.

.PARAMETER FullAccessUsers
Array of users who should have FullAccess permissions.

.PARAMETER SendAsUsers
Array of users who should have SendAs permissions.

.PARAMETER SendOnBehalf
Array of users who should have SendOnBehalf permissions.

.PARAMETER DryRun
If specified, actions are printed but not executed.

.EXAMPLE
Set-MailboxPermissions -PrimarySmtp "it@untapped.tech" `
    -FullAccessUsers @("user1","user2") `
    -SendAsUsers @("user1") `
    -SendOnBehalf @("manager")

.NOTES
SendOnBehalf uses Set-Mailbox -GrantSendOnBehalfTo.
#>
function Set-MailboxPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PrimarySmtp,

        [string[]]$FullAccessUsers = @(),
        [string[]]$SendAsUsers = @(),
        [string[]]$SendOnBehalf = @(),

        [switch]$DryRun
    )

    Connect-EXO

    #
    # FullAccess
    #
    foreach ($user in $FullAccessUsers) {
        if (-not $user) { continue }

        $perm = Get-MailboxPermission -Identity $PrimarySmtp -User $user -ErrorAction SilentlyContinue
        if (-not $perm) {
            if ($DryRun) {
                Write-DryRun ("  + Would assign FullAccess to: {0}" -f $user)
            }
            else {
                Add-MailboxPermission -Identity $PrimarySmtp -User $user -AccessRights FullAccess -AutoMapping $true -Confirm:$false
            }
        }
    }

    #
    # SendAs
    #
    foreach ($user in $SendAsUsers) {
        if (-not $user) { continue }

        $perm = Get-RecipientPermission -Identity $PrimarySmtp -Trustee $user -ErrorAction SilentlyContinue
        if (-not $perm) {
            if ($DryRun) {
                Write-DryRun ("  + Would assign SendAs to: {0}" -f $user)
            }
            else {
                Add-RecipientPermission -Identity $PrimarySmtp -Trustee $user -AccessRights SendAs -Confirm:$false
            }
        }
    }

    #
    # SendOnBehalf
    #
    if ($SendOnBehalf.Count -gt 0) {
        if ($DryRun) {
            Write-DryRun ("  + Would set SendOnBehalf: {0}" -f ($SendOnBehalf -join ', '))
        }
        else {
            Set-Mailbox -Identity $PrimarySmtp -GrantSendOnBehalfTo $SendOnBehalf
        }
    }
}
