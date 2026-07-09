# Set-Attribute.Tests.ps1

Import-Module "$PSScriptRoot/../YourModule.psd1"

Describe "Set-Attribute" {

    BeforeEach {
        Mock Set-ADUser {}
        Mock Write-Log {}
    }

    It "normalizes single-attribute mode" {
        $user = [pscustomobject]@{ SamAccountName = "kael" }

        Set-Attribute -AdUser $user -AttributeName "Title" -Value "Engineer"

        Assert-MockCalled Set-ADUser -Times 1 -ParameterFilter {
            $Replace.Title -eq "Engineer"
        }
    }

    It "applies multi-attribute mode" {
        $user = [pscustomobject]@{ SamAccountName = "kael" }

        $attrs = @{
            Department = "Engineering"
            Office     = "HQ-2"
        }

        Set-Attribute -AdUser $user -Attributes $attrs

        Assert-MockCalled Set-ADUser -Times 1 -ParameterFilter {
            $Replace.Department -eq "Engineering" -and
            $Replace.Office -eq "HQ-2"
        }
    }

    It "logs errors when Set-ADUser fails" {
        Mock Set-ADUser { throw "AD failure" }

        $user = [pscustomobject]@{ SamAccountName = "kael" }

        { Set-Attribute -AdUser $user -AttributeName "Title" -Value "Engineer" } |
        Should -Not -Throw

        Assert-MockCalled Write-Log -Times 1 -ParameterFilter {
            $Severity -eq "Error"
        }
    }
}
