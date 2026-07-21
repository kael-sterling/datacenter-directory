function Split-SemicolonList {
    [CmdletBinding()]
    param(
        [string]$Value
    )

    if (-not $Value) {
        return @()
    }

    return $Value.Split(';') |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ }
}
