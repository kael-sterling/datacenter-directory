<#
.SYNOPSIS
Imports and normalizes mailbox definitions from a CSV file.

.DESCRIPTION
Reads the mailbox provisioning CSV, loads the module configuration JSON,
and normalizes each mailbox record into a consistent object structure.
This includes alias expansion, folder parsing, permission lists, manager
UPN resolution, and application of default language/timezone settings.

.PARAMETER Path
The path to the mailbox CSV file.

.EXAMPLE
$mailboxes = Import-MailboxCsv -Path ".\shared_mailboxes.csv"

.NOTES
This function performs no side effects. It only returns normalized objects.
#>
function Import-MailboxCsv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $resolved = (Resolve-Path $Path).Path
    if (-not (Test-Path $resolved)) {
        throw "Mailbox CSV not found at: $resolved"
    }

    $config = Load-MailboxConfig

    $raw = Import-Csv $resolved

    $normalized = foreach ($row in $raw) {
        Normalize-MailboxRecord `
            -InputObject $row `
            -PrimaryDomain $config.PrimaryDomain `
            -AliasDomains $config.AliasDomains `
            -DefaultLanguage $config.DefaultLanguage `
            -DefaultTimeZone $config.DefaultTimeZone
    }

    return $normalized
}
