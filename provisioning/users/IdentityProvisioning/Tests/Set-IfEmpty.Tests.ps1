# Set-IfEmpty.Tests.ps1

Import-Module "$PSScriptRoot/../YourModule.psd1"

Describe "Set-IfEmpty" {

    BeforeEach {
        Mock Write-Log {}
    }

    It "sets attributes only when AD value is empty" {
        $user = [pscustomobject]@{ SamAccountName = "kael" }

        Mock Get-ADUser { return @{ Department = $null } }
        Mock Set-ADUser {}

        $attrs = @{ Department = "Engineering" }

        Set-IfEmpty -AdUser $user -Attributes $attrs

        Assert-MockCalled Set-ADUser -Times 1 -ParameterFilter {
            $Replace.Department -eq "Engineering"
        }
    }

    It "does not overwrite existing attributes" {
        $user = [pscustomobject]@{ SamAccountName = "kael" }

        Mock Get-ADUser { return @{ Department = "Existing" } }
        Mock Set-ADUser {}

        $attrs = @{ Department = "NewValue" }

        Set-IfEmpty -AdUser $user -Attributes $attrs

        Assert-MockCalled Set-ADUser -Times 0
    }

    It "skips empty input values" {
        $user = [pscustomobject]@{ SamAccountName = "kael" }

        Mock Get-ADUser { return @{ Office = $null } }
        Mock Set-ADUser {}

        $attrs = @{ Office = "" }

        Set-IfEmpty -AdUser $user -Attributes $attrs

        Assert-MockCalled Set-ADUser -Times 0
    }

    It "logs errors when Set-ADUser fails" {
        $user = [pscustomobject]@{ SamAccountName = "kael" }

        Mock Get-ADUser { return @{ Department = $null } }
        Mock Set-ADUser { throw "AD failure" }

        { Set-IfEmpty -AdUser $user -AttributeName "Department" -Value "Engineering" } |
        Should -Not -Throw

        Assert-MockCalled Write-Log -Times 1 -ParameterFilter {
            $Severity -eq "Error"
        }
    }
}
