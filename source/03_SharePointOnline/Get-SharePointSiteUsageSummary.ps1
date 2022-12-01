Function Get-SharePointSiteUsageSummary {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [Int]
        $ReportPeriod = 7
    )

    $null = Set-ReportDate -ReportPeriod $ReportPeriod

    if (!(Get-AccessToken)) {
        SayError 'No access token is found in the session. Run the New-AccessToken command first to acquire an access token.'
        Return $null
    }
	$null = Update-AccessToken
	$AccessToken = (Get-AccessToken).access_token

    try {
        $uri = "https://graph.microsoft.com/beta/reports/getSharePointSiteUsageDetail(period='D$($ReportPeriod)')"
        $result = (Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $AccessToken" } -ContentType 'application/json' -ErrorAction Stop)
        $null = $result -match '(.*)Report Refresh Date'
        $result = ($result -replace $Matches[1], '') | ConvertFrom-Csv
        $result | Add-Member -MemberType ScriptProperty -Name LastActivityDate -Value { [datetime]$this."Last Activity Date" }
        [PSCustomObject]@{
            'Report Refresh Date'       = $result[0].'Report Refresh Date'
            'Total SharePoint Sites'    = ($result | Where-Object { $_.'Is Deleted' -eq $false }).Count
            'Active SharePoint Sites'   = ($result | Where-Object { $_.LastActivityDate -ge $Script:GraphStartDate -and $_.'Is Deleted' -eq $false }).Count
            'Inactive SharePoint Sites' = ($result | Where-Object { $_.LastActivityDate -lt $Script:GraphStartDate }).Count
            'Deleted SharePoint Sites'  = ($result | Where-Object { $_.'Is Deleted' -eq $true }).Count
            'Report Period'             = $ReportPeriod
        }
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}