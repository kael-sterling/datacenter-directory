function ConvertTo-ADAttributeMap {
    <#
.SYNOPSIS
Validates and cleans an attribute hashtable for safe use with Set-ADUser.

.DESCRIPTION
ConvertTo-ADAttributeMap performs two operations:

1. Validates required attributes:
   Ensures all attributes listed in -RequiredAttributes exist in the map and
   contain non-empty, non-null, non-whitespace values. Missing required
   attributes cause the function to throw.

2. Removes AD-unsafe values:
   Active Directory cannot store empty strings, nulls, or whitespace-only
   values. These entries are removed from the map, producing a cleaned
   hashtable safe for Set-ADUser -Replace or -Add.

.PARAMETER Map
The hashtable containing attribute names and values to validate and clean.

.PARAMETER RequiredAttributes
A list of attribute names that must be present and contain non-empty values.

.PARAMETER Context
Optional string used for diagnostic output (e.g., SamAccountName).

.OUTPUTS
[hashtable]
Returns a cleaned, AD-safe hashtable.

.EXAMPLE
$map = @{
    GivenName = "Kael"
    SN        = "Sterling"
    Title     = "CEO"
    Department = ""
}

$required = @("GivenName","SN","Department","Title")

ConvertTo-ADAttributeMap -Map $map -RequiredAttributes $required -Context "Kael"

# Throws:
# Missing required attributes for Kael: Department

.EXAMPLE
$map = @{
    StreetAddress = "123 Main St"
    PostOfficeBox = ""
    l             = "New York"
    ST            = "NY"
    PostalCode    = ""
}

ConvertTo-ADAttributeMap -Map $map

# Returns:
# @{
#   StreetAddress = "123 Main St"
#   l             = "New York"
#   ST            = "NY"
# }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Map,

        [Parameter()]
        [string[]]$RequiredAttributes = @(),

        [Parameter()]
        [string]$Context = "Unknown"
    )

    # Validate required attributes
    $missing = @()

    foreach ($attr in $RequiredAttributes) {
        if (-not $Map.ContainsKey($attr) -or
            -not $Map[$attr] -or
            $Map[$attr].ToString().Trim().Length -eq 0) {

            $missing += $attr
        }
    }

    if ($missing.Count -gt 0) {
        Write-Log Error ("Missing required attributes for {0}: {1}" -f $Context, ($missing -join ', '))
        throw ("Missing required attributes: {0}" -f ($missing -join ', '))
    }


    # Build cleaned map
    $clean = @{}

    foreach ($kv in $Map.GetEnumerator()) {
        $value = $kv.Value

        if ($value -is [string]) {
            if ($value.Trim().Length -gt 0) {
                $clean[$kv.Key] = $value
            }
        }
        elseif ($value) {
            $clean[$kv.Key] = $value
        }
    }

    return $clean
}
