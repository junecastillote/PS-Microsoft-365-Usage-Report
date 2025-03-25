Function Get-TeamsDeviceUsageDistributionDetail {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [int]
        $ReportPeriod = 7,

        [Parameter()]
        [Switch]
        $IncludeNonLicensedUser
    )
    $ProgressPreference = 'SilentlyContinue'

    $uri = "https://graph.microsoft.com/beta/reports/getTeamsDeviceUsageUserCounts(period='D$($ReportPeriod)')"
    if ($IncludeNonLicensedUser) {
        $uri = "https://graph.microsoft.com/beta/reports/getTeamsDeviceUsageTotalUserCounts(period='D$($ReportPeriod)')"
    }

    try {
        $outFile = Get-OutputFileName $uri -ErrorAction Stop
        Invoke-MgGraphRequest -Method Get -Uri $uri -ContentType 'application/json' -ErrorAction Stop -OutputFilePath $outFile
        $result = Get-Content $outFile | ConvertFrom-Csv
        return $result
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}