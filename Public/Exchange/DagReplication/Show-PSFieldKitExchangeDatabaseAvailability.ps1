function Show-PSFieldKitExchangeDatabaseAvailability {
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

    Write-Host "+--------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|               DATABASE AVAILABILITY              |" -ForegroundColor Cyan
    Write-Host "|                     PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+--------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    try {
        $DatabaseCopies = @(
            Get-MailboxDatabaseCopyStatus -ErrorAction Stop
        )

        if ($DatabaseCopies.Count -eq 0) {
            Write-Host "No database copies were found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $Results = foreach ($Copy in $DatabaseCopies) {
            $Status = [string]$Copy.Status

            $Availability = switch ($Status) {
                "Mounted" {
                    "Available"
                }

                "Healthy" {
                    "Available"
                }

                "DisconnectedAndHealthy" {
                    "Degraded"
                }

                default {
                    "Unavailable"
                }
            }

            $Color = switch ($Availability) {
                "Available" {
                    "Green"
                }

                "Degraded" {
                    "Yellow"
                }

                default {
                    "Red"
                }
            }

            [PSCustomObject]@{
                Database     = $Copy.Name
                Server       = $Copy.MailboxServer
                Status       = $Status
                Availability = $Availability
                CopyQueue    = $Copy.CopyQueueLength
                ReplayQueue  = $Copy.ReplayQueueLength
                Color        = $Color
            }
        }

        foreach ($Result in $Results) {
            Write-Host ("Database : {0}" -f $Result.Database)
            Write-Host ("Server   : {0}" -f $Result.Server)
            Write-Host ("Status   : {0}" -f $Result.Status)

            Write-Host "Available: $($Result.Availability)" `
                -ForegroundColor $Result.Color

            Write-Host ("Copy Q   : {0}" -f $Result.CopyQueue)
            Write-Host ("Replay Q : {0}" -f $Result.ReplayQueue)
            Write-Host ""
        }

        Write-Host "Summary:" -ForegroundColor Cyan
        Write-Host ""

        $Results |
            Group-Object Availability |
            Select-Object `
                @{Name = "Availability"; Expression = { $_.Name } },
                Count |
            Format-Table -AutoSize
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve database availability." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}