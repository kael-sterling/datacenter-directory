# Dot-source public functions
Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 | ForEach-Object {
    . $_.FullName
}

# Dot-source private functions
Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | ForEach-Object {
    . $_.FullName
}
