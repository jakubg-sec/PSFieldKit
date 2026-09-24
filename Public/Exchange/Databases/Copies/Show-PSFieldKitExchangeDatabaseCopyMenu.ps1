function Show-PSFieldKitExchangeDatabaseCopyMenu {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext

    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    while ($true) {
        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              Database Copies                 |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  INFORMATION                                 |" -ForegroundColor DarkCyan
        Write-Host "|  [1] Show Database Copies                    |"
        Write-Host "|  [2] Show Copy Status                        |"
        Write-Host "|                                              |"
        Write-Host "|  COPY MANAGEMENT                             |" -ForegroundColor DarkCyan
        Write-Host "|  [3] Add Database Copy                       |"
        Write-Host "|  [4] Remove Database Copy                    |"
        Write-Host "|                                              |"
        Write-Host "|  REPLICATION                                 |" -ForegroundColor DarkCyan
        Write-Host "|  [5] Suspend Database Copy                   |"
        Write-Host "|  [6] Resume Database Copy                    |"
        Write-Host "|  [7] Update / Seed Database Copy             |"
        Write-Host "|                                              |"
        Write-Host "|  ACTIVATION                                  |" -ForegroundColor DarkCyan
        Write-Host "|  [8] Activate Database Copy                  |"
        Write-Host "|  [9] Set Activation Preference               |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            '2' {
                Show-PSFieldKitExchangeDatabaseCopyStatus -ExchangeContext $ExchangeContext
            }

            '3' {
                Add-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            '4' {
                Remove-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            '5' {
                Suspend-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            '6' {
                Resume-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            '7' {
                Update-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            '8' {
                Move-PSFieldKitExchangeDatabaseCopy -ExchangeContext $ExchangeContext
            }

            '9' {
                Set-PSFieldKitExchangeDatabaseCopyActivationPreference -ExchangeContext $ExchangeContext
            }

            '0' {
                return
            }

            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}