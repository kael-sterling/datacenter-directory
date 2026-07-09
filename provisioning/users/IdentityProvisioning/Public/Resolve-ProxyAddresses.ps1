function Resolve-ProxyAddresses {
    <#
.SYNOPSIS
Generates a complete, AD‑safe proxyAddresses array for a user.

.DESCRIPTION
Resolve-ProxyAddresses constructs the full proxyAddresses list for a user
based on login domains, mail domains, and secondary alias domains.

This function:
1. Builds the primary SMTP address using SamAccountName.
2. Builds alias SMTP addresses using CanonicalName and all mail domains.
3. Applies correct SMTP/smtp prefixes.
4. Enforces case-insensitive uniqueness.
5. Returns an array suitable for Set-ADUser -Replace proxyAddresses.

.PARAMETER SamAccountName
The user's SamAccountName. Used to generate primary and alias SMTP addresses.

.PARAMETER CanonicalName
The user's canonical name (e.g., firstname.lastname). Used for alias addresses.

.PARAMETER PrimaryLoginDomain
The domain used for the user's primary login identity.

.PARAMETER PrimaryMailDomain
The domain used for the user's primary email identity.

.PARAMETER SecondaryMailDomains
Additional mail domains used to generate alias addresses.

.OUTPUTS
[string[]]
Returns an array of proxyAddresses including:
- One primary SMTP: address (uppercase prefix)
- Zero or more smtp: aliases (lowercase prefix)

.EXAMPLE
Resolve-ProxyAddresses `
    -SamAccountName "kael" `
    -CanonicalName "kael.sterling" `
    -PrimaryLoginDomain "corp.example.com" `
    -PrimaryMailDomain "example.com" `
    -SecondaryMailDomains @("alt.example.com")

.NOTES
This function does not write to Active Directory. It only resolves addresses.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SamAccountName,

        [Parameter(Mandatory)]
        [string]$CanonicalName,

        [Parameter(Mandatory)]
        [string]$PrimaryLoginDomain,

        [Parameter(Mandatory)]
        [string]$PrimaryMailDomain,

        [Parameter()]
        [string[]]$SecondaryMailDomains = @()
    )

    Write-Log Verbose "Resolving proxyAddresses" $SamAccountName

    try {
        #
        # Build raw SMTP addresses (no prefixes yet)
        #
        $primarySmtp = "$SamAccountName@$PrimaryLoginDomain"

        $aliases = @()

        foreach ($domain in $SecondaryMailDomains) {
            $aliases += "$SamAccountName@$domain"
        }

        $aliases += "$CanonicalName@$PrimaryLoginDomain"

        if ($PrimaryMailDomain -ne $PrimaryLoginDomain) {
            $aliases += "$CanonicalName@$PrimaryMailDomain"
        }

        foreach ($domain in $SecondaryMailDomains) {
            $aliases += "$CanonicalName@$domain"
        }

        #
        # Wrap with SMTP/smtp prefixes
        #
        $primary = "SMTP:$primarySmtp"
        $smtpAliases = $aliases | ForEach-Object { "smtp:$_" }

        #
        # Combine and enforce uniqueness (case-insensitive)
        #
        $resolved = @($primary) + $smtpAliases
        $resolved = $resolved | Sort-Object -Unique -CaseSensitive:$false

        Write-Log Debug "Resolved proxyAddresses list" $SamAccountName
        Write-Log Debug ($resolved -join ', ') $SamAccountName
        $resolved = [string[]]$resolved # Force to string array for AD compatibility

        return $resolved
    }
    catch {
        Write-Log Error ("Failed to resolve proxyAddresses: {0}" -f $_.Exception.Message) $SamAccountName
        Write-Log Debug $_ $SamAccountName
        return $null
    }
}
