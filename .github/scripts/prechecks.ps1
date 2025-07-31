Write-Host "🔍 Running pre-publish checks..."

$manifestFileName = 'PS.M365UsageReport.psd1'

# Check for module manifest
$manifest = Get-ChildItem -Path . -Filter $manifestFileName -Recurse | Select-Object -First 1
if (-not $manifest) {
    Write-Error "❌ Module manifest not found. Expected '$manifestFileName'."
    exit 1
}

# Validate module version
try {
    $manifestData = Test-ModuleManifest -Path $manifest.FullName -ErrorAction Stop
    $version = $manifestData.Version
    Write-Host "✅ Module version found: $version"
}
catch {
    Write-Error "❌ Failed to validate module manifest: $($_.Exception.Message)"
    exit 1
}

# Check if version already exists on PowerShell Gallery
try {
    $existing = Find-Module -Name $($manifestData.Name) -Repository PSGallery -ErrorAction Stop

    if ($existing -and $existing.Version -eq $version) {
        Write-Error "❌ Version '$version' of $($manifestData.Name) already exists on PSGallery. Update the version before publishing."
        exit 1
    }
    else {
        Write-Host "✅ No conflict with existing PSGallery version."
    }
}
catch {
    Write-Warning "⚠️ Could not check existing version on PSGallery. Error: $($_.Exception.Message)"
}

# # Optional: enforce publishing from main branch
# try {
#     # $branch = (& git rev-parse --abbrev-ref HEAD).Trim()
#     # $branch = $env:GITHUB_REF_NAME
#     $branch = $env:BRANCH_NAME
# }
# catch {
#     Write-Warning "⚠️ Could not determine current Git branch. Skipping branch check."
#     $branch = $null
# }

# if ($env:ENFORCE_BRANCH_CHECK -eq 'true' -and $branch -ne 'main') {
#     Write-Error "❌ Publishing is only allowed from 'main' branch. Current branch: '$branch'"
#     exit 1
# }
# elseif ($branch -ne 'main') {
#     Write-Warning "⚠️ Current branch is '$branch'. Expected 'main'."
# }

Write-Host "✅ Pre-publish checks completed."
