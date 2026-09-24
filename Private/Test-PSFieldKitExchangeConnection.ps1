function Test-PSFieldKitExchangeConnection {
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [PSCustomObject]$ExchangeContext
    )

    if ($null -eq $ExchangeContext) {
        Write-Host "`nConnect to an Exchange server first." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return $false
    }

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains 'Connected' -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host "`nThe Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return $false
    }

    return $true
}