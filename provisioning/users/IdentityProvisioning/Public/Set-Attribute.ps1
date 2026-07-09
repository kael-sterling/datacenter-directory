function Set-Attribute {
    <#
.SYNOPSIS
Applies one or more Active Directory user attributes using Set-ADUser.

.DESCRIPTION
Set-Attribute provides a unified interface for writing identity or
non-identity attributes to an AD user object. It supports two modes:

1. **Single-attribute mode**
   Accepts -AttributeName and -Value, then internally converts them into a
   hashtable.

2. **Multi-attribute mode**
   Accepts a hashtable of attributes via -Attributes.

This function:
- Normalizes both modes into a single hashtable.
- Logs the attribute write operation.
- Calls Set-ADUser -Replace to apply the attributes.
- Logs success or failure using Write-Log.

This function does not validate or sanitize attribute values. Callers should
use ConvertTo-ADAttributeMap before invoking Set-Attribute if AD-safe
normalization is required.

.PARAMETER AdUser
The AD user object (Microsoft.ActiveDirectory.Management.ADUser) to modify.

.PARAMETER AttributeName
The name of the attribute to set (single-attribute mode only).

.PARAMETER Value
The value to assign to the attribute (single-attribute mode only).

.PARAMETER Attributes
A hashtable of attribute names and values (multi-attribute mode only).

.EXAMPLE
Set-Attribute -AdUser $user -AttributeName "Title" -Value "Engineer"

.EXAMPLE
$attrs = @{
    Department = "Engineering"
    Office     = "HQ-2"
}
Set-Attribute -AdUser $user -Attributes $attrs

.NOTES
This function wraps Set-ADUser -Replace and logs all operations. It does not
perform AD-safe cleaning; callers should use ConvertTo-ADAttributeMap when
writing user-provided or pipeline-generated data.
#>
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param(
        # Shared parameter
        [Parameter(Mandatory)]
        [Microsoft.ActiveDirectory.Management.ADUser]$AdUser,

        # Single-attribute mode
        [Parameter(Mandatory, ParameterSetName = 'Single')]
        [string]$AttributeName,

        [Parameter(Mandatory, ParameterSetName = 'Single')]
        [object]$Value,

        # Multi-attribute mode
        [Parameter(Mandatory, ParameterSetName = 'Multi')]
        [hashtable]$Attributes
    )

    try {
        #
        # Normalize into a single hashtable
        #
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            $Attributes = @{ $AttributeName = $Value }
        }

        Write-Log Debug "Applying attributes" $AdUser.SamAccountName
        Write-Log Debug ($Attributes | Out-String) $AdUser.SamAccountName

        #
        # Apply attributes directly
        #
        Set-ADUser -Identity $AdUser -Replace $Attributes

        Write-Log Info "Attributes applied" $AdUser.SamAccountName
    }
    catch {
        Write-Log Error ("Failed to apply attributes: {0}" -f $_.Exception.Message) $AdUser.SamAccountName
        Write-Log Debug $_ $AdUser.SamAccountName
    }
}
