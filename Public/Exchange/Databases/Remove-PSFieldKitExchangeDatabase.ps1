function Remove-PSFieldKitExchangeDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,
        [Parameter()]
        [string]$Identity,
        [Parameter()]
        [switch]$WhatIf
    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Remove-MailboxDatabase -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Remove-MailboxDatabase' is not available." -ForegroundColor Red
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
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|             Remove Mailbox Database          |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $DisplayName = [string]$Database.Name
    if ($DisplayName.Length -gt 36) {
        $DisplayName = $DisplayName.Substring(0, 33) + "..."
    }

    $DatabaseStatus = if ($Database.Mounted) {
        "Mounted"
    }
    else {
        "Dismounted"
    }

    Write-Host ("|  Database : {0,-33}|" -f $DisplayName)
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server)
    Write-Host ("|  Status   : {0,-33}|" -f $DatabaseStatus)
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host ""
    Write-Host "WARNING" -ForegroundColor Red
    Write-Host "This operation removes the mailbox database object from Active Directory." -ForegroundColor Yellow
    Write-Host "The physical EDB and log files are NOT removed automatically." -ForegroundColor Yellow

    if ($Database.Mounted) {
        Write-Host ""
        Write-Host "The database is currently MOUNTED." -ForegroundColor Red
        Write-Host "It should be dismounted before removal." -ForegroundColor Yellow

        $DismountConfirmation = Read-Host "`nDismount database '$($Database.Name)' now? [Y/N]"

        if ($DismountConfirmation -notmatch '^(Y|y|Yes|yes)$') {
            Write-Host "`nOperation cancelled." -ForegroundColor Yellow
            return
        }

        try {
            Write-Host "`nDismounting database..." -ForegroundColor Yellow

            Dismount-Database `
                -Identity $Database.Identity `
                -Confirm:$false `
                -ErrorAction Stop

            Write-Host "Database dismounted successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "`nFailed to dismount database." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        try {
            $Database = Get-MailboxDatabase `
                -Identity $Database.Identity `
                -Status `
                -ErrorAction Stop
        }
        catch {
            Write-Host "`nDatabase was dismounted, but its status could not be refreshed." -ForegroundColor Yellow
            Write-Host $_.Exception.Message -ForegroundColor DarkYellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        if ($Database.Mounted) {
            Write-Host "`nDatabase is still mounted. Removal has been cancelled." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }

    Write-Host ""
    Write-Host "DATABASE INFORMATION" -ForegroundColor DarkCyan
    Write-Host ("Name       : {0}" -f $Database.Name)
    Write-Host ("Server     : {0}" -f $Database.Server)
    Write-Host ("EDB Path   : {0}" -f $Database.EdbFilePath)
    Write-Host ("Log Folder : {0}" -f $Database.LogFolderPath)

    if ($WhatIf) {
        Write-Host "`nWHATIF MODE ENABLED - no changes will be made." -ForegroundColor Yellow
    }

    Write-Host ""

    $Confirmation = Read-Host "Permanently remove database object '$($Database.Name)'? [Y/N]"

    if ($Confirmation -notmatch '^(Y|y|Yes|yes)$') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nRemoving mailbox database '$($Database.Name)'..." -ForegroundColor Yellow

        $RemoveParameters = @{
            Identity    = $Database.Identity
            Confirm     = $false
            ErrorAction = 'Stop'
        }

        if ($WhatIf) {
            $RemoveParameters['WhatIf'] = $true
        }

        Remove-MailboxDatabase @RemoveParameters

        if ($WhatIf) {
            Write-Host "`nWhatIf completed. No database object was removed." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "`nMailbox database object removed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to remove mailbox database '$($Database.Name)'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "IMPORTANT" -ForegroundColor DarkCyan
    Write-Host "Exchange removed the database object from Active Directory." -ForegroundColor Yellow
    Write-Host "The physical database and log files remain on disk." -ForegroundColor Yellow
    Write-Host "If they are no longer required, remove them manually after verification."

    Read-Host "`nPress Enter to continue" | Out-Null
}