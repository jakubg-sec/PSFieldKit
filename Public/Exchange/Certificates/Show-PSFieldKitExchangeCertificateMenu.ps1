function Show-PSFieldKitExchangeCertificateMenu {
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
        Write-Host "|                 Certificates                 |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  CERTIFICATE MANAGEMENT                      |" -ForegroundColor DarkCyan
        Write-Host "|  [1] List Certificates                       |"
        Write-Host "|  [2] Certificate Information                 |"
        Write-Host "|  [3] Check Certificate Status                |"
        Write-Host "|  [4] Check Certificate Expiration            |"
        Write-Host "|  [5] Import Certificate                      |"
        Write-Host "|  [6] Export Certificate                      |"
        Write-Host "|  [7] Assign Certificate to Services          |"
        Write-Host "|  [8] Remove Certificate                      |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            "1" {
                Get-PSFieldKitExchangeCertificate -ExchangeContext $ExchangeContext
            }

            "2" {
                Show-PSFieldKitExchangeCertificateInformation -ExchangeContext $ExchangeContext
            }

            "3" {
                Test-PSFieldKitExchangeCertificate -ExchangeContext $ExchangeContext
            }

            "4" {
                Show-PSFieldKitExchangeCertificateExpiration -ExchangeContext $ExchangeContext
            }

            "5" {
                Import-PSFieldKitExchangeCertificate -ExchangeContext $ExchangeContext
            }

            "6" {
                Export-PSFieldKitExchangeCertificate -ExchangeContext $ExchangeContext
            }

            "7" {
                Enable-PSFieldKitExchangeCertificate -ExchangeContext $ExchangeContext
            }

            "8" {
                Remove-PSFieldKitExchangeCertificate -ExchangeContext $ExchangeContext
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