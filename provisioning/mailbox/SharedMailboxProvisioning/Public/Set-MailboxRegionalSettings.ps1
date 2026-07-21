<#
.SYNOPSIS
Applies language and timezone settings to a shared mailbox.

.DESCRIPTION
Ensures the mailbox's regional configuration matches the default values
defined in the module configuration JSON.

.PARAMETER PrimarySmtp
The primary SMTP address of the mailbox.

.PARAMETER Language
The language code to apply (e.g., "en-US").

.PARAMETER TimeZone
The timezone identifier to apply (e.g., "Eastern Standard Time").

.PARAMETER DryRun
If specified, actions are printed but not executed.

.EXAMPLE
Set-MailboxRegionalSettings -PrimarySmtp "it@untapped.tech" -Language "en-US" -TimeZone "Eastern Standard Time"

.NOTES
Regional settings are global defaults, not mailbox-specific.
#>
function Set-MailboxRegionalSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PrimarySmtp,

        [Parameter(Mandatory)]
        [string]$Language,

        [Parameter(Mandatory)]
        [string]$TimeZone,

        [switch]$DryRun
    )

    Connect-EXO

    if ($DryRun) {
        Write-DryRun ("  ~ Would set Language={0}, TimeZone={1}" -f $Language, $TimeZone)
    }
    else {
        Set-MailboxRegionalConfiguration -Identity $PrimarySmtp `
            -Language $Language `
            -TimeZone $TimeZone
    }
}
