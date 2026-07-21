<#
.SYNOPSIS
Applies alias drift correction for a shared mailbox.

.DESCRIPTION
Ensures all aliases defined in the CSV exist on the mailbox. Missing
aliases are added. Existing aliases not defined in the CSV are ignored.

.PARAMETER PrimarySmtp
The primary SMTP address of the mailbox.

.PARAMETER Aliases
Array of SMTP aliases that should exist on the mailbox.

.PARAMETER DryRun
If specified, actions are printed but not executed.

.EXAMPLE
Set-MailboxAliases -PrimarySmtp "it@untapped.tech" -Aliases @("it@untapped.tech","it@untappedtechnologies.com")

.NOTES
Alias expansion is handled during normalization, not here.
#>
function Set-MailboxAliases {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PrimarySmtp,

        [string[]]$Aliases = @(),

        [switch]$DryRun
    )

    Connect-EXO

    $mailboxObj = Get-Mailbox -Identity $PrimarySmtp -ErrorAction SilentlyContinue
    if (-not $mailboxObj) {
        Write-Host "  ! Mailbox not found, skipping aliases." -ForegroundColor Red
        return
    }

    $currentAliases = $mailboxObj.EmailAddresses

    foreach ($alias in $Aliases) {
        if ($currentAliases -notcontains $alias) {
            if ($DryRun) {
                Write-DryRun ("  + Would add alias: {0}" -f $alias)
            }
            else {
                Set-Mailbox -Identity $PrimarySmtp -EmailAddresses @{ add = $alias }
            }
        }
    }
}
