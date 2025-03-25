Function Get-ExchangeMailFlowStatus {
    [CmdletBinding()]
    param (
        [Parameter()]
        [int]
        $ReportPeriod = 7,

        [Parameter()]
        [switch]
        $Summary
    )

    if (!(IsExchangeConnected)) {
        SayError 'Exchange PowerShell is not connected. Connect to Exchange Online PowerShell first and try again.'
        return $null
    }

    if ($ReportPeriod -gt 90) {
        SayInfo 'Maximum mail flow data history is 90 days.'
        $ReportPeriod = 90
    }

    $now = (Get-Date)
    $startDate = $now.AddDays(-$ReportPeriod)

    try {
        $mailTrafficData = Get-MailFlowStatusReport -StartDate $startDate.ToUniversalTime() -EndDate $now.ToUniversalTime() -Direction Inbound, Outbound -ErrorAction Stop

        if ($Summary) {
            return $(
                [PSCustomObject][ordered]@{
                    'Total Messages'             = ($mailTrafficData | Measure-Object MessageCount -Sum).Sum
                    'Inbound'                    = ($mailTrafficData | Where-Object { $_.Direction -eq "Inbound" } | Measure-Object MessageCount -Sum).Sum
                    'Outbound'                   = ($mailTrafficData | Where-Object { $_.Direction -eq "Outbound" } | Measure-Object MessageCount -Sum).Sum
                    'Blocked by Edge Protection' = ($mailTrafficData | Where-Object { $_.EventType -eq "EdgeBlockSpam" } | Measure-Object MessageCount -Sum).Sum
                    'Malware Email'              = ($mailTrafficData | Where-Object { $_.EventType -eq "EmailMalware" } | Measure-Object MessageCount -Sum).Sum
                    'Spam Email'                 = ($mailTrafficData | Where-Object { $_.EventType -eq "SpamDetections" } | Measure-Object MessageCount -Sum).Sum
                    'Phishing Email'             = ($mailTrafficData | Where-Object { $_.EventType -eq "EmailPhish" } | Measure-Object MessageCount -Sum).Sum
                    'Good Mail'                  = ($mailTrafficData | Where-Object { $_.EventType -eq "GoodMail" } | Measure-Object MessageCount -Sum).Sum
                    'Triggered Transport Rules'  = ($mailTrafficData | Where-Object { $_.EventType -eq "TransportRules" } | Measure-Object MessageCount -Sum).Sum
                }
            )
        }
        else {
            return $mailTrafficData
        }

    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}