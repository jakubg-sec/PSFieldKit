function Test-ADTimeSynchronization {
    $Identity = Read-Host "Enter domain controller name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDomain controller name cannot be empty." -ForegroundColor Red
        return
    }

    try {
        $DC = Get-ADDomainController `
            -Identity $Identity `
            -ErrorAction Stop

        $Domain = Get-ADDomain `
            -ErrorAction Stop

        $HostName = $DC.HostName
        $PDCName = $Domain.PDCEmulator

        Write-Host "`nActive Directory Time Synchronization" -ForegroundColor Cyan
        Write-Host "-------------------------------------" -ForegroundColor DarkCyan
        Write-Host "Domain Controller : $HostName"
        Write-Host "Domain            : $($Domain.DNSRoot)"
        Write-Host "PDC Emulator      : $PDCName"
        Write-Host ""

        $Results = @()

        # 1. Windows Time Service
        try {
            $TimeService = Get-WmiObject `
                -Class Win32_Service `
                -ComputerName $HostName `
                -Filter "Name = 'W32Time'" `
                -ErrorAction Stop

            if ($TimeService.State -eq 'Running') {
                $Results += [PSCustomObject]@{
                    Test    = 'Windows Time Service'
                    Status  = 'PASS'
                    Details = "W32Time is $($TimeService.State)"
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    Test    = 'Windows Time Service'
                    Status  = 'FAIL'
                    Details = "W32Time is $($TimeService.State)"
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'Windows Time Service'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 2. Synchronization status
        try {
            $StatusOutput = & w32tm.exe `
                /query `
                /status `
                "/computer:$HostName" 2>&1

            $StatusExitCode = $LASTEXITCODE
            $StatusText = ($StatusOutput | Out-String).Trim()

            if ($StatusExitCode -eq 0) {
                $Results += [PSCustomObject]@{
                    Test    = 'Synchronization Status'
                    Status  = 'PASS'
                    Details = 'W32Time status query succeeded'
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    Test    = 'Synchronization Status'
                    Status  = 'FAIL'
                    Details = if ($StatusText) {
                        $StatusText
                    }
                    else {
                        "w32tm exited with code $StatusExitCode"
                    }
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'Synchronization Status'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 3. Time source
        try {
            $SourceOutput = & w32tm.exe `
                /query `
                /source `
                "/computer:$HostName" 2>&1

            $SourceExitCode = $LASTEXITCODE
            $Source = ($SourceOutput | Out-String).Trim()

            if ($SourceExitCode -eq 0 -and $Source) {
                $Results += [PSCustomObject]@{
                    Test    = 'Time Source'
                    Status  = 'PASS'
                    Details = $Source
                }
            }
            else {
                $Results += [PSCustomObject]@{
                    Test    = 'Time Source'
                    Status  = 'FAIL'
                    Details = if ($Source) {
                        $Source
                    }
                    else {
                        'Unable to determine time source'
                    }
                }
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'Time Source'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # 4. AD Time Hierarchy
        if ($HostName -ieq $PDCName) {
            $HierarchyDetails = 'This DC is the PDC Emulator'
        }
        else {
            $HierarchyDetails = "Expected time authority: $PDCName"
        }

        $Results += [PSCustomObject]@{
            Test    = 'AD Time Hierarchy'
            Status  = 'PASS'
            Details = $HierarchyDetails
        }

        # 5. Current time comparison
        try {
            $RemoteTimeData = Get-WmiObject `
                -Class Win32_LocalTime `
                -ComputerName $HostName `
                -ErrorAction Stop

            $PDCTimeData = Get-WmiObject `
                -Class Win32_LocalTime `
                -ComputerName $PDCName `
                -ErrorAction Stop

            $RemoteTime = Get-Date `
                -Year $RemoteTimeData.Year `
                -Month $RemoteTimeData.Month `
                -Day $RemoteTimeData.Day `
                -Hour $RemoteTimeData.Hour `
                -Minute $RemoteTimeData.Minute `
                -Second $RemoteTimeData.Second

            $PDCTime = Get-Date `
                -Year $PDCTimeData.Year `
                -Month $PDCTimeData.Month `
                -Day $PDCTimeData.Day `
                -Hour $PDCTimeData.Hour `
                -Minute $PDCTimeData.Minute `
                -Second $PDCTimeData.Second

            $DifferenceSeconds = [math]::Abs(
                ($RemoteTime - $PDCTime).TotalSeconds
            )

            if ($DifferenceSeconds -le 5) {
                $TimeStatus = 'PASS'
            }
            elseif ($DifferenceSeconds -le 30) {
                $TimeStatus = 'WARN'
            }
            else {
                $TimeStatus = 'FAIL'
            }

            $Results += [PSCustomObject]@{
                Test    = 'Time Difference'
                Status  = $TimeStatus
                Details = "{0:N2} seconds (DC vs PDC)" -f $DifferenceSeconds
            }
        }
        catch {
            $Results += [PSCustomObject]@{
                Test    = 'Time Difference'
                Status  = 'WARN'
                Details = $_.Exception.Message
            }
        }

        Write-Host "`nTime Synchronization Results" -ForegroundColor Cyan
        Write-Host "----------------------------" -ForegroundColor DarkCyan

        $Results |
            Format-Table `
                Test,
                Status,
                Details `
                -Wrap `
                -AutoSize

        $Failed = @(
            $Results |
            Where-Object {
                $_.Status -eq 'FAIL'
            }
        )

        $Warnings = @(
            $Results |
            Where-Object {
                $_.Status -eq 'WARN'
            }
        )

        Write-Host ""

        if ($Failed) {
            Write-Host "Time synchronization problems detected." -ForegroundColor Red
        }
        elseif ($Warnings) {
            Write-Host "Time synchronization test completed with warnings." -ForegroundColor Yellow
        }
        else {
            Write-Host "Time synchronization test passed." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`nFailed to test time synchronization." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}