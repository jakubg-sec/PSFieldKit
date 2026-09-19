function Test-PSFieldKitMenuOption {
    param(
        [Parameter(Mandatory)]
        [bool]$Available
    )

    if ($Available) {
        return $true
    }

    Write-Host "`nThis option is not available for the current target mode." `
        -ForegroundColor Yellow

    return $false
}