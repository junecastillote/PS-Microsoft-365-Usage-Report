Function Get-ExchangeATPMailDetectionSummary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [datetime]$StartDate,

        [Parameter(Mandatory)]
        [datetime]$EndDate
    )

    if (!(IsExchangeConnected)) {
        SayError 'Exchange PowerShell is not connected. Connect to Exchange Online PowerShell first and try again.'
        return $null
    }

    try {
        # $atpTrafficReport = Get-ATPTotalTrafficReport -StartDate $startDate -EndDate ($now).AddDays(-1) -AggregateBy Summary -ErrorAction Stop | Select-Object EventType, MessageCount
        $atpTrafficReport = Get-ATPTotalTrafficReport -StartDate $StartDate -EndDate $EndDate -AggregateBy Summary -ErrorAction Stop | Select-Object EventType, MessageCount
        return $(
            [PSCustomObject]@{
                'ATP Safe Links'       = ($atpTrafficReport | Where-Object { $_.EventType -eq 'TotalSafeLinkCount' }).MessageCount
                'ATP Safe Attachments' = ($atpTrafficReport | Where-Object { $_.EventType -eq 'TotalSafeAttachmentCount' }).MessageCount
            }
        )
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}