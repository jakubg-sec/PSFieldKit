function Get-PSFieldKitExchangeMailbox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$ResultSize = 50
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
    Write-Host "|                List Mailboxes                |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    try {
        Write-Host "Retrieving mailboxes..." -ForegroundColor Yellow

        $Mailboxes = @(
            Get-Mailbox -ResultSize $ResultSize -ErrorAction Stop |
                Sort-Object DisplayName
        )

        if ($Mailboxes.Count -eq 0) {
            Write-Host ""
            Write-Host "No mailboxes were found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host ""

        $Mailboxes |
            Select-Object DisplayName, Alias, PrimarySmtpAddress, Database |
            Format-Table -AutoSize |
            Out-Host

        Write-Host ""
        Write-Host "Mailboxes displayed: $($Mailboxes.Count)" -ForegroundColor DarkGray

        if ($Mailboxes.Count -eq $ResultSize) {
            Write-Host "Result limit reached: $ResultSize." -ForegroundColor Yellow
        }

        Read-Host "`nPress Enter to continue" | Out-Null
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve mailboxes." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
    }
}