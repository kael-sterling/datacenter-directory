function Invoke-IdentityProvisioning {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = "$PSScriptRoot\..\Config"
    )

    Write-Log Info "Starting identity provisioning pipeline"

    $config = Invoke-ConfigLoad -ConfigPath $ConfigPath

    $users = $config.Users
    $groups = $config.Groups
    $identity = $config.Identity

    Invoke-Phase -Name "Pre-provisioning users" {
        Invoke-UserPreProvisioning -Users $users -Settings $identity
    }

    Invoke-Phase -Name "Identity attributes" {
        Invoke-UserIdentityAttributes -Users $users -Settings $identity
    }

    Invoke-Phase -Name "Non-identity attributes" {
        Invoke-UserNonIdentityAttributes -Users $users -Settings $identity
    }

    Invoke-Phase -Name "ProxyAddresses" {
        Invoke-UserProxyAddresses -Users $users -Settings $identity
    }

    Invoke-Phase -Name "Group creation" {
        Invoke-GroupCreation -Groups $groups -Settings $identity
    }

    Invoke-Phase -Name "Direct membership" {
        Invoke-GroupMembership -Groups $groups -Settings $identity
    }

    Invoke-Phase -Name "Nested membership" {
        Invoke-GroupNesting -Groups $groups -Settings $identity
    }

    Write-Log Info "Identity provisioning completed"
}
