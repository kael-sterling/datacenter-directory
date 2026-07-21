<#
.SYNOPSIS
Creates missing Inbox subfolders for a shared mailbox.

.DESCRIPTION
Ensures all folders defined in the CSV exist under the mailbox's Inbox.
Missing folders are created. Existing folders are ignored.

.PARAMETER PrimarySmtp
The primary SMTP address of the mailbox.

.PARAMETER Folders
Array of folder names to ensure exist under Inbox.

.PARAMETER DryRun
If specified, actions are printed but not executed.

.EXAMPLE
Set-MailboxFolders -PrimarySmtp "it@untapped.tech" -Folders @("Alerts","Systems")

.NOTES
Folder drift detection is limited to existence checks.
#>
function Set-MailboxFolders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PrimarySmtp,

        [string[]]$Folders = @(),

        [switch]$DryRun
    )

    Connect-EXO

    foreach ($folder in $Folders) {
        if (-not $folder) { continue }

        $folderPath = "${PrimarySmtp}:\Inbox\$folder"
        $existsFolder = Get-MailboxFolder -Identity $folderPath -ErrorAction SilentlyContinue
        if (-not $existsFolder) {
            if ($DryRun) {
                Write-DryRun ("  + Would create folder: {0}" -f $folder)
            }
            else {
                New-MailboxFolder -Parent "${PrimarySmtp}:\Inbox" -Name $folder -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }
}
