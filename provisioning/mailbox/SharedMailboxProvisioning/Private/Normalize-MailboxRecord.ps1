function Normalize-MailboxRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$InputObject,

        [Parameter(Mandatory)]
        [string]$PrimaryDomain,

        [Parameter(Mandatory)]
        [string[]]$AliasDomains,

        [Parameter(Mandatory)]
        [string]$DefaultLanguage,

        [Parameter(Mandatory)]
        [string]$DefaultTimeZone
    )

    $hide = $InputObject.HideFromGAL.ToString().Trim() -match '^(yes|true|1)$'

    $primarySmtp = "{0}@{1}" -f $InputObject.Name.ToLower(), $PrimaryDomain
    # Aliases: names → full SMTP addresses
    $aliasNames = Split-SemicolonList -Value $InputObject.Aliases
    $aliases = Expand-Aliases -AliasNames $aliasNames -AliasDomains $AliasDomains

    # Folders
    $folders = Split-SemicolonList -Value $InputObject.Folders

    # Permissions
    $faUsers = (Split-SemicolonList $InputObject.FullAccessUsers) | ForEach-Object { "$_@$PrimaryDomain" }
    $saUsers = Split-SemicolonList $InputObject.SendAsUsers       | ForEach-Object { "$_@$PrimaryDomain" }
    $sobUsers = Split-SemicolonList $InputObject.SendOnBehalf     | ForEach-Object { "$_@$PrimaryDomain" }

    $displayName = 
    if ([string]::IsNullOrWhiteSpace($InputObject.DisplayName)) {
        $InputObject.Name# + " Shared Mailbox" 
    }
    else {
        $InputObject.DisplayName 
    }
    
    $autoReplyEnabled =
    if ([string]::IsNullOrWhiteSpace($InputObject.AutoReplyEnabled)) {
        $false
    }
    else {
        [bool]$InputObject.AutoReplyEnabled
    }

    # Manager: sAMAccountName → UPN
    $managerUpn = $null
    if ($InputObject.Manager) {
        $managerUpn = "{0}@{1}" -f $InputObject.Manager.Trim(), $PrimaryDomain
    }



    [pscustomobject]@{
        Name             = $InputObject.Name
        DisplayName      = $displayName
        PrimarySmtp      = $primarySmtp
        HideFromGAL      = $hide
        Aliases          = $aliases
        Folders          = $folders
        Description      = $InputObject.Description
        Department       = $InputObject.Department
        ManagerUpn       = $managerUpn
        FullAccessUsers  = $faUsers
        SendAsUsers      = $saUsers
        SendOnBehalf     = $sobUsers
        Language         = $DefaultLanguage
        TimeZone         = $DefaultTimeZone
        AutoReplyEnabled = $autoReplyEnabled
    }
}
