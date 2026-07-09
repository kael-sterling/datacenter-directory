# ConvertTo-ADAttributeMap.Tests.ps1

Import-Module "$PSScriptRoot/../YourModule.psd1"

Describe "ConvertTo-ADAttributeMap" {

    It "removes empty string values" {
        $map = @{
            GivenName = "Kael"
            Title     = ""
            Office    = "HQ"
        }

        $result = ConvertTo-ADAttributeMap -Map $map

        $result.Keys | Should -Contain "GivenName"
        $result.Keys | Should -Contain "Office"
        $result.Keys | Should -Not -Contain "Title"
    }

    It "removes whitespace-only values" {
        $map = @{
            Department = "Engineering"
            Office     = "   "
        }

        $result = ConvertTo-ADAttributeMap -Map $map

        $result.Keys | Should -Contain "Department"
        $result.Keys | Should -Not -Contain "Office"
    }

    It "keeps non-string truthy values" {
        $map = @{
            Enabled = $true
            Count   = 42
        }

        $result = ConvertTo-ADAttributeMap -Map $map

        $result.Enabled | Should -BeTrue
        $result.Count   | Should -Be 42
    }

    It "throws when required attributes are missing" {
        $map = @{ GivenName = "Kael" }

        { ConvertTo-ADAttributeMap -Map $map -RequiredAttributes @("GivenName", "SN") } |
        Should -Throw
    }
}
