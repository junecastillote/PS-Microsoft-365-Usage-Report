Function Get-M365AppActivationSummary {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$AccessToken
    )

    if (!(Get-AccessToken)) {
        SayError 'No access token is found in the session. Run the New-AccessToken command first to acquire an access token.'
        Return $null
    }
	$null = Update-AccessToken
	$AccessToken = (Get-AccessToken).access_token

    try {
        $uri = "https://graph.microsoft.com/beta/reports/getOffice365ActivationsUserCounts"
        $result = (Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $AccessToken" } -ContentType 'application/json' -ErrorAction Stop)
        $null = $result -match '(.*)Report Refresh Date'
        $result = ($result -replace $Matches[1], '') | ConvertFrom-Csv

        for ($i=0;$i -lt ($result.count);$i++) {
            # Convert Product Type value to Title Case
            $result[$i].'Product Type' = ([cultureinfo]::CurrentCulture).TextInfo.ToTitleCase(($($result[$i].'Product Type')).ToLower())
        }
        return $result
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}