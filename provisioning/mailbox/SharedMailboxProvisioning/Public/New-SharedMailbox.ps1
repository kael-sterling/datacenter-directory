<#
.SYNOPSIS
Creates shared mailboxes and applies rename drift correction.

.DESCRIPTION
Ensures each mailbox defined in the CSV exists in Exchange Online.
If the mailbox does not exist, it is created. If the mailbox exists
but its DisplayName differs from the CSV, the mailbox is renamed and
the rename is logged.

.PARAMETER Mailboxes
The normalized mailbox objects returned from Import-MailboxCsv.

.PARAMETER RenameLogPath
Path to the rename log file.

.PARAMETER DryRun
If specified, actions are printed but not executed.

.EXAMPLE
New-SharedMailbox -Mailboxes $mailboxes -RenameLogPath ".\rename_log.txt"

.NOTES
This function handles mailbox creation and rename drift only.
#>
function New-SharedMailbox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject[]]$Mailboxes,
        [string]$RenameLogPath = ".\rename_log.txt",
        [switch]$DryRun
    )

    Connect-EXO

    foreach ($mb in $Mailboxes) {
        $name = $mb.Name
        $primary = $mb.PrimarySmtp

        Write-Info "Processing mailbox: $primary"

        $existing = Get-Mailbox -Identity $primary -ErrorAction SilentlyContinue

        if (-not $existing) {
            if ($DryRun) {
                Write-DryRun ("  + Would create shared mailbox: {0}" -f $primary)
            }
            else {
                Write-Info "  + Creating shared mailbox..."
                New-Mailbox -Shared -Name $name -PrimarySmtpAddress $primary | Out-Null
                $existing = Get-Mailbox -Identity $primary
            }
        }

        if ($existing.DisplayName -ne $name) {
            $oldName = $existing.DisplayName
            if ($DryRun) {
                Write-DryRun ("  ~ Would rename mailbox: '{0}' → '{1}'" -f $oldName, $name)
            }
            else {
                Write-RenameLog -Path $RenameLogPath -Message "Renamed mailbox '$oldName' → '$name'"
                Set-Mailbox -Identity $primary -DisplayName $name
            }
        }
    }
}
