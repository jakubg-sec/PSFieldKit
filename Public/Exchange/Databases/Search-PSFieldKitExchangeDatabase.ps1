function Search-PSFieldKitExchangeDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,

        [Parameter()]
        [string]$SearchTerm
    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-MailboxDatabase' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        $SearchTerm = Read-Host "Enter database name or search term"
    }

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        Write-Host "`nSearch term cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        Write-Host "`nSearching mailbox databases..." -ForegroundColor Yellow

        $Databases = @(
            Get-MailboxDatabase -Status -ErrorAction Stop |
                Where-Object {
                    $_.Name -like "*$SearchTerm*" -or
                    $_.Server -like "*$SearchTerm*" -or
                    $_.DistinguishedName -like "*$SearchTerm*"
                } |
                Sort-Object Name
        )
    }
    catch {
        Write-Host "`nFailed to search mailbox databases." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|             Search Mailbox Databases         |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Search : {0,-34}|" -f $SearchTerm) -ForegroundColor White
    Write-Host ("|  Results: {0,-34}|" -f $Databases.Count) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    if ($Databases.Count -eq 0) {
        Write-Host "`nNo mailbox databases matched the search." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "`nRESULTS" -ForegroundColor DarkCyan
    Write-Host ""

    $Index = 1

    foreach ($Database in $Databases) {
        $Status = if ($Database.Mounted) {
            "Mounted"
        }
        else {
            "Dismounted"
        }

        $StatusColor = if ($Database.Mounted) {
            "Green"
        }
        else {
            "Red"
        }

        Write-Host ("[{0}] {1}" -f $Index, $Database.Name) -ForegroundColor Cyan
        Write-Host ("    Server        : {0}" -f $Database.Server)
        Write-Host ("    Status        : {0}" -f $Status) -ForegroundColor $StatusColor
        Write-Host ("    Database Path : {0}" -f $Database.EdbFilePath)

        if ($Database.PSObject.Properties.Name -contains 'DatabaseSize') {
            Write-Host ("    Database Size : {0}" -f $Database.DatabaseSize)
        }

        if ($Database.PSObject.Properties.Name -contains 'AvailableNewMailboxSpace') {
            Write-Host ("    Free Space    : {0}" -f $Database.AvailableNewMailboxSpace)
        }

        Write-Host ("    Circular Log  : {0}" -f $Database.CircularLoggingEnabled)
        Write-Host ""

        $Index++
    }

    Write-Host ("Total results: {0}" -f $Databases.Count) -ForegroundColor Cyan

    Read-Host "`nPress Enter to continue" | Out-Null
}