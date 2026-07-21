<#
.SYNOPSIS
Applies automatic reply settings to a shared mailbox.

.DESCRIPTION
Ensures the mailbox's automatic reply configuration matches the values
defined in the CSV. If AutoReplyState is empty, no changes are made.
If AutoReplyState is Disabled and all message fields are empty, the
auto-reply configuration is cleared.

.PARAMETER PrimarySmtp
The primary SMTP address of the mailbox.

.PARAMETER AutoReplyState
Enabled or Disabled. If empty, no changes are applied.

.PARAMETER InternalReply
Internal auto-reply message. May be empty.

.PARAMETER ExternalReply
External auto-reply message. May be empty.

.PARAMETER ExternalAudience
None, Known, or All. May be empty.

.PARAMETER DryRun
If specified, actions are printed but not executed.

.EXAMPLE
Set-MailboxAutoReply -PrimarySmtp "info@untapped.tech" `
    -AutoReplyState Enabled `
    -InternalReply "Thanks for contacting us" `
    -ExternalReply "We received your message" `
    -ExternalAudience All

.EXAMPLE
Set-MailboxAutoReply -PrimarySmtp "info@untapped.tech" `
    -AutoReplyState Disabled `
    -InternalReply "" `
    -ExternalReply "" `
    -ExternalAudience ""

.NOTES
Uses Set-MailboxAutoReplyConfiguration from Exchange Online.
#>
function Set-MailboxAutoReply {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PrimarySmtp,

        [bool]$AutoReplyEnabled,

        [string]$InternalReply,
        [string]$ExternalReply,
        [string]$ExternalAudience,

        [switch]$DryRun
    )

    Connect-EXO

    $allEmpty =
    [string]::IsNullOrWhiteSpace($InternalReply) -and
    [string]::IsNullOrWhiteSpace($ExternalReply) -and
    [string]::IsNullOrWhiteSpace($ExternalAudience)

    #
    # CASE 1 — AutoReplyEnabled = False AND all fields empty → clear configuration
    #
    if ($AutoReplyEnabled -eq $false -and $allEmpty) {
        if ($DryRun) {
            Write-DryRun "  ~ Would clear automatic reply configuration"
        }
        else {
            Set-MailboxAutoReplyConfiguration -Identity $PrimarySmtp `
                -AutoReplyState Disabled `
                -InternalMessage "" `
                -ExternalMessage "" `
                -ExternalAudience None
        }
        return
    }

    #
    # CASE 2 — AutoReplyEnabled = False → disable auto-reply but preserve messages if provided
    #
    if ($AutoReplyEnabled -eq $false) {
        if ($DryRun) {
            Write-DryRun "  ~ Would disable automatic replies"
        }
        else {
            Set-MailboxAutoReplyConfiguration -Identity $PrimarySmtp `
                -AutoReplyState Disabled `
                -InternalMessage ($InternalReply ? $InternalReply : "") `
                -ExternalMessage ($ExternalReply ? $ExternalReply : "") `
                -ExternalAudience ($ExternalAudience ? $ExternalAudience : "None")
        }
        return
    }

    #
    # CASE 3 — AutoReplyEnabled = True → enable auto-reply
    #
    if ($DryRun) {
        Write-DryRun "  ~ Would enable automatic replies"
    }
    else {
        Set-MailboxAutoReplyConfiguration -Identity $PrimarySmtp `
            -AutoReplyState Enabled `
            -InternalMessage $InternalReply `
            -ExternalMessage $ExternalReply `
            -ExternalAudience ($ExternalAudience ? $ExternalAudience : "None")
    }
}
