(Get-Location).Path
$manifest = Get-ChildItem -Path . -Filter PS.M365UsageReport.psd1 -Recurse | Select-Object -First 1
(Get-ChildItem $manifest.Directory.ToString() -Recurse).FullName

Publish-Module -Path $manifest.Directory.ToString() `
    -NuGetApiKey $env:PSGALLERY_API_KEY `
    -Force