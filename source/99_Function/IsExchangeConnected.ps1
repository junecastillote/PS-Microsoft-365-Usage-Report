Function IsExchangeConnected {
    [CmdletBinding()]
    param (

    )
    try {
        $null = Get-OrganizationConfig -ErrorAction Stop
        return $true
    }
    catch {
        # "Please connect to Exchange Online PowerShell first."
        return $false
    }
}