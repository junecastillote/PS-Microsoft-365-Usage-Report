Function Get-M365GroupProvisioningSummary {
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

        # Get existing groups
        $liveGroups = @()
        $uri = "https://graph.microsoft.com/beta/groups`?`$filter=groupTypes/any(c:c+eq+'Unified')`&`$select=mailNickname,deletedDateTime,createdDateTime"
        $raw = (Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $AccessToken" } -ErrorAction Stop )

        if ($raw.value) {
            $liveGroups += $raw.value
            while (($raw.'@odata.nextLink')) {
                $raw = (Invoke-RestMethod -Method Get -Uri ($raw.'@odata.nextLink') -Headers @{Authorization = "Bearer $AccessToken" } )
                $liveGroups += $raw.value
            }
        }

        # Get deleted groups
        $deletedGroups = @()
        $uri = "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.group`?`$filter=groupTypes/any(c:c+eq+'Unified')`&`$select=mailNickname,deletedDateTime,createdDateTime"
        $raw = (Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $AccessToken" } -ContentType 'application/json' -ErrorAction Stop)
        if ($raw.value) {
            $deletedGroups += $raw.value
            while (($raw.'@odata.nextLink')) {
                $raw = (Invoke-RestMethod -Method Get -Uri ($raw.'@odata.nextLink') -Headers @{Authorization = "Bearer $AccessToken" })
                $deletedGroups += $raw.value
            }
        }

        [PSCustomObject]@{
            'Current'       = $liveGroups.count
            'Created'       = ($liveGroups | Where-Object { ([datetime]$_.createdDateTime) -ge $Script:GraphStartDate }).Count
            'Deleted'       = ($deletedGroups | Where-Object { ([datetime]$_.deletedDateTime) -ge $Script:GraphStartDate }).Count
            'Report Period' = $ReportPeriod
        }
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}