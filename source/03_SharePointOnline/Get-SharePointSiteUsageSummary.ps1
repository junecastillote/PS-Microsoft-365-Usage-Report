Function Get-SharePointSiteUsageSummary {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [int]
        $ReportPeriod = 7
    )
    $ProgressPreference = 'SilentlyContinue'

    $null = Set-M365ReportDate -ReportPeriod $ReportPeriod

    try {
        $uri = "https://graph.microsoft.com/beta/reports/getSharePointSiteUsageDetail(period='D$($ReportPeriod)')"
        $outFile = Get-OutputFileName $uri -ErrorAction Stop
        Invoke-MgGraphRequest -Method Get -Uri $uri -ContentType 'application/json' -ErrorAction Stop -OutputFilePath $outFile
        $result = Get-Content $outFile | ConvertFrom-Csv
        $result | Add-Member -MemberType ScriptProperty -Name LastActivityDate -Value { [datetime]$this."Last Activity Date" }
        [PSCustomObject]@{
            'Report Refresh Date'       = $result[0].'Report Refresh Date'
            'Total SharePoint Sites'    = ($result | Where-Object { $_.'Is Deleted' -eq $false }).Count
            'Active SharePoint Sites'   = ($result | Where-Object { $_.LastActivityDate -ge $Script:GraphStartDate -and $_.'Is Deleted' -eq $false }).Count
            'Inactive SharePoint Sites' = ($result | Where-Object { $_.LastActivityDate -lt $Script:GraphStartDate }).Count
            'Deleted SharePoint Sites'  = ($result | Where-Object { $_.'Is Deleted' -eq $true }).Count
            'Report Period'             = $ReportPeriod
            'Start Date'                = ($Script:GraphStartDate).ToString('yyyy-MM-dd')
            'End Date'                  = ($Script:GraphEndDate).ToString('yyyy-MM-dd')
        }
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}