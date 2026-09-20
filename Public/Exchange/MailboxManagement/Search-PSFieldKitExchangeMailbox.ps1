function Search-PSFieldKitExchangeMailbox {
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
    Write-Host "|               Search Mailboxes               |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    $SearchTerm = Read-Host "Enter mailbox name, alias or email address"

    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        Write-Host ""
        Write-Host "Search term cannot be empty." -ForegroundColor Red
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        Write-Host ""
        Write-Host "Searching mailboxes..." -ForegroundColor Yellow

        $Mailboxes = @(
            Get-Mailbox -Anr $SearchTerm -ResultSize Unlimited -ErrorAction Stop |
                Sort-Object DisplayName
        )

        if ($Mailboxes.Count -eq 0) {
            Write-Host ""
            Write-Host "No mailboxes matching '$SearchTerm' were found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host ""

        $Mailboxes |
            Select-Object DisplayName, Alias, PrimarySmtpAddress, Database |
            Format-Table -AutoSize |
            Out-Host

        Write-Host ""
        Write-Host "Matches found: $($Mailboxes.Count)" -ForegroundColor DarkGray

        Read-Host "`nPress Enter to continue" | Out-Null
    }
    catch {
        Write-Host ""
        Write-Host "Mailbox search failed." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
    }
}