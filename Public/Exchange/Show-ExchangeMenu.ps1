function Show-ExchangeMenu {

    $ExchangeContext = $null

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              Exchange Management             |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"

        if ($null -eq $ExchangeContext) {

            Write-Host ("|  Server : {0,-35}|" -f "Not connected") -ForegroundColor Yellow
            Write-Host ("|  Status : {0,-35}|" -f "Disconnected") -ForegroundColor Red
        }
        else {

            $ServerName = "Unknown"
            $Status = "Disconnected"

            if (
                $ExchangeContext.PSObject.Properties.Name -contains "ServerName" -and
                -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
            ) {

                $ServerName = [string]$ExchangeContext.ServerName
            }

            if (
                $ExchangeContext.PSObject.Properties.Name -contains "Connected" -and
                $ExchangeContext.Connected
            ) {

                $Status = "Connected"
            }

            if ($ServerName.Length -gt 35) {

                $ServerName = $ServerName.Substring(0, 32) + "..."
            }

            $StatusColor = "Red"

            if ($Status -eq "Connected") {

                $StatusColor = "Green"
            }

            Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
            Write-Host ("|  Status : {0,-35}|" -f $Status) -ForegroundColor $StatusColor
        }

        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  CONNECTION                                  |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Connect to Exchange Server              |"
        Write-Host "|  [2] Disconnect from Exchange Server         |"
        Write-Host "|                                              |"
        Write-Host "|  SERVER                                      |" -ForegroundColor DarkCyan
        Write-Host "|  [3] Server Information                      |"
        Write-Host "|                                              |"
        Write-Host "|  MANAGEMENT                                  |" -ForegroundColor DarkCyan
        Write-Host "|  [4] Mailbox Management                      |"
        Write-Host "|  [5] Shared Mailboxes                        |"
        Write-Host "|  [6] Distribution Groups                     |"
        Write-Host "|  [7] Mailbox Databases                       |"
        Write-Host "|  [8] Mail Flow                               |"
        Write-Host "|  [9] DAG & Replication                       |"
        Write-Host "|                                              |"
        Write-Host "|  SECURITY & HEALTH                           |" -ForegroundColor DarkCyan
        Write-Host "| [10] Certificates                            |"
        Write-Host "| [11] Exchange Health                         |"
        Write-Host "| [12] Diagnostics                             |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            "1" {

                if ($null -ne $ExchangeContext) {

                    if (
                        $ExchangeContext.PSObject.Properties.Name -contains "Session" -and
                        $null -ne $ExchangeContext.Session
                    ) {

                        Write-Host ""
                        Write-Host "An Exchange session is already active." -ForegroundColor Yellow
                        Write-Host "Disconnecting the existing session..." -ForegroundColor Yellow

                        Disconnect-PSFieldKitExchangeServer -ExchangeContext $ExchangeContext | Out-Null
                    }

                    $ExchangeContext = $null
                }

                Write-Host ""

                $ServerFQDN = Read-Host "Enter Exchange Server FQDN"

                if ([string]::IsNullOrWhiteSpace($ServerFQDN)) {

                    Write-Host ""
                    Write-Host "Exchange Server FQDN cannot be empty." -ForegroundColor Red

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                $ExchangeContext = Connect-PSFieldKitExchangeServer -ServerFQDN $ServerFQDN

                if ($null -eq $ExchangeContext) {

                    Read-Host "`nPress Enter to continue" | Out-Null
                }
            }

            "2" {

                if ($null -eq $ExchangeContext) {

                    Write-Host ""
                    Write-Host "No Exchange session is currently active." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                $Disconnected = Disconnect-PSFieldKitExchangeServer -ExchangeContext $ExchangeContext

                if ($Disconnected) {

                    $ExchangeContext = $null
                }

                Read-Host "`nPress Enter to continue" | Out-Null
            }

            "3" {

                if ($null -eq $ExchangeContext) {

                    Write-Host ""
                    Write-Host "Connect to an Exchange server first." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                if (
                    $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
                    -not $ExchangeContext.Connected
                ) {

                    Write-Host ""
                    Write-Host "The Exchange session is not connected." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                Show-PSFieldKitExchangeServerInformation -ExchangeContext $ExchangeContext
            }

            "4" {

                if ($null -eq $ExchangeContext) {

                    Write-Host ""
                    Write-Host "Connect to an Exchange server first." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                if (
                    $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
                    -not $ExchangeContext.Connected
                ) {

                    Write-Host ""
                    Write-Host "The Exchange session is not connected." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                Show-PSFieldKitExchangeMailboxMenu -ExchangeContext $ExchangeContext
            }

            "5" {

                if ($null -eq $ExchangeContext) {

                    Write-Host ""
                    Write-Host "Connect to an Exchange server first." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                if (
                    $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
                    -not $ExchangeContext.Connected
                ) {

                    Write-Host ""
                    Write-Host "The Exchange session is not connected." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                Show-PSFieldKitExchangeSharedMailboxMenu -ExchangeContext $ExchangeContext
            }

            "6" {

                if ($null -eq $ExchangeContext) {

                    Write-Host ""
                    Write-Host "Connect to an Exchange server first." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                if (
                    $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
                    -not $ExchangeContext.Connected
                ) {

                    Write-Host ""
                    Write-Host "The Exchange session is not connected." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                Show-PSFieldKitExchangeDistributionGroupMenu -ExchangeContext $ExchangeContext
            }

            "7" {

                if ($null -eq $ExchangeContext) {

                    Write-Host ""
                    Write-Host "Connect to an Exchange server first." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                if (
                    $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
                    -not $ExchangeContext.Connected
                ) {

                    Write-Host ""
                    Write-Host "The Exchange session is not connected." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                Show-PSFieldKitExchangeDatabaseMenu -ExchangeContext $ExchangeContext
            }

            "8" {

                if ($null -eq $ExchangeContext) {

                    Write-Host ""
                    Write-Host "Connect to an Exchange server first." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                if (
                    $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
                    -not $ExchangeContext.Connected
                ) {

                    Write-Host ""
                    Write-Host "The Exchange session is not connected." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                Show-PSFieldKitExchangeMailFlowMenu -ExchangeContext $ExchangeContext
            }

            "9" {

                if ($null -eq $ExchangeContext) {

                    Write-Host ""
                    Write-Host "Connect to an Exchange server first." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                if (
                    $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
                    -not $ExchangeContext.Connected
                ) {

                    Write-Host ""
                    Write-Host "The Exchange session is not connected." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                Show-PSFieldKitExchangeDAGMenu -ExchangeContext $ExchangeContext
            }

            "10" {

                if ($null -eq $ExchangeContext) {

                    Write-Host ""
                    Write-Host "Connect to an Exchange server first." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                if (
                    $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
                    -not $ExchangeContext.Connected
                ) {

                    Write-Host ""
                    Write-Host "The Exchange session is not connected." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                Show-PSFieldKitExchangeCertificateMenu -ExchangeContext $ExchangeContext
            }

            "11" {

                if ($null -eq $ExchangeContext) {

                    Write-Host ""
                    Write-Host "Connect to an Exchange server first." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                if (
                    $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
                    -not $ExchangeContext.Connected
                ) {

                    Write-Host ""
                    Write-Host "The Exchange session is not connected." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                Show-PSFieldKitExchangeHealthMenu -ExchangeContext $ExchangeContext
            }

            "12" {

                if ($null -eq $ExchangeContext) {

                    Write-Host ""
                    Write-Host "Connect to an Exchange server first." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                if (
                    $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
                    -not $ExchangeContext.Connected
                ) {

                    Write-Host ""
                    Write-Host "The Exchange session is not connected." -ForegroundColor Yellow

                    Read-Host "`nPress Enter to continue" | Out-Null

                    continue
                }

                Show-PSFieldKitExchangeDiagnosticsMenu -ExchangeContext $ExchangeContext
            }

            "0" {

                if ($null -ne $ExchangeContext) {

                    Disconnect-PSFieldKitExchangeServer -ExchangeContext $ExchangeContext | Out-Null

                    $ExchangeContext = $null
                }

                return
            }

            default {

                Write-Host ""
                Write-Host "Invalid option." -ForegroundColor Red

                Start-Sleep -Seconds 1
            }
        }
    }
}