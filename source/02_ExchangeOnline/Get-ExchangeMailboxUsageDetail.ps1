Function Get-ExchangeMailboxUsageDetail {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [Int]
        $ReportPeriod = 7
    )

    # $now = Get-Date

    if (!(Get-AccessToken)) {
        SayError 'No access token is found in the session. Run the New-AccessToken command first to acquire an access token.'
        Return $null
    }
	$null = Update-AccessToken
	$AccessToken = (Get-AccessToken).access_token

    try {
        $uri = "https://graph.microsoft.com/beta/reports/getMailboxUsageDetail(period='D$($ReportPeriod)')"
        $result = (Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $AccessToken" } -ContentType 'application/json' -ErrorAction Stop)
        $null = $result -match '(.*)Report Refresh Date'
        $result = ($result -replace $Matches[1], '') | ConvertFrom-Csv
        # How many days since the last mailbox activity
        $result | Add-Member -MemberType ScriptProperty -Name 'Days Inactive' -Value {
            # Calculate the number of days since the last activity date to today.
            if ($this.'Last Activity Date') {
                (New-TimeSpan -Start $([datetime]($this.'Last Activity Date')) -End (Get-Date)).Days
            }
            else {
                # If there's no 'Last Activity Date', use 'Created Date' instead.
                (New-TimeSpan -Start $([datetime]($this.'Created Date')) -End (Get-Date)).Days
            }
        }
        $result | Add-Member -MemberType ScriptProperty -Name 'Mailbox Quota Status' -Value {
            # Quota = Under Limit (Used < Warning Issued)
            if (
                [double]$this."Storage Used (Byte)" -lt `
                    [double]$this."Issue Warning Quota (Byte)"
            ) {
                "Under Limit"
            }

            # Quota = Warning Issued (Used >= Warning Issued < Send Prohibited)
            if (
                [double]$this."Storage Used (Byte)" -ge `
                    [double]$this."Issue Warning Quota (Byte)" -and `
                    [double]$this."Storage Used (Byte)" -lt `
                    [double]$this."Prohibit Send Quota (Byte)"
            ) {
                "Warning Issued"
            }

            # Quota = Send Prohibited (Used >= Send Prohibited < Send/Receive Prohibited)
            if (
                [double]$this."Storage Used (Byte)" -ge `
                    [double]$this."Prohibit Send Quota (Byte)" -and `
                    [double]$this."Storage Used (Byte)" -lt `
                    [double]$this."Prohibit Send/Receive Quota (Byte)"
            ) {
                "Send Prohibited"
            }

            # Quota = Send/Receive Prohibited (Used >= Send/Receive Prohibited)
            if (
                [double]$this."Storage Used (Byte)" -ge `
                    [double]$this."Prohibit Send/Receive Quota (Byte)"
            ) {
                "Send/Receive Prohibited"
            }
        }

        $result | Add-Member -MemberType ScriptProperty -Name 'Percent Used' -Value {
            # ([double]$this."Storage Used (Byte)" / [double]$this."Prohibit Send/Receive Quota (Byte)").ToString('P')
            [Math]::Round((([double]$this."Storage Used (Byte)" / [double]$this."Prohibit Send/Receive Quota (Byte)") * 100), 2)
        }

        $result | Add-Member -MemberType ScriptProperty -Name 'Active Status' -Value {
            if (($this.'Days Inactive') -le ($this.'Report Period')) {
                'Active'
            }
            else {
                'Inactive'
            }
        }
        return $result
    }
    catch {
        SayError $_
        return $null
    }
}