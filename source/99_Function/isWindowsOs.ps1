Function isWindowsOs {
    param()
    if ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
        return $true
    }
    else {
        return $false
    }
}