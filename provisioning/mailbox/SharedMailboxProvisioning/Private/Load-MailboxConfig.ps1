function Load-MailboxConfig {
    [CmdletBinding()]
    param(
        [string]$Path = "$PSScriptRoot\..\SharedMailboxProvisioning.json"
    )

    if (-not (Test-Path $Path)) {
        throw "Mailbox provisioning config not found at: $Path"
    }

    $json = Get-Content -Path $Path -Raw | ConvertFrom-Json

    return [pscustomobject]@{
        PrimaryDomain   = $json.Domains.Primary
        AliasDomains    = $json.Domains.Aliases
        DefaultLanguage = $json.Defaults.Language
        DefaultTimeZone = $json.Defaults.TimeZone
    }
}
