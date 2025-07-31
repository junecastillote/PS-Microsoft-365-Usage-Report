$manifest = Test-ModuleManifest PS.M365UsageReport.psd1
$modulePath = $manifest.ModuleBase
# Get-ChildItem $modulePath

Publish-Module -Path $modulePath `
    -NuGetApiKey $env:PSGALLERY_API_KEY `
    -Force