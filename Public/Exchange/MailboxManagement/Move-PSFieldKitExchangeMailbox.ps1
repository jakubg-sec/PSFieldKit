function Move-PSFieldKitExchangeMailbox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host ""
        Write-Host "The Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Clear-Host

    $ServerName = "Unknown"

    if (
        $ExchangeContext.PSObject.Properties.Name -contains "ServerName" -and
        -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
    ) {
        $ServerName = [string]$ExchangeContext.ServerName
    }

    if ($ServerName.Length -gt 35) {
        $ServerName = $ServerName.Substring(0, 32) + "..."
    }

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                  Move Mailbox                |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    $MailboxIdentity = Read-Host "Enter mailbox identity"

    if ([string]::IsNullOrWhiteSpace($MailboxIdentity)) {
        Write-Host ""
        Write-Host "Mailbox identity cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $Mailbox = Get-Mailbox -Identity $MailboxIdentity -ErrorAction Stop
    }
    catch {
        Write-Host ""
        Write-Host "Failed to find mailbox." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $ExistingMoveRequest = Get-MoveRequest -Identity $Mailbox.Identity -ErrorAction SilentlyContinue

        if ($null -ne $ExistingMoveRequest) {
            Write-Host ""
            Write-Host "A move request already exists for this mailbox." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Status : $($ExistingMoveRequest.Status)" -ForegroundColor White
            Write-Host "Target : $($ExistingMoveRequest.TargetDatabase)" -ForegroundColor White
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }
    catch {
        Write-Verbose $_.Exception.Message
    }

    $SourceDatabase = [string]$Mailbox.Database

    Write-Host ""
    Write-Host "Mailbox selected:" -ForegroundColor Cyan
    Write-Host "  Name         : $($Mailbox.DisplayName)"
    Write-Host "  Alias        : $($Mailbox.Alias)"
    Write-Host "  Primary SMTP : $($Mailbox.PrimarySmtpAddress)"
    Write-Host "  Source DB    : $SourceDatabase"
    Write-Host ""

    $TargetDatabase = Read-Host "Enter target mailbox database"

    if ([string]::IsNullOrWhiteSpace($TargetDatabase)) {
        Write-Host ""
        Write-Host "Target mailbox database cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $TargetDatabaseObject = Get-MailboxDatabase -Identity $TargetDatabase -ErrorAction Stop
    }
    catch {
        Write-Host ""
        Write-Host "Target mailbox database was not found." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    $TargetDatabaseName = [string]$TargetDatabaseObject.Name

    if ($SourceDatabase -eq $TargetDatabaseName) {
        Write-Host ""
        Write-Host "The mailbox is already located in the selected database." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""
    Write-Host "Move configuration:" -ForegroundColor Cyan
    Write-Host "  Mailbox : $($Mailbox.DisplayName)"
    Write-Host "  Source  : $SourceDatabase"
    Write-Host "  Target  : $TargetDatabaseName"
    Write-Host ""

    $Confirmation = Read-Host "Type MOVE to continue"

    if ($Confirmation -cne "MOVE") {
        Write-Host ""
        Write-Host "Mailbox move cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host ""
        Write-Host "Creating mailbox move request..." -ForegroundColor Yellow

        New-MoveRequest -Identity $Mailbox.Identity -TargetDatabase $TargetDatabaseName -ErrorAction Stop

        Write-Host ""
        Write-Host "Mailbox move request created successfully." -ForegroundColor Green

        Start-Sleep -Seconds 2

        $MoveRequest = Get-MoveRequest -Identity $Mailbox.Identity -ErrorAction Stop

        Write-Host ""
        Write-Host "Move request status:" -ForegroundColor Cyan
        Write-Host "  Mailbox : $($Mailbox.DisplayName)"
        Write-Host "  Status  : $($MoveRequest.Status)"
        Write-Host "  Target  : $($MoveRequest.TargetDatabase)"

        try {
            $MoveStatistics = Get-MoveRequestStatistics -Identity $Mailbox.Identity -ErrorAction Stop

            if ($null -ne $MoveStatistics) {
                Write-Host "  Percent : $($MoveStatistics.PercentComplete)%"
            }
        }
        catch {
            Write-Verbose $_.Exception.Message
        }

        Write-Host ""
        Write-Host "The mailbox move will be processed by the Mailbox Replication Service." -ForegroundColor DarkGray
    }
    catch {
        Write-Host ""
        Write-Host "Failed to create mailbox move request." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}