@{
    RootModule        = 'IdentityProvisioning.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '6746d9c7-30ab-4283-9fb7-afa59341aa54'
    Author            = 'Kael Sterling'
    CompanyName       = 'Untapped Technologies'
    Copyright         = '(c) Untapped Technologies. All rights reserved.'
    Description       = 'Declarative identity provisioning for AD DS and Exchange-style attributes.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'ConvertTo-ADAttributeMap',
        'Invoke-IdentityProvisioning',
        'Resolve-ProxyAddresses',
        'Set-Attribute',
        'Set-IfEmpty',
        'Test-GroupDrift'
    )

    PrivateData       = @{
        PSData = @{
            Tags       = @('Identity', 'Provisioning', 'AD', 'Exchange')
            ProjectUri = ''
        }
    }
}
