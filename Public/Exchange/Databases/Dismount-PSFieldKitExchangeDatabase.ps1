function Dismount-PSFieldKitExchangeDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$Identity,

        [Parameter()]
        [switch]$Force
    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Dismount-Database -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Dismount-Database' is not available." -ForegroundColor Red
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

    if (-not $Database.Mounted) {
        Write-Host "`nDatabase '$($Database.Name)' is already dismounted." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|             Dismount Database                |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $DisplayName = [string]$Database.Name

    if ($DisplayName.Length -gt 36) {
        $DisplayName = $DisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Database : {0,-33}|" -f $DisplayName)
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server)
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nWARNING: Dismounting the database will make its mailboxes unavailable." -ForegroundColor Yellow

    if ($Force) {
        Write-Host "Force mode is enabled. Exchange confirmation prompts will be suppressed." -ForegroundColor Yellow
    }

    $Confirmation = Read-Host "`nDismount database '$($Database.Name)'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        Write-Host "`nDismounting database '$($Database.Name)'..." -ForegroundColor Yellow

        $DismountParameters = @{
            Identity    = $Database.Identity
            ErrorAction = 'Stop'
        }

        if ($Force) {
            $DismountParameters['Confirm'] = $false
        }

        Dismount-Database @DismountParameters

        Write-Host "`nDatabase dismount command completed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to dismount database '$($Database.Name)'." -ForegroundColor Red
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

        if (-not $Verification.Mounted) {
            Write-Host "`nDatabase '$($Verification.Name)' is now DISMOUNTED." -ForegroundColor Green
            Write-Host ("Server: {0}" -f $Verification.Server) -ForegroundColor Cyan
        }
        else {
            Write-Host "`nDatabase '$($Verification.Name)' is still MOUNTED." -ForegroundColor Red
            Write-Host "The dismount command completed, but Exchange reports the database as mounted." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`nDatabase was dismounted, but its status could not be verified." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}