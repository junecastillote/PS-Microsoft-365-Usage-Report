Function Get-ExchangeMailboxProvisioningSummary {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Int]
        $ReportPeriod = 7
    )

    if (!(IsExchangeConnected)) {
        SayError 'Exchange PowerShell is not connected. Connect to Exchange Online PowerShell first and try again.'
        return $null
    }

    $now = (Get-Date)
    $startDate = $now.AddDays(-$ReportPeriod)

    try {
        $deletedMailbox = @(Get-Mailbox -ResultSize Unlimited -SoftDeletedMailbox -Filter "WhenSoftDeleted -ge '$startDate'" -ErrorAction Stop |
            Select-Object UserPrincipalName, WhenSoftDeleted |
            Sort-Object UserPrincipalName)

        $createdMailbox = @(Get-Mailbox -ResultSize Unlimited -Filter "WhenCreated -ge '$startDate'" -ErrorAction Stop |
            Select-Object UserPrincipalName, WhenCreated |
            Sort-Object UserPrincipalName)

        [PSCustomObject]@{
            'Created Mailbox' = $createdMailbox.count
            'Deleted Mailbox' = $deletedMailbox.count
        }
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}