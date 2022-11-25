Function Get-ExchangeActiveMailboxCount {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [Int]
        $ReportPeriod = 7
    )

    if (!(Get-AccessToken)) {
        SayError 'No access token is found in the session. Run the New-AccessToken command first to acquire an access token.'
        Return $null
    }
	$null = Update-AccessToken
	$AccessToken = (Get-AccessToken).access_token

    try {
        $uri = "https://graph.microsoft.com/beta/reports/getMailboxUsageMailboxCounts(period='D$($ReportPeriod)')"
        $result = ((Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $AccessToken" } -ContentType 'application/json' -ErrorAction Stop))
        $null = $result -match '(.*)Report Refresh Date'
        $result = ($result -replace $Matches[1], '') | ConvertFrom-Csv
        $result | Add-Member -Name 'Inactive' -MemberType ScriptProperty -Value { ([int]($this.Total) - [int]($this.Active)) }
        return $result
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}