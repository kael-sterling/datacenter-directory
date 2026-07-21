function Connect-EXO {
    [CmdletBinding()]
    param()

    if (-not (Get-Module ExchangeOnlineManagement -ListAvailable)) {
        throw "ExchangeOnlineManagement module not found."
    }

    if (-not (Get-ConnectionInformation)) {
        Connect-ExchangeOnline -Device -ShowBanner:$false | Out-Null
    }
}
