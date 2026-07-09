# Resolve-ProxyAddresses.Tests.ps1

Import-Module "$PSScriptRoot/../YourModule.psd1"

Describe "Resolve-ProxyAddresses" {

    It "creates a primary SMTP address" {
        $result = Resolve-ProxyAddresses `
            -SamAccountName "kael" `
            -CanonicalName "kael.sterling" `
            -PrimaryLoginDomain "corp.example.com" `
            -PrimaryMailDomain "corp.example.com" `
            -SecondaryMailDomains @()

        $result | Should -Contain "SMTP:kael@corp.example.com"
    }

    It "creates alias smtp addresses for secondary domains" {
        $result = Resolve-ProxyAddresses `
            -SamAccountName "kael" `
            -CanonicalName "kael.sterling" `
            -PrimaryLoginDomain "corp.example.com" `
            -PrimaryMailDomain "corp.example.com" `
            -SecondaryMailDomains @("example.com", "alt.example.com")

        $result | Should -Contain "smtp:kael@example.com"
        $result | Should -Contain "smtp:kael@alt.example.com"
    }

    It "creates canonical-name aliases" {
        $result = Resolve-ProxyAddresses `
            -SamAccountName "kael" `
            -CanonicalName "kael.sterling" `
            -PrimaryLoginDomain "corp.example.com" `
            -PrimaryMailDomain "corp.example.com" `
            -SecondaryMailDomains @()

        $result | Should -Contain "smtp:kael.sterling@corp.example.com"
    }

    It "enforces case-insensitive uniqueness" {
        $result = Resolve-ProxyAddresses `
            -SamAccountName "kael" `
            -CanonicalName "kael" `
            -PrimaryLoginDomain "corp.example.com" `
            -PrimaryMailDomain "corp.example.com" `
            -SecondaryMailDomains @("corp.example.com")

        # Should only contain one alias for the duplicate domain
        ($result | Where-Object { $_ -eq "smtp:kael@corp.example.com" }).Count |
        Should -Be 1
    }
}
