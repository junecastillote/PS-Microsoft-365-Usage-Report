(Get-Location).Path
$manifest = Get-ChildItem -Path . -Filter PS.M365UsageReport.psd1 -Recurse | Select-Object -First 1
$manifest.FullName

Publish-Module -Path (Split-Path $manifest.FullName) `
    -NuGetApiKey $env:PSGALLERY_API_KEY `
    -Force