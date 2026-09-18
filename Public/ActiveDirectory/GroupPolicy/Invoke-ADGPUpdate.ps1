function Invoke-ADGPUpdate {

    $ComputerName = Read-Host "Enter computer name"

    if ([string]::IsNullOrWhiteSpace($ComputerName)) {

        Write-Host "`nComputer name cannot be empty." `
            -ForegroundColor Red

        return
    }

    Write-Host "`nSelect target"
    Write-Host "[1] Computer"
    Write-Host "[2] User"
    Write-Host "[3] Both"

    $TargetChoice = Read-Host "`nSelect option"

    try {

        switch ($TargetChoice) {

            '1' {

                $Target = 'Computer'
            }

            '2' {

                $Target = 'User'
            }

            '3' {

                $Target = $null
            }

            default {

                Write-Host "`nInvalid option." `
                    -ForegroundColor Red

                return
            }
        }

        Write-Host "`nStarting Group Policy update on $ComputerName..." `
            -ForegroundColor Yellow

        $Parameters = @{
            Computer             = $ComputerName
            Force                = $true
            RandomDelayInMinutes = 0
            ErrorAction          = 'Stop'
        }

        if ($Target) {

            $Parameters.Target = $Target
        }

        Invoke-GPUpdate @Parameters

        Write-Host "`nGroup Policy update scheduled successfully." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "`nFailed to trigger Group Policy update." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}