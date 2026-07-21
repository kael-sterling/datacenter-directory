<#
.SYNOPSIS
Applies HideFromGAL settings for a shared mailbox.

.DESCRIPTION
Ensures the mailbox's HiddenFromAddressListsEnabled attribute matches
the value defined in the CSV.

.PARAMETER PrimarySmtp
The primary SMTP address of the mailbox.

.PARAMETER HideFromGAL
Boolean indicating whether the mailbox should be hidden from the GAL.

.PARAMETER DryRun
If specified, actions are printed but not executed.

.EXAMPLE
Set-MailboxVisibility -PrimarySmtp "noreply@untapped.tech" -HideFromGAL $true

.NOTES
This function only manages GAL visibility.
#>
function Set-MailboxVisibility {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PrimarySmtp,

        [Parameter(Mandatory)]
        [bool]$HideFromGAL,

        [switch]$DryRun
    )

    Connect-EXO

    $mailboxObj = Get-Mailbox -Identity $PrimarySmtp -ErrorAction SilentlyContinue
    if (-not $mailboxObj) {
        Write-Host "  ! Mailbox not found, skipping visibility." -ForegroundColor Red
        return
    }

    if ($mailboxObj.HiddenFromAddressListsEnabled -ne $HideFromGAL) {
        if ($DryRun) {
            Write-DryRun ("  ~ Would set HideFromGAL: {0}" -f $HideFromGAL)
        }
        else {
            Set-Mailbox -Identity $PrimarySmtp -HiddenFromAddressListsEnabled $HideFromGAL
        }
    }
}
