function New-PSFieldKitContext {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              Select Target                   |" -ForegroundColor Cyan
        Write-Host "|              PSFieldKit                      |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Local Computer                          |"
        Write-Host "|  [2] Remote Computer                         |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {

                return [PSCustomObject]@{
                    ComputerName = $env:COMPUTERNAME
                    IsRemote     = $false
                    Session      = $null
                }
            }

            '2' {

                $ComputerName = Read-Host "Enter computer name or IP"

                if ([string]::IsNullOrWhiteSpace($ComputerName)) {

                    Write-Host "`nComputer name cannot be empty." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                    continue
                }

                Write-Host "`nTesting connection to $ComputerName..." -ForegroundColor Yellow

                if (-not (Test-PSFieldKitTarget -ComputerName $ComputerName)) {

                    Write-Host "Unable to connect to $ComputerName." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    continue
                }

                Write-Host "Connection successful." -ForegroundColor Green
                Start-Sleep -Seconds 1

                return [PSCustomObject]@{
                    ComputerName = $ComputerName
                    IsRemote     = $true
                    Session      = $null
                }
            }

            '0' {

                return $null
            }

            default {

                Write-Host "`nInvalid option." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}