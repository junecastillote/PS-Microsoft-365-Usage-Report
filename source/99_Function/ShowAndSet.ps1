Function Show-ThisModule {
    $Script:thisModule = $MyInvocation.MyCommand.Module
    $Script:thisModule
}

Function Show-M365ReportDate {
    [PSCustomObject]@{
        StartDate = $Script:GraphStartDate
        EndDate   = $Script:GraphEndDate
    }
}

Function Set-M365ReportDate {
    param (
        [Parameter()]
        [ValidateSet(7, 30, 90, 180)]
        [int]
        $ReportPeriod = 7,

        [Parameter()]
        [switch]
        $Force
    )
    $ProgressPreference = 'SilentlyContinue'
    if ($Script:GraphStartDate -eq '1970-01-01' -or $Force) {
        $temp = (Get-M365ActiveUserCounts -ReportPeriod $ReportPeriod)
        $Script:GraphStartDate = [datetime]$temp[0].'Report Date'
        $Script:GraphEndDate = [datetime]$temp[-1].'Report Date'
    }
}

# Show-M365ReportDate