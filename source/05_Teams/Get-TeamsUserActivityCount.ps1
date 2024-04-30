Function Get-TeamsUserActivityCount {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [Int]
        $ReportPeriod = 7,

        [Parameter()]
        [Switch]
        $IncludeNonLicensedUser,

        [Parameter()]
        [Switch]
        $Daily
    )

    # $baseTime = ([datetime]$this.'Report Refresh Date')

    if (!(Get-AccessToken)) {
        SayError 'No access token is found in the session. Run the New-AccessToken command first to acquire an access token.'
        Return $null
    }
	$null = Update-AccessToken
	$AccessToken = (Get-AccessToken).access_token

    try {
        $uri = "https://graph.microsoft.com/beta/reports/getTeamsUserActivityCounts(period='D$($ReportPeriod)')"
        if ($IncludeNonLicensedUser) {
            $uri = "https://graph.microsoft.com/beta/reports/getTeamsUserActivityTotalCounts(period='D$($ReportPeriod)')"
        }
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
            [System.Math]::Round((New-TimeSpan -Start ([datetime]$this.'Report Refresh Date') -End ([datetime]$this.'Report Refresh Date').Add($($this.'Screen Share Duration' -replace 'P', '' -replace 'DT', '.' -replace 'H', ':' -replace 'M', ':' -replace 'S', ''))).TotalMinutes, 2)
        }

        if ($Daily) {
            return $result
        }
        else {
            [PSCustomObject]@{
                'Report Refresh Date'               = $result[0].'Report Refresh Date'
                'Report Period'                     = $result[0].'Report Period'
                'Team Chat Messages'                = ($result | Measure-Object 'Team Chat Messages' -Sum).Sum
                'Private Chat Messages'             = ($result | Measure-Object 'Private Chat Messages' -Sum).Sum
                'Calls'                             = ($result | Measure-Object 'Calls' -Sum).Sum
                'Meetings'                          = ($result | Measure-Object 'Meetings' -Sum).Sum
                'Meetings Organized Count'          = ($result | Measure-Object 'Meetings Organized Count' -Sum).Sum
                'Meetings Attended Count'           = ($result | Measure-Object 'Meetings Attended Count' -Sum).Sum
                'Post Messages'                     = ($result | Measure-Object 'Post Messages' -Sum).Sum
                'Reply Messages'                    = ($result | Measure-Object 'Reply Messages' -Sum).Sum
                'Audio Duration (Minutes)'          = ($result | Measure-Object 'Audio Duration (Minutes)' -Sum).Sum
                'Video Duration (Minutes)'          = ($result | Measure-Object 'Video Duration (Minutes)' -Sum).Sum
                'Screen Sharing Duration (Minutes)' = ($result | Measure-Object 'Screen Sharing Duration (Minutes)' -Sum).Sum
            }
        }
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}