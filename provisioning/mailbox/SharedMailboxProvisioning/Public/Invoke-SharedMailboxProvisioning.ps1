<#
.SYNOPSIS
Runs the full shared mailbox provisioning pipeline.

.DESCRIPTION
Orchestrates mailbox creation, metadata application, folder creation,
alias expansion, manager assignment, regional settings, auto-replies,
and permission assignment. Optionally enforces strict permission drift.

.PARAMETER MailboxesCsvPath
Path to the mailbox CSV file.

.PARAMETER RenameLogPath
Path to the rename log file.

.PARAMETER DryRun
If specified, actions are printed but not executed.

.PARAMETER EnforcePermissions
If specified, mailbox permissions are strictly enforced.

.EXAMPLE
Invoke-SharedMailboxProvisioning -MailboxesCsvPath ".\shared_mailboxes.csv"

.NOTES
This is the primary entry point for the module.
#>
function Invoke-SharedMailboxProvisioning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MailboxesCsvPath = ".\shared_mailboxes.csv",
        [string]$RenameLogPath = ".\rename_log.txt",
        [switch]$DryRun,
        [switch]$EnforcePermissions
    )

    Write-Info "`n=== Shared Mailbox Provisioning ===`n"

    $mailboxes = Import-MailboxCsv -Path $MailboxesCsvPath

    Write-Step "`n--- Step 1: Create/rename shared mailboxes ---`n"
    New-SharedMailbox -Mailboxes $mailboxes -RenameLogPath $RenameLogPath -DryRun:$DryRun

    foreach ($mb in $mailboxes) {
        Write-Step "`n--- Processing mailbox: $($mb.PrimarySmtp) ---`n"

        Set-MailboxVisibility       -PrimarySmtp $mb.PrimarySmtp -HideFromGAL $mb.HideFromGAL -DryRun:$DryRun
        Set-MailboxDescription      -PrimarySmtp $mb.PrimarySmtp -Description $mb.Description -DryRun:$DryRun
        Set-MailboxDisplayName      -PrimarySmtp $mb.PrimarySmtp -DisplayName $mb.DisplayName -DryRun:$DryRun
        Set-MailboxDepartment       -PrimarySmtp $mb.PrimarySmtp -Department $mb.Department -DryRun:$DryRun
        Set-MailboxManager          -PrimarySmtp $mb.PrimarySmtp -ManagerUpn $mb.ManagerUpn -DryRun:$DryRun
        Set-MailboxRegionalSettings -PrimarySmtp $mb.PrimarySmtp -Language $mb.Language -TimeZone $mb.TimeZone -DryRun:$DryRun
        Set-MailboxAliases          -PrimarySmtp $mb.PrimarySmtp -Aliases $mb.Aliases -DryRun:$DryRun
        Set-MailboxFolders          -PrimarySmtp $mb.PrimarySmtp -Folders $mb.Folders -DryRun:$DryRun
        Set-MailboxAutoReply `
            -PrimarySmtp $mb.PrimarySmtp `
            -AutoReplyEnabled $mb.AutoReplyEnabled `
            -InternalReply $mb.InternalReply `
            -ExternalReply $mb.ExternalReply `
            -ExternalAudience $mb.ExternalAudience `
            -DryRun:$DryRun
        Set-MailboxPermissions `
            -PrimarySmtp $mb.PrimarySmtp `
            -FullAccessUsers $mb.FullAccessUsers `
            -SendAsUsers $mb.SendAsUsers `
            -SendOnBehalf $mb.SendOnBehalf `
            -DryRun:$DryRun

        if ($EnforcePermissions) {
            Enforce-MailboxPermissions `
                -PrimarySmtp $mb.PrimarySmtp `
                -FullAccessUsers $mb.FullAccessUsers `
                -SendAsUsers $mb.SendAsUsers `
                -SendOnBehalf $mb.SendOnBehalf `
                -DryRun:$DryRun
        }
    }

    Write-Info "`n=== Shared Mailbox Provisioning complete ===`n"
}
