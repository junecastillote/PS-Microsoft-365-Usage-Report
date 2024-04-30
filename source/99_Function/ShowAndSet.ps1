Function Show-ThisModule {
    $Script:thisModule = $MyInvocation.MyCommand.Module
    $Script:thisModule
}

Function Show-ReportDate {
    [PSCustomObject]@{
        StartDate = $Script:GraphStartDate
        EndDate   = $Script:GraphEndDate
    }
}

Function Set-ReportDate {
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [Int]
        $ReportPeriod = 7
    )
    if ($Script:GraphStartDate -eq '1970-01-01') {
        if (!$(Get-AccessToken)) {
            SayError 'No access token is found in the session. Run the New-AccessToken command first to acquire an access token.'
            Return $null
        }

        $temp = (Get-M365ActiveUserCounts -ReportPeriod $ReportPeriod)
        $Script:GraphStartDate = [datetime]$temp[0].'Report Date'
        $Script:GraphEndDate = [datetime]$temp[-1].'Report Date'
    }
}

# Show-ReportDate