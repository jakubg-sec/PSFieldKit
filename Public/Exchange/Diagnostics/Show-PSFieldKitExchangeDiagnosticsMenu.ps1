function Show-PSFieldKitExchangeDiagnosticsMenu {
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

    while ($true) {
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
        Write-Host "|              Exchange Diagnostics            |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  CONNECTIVITY TESTS                          |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Test PowerShell Connectivity            |"
        Write-Host "|  [2] Test Mail Flow                          |"
        Write-Host "|  [3] Test MAPI Connectivity                  |"
        Write-Host "|  [4] Test Outlook Connectivity               |"
        Write-Host "|  [5] Test OWA Connectivity                   |"
        Write-Host "|  [6] Test ECP Connectivity                   |"
        Write-Host "|  [7] Test ActiveSync Connectivity            |"
        Write-Host "|  [8] Test Web Services Connectivity          |"
        Write-Host "|  [9] Test SMTP Connectivity                  |"
        Write-Host "|                                              |"
        Write-Host "|  EXCHANGE DIAGNOSTICS                        |" -ForegroundColor DarkCyan
        Write-Host "| [10] Exchange Search Test                    |"
        Write-Host "| [11] MRS Health Test                         |"
        Write-Host "| [12] Service Health Test                     |"
        Write-Host "| [13] Federation Test                         |"
        Write-Host "| [14] OAuth Connectivity Test                 |"
        Write-Host "| [15] Exchange Event Log Analysis             |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Test-PSFieldKitExchangePowerShellConnectivity -ExchangeContext $ExchangeContext
            }

            "2" {
                Test-PSFieldKitExchangeMailFlow -ExchangeContext $ExchangeContext
            }

            "3" {
                Test-PSFieldKitExchangeMAPIConnectivity -ExchangeContext $ExchangeContext
            }

            "4" {
                Test-PSFieldKitExchangeOutlookConnectivity -ExchangeContext $ExchangeContext
            }

            "5" {
                Test-PSFieldKitExchangeOWAConnectivity -ExchangeContext $ExchangeContext
            }

            "6" {
                Test-PSFieldKitExchangeECPConnectivity -ExchangeContext $ExchangeContext
            }

            "7" {
                Test-PSFieldKitExchangeActiveSyncConnectivity -ExchangeContext $ExchangeContext
            }

            "8" {
                Test-PSFieldKitExchangeWebServicesConnectivity -ExchangeContext $ExchangeContext
            }

            "9" {
                Test-PSFieldKitExchangeSMTPConnectivity -ExchangeContext $ExchangeContext
            }

            "10" {
                Test-PSFieldKitExchangeSearch -ExchangeContext $ExchangeContext
            }

            "11" {
                Test-PSFieldKitExchangeMRSHealth -ExchangeContext $ExchangeContext
            }

            "12" {
                Test-PSFieldKitExchangeServiceHealth -ExchangeContext $ExchangeContext
            }

            "13" {
                Test-PSFieldKitExchangeFederation -ExchangeContext $ExchangeContext
            }

            "14" {
                Test-PSFieldKitExchangeOAuthConnectivity -ExchangeContext $ExchangeContext
            }

            "15" {
                Show-PSFieldKitExchangeEventLogDiagnostics -ExchangeContext $ExchangeContext
            }

            "0" {
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