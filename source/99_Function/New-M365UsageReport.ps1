Function New-M365UsageReport {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [Int]
        $ReportPeriod = 7,

        [Parameter()]
        [ValidateSet(
            'Microsoft365',
            'Exchange',
            'DefenderATP',
            'SharePoint',
            'OneDrive',
            'Teams'
        )]
        [string[]]
        $Scope = @(
            'Microsoft365',
            'Exchange',
            'DefenderATP',
            'SharePoint',
            'OneDrive',
            'Teams'
        ),

        [Parameter()]
        [ValidateSet(
            'Microsoft365AssignedLicenses',
            'Microsoft365ActiveUsers',
            'Microsoft365ProductActivation',
            'Microsoft365Groups',
            'ExchangeMailboxUsageAndProvisioning',
            'ExchangeClientAppUsage',
            'ExchangeMailFlow',
            'ExchangeTop10MailTraffic',
            'DefenderATPDetections',
            'SharePointUsageAndStorage',
            'OneDriveUsageAndStorage',
            'TeamsUsers',
            'TeamsUsersActivities',
            'TeamsDevices'
        )]
        [string[]]
        $Exclude,

        [Parameter()]
        [switch]
        $SendEmail,

        [Parameter()]
        [string[]]
        $From,

        [Parameter()]
        [string[]]
        $To,

        [Parameter()]
        [string[]]
        $Cc,

        [Parameter()]
        [string[]]
        $Bcc
    )

    if (!$(Get-AccessToken)) {
        SayError 'No access token is found in the session. Run the New-AccessToken command first to acquire an access token.'
        Return $null
    }

    $apiPermissions = ((Get-AccessToken).access_token | Get-JWTDetails).Roles
    if (
        $apiPermissions -notcontains 'Directory.Read.All' -or `
            $apiPermissions -notcontains 'Mail.Send' -or `
            $apiPermissions -notcontains 'Reports.Read.All'
    ) {
        SayError 'The access token must include the following permissions: {Directory.Read.All, Mail.Send, Reports.Read.All}'
        Return $null
    }

    # Refresh the token if it is expired.
    $null = Update-AccessToken

    if ($IncludeReport -contains 'Exchange' -and $IncludeReport -contains 'DefenderATP') {
        if (!(IsExchangeConnected)) {
            SayError 'Exchange PowerShell is not connected. Connect to Exchange Online PowerShell first and try again.'
            return $null
        }
    }

    $AccessToken = $GraphApiToken.access_token

    $null = Set-ReportDate -ReportPeriod $ReportPeriod

    $reportFolder = $($env:TEMP)

    $uri = "https://graph.microsoft.com/beta/organization`?`$select=displayname"
    $organizationName = (Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $AccessToken" }).Value.displayname

    $thisModule = $MyInvocation.MyCommand.Module
    $moduleBase = $thisModule.ModuleBase.ToString()
    $resourceFolder = "$($moduleBase)\resource"
    $logoFile = "$($resourceFolder)\logo.png"
    $officeIconFile = "$($resourceFolder)\office.png"
    $exchangeIconFile = "$($resourceFolder)\exchange.png"
    $sharepointIconFile = "$($resourceFolder)\sharepoint.png"
    $onedriveIconFile = "$($resourceFolder)\onedrive.png"
    # $skypeIconFile = "$($resourceFolder)\skype.png"
    $teamsIconFile = "$($resourceFolder)\teams.png"
    $settingsIconFile = "$($resourceFolder)\settings.png"
    $defenderIconFile = "$($resourceFolder)\defender.png"
    $css = $(Get-Content "$($resourceFolder)\style.css" -Raw)

    $mailSubject = "[$($organizationName)] Microsoft 365 Usage Report ($ReportPeriod days)"
    $html = '<html><head><title>' + $($mailSubject) + '</title>'
    $html += '<style type="text/css">'
    $html += $css
    $html += '</style>'
    $html += '</head><body>'
    $html += '<table id="mainTable">'
    if ($showLogo) {
        $html += '<tr><td class="placeholder"><img src="' + $logoFile + '"></td>'
    }
    $html += '<td class="vl"></td>'
    $html += '<td class="title">' + $organizationName + '<br>' + 'Microsoft 365 Usage Report' + '<br>' + ("{0:MMMM dd, yyyy}" -f $Script:GraphStartDate ) + " to " + ("{0:MMMM dd, yyyy}" -f $Script:GraphEndDate) + '</td></tr>'
    $html += '<tr><td class="placeholder" colspan="3"></td></tr>'
    $html += '</table>'

    #==============================================
    # Licenses Assigned Report
    #==============================================
    if ($Scope -contains 'Microsoft365' -and $Exclude -notcontains 'Microsoft365AssignedLicenses') {
        SayInfo "Microsoft 365 Report: Users and Licenses"
        $raw = Get-M365UserLicenseSummary -ReportPeriod $ReportPeriod
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $officeIconFile + '"></th><th class="section">Users and Assigned Licenses</th></tr></table><table id="mainTable">'
        $html += '<tr><th>Total Users</th><td>' + ("{0:N0}" -f $raw.'Total Users') + '</td></tr>'
        $html += '<tr><th>With License</th><td>' + ("{0:N0}" -f $raw.'With License') + '</td></tr>'
        $html += '<tr><th>Without License</th><td>' + ("{0:N0}" -f $raw.'Without License') + '</td></tr>'
        $html += '<tr><th>Has Exchange License</th><td>' + ("{0:N0}" -f $raw.'Has Exchange License') + '</td></tr>'
        $html += '<tr><th>Has Sharepoint License</th><td>' + ("{0:N0}" -f $raw.'Has Sharepoint License') + '</td></tr>'
        $html += '<tr><th>Has OneDrive License</th><td>' + ("{0:N0}" -f $raw.'Has OneDrive License') + '</td></tr>'
        $html += '<tr><th>Has Teams License</th><td>' + ("{0:N0}" -f $raw.'Has Teams License') + '</td></tr>'
        $html += '<tr><th>Has Yammer License</th><td>' + ("{0:N0}" -f $raw.'Has Yammer License') + '</td></tr>'
        $html += '<tr><td class="placeholder"> </td></tr>'
        $html += '</table>'
    }

    #==============================================
    # MS365 Activations Users Count Report
    #==============================================

    if ($Scope -contains 'Microsoft365' -and $Exclude -notcontains 'Microsoft365ProductActivation') {
        SayInfo "Microsoft 365 Report: Microsoft 365 App Activations"
        $raw = Get-M365AppActivationSummary

        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $officeIconFile + '"></th><th class="section">Product Activations</th></tr></table><table id="mainTable">'
        $html += '<tr><th>Product Type</th><th>Assigned</th><th>Activated</th><th>Shared Computer Activation</th></tr>'

        foreach ($detail in $raw) {
            $html += '<tr><th>' + ($detail."product Type") + '</th>
        <td>' + ("{0:N0}" -f [int]$detail.assigned) + '</td>
        <td>' + ("{0:N0}" -f [int]$detail.activated) + '</td>
        <td>' + ("{0:N0}" -f [int]$detail."shared Computer Activation") + '</td>
        </tr>'
        }
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    #==============================================
    # MS365 Active Users Count Report
    #==============================================

    if ($Scope -contains 'Microsoft365' -and $Exclude -notcontains 'Microsoft365ActiveUsers') {
        SayInfo "Microsoft 365 Report: Active Users Per Service"
        $raw = Get-M365ActiveUserSummary -ReportPeriod $ReportPeriod
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $officeIconFile + '"></th><th class="section">Active Users</th></tr></table><table id="mainTable">'
        $html += '<tr><th>Service</th><th>Active</th><th>Inactive</th></tr>'
        $html += '<tr><th>Office 365</th><td>' + ("{0:N0}" -f [int]$raw.'Office 365 Active') + '</td><td>' + ("{0:N0}" -f [int]$raw.'Office 365 Inactive') + '</td></tr>'
        $html += '<tr><th>Exchange</th><td>' + ("{0:N0}" -f [int]$raw.'Exchange Active') + '</td><td>' + ("{0:N0}" -f [int]$raw.'Exchange Inactive') + '</td></tr>'
        $html += '<tr><th>OneDrive</th><td>' + ("{0:N0}" -f [int]$raw.'OneDrive Active') + '</td><td>' + ("{0:N0}" -f [int]$raw.'OneDrive Inactive') + '</td></tr>'
        $html += '<tr><th>Sharepoint</th><td>' + ("{0:N0}" -f [int]$raw.'SharePoint Active') + '</td><td>' + ("{0:N0}" -f [int]$raw.'SharePoint Inactive') + '</td></tr>'
        $html += '<tr><th>Teams</th><td>' + ("{0:N0}" -f [int]$raw.'Teams Active') + '</td><td>' + ("{0:N0}" -f [int]$raw.'Teams Inactive') + '</td></tr>'
        $html += '<tr><th>Yammer</th><td>' + ("{0:N0}" -f [int]$raw.'Yammer Active') + '</td><td>' + ("{0:N0}" -f [int]$raw.'Yammer Inactive') + '</td></tr>'
        $html += '<tr><td class="placeholder"> </td></tr>'
        $html += '</table>'
    }

    #==============================================
    # MS365 Groups Report
    #==============================================

    if ($Scope -contains 'Microsoft365' -and $Exclude -notcontains 'Microsoft365Groups') {
        SayInfo "Microsoft 365 Report: Microsoft 365 Groups Provisioning"
        $raw = Get-M365GroupProvisioningSummary -ReportPeriod $ReportPeriod

        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $officeIconFile + '"></th><th class="section">Microsoft 365 Groups Provisioning</th></tr></table><table id="mainTable">'
        $html += '<tr><th>Current Groups</th><td>' + ("{0:N0}" -f $raw.Current) + '</td></tr>'
        $html += '<tr><th>Created Groups</th><td>' + ("{0:N0}" -f $raw.Created) + '</td></tr>'
        $html += '<tr><th>Delete Group</th><td>' + ("{0:N0}" -f $raw.Deleted) + '</td></tr>'
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    #==============================================
    # Exchange Mailbox Usage and Provisioning Report
    #==============================================
    if ($Scope -contains 'Exchange' -and $Exclude -notcontains 'ExchangeMailboxUsageAndProvisioning') {
        SayInfo "Exchange Online Report: Mailbox Active Status"
        $ExchangeMailboxUsageDetail = Get-ExchangeMailboxUsageDetail -ReportPeriod $ReportPeriod

        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $exchangeIconFile + '"></th><th class="section">Mailbox Status</th></tr></table><table id="mainTable">'
        $html += '<tr><th>Active Mailbox</th><td>' + ("{0:N0}" -f ($ExchangeMailboxUsageDetail | Where-Object { $_.'Active Status' -eq 'Active' }).Count) + '</td></tr>'
        $html += '<tr><th>Inactive Mailbox</th><td>' + ("{0:N0}" -f ($ExchangeMailboxUsageDetail | Where-Object { $_.'Active Status' -eq 'Inactive' }).Count) + '</td></tr>'
        $html += '</table>'

        SayInfo "Exchange Online Report: Mailbox Provisioning"
        $ExchangeMailboxProvisioningSummary = Get-ExchangeMailboxProvisioningSummary -ReportPeriod $ReportPeriod
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $exchangeIconFile + '"></th><th class="section">Mailbox Provisioning</th></tr></table><table id="mainTable">'
        $html += '<tr><th>Created Mailbox</th><td>' + ("{0:N0}" -f $ExchangeMailboxProvisioningSummary.'Created Mailbox') + '</td></tr>'
        $html += '<tr><th>Deleted Mailbox</th><td>' + ("{0:N0}" -f $ExchangeMailboxProvisioningSummary.'Deleted Mailbox') + '</td></tr>'
        $html += '<tr><td class="placeholder"> </td></tr></table>'

        SayInfo "Exchange Online Report: Mailbox Quota and Tenant Storage"
        $ExchangeMailboxQuotaSummary = (Get-ExchangeMailboxQuotaSummary -ReportPeriod $ReportPeriod)[0]
        $exoStorage = ((Get-ExchangeTenantStorageUsage -ReportPeriod $ReportPeriod)[0])
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $exchangeIconFile + '"></th><th class="section">Mailbox Storage Usage</th></tr></table><table id="mainTable">'
        $html += '<tr><th>Storage Used (TB)</th><td>' + ("{0:N2}" -f (($exoStorage.'Storage Used (Byte)') / 1TB)) + '</td></tr>'
        $html += '<tr><th>Under 25%</th><td>' + ("{0:N0}" -f ($ExchangeMailboxUsageDetail | Where-Object { $_.'Percent Used' -LT 25 }).Count) + '</td></tr>'
        $html += '<tr><th>Under Limit</th><td>' + ("{0:N0}" -f $ExchangeMailboxQuotaSummary.'under Limit') + '</td></tr>'
        $html += '<tr><th>Warning Issued</th><td>' + ("{0:N0}" -f $ExchangeMailboxQuotaSummary.'Warning Issued') + '</td></tr>'
        $html += '<tr><th>Send Prohibited</th><td>' + ("{0:N0}" -f $ExchangeMailboxQuotaSummary.'Send Prohibited') + '</td></tr>'
        $html += '<tr><th>Send/Receive Prohibited</th><td>' + ("{0:N0}" -f $ExchangeMailboxQuotaSummary.'Send/Receive Prohibited') + '</td></tr>'
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    #==============================================
    # Exchange Email App Report
    #==============================================
    if ($Scope -contains 'Exchange' -and $Exclude -notcontains 'ExchangeClientAppUsage') {
        SayInfo "Exchange Online Report: Email Apps"
        $raw = Get-ExchangeEmailAppUsageSummary -ReportPeriod $ReportPeriod | Select-Object * -ExcludeProperty Report*

        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $exchangeIconFile + '"></th><th class="section">Email Apps Usage</th></tr></table><table id="mainTable">'

        foreach ($item in ($raw.psobject.properties | Sort-Object Name)) {
            $html += '<tr><th>' + $item.Name + '</th><td>' + ("{0:N0}" -f [int]($item.Value)) + '</td></tr>'
        }
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    #==============================================
    # Exchange Email Flow Report
    #==============================================
    if ($Scope -contains 'Exchange' -and $Exclude -notcontains 'ExchangeMailFlow') {
        SayInfo "Exchange Online Report: Mail Flow"
        $raw = Get-ExchangeMailFlowStatus -ReportPeriod $ReportPeriod -Summary

        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $exchangeIconFile + '"></th><th class="section">Mail Flow Summary</th></tr></table><table id="mainTable">'

        foreach ($item in ($raw.psobject.properties)) {
            $html += '<tr><th>' + $item.Name + '</th><td>' + ("{0:N0}" -f [int]($item.Value)) + '</td></tr>'
        }
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    #==============================================
    # Exchange Top 10 Mail Traffic Report
    #==============================================
    if ($Scope -contains 'Exchange' -and $Exclude -notcontains 'ExchangeTop10MailTraffic') {

        # Top 10 Mail Recipients
        SayInfo "Exchange Online Report: Top 10 Mail Recipients"
        $raw = Get-ExchangeTopMailRecipient -ReportPeriod $ReportPeriod
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $exchangeIconFile + '"></th><th class="section">Top 10 Email Recipients</th></tr></table><table id="mainTable">'
        $html += '<tr><th>ID</th><th>Message Count</th></tr>'
        foreach ($item in $raw) {
            $html += '<tr><th>' + $item.Id + '</th><td>' + ("{0:N0}" -f [int]($item.'Message Count')) + '</td></tr>'
        }
        $html += '<tr><td class="placeholder"> </td></tr></table>'

        # Top 10 Mail Senders
        SayInfo "Exchange Online Report: Top 10 Mail Senders"
        $raw = Get-ExchangeTopMailSender -ReportPeriod $ReportPeriod
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $exchangeIconFile + '"></th><th class="section">Top 10 Email Senders</th></tr></table><table id="mainTable">'
        $html += '<tr><th>ID</th><th>Message Count</th></tr>'
        foreach ($item in $raw) {
            $html += '<tr><th>' + $item.Id + '</th><td>' + ("{0:N0}" -f [int]($item.'Message Count')) + '</td></tr>'
        }
        $html += '<tr><td class="placeholder"> </td></tr></table>'

        # Top 10 Spam Recipients
        SayInfo "Exchange Online Report: Top 10 Spam Recipients"
        $raw = Get-ExchangeTopSpamRecipient -ReportPeriod $ReportPeriod
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $exchangeIconFile + '"></th><th class="section">Top 10 Spam Recipients</th></tr></table><table id="mainTable">'
        $html += '<tr><th>ID</th><th>Message Count</th></tr>'
        foreach ($item in $raw) {
            $html += '<tr><th>' + $item.Id + '</th><td>' + ("{0:N0}" -f [int]($item.'Message Count')) + '</td></tr>'
        }
        $html += '<tr><td class="placeholder"> </td></tr></table>'

        # Top 10 Malware Recipients
        SayInfo "Exchange Online Report: Top 10 Malware Recipients"
        $raw = Get-ExchangeTopMalwareRecipient -ReportPeriod $ReportPeriod
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $exchangeIconFile + '"></th><th class="section">Top 10 Malware Recipients</th></tr></table><table id="mainTable">'
        $html += '<tr><th>ID</th><th>Message Count</th></tr>'
        foreach ($item in $raw) {
            $html += '<tr><th>' + $item.Id + '</th><td>' + ("{0:N0}" -f [int]($item.'Message Count')) + '</td></tr>'
        }
        $html += '<tr><td class="placeholder"> </td></tr></table>'

        # Top 10 Malware Types
        SayInfo "Exchange Online Report: Top 10 Malware Types"
        $raw = Get-ExchangeTopMalwareDetected -ReportPeriod $ReportPeriod
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $exchangeIconFile + '"></th><th class="section">Top 10 Malware Types</th></tr></table><table id="mainTable">'
        $html += '<tr><th>ID</th><th>Message Count</th></tr>'
        foreach ($item in $raw) {
            $html += '<tr><th>' + $item.Id + '</th><td>' + ("{0:N0}" -f [int]($item.'Message Count')) + '</td></tr>'
        }
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    #==============================================
    # Defender ATP Detections Report
    #==============================================
    if ($Scope -contains 'DefenderATP' -and $Exclude -notcontains 'DefenderATPDetections') {
        SayInfo "Defender ATP Report: SafeLinks and SafeAttachments"
        $raw = Get-ExchangeATPMailDetectionSummary -StartDate $Script:GraphStartDate -EndDate $Script:GraphEndDate
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $defenderIconFile + '"></th><th class="section">Defender ATP Email Detection</th></tr></table><table id="mainTable">'
        foreach ($item in ($raw.psobject.properties)) {
            $html += '<tr><th>' + $item.Name + '</th><td>' + ("{0:N0}" -f [int]($item.Value)) + '</td></tr>'
        }
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    #==============================================
    # Sharepoint Report
    #==============================================
    if ($Scope -contains 'SharePoint' -and $Exclude -notcontains 'SharePointUsageAndStorage') {
        SayInfo "SharePoint Online Report: Sites and Storage"
        $raw = Get-SharePointSiteUsageSummary -ReportPeriod $ReportPeriod | Select-Object * -ExcludeProperty Report*
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $sharepointIconFile + '"></th><th class="section">Sharepoint Sites and Storage</th></tr></table><table id="mainTable">'
        $html += '<tr><th>Storage Used (TB)</th><td>' + ("{0:N2}" -f ((Get-SharePointTenantStorageUsage -ReportPeriod $ReportPeriod)[0].'Storage Used (Byte)' / 1TB)) + '</td></tr>'
        foreach ($item in ($raw.psobject.properties)) {
            $html += '<tr><th>' + $item.Name + '</th><td>' + ("{0:N0}" -f [int]($item.Value)) + '</td></tr>'
        }
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    #==============================================
    # OneDrive Report
    #==============================================
    if ($Scope -contains 'OneDrive' -and $Exclude -notcontains 'OneDriveUsageAndStorage') {
        SayInfo "OneDrive Report: Accounts and Storage"
        $raw = Get-OneDriveAccountUsageSummary -ReportPeriod $ReportPeriod | Select-Object * -ExcludeProperty Report*
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $onedriveIconFile + '"></th><th class="section">OneDrive Sites and Storage</th></tr></table><table id="mainTable">'
        $html += '<tr><th>Storage Used (TB)</th><td>' + ("{0:N2}" -f ((Get-OneDriveTenantStorageUsage -ReportPeriod $ReportPeriod)[0].'Storage Used (Byte)' / 1TB)) + '</td></tr>'
        foreach ($item in ($raw.psobject.properties)) {
            $html += '<tr><th>' + $item.Name + '</th><td>' + ("{0:N0}" -f [int]($item.Value)) + '</td></tr>'
        }
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    #==============================================
    # Microsoft Teams Report
    #==============================================

    # Teams Users
    if ($Scope -contains 'Teams' -and $Exclude -notcontains 'TeamsUsers') {
        SayInfo "Teams Report: Teams Users"
        $raw = Get-TeamsUserActivityDetail -ReportPeriod $ReportPeriod
        $raw | Add-Member -MemberType ScriptProperty -Name LastActivityDate -Value { [datetime]$this.'Last Activity Date' }
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $teamsIconFile + '"></th><th class="section">Teams Users</th></tr></table><table id="mainTable">'
        $html += '<tr><th>Teams Users</th><td>' + ("{0:N0}" -f ($raw | Where-Object { $_.'Is Licensed' -eq 'Yes' }).count) + '</td></tr>'
        $html += '<tr><th>Active Teams Users</th><td>' + ("{0:N0}" -f ($raw | Where-Object { $_.'Is Licensed' -eq 'Yes' -and $_.LastActivityDate -ge $Script:GraphStartDate }).count) + '</td></tr>'
        $html += '<tr><th>Inctive Teams Users</th><td>' + ("{0:N0}" -f ($raw | Where-Object { $_.'Is Licensed' -eq 'Yes' -and $_.LastActivityDate -lt $Script:GraphStartDate }).count) + '</td></tr>'
        $html += '<tr><th>Guest Users</th><td>' + ("{0:N0}" -f ($raw | Where-Object { $_.'User Principal Name' -match '#EXT#' }).count) + '</td></tr>'
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    # Teams User Activity
    if ($Scope -contains 'Teams' -and $Exclude -notcontains 'TeamsUsersActivities') {
        SayInfo "Teams Report: Teams Users Activities"
        $raw = Get-TeamsUserActivityCount -ReportPeriod $ReportPeriod | Select-Object * -ExcludeProperty "Report*", 'Audio Duration', 'Video Duration', 'Screen Sharing Duration'
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $teamsIconFile + '"></th><th class="section">Teams User Activity</th></tr></table><table id="mainTable">'
        # foreach ($item in ($raw.psobject.properties)) {
        #     $html += '<tr><th>' + $item.Name + '</th><td>' + ("{0:N0}" -f [int]($item.Value)) + '</td></tr>'
        # }\
        $html += '<tr><th>1:1 Calls</th><td>' + ("{0:N0}" -f ($raw.Calls)) + '</td></tr>'
        $html += '<tr><th>Chat Messages</th><td>' + ("{0:N0}" -f ($raw.'Private Chat Messages')) + '</td></tr>'
        $html += '<tr><th>Channel Messages</th><td>' + ("{0:N0}" -f ($raw.'Team Chat Messages' )) + '</td></tr>'
        $html += '<tr><th>Meetings</th><td>' + ("{0:N0}" -f ($raw.'Meetings' )) + '</td></tr>'
        $html += '<tr><th>Audio Duration (Minutes)</th><td>' + ("{0:N0}" -f ($raw.'Audio Duration (Minutes)' )) + '</td></tr>'
        $html += '<tr><th>Video Duration (Minutes)</th><td>' + ("{0:N0}" -f ($raw.'Video Duration (Minutes)' )) + '</td></tr>'
        $html += '<tr><th>Screen Sharing Duration (Minutes)</th><td>' + ("{0:N0}" -f ($raw.'Screen Sharing Duration (Minutes)' )) + '</td></tr>'
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    # Teams Device Usage
    if ($Scope -contains 'Teams' -and $Exclude -notcontains 'TeamsDevices') {
        SayInfo "Teams Report: Teams Devices"
        $raw = Get-TeamsDeviceUsageDistributionSummary -ReportPeriod $ReportPeriod | Select-Object Windows, Mac, Web, iOS, 'Android Phone', 'Windows Phone', 'Chrome OS', 'Linux'
        $html += '<table id="mainTable"><tr><th class="section"><img src="' + $teamsIconFile + '"></th><th class="section">Teams Devices</th></tr></table><table id="mainTable">'
        $html += '<tr><th>Windows</th><td>' + ("{0:N0}" -f [int]($raw.Windows)) + '</td></tr>'
        $html += '<tr><th>Mac</th><td>' + ("{0:N0}" -f [int]($raw.Mac)) + '</td></tr>'
        $html += '<tr><th>Web</th><td>' + ("{0:N0}" -f [int]($raw.Web)) + '</td></tr>'
        $html += '<tr><th>iOS</th><td>' + ("{0:N0}" -f [int]($raw.iOS)) + '</td></tr>'
        $html += '<tr><th>Android Phone</th><td>' + ("{0:N0}" -f [int]($raw.'Android Phone')) + '</td></tr>'
        $html += '<tr><th>Windows Phone</th><td>' + ("{0:N0}" -f [int]($raw.'Windows Phone')) + '</td></tr>'
        $html += '<tr><th>Chrome OS</th><td>' + ("{0:N0}" -f [int]($raw.'Chrome OS')) + '</td></tr>'
        $html += '<tr><th>Linux</th><td>' + ("{0:N0}" -f [int]($raw.Linux)) + '</td></tr>'
        $html += '<tr><td class="placeholder"> </td></tr></table>'
    }

    $html += '<table id="mainTable"><tr><th class="section"><img src="' + $settingsIconFile + '"></th><th class="section">Report Parameters</th></tr></table><table id="mainTable">'
    $html += '<tr><th>Report Period</th><td>' + $ReportPeriod + ' days</td></tr>'
    $html += '<tr><th>Enabled Reports</th><td>' + ($Scope -join ', ') + '</td></tr>'
    $html += '<tr><th>Source</th><td>' + $env:COMPUTERNAME + '</td></tr>'
    $html += '<tr><td colspan="2"><a href="' + ($thisModule.PROJECTURI) + '">' + ($thismodule.Name) + ' v.' + ($thismodule.Version) + '</td></tr>'
    $html += '</table>'
    $html += '</body></html>'
    $html = $html -join "`n"
    $html | Out-File ([System.IO.Path]::Combine($reportFolder, "$($organizationName)_usage_report.html"))

    $html = $html.Replace($officeIconFile, "cid:officeIconFile")
    $html = $html.Replace("$($exchangeIconFile)", "exchangeIconFile")
    $html = $html.Replace("$($defenderIconFile)", "defenderIconFile")
    $html = $html.Replace("$($sharepointIconFile)", "cid:sharepointIconFile")
    $html = $html.Replace("$($onedriveIconFile)", "cid:onedriveIconFile")
    # $html = $html.Replace("$($skypeIconFile)", "cid:skypeIconFile")
    $html = $html.Replace("$($teamsIconFile)", "cid:teamsIconFile")
    $html = $html.Replace("$($settingsIconFile)", "cid:settingsIconFile")

    if ($SendEmail) {
        SayInfo "Sending email report"
        try {
            #message
            $mailBody = @{
                message = @{
                    subject                = $mailSubject
                    body                   = @{
                        contentType = "HTML"
                        content     = $html
                    }
                    internetMessageHeaders = @(
                        @{
                            name  = "X-Mailer"
                            value = "M365UsageReport by June Castillote"
                        }
                    )
                    attachments            = @(
                        @{
                            "@odata.type"  = "#microsoft.graph.fileAttachment"
                            "contentID"    = "logoFile"
                            "name"         = "logoFile"
                            "IsInline"     = $true
                            "contentType"  = "image/png"
                            "contentBytes" = "$([convert]::ToBase64String((Get-Content $logoFile -Raw -Encoding byte)))"
                        }
                        @{
                            "@odata.type"  = "#microsoft.graph.fileAttachment"
                            "contentID"    = "officeIconFile"
                            "name"         = "officeIconFile"
                            "IsInline"     = $true
                            "contentType"  = "image/png"
                            "contentBytes" = "$([convert]::ToBase64String((Get-Content $officeIconFile -Raw -Encoding byte)))"
                        }
                        @{
                            "@odata.type"  = "#microsoft.graph.fileAttachment"
                            "contentID"    = "exchangeIconFile"
                            "name"         = "exchangeIconFile"
                            "IsInline"     = $true
                            "contentType"  = "image/png"
                            "contentBytes" = "$([convert]::ToBase64String((Get-Content $exchangeIconFile -Raw -Encoding byte)))"
                        }
                        @{
                            "@odata.type"  = "#microsoft.graph.fileAttachment"
                            "contentID"    = "defenderIconFile"
                            "name"         = "defenderIconFile"
                            "IsInline"     = $true
                            "contentType"  = "image/png"
                            "contentBytes" = "$([convert]::ToBase64String((Get-Content $defenderIconFile -Raw -Encoding byte)))"
                        }
                        @{
                            "@odata.type"  = "#microsoft.graph.fileAttachment"
                            "contentID"    = "sharepointIconFile"
                            "name"         = "sharepointIconFile"
                            "IsInline"     = $true
                            "contentType"  = "image/png"
                            "contentBytes" = "$([convert]::ToBase64String((Get-Content $sharepointIconFile -Raw -Encoding byte)))"
                        }
                        @{
                            "@odata.type"  = "#microsoft.graph.fileAttachment"
                            "contentID"    = "onedriveIconFile"
                            "name"         = "onedriveIconFile"
                            "IsInline"     = $true
                            "contentType"  = "image/png"
                            "contentBytes" = "$([convert]::ToBase64String((Get-Content $onedriveIconFile -Raw -Encoding byte)))"
                        }
                        @{
                            "@odata.type"  = "#microsoft.graph.fileAttachment"
                            "contentID"    = "teamsIconFile"
                            "name"         = "teamsIconFile"
                            "IsInline"     = $true
                            "contentType"  = "image/png"
                            "contentBytes" = "$([convert]::ToBase64String((Get-Content $teamsIconFile -Raw -Encoding byte)))"
                        }
                        @{
                            "@odata.type"  = "#microsoft.graph.fileAttachment"
                            "contentID"    = "settingsIconFile"
                            "name"         = "settingsIconFile"
                            "IsInline"     = $true
                            "contentType"  = "image/png"
                            "contentBytes" = "$([convert]::ToBase64String((Get-Content $settingsIconFile -Raw -Encoding byte)))"
                        }
                    )
                }
            }

            # To address
            if ($To) {
                [array]$toAddress = $To.Split(",")
                # create JSON-format recipients
                $toAddressJSON = @()
                $toAddress | ForEach-Object {
                    $toAddressJSON += @{EmailAddress = @{Address = $_ } }
                }
                $mailBody.message += @{
                    toRecipients = @(
                        $ToAddressJSON
                    )
                }
            }

            # Cc address
            if ($Cc) {
                [array]$ccAddress = $Cc.Split(",")
                # create JSON-format recipients
                $ccAddressJSON = @()
                $ccAddress | ForEach-Object {
                    $ccAddressJSON += @{EmailAddress = @{Address = $_ } }
                }
                $mailBody.message += @{
                    ccRecipients = @(
                        $ccAddressJSON
                    )
                }
            }

            # Bcc address
            if ($Bcc) {
                [array]$bccAddress = $Bcc.Split(",")
                # create JSON-format recipients
                $bccAddressJSON = @()
                $bccAddress | ForEach-Object {
                    $bccAddressJSON += @{EmailAddress = @{Address = $_ } }
                }
                $mailBody.message += @{
                    bccRecipients = @(
                        $bccAddressJSON
                    )
                }
            }

            $mailBody = $mailBody | ConvertTo-Json -Depth 4
            $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint('https://graph.microsoft.com')
            $mailApiUri = "https://graph.microsoft.com/beta/users/$($From)/sendmail"
            Invoke-RestMethod -Method Post -Uri $mailApiUri -Body $mailbody -Headers @{Authorization = "Bearer $AccessToken" } -ContentType application/json -ErrorAction STOP
            $null = $ServicePoint.CloseConnectionGroup("")
            SayInfo "[$([Char]8730)] Sending Complete"
        }
        catch {
            $null = $ServicePoint.CloseConnectionGroup("")
            SayError "[X] Sending failed"
            SayError "$($_.Exception)"
            [System.GC]::Collect()
            return $null
        }
    }
}