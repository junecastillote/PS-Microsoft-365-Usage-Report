Function Get-TeamsUserActivitySummary {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [int]
        $ReportPeriod = 7
    )

    $ProgressPreference = 'SilentlyContinue'
    $uri = "https://graph.microsoft.com/beta/reports/getTeamsUserActivityTotalDistributionCounts(period='D7')?`$format=text/csv"

    try {
        $outFile = Get-OutputFileName $uri -ErrorAction Stop
        Invoke-MgGraphRequest -Method Get -Uri $uri -ContentType 'application/json' -ErrorAction Stop -OutputFilePath $outFile
        $result = Get-Content $outFile | ConvertFrom-Csv

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