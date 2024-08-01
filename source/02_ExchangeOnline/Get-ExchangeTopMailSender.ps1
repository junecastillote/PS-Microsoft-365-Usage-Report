Function Get-ExchangeTopMailSender {
    [CmdletBinding()]
    param (
        [Parameter()]
        [int]
        $ReportPeriod = 7,

        [Parameter()]
        [Int]
        $Top = 10
    )

    if ($ReportPeriod -gt 90) {
        SayInfo 'Maximum mail traffic data history is 90 days.'
        $ReportPeriod = 90
    }

    $now = (Get-Date)
    $startDate = $now.AddDays(-$ReportPeriod)

    try {
        $result = Get-MailTrafficSummaryReport -StartDate $startDate -EndDate $now -Category TopMailSender -ErrorAction Stop |
        Select-Object -First $Top -Property @{n = 'ID'; e = { $_.C1 } }, @{n = 'Message Count'; e = { $_.C2 } }
        return $result
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}