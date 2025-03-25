Function Get-ExchangeActiveMailboxCount {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [int]
        $ReportPeriod = 7
    )
    $ProgressPreference = 'SilentlyContinue'

    try {
        $uri = "https://graph.microsoft.com/beta/reports/getMailboxUsageMailboxCounts(period='D$($ReportPeriod)')"
        $outFile = Get-OutputFileName $uri -ErrorAction Stop
        Invoke-MgGraphRequest -Method Get -Uri $uri -ContentType 'application/json' -ErrorAction Stop -OutputFilePath $outFile
        $result = Get-Content $outFile | ConvertFrom-Csv
        $result | Add-Member -Name 'Inactive' -MemberType ScriptProperty -Value { ([int]($this.Total) - [int]($this.Active)) }
        return $result
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}