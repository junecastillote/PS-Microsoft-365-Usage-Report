Function Get-OutputFileName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $URI
    )

    $pattern = ".*/([^/()]+)(?:\(|$)"

    if ($uri -match $pattern) {
        "$($env:temp)\$($matches[1]).csv"
    }
}