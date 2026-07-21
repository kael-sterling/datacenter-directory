<#
.SYNOPSIS
Applies the mailbox description stored in CustomAttribute1.

.DESCRIPTION
Ensures the mailbox's CustomAttribute1 matches the Description field
defined in the CSV.

.PARAMETER PrimarySmtp
The primary SMTP address of the mailbox.

.PARAMETER Description
The description to assign.

.PARAMETER DryRun
If specified, actions are printed but not executed.

.EXAMPLE
Set-MailboxDescription -PrimarySmtp "it@untapped.tech" -Description "IT operations mailbox"

.NOTES
Description is stored in CustomAttribute1 for consistency.
#>
function Set-MailboxDescription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PrimarySmtp,

        [string]$Description,

        [switch]$DryRun
    )

    Connect-EXO

    $mailboxObj = Get-Mailbox -Identity $PrimarySmtp -ErrorAction SilentlyContinue
    if (-not $mailboxObj) {
        Write-Host "  ! Mailbox not found, skipping description." -ForegroundColor Red
        return
    }

    if ($mailboxObj.CustomAttribute1 -ne $Description) {
        if ($DryRun) {
            Write-DryRun ("  ~ Would set Description: '{0}'" -f $Description)
        }
        else {
            Set-Mailbox -Identity $PrimarySmtp -CustomAttribute1 $Description
        }
    }
}
