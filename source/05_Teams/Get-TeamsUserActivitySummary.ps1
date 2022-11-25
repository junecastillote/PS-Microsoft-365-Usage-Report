Function Get-TeamsUserActivitySummary {
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
        $uri = "https://graph.microsoft.com/beta/reports/getTeamsUserActivityTotalDistributionCounts(period='D7')?`$format=text/csv"
        $result = (Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $AccessToken" } -ContentType 'application/json' -ErrorAction Stop)
        $null = $result -match '(.*)Report Refresh Date'
        $result = ($result -replace $Matches[1], '') | ConvertFrom-Csv

        $result | Add-Member -MemberType ScriptProperty -Name 'Audio Duration (Minutes)' -Value {
            [System.Math]::Round((New-TimeSpan -Start ([datetime]$this.'Report Refresh Date') -End ([datetime]$this.'Report Refresh Date').Add($($this.'Audio Duration' -replace 'P', '' -replace 'DT', '.' -replace 'H', ':' -replace 'M', ':' -replace 'S', ''))).TotalMinutes, 2)
        }

        $result | Add-Member -MemberType ScriptProperty -Name 'Video Duration (Minutes)' -Value {
            [System.Math]::Round((New-TimeSpan -Start ([datetime]$this.'Report Refresh Date') -End ([datetime]$this.'Report Refresh Date').Add($($this.'Video Duration' -replace 'P', '' -replace 'DT', '.' -replace 'H', ':' -replace 'M', ':' -replace 'S', ''))).TotalMinutes, 2)
        }

        $result | Add-Member -MemberType ScriptProperty -Name 'Screen Sharing Duration (Minutes)' -Value {
            [System.Math]::Round((New-TimeSpan -Start ([datetime]$this.'Report Refresh Date') -End ([datetime]$this.'Report Refresh Date').Add($($this.'Screen Sharing Duration' -replace 'P', '' -replace 'DT', '.' -replace 'H', ':' -replace 'M', ':' -replace 'S', ''))).TotalMinutes, 2)
        }

        return $result


    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}