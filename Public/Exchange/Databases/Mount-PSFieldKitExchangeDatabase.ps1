function Mount-PSFieldKitExchangeDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$AcceptDataLoss
    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Mount-Database -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Mount-Database' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter mailbox database name or identity"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDatabase identity cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Database = Get-MailboxDatabase `
            -Identity $Identity `
            -Status `
            -ErrorAction Stop
    }
    catch {
        Write-Host "`nMailbox database '$Identity' was not found." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ($Database.Mounted) {
        Write-Host "`nDatabase '$($Database.Name)' is already mounted." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|              Mount Database                  |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Database : {0,-33}|" -f $Database.Name)
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server)
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    if ($AcceptDataLoss) {
        Write-Host "`nWARNING: -AcceptDataLoss was specified." -ForegroundColor Red
        Write-Host "This allows Exchange to mount the database despite missing committed transaction logs." -ForegroundColor Yellow
    }

    if ($Force) {
        Write-Host "`nWARNING: -Force was specified." -ForegroundColor Yellow
        Write-Host "Exchange warnings and confirmation messages will be suppressed." -ForegroundColor Yellow
    }

    $Confirmation = Read-Host "`nMount database '$($Database.Name)'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        Write-Host "`nMounting database '$($Database.Name)'..." -ForegroundColor Yellow

        $MountParameters = @{
            Identity    = $Database.Identity
            ErrorAction = 'Stop'
        }

        if ($Force) {
            $MountParameters['Force'] = $true
        }

        if ($AcceptDataLoss) {
            $MountParameters['AcceptDataLoss'] = $true
        }

        Mount-Database @MountParameters

        Write-Host "`nDatabase mount command completed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to mount database '$($Database.Name)'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        Write-Host "`nVerifying database status..." -ForegroundColor Yellow

        $Verification = Get-MailboxDatabase `
            -Identity $Database.Identity `
            -Status `
            -ErrorAction Stop

        if ($Verification.Mounted) {
            Write-Host "`nDatabase '$($Verification.Name)' is now MOUNTED." -ForegroundColor Green
            Write-Host ("Server: {0}" -f $Verification.Server) -ForegroundColor Cyan
        }
        else {
            Write-Host "`nDatabase '$($Verification.Name)' is still DISMOUNTED." -ForegroundColor Red
            Write-Host "The mount command completed, but Exchange reports the database as dismounted." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nDatabase was mounted, but its status could not be verified." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}