function Expand-Aliases {
    param(
        [string[]]$AliasNames,
        [string]$PrimaryDomain,
        [string[]]$AliasDomains
    )

    $expanded = foreach ($name in $AliasNames) {
        foreach ($domain in $AliasDomains) {
            "{0}@{1}" -f $name.ToLower(), $domain.ToLower()
        }
    }

    return $expanded
}
