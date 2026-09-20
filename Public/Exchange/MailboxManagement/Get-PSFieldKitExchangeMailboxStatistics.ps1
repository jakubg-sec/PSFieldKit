function Get-PSFieldKitExchangeMailboxStatistics {
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
    Write-Host "|               Mailbox Statistics             |" -ForegroundColor Cyan
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

        $Statistics = Get-MailboxStatistics -Identity $Mailbox.Identity -ErrorAction Stop

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|               Mailbox Statistics             |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"

        $DisplayName = [string]$Mailbox.DisplayName

        if ($DisplayName.Length -gt 35) {
            $DisplayName = $DisplayName.Substring(0, 32) + "..."
        }

        Write-Host ("|  Mailbox: {0,-35}|" -f $DisplayName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"

        $Database = [string]$Mailbox.Database
        $TotalItemSize = [string]$Statistics.TotalItemSize
        $ItemCount = [string]$Statistics.ItemCount
        $DeletedItemCount = [string]$Statistics.DeletedItemCount
        $StorageLimitStatus = [string]$Statistics.StorageLimitStatus
        $LastLogonTime = [string]$Statistics.LastLogonTime
        $LastLogoffTime = [string]$Statistics.LastLogoffTime

        if ([string]::IsNullOrWhiteSpace($Database)) {
            $Database = "Unknown"
        }

        if ([string]::IsNullOrWhiteSpace($TotalItemSize)) {
            $TotalItemSize = "Unknown"
        }

        if ([string]::IsNullOrWhiteSpace($ItemCount)) {
            $ItemCount = "Unknown"
        }

        if ([string]::IsNullOrWhiteSpace($DeletedItemCount)) {
            $DeletedItemCount = "Unknown"
        }

        if ([string]::IsNullOrWhiteSpace($StorageLimitStatus)) {
            $StorageLimitStatus = "Unknown"
        }

        if ([string]::IsNullOrWhiteSpace($LastLogonTime)) {
            $LastLogonTime = "Never"
        }

        if ([string]::IsNullOrWhiteSpace($LastLogoffTime)) {
            $LastLogoffTime = "Never"
        }

        if ($Database.Length -gt 35) {
            $Database = $Database.Substring(0, 32) + "..."
        }

        if ($TotalItemSize.Length -gt 35) {
            $TotalItemSize = $TotalItemSize.Substring(0, 32) + "..."
        }

        if ($StorageLimitStatus.Length -gt 35) {
            $StorageLimitStatus = $StorageLimitStatus.Substring(0, 32) + "..."
        }

        Write-Host "|  STORAGE                                     |" -ForegroundColor DarkCyan
        Write-Host ("|  Database          : {0,-25}|" -f $Database) -ForegroundColor White
        Write-Host ("|  Total Item Size   : {0,-25}|" -f $TotalItemSize) -ForegroundColor White
        Write-Host ("|  Item Count        : {0,-25}|" -f $ItemCount) -ForegroundColor White
        Write-Host ("|  Deleted Items     : {0,-25}|" -f $DeletedItemCount) -ForegroundColor White

        $StorageColor = "Green"

        if ($StorageLimitStatus -ne "BelowLimit") {
            $StorageColor = "Yellow"
        }

        Write-Host ("|  Storage Status    : {0,-25}|" -f $StorageLimitStatus) -ForegroundColor $StorageColor

        Write-Host "|                                              |"
        Write-Host "|  ACTIVITY                                    |" -ForegroundColor DarkCyan
        Write-Host ("|  Last Logon        : {0,-24}|" -f $LastLogonTime) -ForegroundColor White
        Write-Host ("|  Last Logoff       : {0,-24}|" -f $LastLogoffTime) -ForegroundColor White

        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [R] Refresh                                 |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        while ($true) {
            $Choice = Read-Host "`nSelect option"

            switch ($Choice) {
                "R" {
                    break
                }

                "r" {
                    break
                }

                "0" {
                    return
                }

                default {
                    Write-Host ""
                    Write-Host "Invalid option." -ForegroundColor Red
                }
            }
        }
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve mailbox statistics." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
    }
}