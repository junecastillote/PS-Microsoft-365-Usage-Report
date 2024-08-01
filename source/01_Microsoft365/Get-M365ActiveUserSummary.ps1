Function Get-M365ActiveUserSummary {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [int]
        $ReportPeriod = 7
    )
    $ProgressPreference = 'SilentlyContinue'

    try {
        $uri = "https://graph.microsoft.com/beta/reports/getOffice365ServicesUserCounts(period='D$($ReportPeriod)')"
        $outFile = Get-OutputFileName $uri -ErrorAction Stop
        Invoke-MgGraphRequest -Method Get -Uri $uri -ContentType 'application/json' -ErrorAction Stop -OutputFilePath $outFile
        Get-Content $outFile | ConvertFrom-Csv
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}