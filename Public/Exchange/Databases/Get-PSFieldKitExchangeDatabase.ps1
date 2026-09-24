function Get-PSFieldKitExchangeDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,
        [Parameter()]
        [ValidateRange(1, 1000)]
        [int]$ResultSize = 100
    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-MailboxDatabase' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        Write-Host "`nRetrieving mailbox databases..." -ForegroundColor Yellow
        $Databases = @(
            Get-MailboxDatabase -Status -ErrorAction Stop |
                Sort-Object Name |
                Select-Object -First $ResultSize
        )
    }
    catch {
        Write-Host "`nFailed to retrieve mailbox databases." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ($Databases.Count -eq 0) {
        Write-Host "`nNo mailbox databases were found." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|              Mailbox Databases               |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $ServerName = "Unknown"
    if (
        $ExchangeContext.PSObject.Properties.Name -contains 'ServerName' -and
        -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
    ) {
        $ServerName = [string]$ExchangeContext.ServerName
    }

    if ($ServerName.Length -gt 35) {
        $ServerName = $ServerName.Substring(0, 32) + "..."
    }

    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host ("|  Count  : {0,-35}|" -f $Databases.Count) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nDATABASES" -ForegroundColor DarkCyan
    Write-Host ""

    $Databases |
        Select-Object `
            Name,
            Server,
            @{Name = 'Status'; Expression = {
                if ($_.Mounted) { 'Mounted' }
                else { 'Dismounted' }
            }},
            @{Name = 'Size'; Expression = {
                if ($_.DatabaseSize) { $_.DatabaseSize.ToString() }
                else { 'Unknown' }
            }},
            @{Name = 'Free Space'; Expression = {
                if ($_.AvailableNewMailboxSpace) { $_.AvailableNewMailboxSpace.ToString() }
                else { 'Unknown' }
            }},
            CircularLoggingEnabled |
        Format-Table -AutoSize |
        Out-Host

    if ($Databases.Count -eq $ResultSize) {
        Write-Host "Result limit reached: $ResultSize." -ForegroundColor Yellow
    }

    Write-Host ""
    Read-Host "Press Enter to continue" | Out-Null
}