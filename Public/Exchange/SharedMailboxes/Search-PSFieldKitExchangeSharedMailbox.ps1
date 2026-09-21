function Search-PSFieldKitExchangeSharedMailbox {
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
    Write-Host "|           Search Shared Mailboxes            |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    $SearchTerm = Read-Host "Enter search term"

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        Write-Host ""
        Write-Host "Search term cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        $SharedMailboxes = @(
            Get-Mailbox -Anr $SearchTerm -RecipientTypeDetails SharedMailbox -ResultSize Unlimited -ErrorAction Stop |
                Sort-Object DisplayName
        )
    }
    catch {
        Write-Host ""
        Write-Host "Failed to search shared mailboxes." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host ""

    if ($SharedMailboxes.Count -eq 0) {
        Write-Host "No shared mailboxes matched '$SearchTerm'." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Write-Host "Search results: $($SharedMailboxes.Count)" -ForegroundColor Cyan
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