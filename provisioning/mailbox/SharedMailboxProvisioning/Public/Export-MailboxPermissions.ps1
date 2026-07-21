function Export-MailboxPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PrimarySmtp,
        [Parameter(Mandatory)]
        [string]$Path
    )

    Connect-EXO

    $fa = Get-MailboxPermission -Identity $PrimarySmtp -ErrorAction SilentlyContinue |
    Where-Object { $_.User -notmatch 'NT AUTHORITY|S-1-5-' } |
    Select-Object -ExpandProperty User

    $sa = Get-RecipientPermission -Identity $PrimarySmtp -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Trustee

    $obj = [pscustomobject]@{
        PrimarySmtp     = $PrimarySmtp
        FullAccessUsers = ($fa -join ';')
        SendAsUsers     = ($sa -join ';')
    }

    $obj | Export-Csv -Path $Path -NoTypeInformation
}
