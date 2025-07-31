(Get-Location).Path
$manifest = Get-ChildItem -Path . -Filter PS.M365UsageReport.psd1 -Recurse | Select-Object -First 1
tree

Publish-Module -Path $manifest.Directory.ToString() `
    -NuGetApiKey $env:PSGALLERY_API_KEY `
    -Force