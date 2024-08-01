Function IsExchangeConnected {
    [CmdletBinding()]
    param (

    )

    if (!(Get-Module ExchangeOnlineManagement -ListAvailable)) {
        return $false
    }

    if (!(Get-ConnectionInformation)) {
        return $false
    }
    else {
        return $true
    }
}