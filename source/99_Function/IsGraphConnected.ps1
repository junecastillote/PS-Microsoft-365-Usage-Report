Function IsGraphConnected {
    [CmdletBinding()]
    [OutputType([bool])]
    param (

    )

    if (!(Get-Module Microsoft.Graph -ListAvailable)) {
        return $false
    }

    if (!(Get-Module Microsoft.Graph.Authentication)) {
        return $false
    }

    if (Get-MgContext) {
        return $true
    }
    else {
        return $false
    }
}