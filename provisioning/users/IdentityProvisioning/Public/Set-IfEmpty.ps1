function Set-IfEmpty {
    <#
.SYNOPSIS
Sets one or more AD user attributes only if the existing attribute value is empty.

.DESCRIPTION
Set-IfEmpty provides a controlled way to populate missing Active Directory
attributes without overwriting existing data. It supports two modes:

1. **Single-attribute mode**
   Accepts -AttributeName and -Value, then internally converts them into a
   hashtable.

2. **Multi-attribute mode**
   Accepts a hashtable of attributes via -Attributes.

The function:
- Normalizes both modes into a single hashtable.
- Retrieves all relevant AD properties in a single Get-ADUser call.
- Compares each desired attribute value with the current AD value.
- Applies only those attributes whose current AD value is empty.
- Logs evaluation, decisions, and results using Write-Log.

This function does not sanitize attribute values. Callers should use
ConvertTo-ADAttributeMap before invoking Set-IfEmpty if AD-safe normalization
is required.

.PARAMETER AdUser
The AD user object (Microsoft.ActiveDirectory.Management.ADUser) to modify.

.PARAMETER AttributeName
The name of the attribute to set (single-attribute mode only).

.PARAMETER Value
The value to assign to the attribute (single-attribute mode only).

.PARAMETER Attributes
A hashtable of attribute names and values (multi-attribute mode only).

.EXAMPLE
Set-IfEmpty -AdUser $user -AttributeName "Office" -Value "HQ-2"

.EXAMPLE
$attrs = @{
    Department = "Engineering"
    Office     = "HQ-2"
}
Set-IfEmpty -AdUser $user -Attributes $attrs

.EXAMPLE
# Safely populate missing identity attributes
$clean = ConvertTo-ADAttributeMap -Map $identityMap
Set-IfEmpty -AdUser $user -Attributes $clean

.NOTES
This function is ideal for provisioning pipelines where certain attributes
should only be set once (e.g., Department, Title, Office, Initials). It avoids
accidental overwrites and reduces AD churn.
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
        [string]$Value,

        # Multi-attribute mode
        [Parameter(Mandatory, ParameterSetName = 'Multi')]
        [psobject]$Attributes
    )

    try {
        #
        # Normalize into a single hashtable
        #
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            $Attributes = @{ $AttributeName = $Value }
        }

        Write-Log Debug "Evaluating attributes for Set-IfEmpty" $AdUser.SamAccountName
        Write-Log Debug $Attributes $AdUser.SamAccountName

        #
        # Fetch all needed AD properties in one call (optimization)
        #
        $propsToCheck = $Attributes.PSObject.Properties.Name
        $adState = Get-ADUser -Identity $AdUser -Properties $propsToCheck

        #
        # Build the final set of attributes to apply
        #
        $toApply = @{}

        foreach ($prop in $Attributes.PSObject.Properties) {
            $name = $prop.Name
            $value = $prop.Value

            # Skip empty values
            if (-not $value -or $value -eq '') { continue }

            # Check current AD value
            $current = $adState.$name

            # Only set if empty
            if (-not $current) {
                $toApply[$name] = $value
                Write-Log Verbose "Will set empty attribute '$name'" $AdUser.SamAccountName
            }
        }

        #
        # Apply if anything needs updating
        #
        if ($toApply.Count -gt 0) {
            Write-Log Debug "Applying attributes" $AdUser.SamAccountName
            Write-Log Debug $toApply $AdUser.SamAccountName

            Set-ADUser -Identity $AdUser -Replace $toApply

            Write-Log Info "Attributes applied" $AdUser.SamAccountName
        }
        else {
            Write-Log Verbose "No empty attributes to apply" $AdUser.SamAccountName
        }
    }
    catch {
        Write-Log Error "Failed to apply attributes: $($_.Exception.Message)" $AdUser.SamAccountName
        Write-Log Debug $_ $AdUser.SamAccountName
    }
}
