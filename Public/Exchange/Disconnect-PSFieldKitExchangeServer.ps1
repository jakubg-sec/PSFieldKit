function Disconnect-PSFieldKitExchangeServer {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]$ExchangeContext
    )

    $DisconnectSuccessful = $true

    if (
        $ExchangeContext.PSObject.Properties.Name -contains "ImportedModule" -and
        $null -ne $ExchangeContext.ImportedModule
    ) {

        foreach ($Module in @($ExchangeContext.ImportedModule)) {

            if ($null -eq $Module) {
                continue
            }

            try {

                Remove-Module `
                    -ModuleInfo $Module `
                    -Force `
                    -ErrorAction Stop
            }
            catch {

                Write-Host ""
                Write-Host "Failed to remove Exchange proxy module." -ForegroundColor Yellow
                Write-Host $_.Exception.Message -ForegroundColor Yellow

                $DisconnectSuccessful = $false
            }
        }
    }

    if (
        $ExchangeContext.PSObject.Properties.Name -contains "Session" -and
        $null -ne $ExchangeContext.Session
    ) {

        try {

            Remove-PSSession `
                -Session $ExchangeContext.Session `
                -ErrorAction Stop
        }
        catch {

            Write-Host ""
            Write-Host "Failed to close Exchange PowerShell session." -ForegroundColor Yellow
            Write-Host $_.Exception.Message -ForegroundColor Yellow

            $DisconnectSuccessful = $false
        }
    }

    if ($DisconnectSuccessful) {

        Write-Host ""
        Write-Host "Exchange session closed successfully." -ForegroundColor Green
    }

    return $DisconnectSuccessful
}