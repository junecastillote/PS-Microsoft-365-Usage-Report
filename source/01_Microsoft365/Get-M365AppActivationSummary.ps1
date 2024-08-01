Function Get-M365AppActivationSummary {
    [CmdletBinding()]
    param ()

    try {
        $uri = "https://graph.microsoft.com/beta/reports/getOffice365ActivationsUserCounts"
        $outFile = Get-OutputFileName $uri -ErrorAction Stop
        Invoke-MgGraphRequest -Method Get -Uri $uri -ContentType 'application/json' -ErrorAction Stop -OutputFilePath $outFile
        $result = (Get-Content $outFile | ConvertFrom-Csv)

        for ($i = 0; $i -lt ($result.count); $i++) {
            $result[$i].'Product Type' = ([cultureinfo]::CurrentCulture).TextInfo.ToTitleCase(($($result[$i].'Product Type')).ToLower())
        }
        return $result
    }
    catch {
        SayError $_.Exception.Message
        return $null
    }
}