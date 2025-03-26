Function Get-OutputFileName {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter()]
        [string]
        $URI
    )

    $pattern = ".*/([^/()]+)(?:\(|$)"

    if ($uri -match $pattern) {
        "$($env:temp)\M365UsageReport\$($script:initialCloudDomain)\$($matches[1]).csv"
    }
}