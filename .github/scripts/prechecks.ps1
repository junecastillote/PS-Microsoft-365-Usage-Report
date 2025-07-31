Write-Host "🔍 Running pre-publish checks..."

# Check for module manifest
$manifest = Get-ChildItem -Path . -Filter PsSkuMon365.psd1 -Recurse | Select-Object -First 1
if (-not $manifest) {
    Write-Error "❌ Module manifest not found. Expected 'PsSkuMon365.psd1'."
    exit 1
}

# Validate module version
$manifestData = Test-ModuleManifest -Path $manifest.FullName
$version = $manifestData.Version
if (-not $version -or $version -match "[^\d\.]") {
    Write-Error "❌ Invalid or missing version in manifest: $version"
    exit 1
}

# Check if version already exists on PowerShell Gallery
try {
    $existing = Find-Module -Name PsSkuMon365 -Repository PSGallery -ErrorAction Stop
    if ($existing.Version -eq $version) {
        Write-Error "❌ Version $version of PsSkuMon365 already exists on PowerShell Gallery. Update the version before publishing."
        exit 1
    }
}
catch {
    Write-Warning "⚠️ Could not check existing version on PSGallery: $_"
}

# Optional: enforce main branch
$branch = git rev-parse --abbrev-ref HEAD 2>$null
if ($branch -ne "main") {
    Write-Warning "⚠️ Current branch is '$branch'. Expected 'main'."
    # Uncomment to enforce:
    # exit 1
}

Write-Host "✅ Pre-checks passed. Ready to publish PsSkuMon365 v$version"
