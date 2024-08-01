Function Get-OneDriveAccountUsageSummary {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [int]
        $ReportPeriod = 7
    )
    $ProgressPreference = 'SilentlyContinue'

    $null = Set-M365ReportDate -ReportPeriod $ReportPeriod

    $uri = "https://graph.microsoft.com/beta/reports/getOneDriveUsageAccountDetail(period='D$($ReportPeriod)')"
    try {
        $outFile = Get-OutputFileName $uri -ErrorAction Stop
        Invoke-MgGraphRequest -Method Get -Uri $uri -ContentType 'application/json' -ErrorAction Stop -OutputFilePath $outFile
        $result = Get-Content $outFile | ConvertFrom-Csv
        $result | Add-Member -MemberType ScriptProperty -Name LastActivityDate -Value { [datetime]$this."Last Activity Date" }
        [PSCustomObject]@{
            'Report Refresh Date'     = $result[0].'Report Refresh Date'
            'Total OneDrive Sites'    = ($result | Where-Object { $_.'Is Deleted' -eq $false }).Count
            'Deleted OneDrive Sites'  = ($result | Where-Object { $_.'Is Deleted' -eq $true }).Count
            'Inactive OneDrive Sites' = ($result | Where-Object { $_.LastActivityDate -lt $Script:GraphStartDate }).Count
            'Active OneDrive Sites'   = ($result | Where-Object { $_.LastActivityDate -ge $Script:GraphStartDate -and $_.'Is Deleted' -eq $false }).Count
            'Report Period'           = $ReportPeriod
        }
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}