function New-PSFieldKitContext {
    param(
        [Parameter()]
        [switch]$AllowMultipleTargets
    )

    while ($true) {
        Clear-Host
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              Select Target                   |" -ForegroundColor Cyan
        Write-Host "|              PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Local Computer                          |"
        Write-Host "|  [2] Remote Computer                         |"

        if ($AllowMultipleTargets) {
            Write-Host "|  [3] Multiple Computers                      |"
        }

        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                return [PSCustomObject]@{
                    ComputerName = $env:COMPUTERNAME
                    IsRemote = $false
                    Session = $null
                    Targets = @(
                        [PSCustomObject]@{
                            ComputerName = $env:COMPUTERNAME
                            IsRemote = $false
                        }
                    )
                    IsMultiTarget = $false
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

                return [PSCustomObject]@{
                    ComputerName = $ComputerName
                    IsRemote = $true
                    Session = $null
                    Targets = @(
                        [PSCustomObject]@{
                            ComputerName = $ComputerName
                            IsRemote = $true
                        }
                    )
                    IsMultiTarget = $false
                }
            }

            '3' {
                if (-not $AllowMultipleTargets) {
                    Write-Host "`nInvalid option." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                    continue
                }

                while ($true) {
                    Clear-Host
                    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
                    Write-Host "|             Multiple Computers               |" -ForegroundColor Cyan
                    Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
                    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
                    Write-Host "|                                              |"
                    Write-Host "|  [1] Computer List                           |"
                    Write-Host "|  [2] IPv4 Range                              |"
                    Write-Host "|  [3] IPv4 CIDR                               |"
                    Write-Host "|  [4] Text File                               |"
                    Write-Host "|                                              |"
                    Write-Host "|  [0] Back                                    |"
                    Write-Host "|                                              |"
                    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

                    $MultiChoice = Read-Host "`nSelect option"

                    switch ($MultiChoice) {
                        '1' {
                            $ComputerNames = Get-PSFieldKitTargets -Mode List
                        }

                        '2' {
                            $ComputerNames = Get-PSFieldKitTargets -Mode Range
                        }

                        '3' {
                            $ComputerNames = Get-PSFieldKitTargets -Mode CIDR
                        }

                        '4' {
                            $ComputerNames = Get-PSFieldKitTargets -Mode File
                        }

                        '0' {
                            break
                        }

                        default {
                            Write-Host "`nInvalid option." -ForegroundColor Red
                            Start-Sleep -Seconds 1
                            continue
                        }
                    }

                    if ($MultiChoice -eq '0') {
                        break
                    }

                    $ComputerNames = @($ComputerNames)

                    if ($ComputerNames.Count -eq 0) {
                        continue
                    }

                    Write-Host "`nTesting $($ComputerNames.Count) targets..." -ForegroundColor Cyan

                    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, 32)
                    $RunspacePool.Open()

                    $Jobs = New-Object System.Collections.ArrayList
                    $Targets = New-Object System.Collections.ArrayList

                    foreach ($ComputerName in $ComputerNames) {
                        $PowerShell = [powershell]::Create()
                        $PowerShell.RunspacePool = $RunspacePool

                        [void]$PowerShell.AddScript({
                            param($TargetName)

                            try {
                                Test-WSMan -ComputerName $TargetName -ErrorAction Stop | Out-Null

                                [PSCustomObject]@{
                                    ComputerName = $TargetName
                                    Reachable = $true
                                }
                            }
                            catch {
                                [PSCustomObject]@{
                                    ComputerName = $TargetName
                                    Reachable = $false
                                }
                            }
                        }).AddArgument($ComputerName)

                        $AsyncResult = $PowerShell.BeginInvoke()

                        [void]$Jobs.Add([PSCustomObject]@{
                            ComputerName = $ComputerName
                            PowerShell = $PowerShell
                            AsyncResult = $AsyncResult
                        })
                    }

                    while ($Jobs.Count -gt 0) {
                        foreach ($Job in @($Jobs)) {
                            if (-not $Job.AsyncResult.IsCompleted) {
                                continue
                            }

                            try {
                                $Result = $Job.PowerShell.EndInvoke($Job.AsyncResult)

                                foreach ($Item in $Result) {
                                    if ($Item.Reachable) {
                                        Write-Host "Connection successful: $($Item.ComputerName)" -ForegroundColor Green

                                        [void]$Targets.Add([PSCustomObject]@{
                                            ComputerName = $Item.ComputerName
                                            IsRemote = $true
                                        })
                                    }
                                    else {
                                        Write-Host "Unable to connect: $($Item.ComputerName)" -ForegroundColor Red
                                    }
                                }
                            }
                            catch {
                                Write-Host "Unable to test: $($Job.ComputerName)" -ForegroundColor Red
                            }
                            finally {
                                $Job.PowerShell.Dispose()
                                [void]$Jobs.Remove($Job)
                            }
                        }

                        if ($Jobs.Count -gt 0) {
                            Start-Sleep -Milliseconds 100
                        }
                    }

                    $RunspacePool.Close()
                    $RunspacePool.Dispose()

                    $Targets = @($Targets)

                    if ($Targets.Count -eq 0) {
                        Write-Host "`nNo reachable targets were found." -ForegroundColor Red
                        Read-Host "Press Enter to continue"
                        continue
                    }

                    Write-Host "`nReachable targets: $($Targets.Count)" -ForegroundColor Cyan
                    Read-Host "Press Enter to continue"

                    return [PSCustomObject]@{
                        ComputerName = $null
                        IsRemote = $true
                        Session = $null
                        Targets = $Targets
                        IsMultiTarget = $true
                    }
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