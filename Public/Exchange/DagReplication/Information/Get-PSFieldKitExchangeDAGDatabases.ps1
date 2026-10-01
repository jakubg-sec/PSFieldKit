function Get-PSFieldKitExchangeDAGDatabases {
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

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                DAG DATABASES                 |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    try {
        $DAGs = @(Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop)

        if ($DAGs.Count -eq 0) {
            Write-Host "No Database Availability Groups found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        foreach ($DAG in $DAGs) {
            Write-Host "DAG: $($DAG.Name)" -ForegroundColor DarkCyan
            Write-Host ""

            $Members = @($DAG.Servers)

            if ($Members.Count -eq 0) {
                Write-Host "  No DAG members found." -ForegroundColor Yellow
                Write-Host ""
                continue
            }

            $Copies = @()

            foreach ($Member in $Members) {
                try {
                    $MemberCopies = @(Get-MailboxDatabaseCopyStatus -Server $Member.Name -ErrorAction Stop)
                    $Copies += $MemberCopies
                }
                catch {
                    Write-Host "  Failed to retrieve database copies from $($Member.Name)." -ForegroundColor Yellow
                }
            }

            if ($Copies.Count -eq 0) {
                Write-Host "  No database copies found." -ForegroundColor Yellow
                Write-Host ""
                continue
            }

            $UniqueCopies = $Copies |
                Group-Object {
                    "{0}\{1}" -f $_.Name, $_.MailboxServer
                } |
                ForEach-Object {
                    $_.Group[0]
                }

            Write-Host ("  {0,-25} {1,-25} {2,-15}" -f "Database", "Server", "Status") -ForegroundColor DarkCyan
            Write-Host ("  {0,-25} {1,-25} {2,-15}" -f "--------", "------", "------") -ForegroundColor DarkGray

            foreach ($Copy in $UniqueCopies) {
                $DatabaseName = [string]$Copy.Name
                $ServerName = [string]$Copy.MailboxServer
                $Status = [string]$Copy.Status

                if ([string]::IsNullOrWhiteSpace($DatabaseName)) {
                    $DatabaseName = "Unknown"
                }

                if ([string]::IsNullOrWhiteSpace($ServerName)) {
                    $ServerName = "Unknown"
                }

                if ([string]::IsNullOrWhiteSpace($Status)) {
                    $Status = "Unknown"
                }

                switch ($Status) {
                    "Mounted" {
                        $Color = "Green"
                    }

                    "Healthy" {
                        $Color = "Green"
                    }

                    "DisconnectedAndHealthy" {
                        $Color = "Yellow"
                    }

                    default {
                        $Color = "Red"
                    }
                }

                Write-Host ("  {0,-25} {1,-25} {2,-15}" -f $DatabaseName, $ServerName, $Status) -ForegroundColor $Color
            }

            Write-Host ""
        }
    }
    catch {
        Write-Host "Failed to retrieve DAG database information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}