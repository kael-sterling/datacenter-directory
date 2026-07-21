<#
.SYNOPSIS
Strictly enforces mailbox permissions for FullAccess, SendAs, and SendOnBehalf.

.DESCRIPTION
Ensures the mailbox's permission state exactly matches the values defined
in the CSV. Missing permissions are added, and unauthorized permissions
are removed. This function provides full drift correction.

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
Enforce-MailboxPermissions -PrimarySmtp "it@untapped.tech" `
    -FullAccessUsers @("user1","user2") `
    -SendAsUsers @("user1") `
    -SendOnBehalf @("manager") `
    -DryRun

.NOTES
This function performs both add and remove operations.
#>
function Enforce-MailboxPermissions {
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
    $currentFa = Get-MailboxPermission -Identity $PrimarySmtp -ErrorAction SilentlyContinue |
    Where-Object { $_.User -notmatch 'NT AUTHORITY|S-1-5-' } |
    Select-Object -ExpandProperty User

    $toAddFa = $FullAccessUsers | Where-Object { $_ -notin $currentFa }
    $toRemoveFa = $currentFa | Where-Object { $_ -notin $FullAccessUsers }

    foreach ($user in $toAddFa) {
        if ($DryRun) {
            Write-DryRun ("  + Would assign FullAccess to: {0}" -f $user)
        }
        else {
            Add-MailboxPermission -Identity $PrimarySmtp -User $user -AccessRights FullAccess -AutoMapping $true -Confirm:$false
        }
    }

    foreach ($user in $toRemoveFa) {
        if ($DryRun) {
            Write-DryRun ("  - Would remove FullAccess from: {0}" -f $user)
        }
        else {
            Remove-MailboxPermission -Identity $PrimarySmtp -User $user -AccessRights FullAccess -Confirm:$false
        }
    }

    #
    # SendAs
    #
    $currentSa = Get-RecipientPermission -Identity $PrimarySmtp -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Trustee

    $toAddSa = $SendAsUsers | Where-Object { $_ -notin $currentSa }
    $toRemoveSa = $currentSa | Where-Object { $_ -notin $SendAsUsers }

    foreach ($user in $toAddSa) {
        if ($DryRun) {
            Write-DryRun ("  + Would assign SendAs to: {0}" -f $user)
        }
        else {
            Add-RecipientPermission -Identity $PrimarySmtp -Trustee $user -AccessRights SendAs -Confirm:$false
        }
    }

    foreach ($user in $toRemoveSa) {
        if ($DryRun) {
            Write-DryRun ("  - Would remove SendAs from: {0}" -f $user)
        }
        else {
            Remove-RecipientPermission -Identity $PrimarySmtp -Trustee $user -AccessRights SendAs -Confirm:$false
        }
    }

    #
    # SendOnBehalf
    #
    $currentSob = (Get-Mailbox -Identity $PrimarySmtp).GrantSendOnBehalfTo

    $toAddSob = $SendOnBehalf | Where-Object { $_ -notin $currentSob }
    $toRemoveSob = $currentSob | Where-Object { $_ -notin $SendOnBehalf }

    foreach ($user in $toAddSob) {
        if ($DryRun) {
            Write-DryRun ("  + Would add SendOnBehalf: {0}" -f $user)
        }
        else {
            Set-Mailbox -Identity $PrimarySmtp -GrantSendOnBehalfTo ($currentSob + $user)
        }
    }

    foreach ($user in $toRemoveSob) {
        if ($DryRun) {
            Write-DryRun ("  - Would remove SendOnBehalf: {0}" -f $user)
        }
        else {
            Set-Mailbox -Identity $PrimarySmtp -GrantSendOnBehalfTo ($currentSob | Where-Object { $_ -ne $user })
        }
    }
}
