Function Get-OneDriveTenantStorageUsage {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [int]
        $ReportPeriod = 7
    )

    $ProgressPreference = 'SilentlyContinue'

    $uri = "https://graph.microsoft.com/beta/reports/getOneDriveUsageStorage(period='D$($ReportPeriod)')"
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