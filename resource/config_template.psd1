@{

    # ReportPeriod: Indicate the reporting period.
    # Valid values are: 7, 30, 90, 180
    ReportPeriod       = 7

    # Scope: Indicate which Office 365 workload will be included.
    # Leave empty to include all workload.
    # Valid values are:
    # -- 'Microsoft365'
    # -- 'Exchange'
    # -- 'DefenderATP'
    # -- 'SharePoint'
    # -- 'OneDrive'
    # -- 'Teams'
    Scope              = @()

    # Exclude: Indicate which workload subitems will be excluded.
    # Leave empty to include all workload subitems.
    # Accepted values are:
    # -- 'Microsoft365AssignedLicenses'
    # -- 'Microsoft365ActiveUsers'
    # -- 'Microsoft365ProductActivation'
    # -- 'Microsoft365Groups
    # -- 'ExchangeMailboxUsageAndProvisioning'
    # -- 'ExchangeClientAppUsage'
    # -- 'ExchangeMailFlow'
    # -- 'ExchangeTop10MailTraffic'
    # -- 'DefenderATPDetections'
    # -- 'SharePointUsageAndStorage'
    # -- 'OneDriveUsageAndStorage'
    # -- 'TeamsUsers'
    # -- 'TeamsUsersActivities'
    # -- 'TeamsDevices'
    Exclude            = @()

    # Set this value to:
    # -- $true (enable email report)
    # -- $false (disable email report)
    SendEmail          = $false

    # Indicate the sender email address. This must be a valid mailbox.
    # Required when [SendEmail = $True]
    From               = ''

    # Specify the TO, Cc, Bcc recipients are needed.
    # At least one recipient is required when [SendEmail = $True]
    To                 = @()
    Cc                 = @()
    Bcc                = @()

    # CustomEmailSubject: Specify a custom email subject.
    # Leave empty to use the default email subject
    CustomEmailSubject = ''

    # Set value to:
    # -- $true (Enable opening the HTML report automatically)
    # -- $false (Disable opening the HTML report automatically)
    ShowReport         = $true
}