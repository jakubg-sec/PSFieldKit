function Get-PSFieldKitExchangeSharedMailbox {
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
    Write-Host "|              Shared Mailboxes                |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    $ResultSizeInput = Read-Host "Enter maximum number of shared mailboxes [50]"

    if ([string]::IsNullOrWhiteSpace($ResultSizeInput)) {
        $ResultSize = 50
    }
    else {
        $ResultSize = 0

        if (-not [int]::TryParse($ResultSizeInput, [ref]$ResultSize)) {
            Write-Host ""
            Write-Host "Invalid number." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        if ($ResultSize -lt 1) {
            Write-Host ""
            Write-Host "The maximum number must be greater than 0." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }
    }

    try {
        $SharedMailboxes = @(
            Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize $ResultSize -ErrorAction Stop |
                Sort-Object DisplayName
        )
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve shared mailboxes." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""

    if ($SharedMailboxes.Count -eq 0) {
        Write-Host "No shared mailboxes were found." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "Shared Mailboxes: $($SharedMailboxes.Count)" -ForegroundColor Cyan
    Write-Host ""

    $SharedMailboxes |
        Select-Object `
            DisplayName,
            Alias,
            PrimarySmtpAddress,
            Database |
        Format-Table -AutoSize

    Write-Host ""
    Read-Host "Press Enter to continue" | Out-Null
}