Function Get-M365UserLicenseSummary {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [Int]
        $ReportPeriod = 7
    )

    if (!(Get-AccessToken)) {
        SayError 'No access token is found in the session. Run the New-AccessToken command first to acquire an access token.'
        Return $null
    }
	$null = Update-AccessToken
	$AccessToken = (Get-AccessToken).access_token

    try {
        $uri = "https://graph.microsoft.com/beta/reports/getOffice365ActiveUserDetail(period='D$($ReportPeriod)')"
        $raw = (Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $AccessToken" } -ContentType 'application/json' -ErrorAction Stop) | ConvertFrom-Csv
        return $(
            New-Object psobject -Property $(
                [ordered]@{
                    "Total Users"                    = $raw.Count
                    "With License"                   = ($raw | Where-Object { $_."Assigned Products" }).count
                    "Without License"                = ($raw | Where-Object { !($_."Assigned Products") }).count
                    "Has Exchange License"           = ($raw | Where-Object { $_."Has Exchange License" -eq $true }).count
                    "Has Sharepoint License"         = ($raw | Where-Object { $_."Has Sharepoint License" -eq $true }).count
                    "Has OneDrive License"           = ($raw | Where-Object { $_."Has OneDrive License" -eq $true }).count
                    "Has Skype For Business License" = ($raw | Where-Object { $_."Has Skype For Business License" -eq $true }).count
                    "Has Yammer License"             = ($raw | Where-Object { $_."Has Yammer License" -eq $true }).count
                    "Has Teams License"              = ($raw | Where-Object { $_."Has Teams License" -eq $true }).count
                }
            )
        )
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}