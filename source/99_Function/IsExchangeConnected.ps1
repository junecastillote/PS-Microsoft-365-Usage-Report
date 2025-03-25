Function IsExchangeConnected {
    [CmdletBinding()]
    [OutputType([bool])]
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