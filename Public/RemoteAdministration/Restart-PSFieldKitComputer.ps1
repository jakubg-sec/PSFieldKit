function Restart-PSFieldKitComputer {

    param(

        [Parameter(Mandatory)]

        [PSCustomObject]$Context

    )

    # Maximum time to wait for the remote power operation.
    $OperationTimeoutSeconds = 30

    if (-not $Context.IsRemote) {

        Write-Host "`nRemote computer power management requires a remote target." `
            -ForegroundColor Yellow

        return

    }

    if ($Context.Targets.Count -eq 0) {

        Write-Host "`nNo remote targets were found." `
            -ForegroundColor Yellow

        return

    }

    Write-Host "`nRemote Reboot / Shutdown" `
        -ForegroundColor Cyan

    Write-Host "-----------------------" `
        -ForegroundColor DarkCyan

    if ($Context.IsMultiTarget) {

        Write-Host "Targets: $($Context.Targets.Count)"

    }
    else {

        Write-Host "Target : $($Context.ComputerName)"

    }

    Write-Host "`nSelect operation:" `
        -ForegroundColor Cyan

    Write-Host "[1] Restart computer"

    Write-Host "[2] Shutdown computer"

    Write-Host "[0] Cancel"

    $Choice = Read-Host "`nSelect option"

    switch ($Choice) {

        '1' {

            $Action = 'Restart'

        }

        '2' {

            $Action = 'Shutdown'

        }

        '0' {

            return

        }

        default {

            Write-Host "`nInvalid option." `
                -ForegroundColor Red

            return

        }

    }

    Write-Host

    foreach ($Target in $Context.Targets) {

        Write-Host " - $($Target.ComputerName)" `
            -ForegroundColor Yellow

    }

    Write-Host

    if ($Context.IsMultiTarget) {

        $Confirmation = Read-Host "Type YES to $Action all listed computers"

    }
    else {

        $Confirmation = Read-Host "Type YES to $Action $($Context.ComputerName)"

    }

    if ($Confirmation -ne 'YES') {

        Write-Host "`nOperation cancelled." `
            -ForegroundColor Yellow

        return

    }

    foreach ($Target in $Context.Targets) {

        $Job = $null

        try {

            Write-Host "`n$($Action)ing $($Target.ComputerName)..." `
                -ForegroundColor Yellow

            if ($Action -eq 'Restart') {

                $Job = Restart-Computer `
                    -ComputerName $Target.ComputerName `
                    -Force `
                    -AsJob `
                    -Confirm:$false `
                    -ErrorAction Stop

            }
            else {

                $Job = Stop-Computer `
                    -ComputerName $Target.ComputerName `
                    -Force `
                    -AsJob `
                    -Confirm:$false `
                    -ErrorAction Stop

            }

            $CompletedJob = Wait-Job `
                -Job $Job `
                -Timeout $OperationTimeoutSeconds

            if ($null -eq $CompletedJob) {

                Write-Host "Timeout after $OperationTimeoutSeconds seconds." `
                    -ForegroundColor Red

                Write-Host "The $Action request may have been sent, but no response was received." `
                    -ForegroundColor Yellow

                Stop-Job `
                    -Job $Job `
                    -ErrorAction SilentlyContinue

                continue

            }

            if ($Job.State -eq 'Failed') {

                $JobError = $Job.ChildJobs |
                    ForEach-Object { $_.JobStateInfo.Reason } |
                    Where-Object { $_ } |
                    Select-Object -First 1

                if ($JobError) {

                    throw $JobError

                }
                else {

                    throw "$Action operation failed."

                }

            }

            Write-Host "$Action request sent successfully." `
                -ForegroundColor Green

        }
        catch {

            Write-Host "Failed to $($Action.ToLower()) $($Target.ComputerName)." `
                -ForegroundColor Red

            Write-Host $_.Exception.Message `
                -ForegroundColor Yellow
        }
        finally {

            if ($Job) {

                Remove-Job `
                    -Job $Job `
                    -Force `
                    -ErrorAction SilentlyContinue

            }

        }

    }

}

