function Test-PSFieldKitExchangeDatabaseReplication {
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

    try {
        $DatabaseCopies = Get-MailboxDatabaseCopyStatus -ErrorAction Stop

        if (-not $DatabaseCopies) {
            Write-Host ""
            Write-Host "No database copies were found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Clear-Host

        Write-Host "+--------------------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              DATABASE REPLICATION HEALTH                    |" -ForegroundColor Cyan
        Write-Host "|                         PSFieldKit                          |" -ForegroundColor Cyan
        Write-Host "+--------------------------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""

        foreach ($Copy in $DatabaseCopies) {
            $DatabaseName = $Copy.Name
            $Status       = [string]$Copy.Status
            $CopyQueue    = $Copy.CopyQueueLength
            $ReplayQueue  = $Copy.ReplayQueueLength

            if ($Status -eq "Mounted" -or $Status -eq "Healthy") {
                $Color = "Green"
            }
            elseif ($Status -eq "DisconnectedAndHealthy") {
                $Color = "Yellow"
            }
            else {
                $Color = "Red"
            }

            Write-Host ("Database : {0}" -f $DatabaseName)
            Write-Host ("Status   : {0}" -f $Status) -ForegroundColor $Color
            Write-Host ("Copy Q   : {0}" -f $CopyQueue)
            Write-Host ("Replay Q : {0}" -f $ReplayQueue)
            Write-Host ""
        }

        Write-Host "+--------------------------------------------------------------+" -ForegroundColor DarkCyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve database replication status." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}