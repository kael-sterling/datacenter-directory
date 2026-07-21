@{
    # Core metadata
    RootModule           = 'SharedMailboxProvisioning.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = '598b9a9d-ef90-4f07-9aca-b4f903fc1ccf'
    Author               = 'Kael Sterling Avner'
    CompanyName          = 'Untapped Technologies'
    Copyright            = '(c) 2026 Untapped Technologies'

    # Compatibility
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    # Public functions
    FunctionsToExport    = @(
        'Enforce-MailboxPermissions',
        'Import-MailboxCsv',
        'Invoke-SharedMailboxProvisioning',
        'New-SharedMailbox',
        'Set-MailboxTitle',
        'Set-MailboxAliases',
        'Set-MailboxAutoReply',
        'Set-MailboxDepartment',
        'Set-MailboxDescription',
        'Set-MailboxFolders',
        'Set-MailboxManager',
        'Set-MailboxPermissions',
        'Set-MailboxRegionalSettings',
        'Set-MailboxVisibility'
    )

    # Private functions
    PrivateData          = @{
        PSData = @{
            Tags       = @('ExchangeOnline', 'Provisioning', 'Automation', 'Identity', 'Mailbox')
            ProjectUri = 'https://untapped.tech'
            LicenseUri = ''
        }
    }

    # Scripts to process
    ScriptsToProcess     = @()

    # Required modules
    RequiredModules      = @(
        @{ ModuleName = 'ExchangeOnlineManagement'; ModuleVersion = '3.4.0' },
        @{ ModuleName = 'Microsoft.Graph.Users'; ModuleVersion = '1.27.0' }
    )

    # Formats / Types
    FormatsToProcess     = @()
    TypesToProcess       = @()

    # Manifest completeness
    Description          = 'Declarative provisioning and drift correction for Exchange Online shared mailboxes.'
}
