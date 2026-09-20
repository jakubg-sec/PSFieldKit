function Get-PersistenceAudit {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ScriptBlock = {

        $Findings = @()

        #
        # Startup Commands
        #

        try {

            $StartupCommands = Get-CimInstance `
                -ClassName Win32_StartupCommand `
                -ErrorAction Stop

            foreach ($StartupCommand in $StartupCommands) {

                $Findings += [PSCustomObject]@{
                    Type     = 'Startup'
                    Name     = $StartupCommand.Name
                    User     = $StartupCommand.User
                    Location = $StartupCommand.Location
                    Command  = $StartupCommand.Command
                }
            }
        }
        catch {
            # Startup command enumeration failed.
        }

        #
        # Scheduled Tasks
        #

        try {

            $ScheduledTasks = Get-ScheduledTask `
                -ErrorAction Stop |
                Where-Object {
                    $_.State -ne 'Disabled'
                }

            foreach ($Task in $ScheduledTasks) {

                foreach ($Action in $Task.Actions) {

                    $Execute = $Action.Execute
                    $Arguments = $Action.Arguments

                    $Command = if (
                        [string]::IsNullOrWhiteSpace($Arguments)
                    ) {
                        $Execute
                    }
                    else {
                        "$Execute $Arguments"
                    }

                    $User = ''

                    if ($Task.Principal) {
                        $User = $Task.Principal.UserId
                    }

                    $Findings += [PSCustomObject]@{
                        Type     = 'Scheduled Task'
                        Name     = $Task.TaskPath + $Task.TaskName
                        User     = $User
                        Location = $Task.TaskPath
                        Command  = $Command
                    }
                }
            }
        }
        catch {
            # Scheduled task enumeration failed.
        }

        #
        # Auto-Start Services
        #

        try {

            $Services = Get-CimInstance `
                -ClassName Win32_Service `
                -Filter "StartMode = 'Auto' OR StartMode = 'Boot' OR StartMode = 'System'" `
                -ErrorAction Stop

            foreach ($Service in $Services) {

                $Findings += [PSCustomObject]@{
                    Type     = 'Auto-Start Service'
                    Name     = $Service.Name
                    User     = $Service.StartName
                    Location = $Service.PathName
                    Command  = $Service.PathName
                }
            }
        }
        catch {
            # Service enumeration failed.
        }

        #
        # WMI Persistence
        #

        try {

            $EventFilters = @(
                Get-CimInstance `
                    -Namespace 'root\subscription' `
                    -ClassName __EventFilter `
                    -ErrorAction Stop
            )

            $Consumers = @(
                Get-CimInstance `
                    -Namespace 'root\subscription' `
                    -ClassName __FilterToConsumerBinding `
                    -ErrorAction Stop
            )

            foreach ($Filter in $EventFilters) {

                $Bindings = @(
                    $Consumers |
                    Where-Object {
                        $_.Filter -match [regex]::Escape($Filter.Name)
                    }
                )

                if ($Bindings.Count -eq 0) {

                    $Findings += [PSCustomObject]@{
                        Type     = 'WMI Event Filter'
                        Name     = $Filter.Name
                        User     = ''
                        Location = 'root\subscription'
                        Command  = $Filter.Query
                    }
                }
                else {

                    foreach ($Binding in $Bindings) {

                        $Findings += [PSCustomObject]@{
                            Type     = 'WMI Event Subscription'
                            Name     = $Filter.Name
                            User     = ''
                            Location = 'root\subscription'
                            Command  = "$($Filter.Query) -> $($Binding.Consumer)"
                        }
                    }
                }
            }
        }
        catch {
            # WMI persistence enumeration failed.
        }

        return @($Findings)
    }

    try {

        Write-Host "`nPersistence & Autoruns Audit" -ForegroundColor Cyan
        Write-Host "----------------------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {

            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {

                if ($Target.IsRemote) {

                    $Findings = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ErrorAction Stop
                }
                else {

                    $Findings = & $ScriptBlock
                }

                $Findings = @($Findings)

                if ($Findings.Count -eq 0) {

                    Write-Host "`nNo persistence mechanisms were found." `
                        -ForegroundColor Green

                    continue
                }

                #
                # Summary
                #

                $StartupCount = @(
                    $Findings |
                    Where-Object {
                        $_.Type -eq 'Startup'
                    }
                ).Count

                $TaskCount = @(
                    $Findings |
                    Where-Object {
                        $_.Type -eq 'Scheduled Task'
                    }
                ).Count

                $ServiceCount = @(
                    $Findings |
                    Where-Object {
                        $_.Type -eq 'Auto-Start Service'
                    }
                ).Count

                $WmiCount = @(
                    $Findings |
                    Where-Object {
                        $_.Type -like 'WMI*'
                    }
                ).Count

                Write-Host "`nPersistence Summary" -ForegroundColor Cyan
                Write-Host "-------------------" -ForegroundColor DarkCyan

                Write-Host "Startup Entries        : $StartupCount"
                Write-Host "Scheduled Tasks        : $TaskCount"
                Write-Host "Auto-Start Services    : $ServiceCount"
                Write-Host "WMI Persistence        : $WmiCount"

                #
                # Startup Entries
                #

                if ($StartupCount -gt 0) {

                    Write-Host "`nStartup Entries" -ForegroundColor Cyan
                    Write-Host "---------------" -ForegroundColor DarkCyan

                    $Findings |
                        Where-Object {
                            $_.Type -eq 'Startup'
                        } |
                        Select-Object `
                            Name,
                            User,
                            Location,
                            Command |
                        Sort-Object Name |
                        Format-Table -Wrap -AutoSize
                }

                #
                # Scheduled Tasks
                #

                if ($TaskCount -gt 0) {

                    Write-Host "`nScheduled Tasks" -ForegroundColor Cyan
                    Write-Host "---------------" -ForegroundColor DarkCyan

                    $Findings |
                        Where-Object {
                            $_.Type -eq 'Scheduled Task'
                        } |
                        Select-Object `
                            Name,
                            User,
                            Command |
                        Sort-Object Name |
                        Format-Table -Wrap -AutoSize
                }

                #
                # Auto-Start Services
                #

                if ($ServiceCount -gt 0) {

                    Write-Host "`nAuto-Start Services" -ForegroundColor Cyan
                    Write-Host "-------------------" -ForegroundColor DarkCyan

                    $Findings |
                        Where-Object {
                            $_.Type -eq 'Auto-Start Service'
                        } |
                        Select-Object `
                            Name,
                            User,
                            Command |
                        Sort-Object Name |
                        Format-Table -Wrap -AutoSize
                }

                #
                # WMI Persistence
                #

                if ($WmiCount -gt 0) {

                    Write-Host "`nWMI Persistence" -ForegroundColor Cyan
                    Write-Host "---------------" -ForegroundColor DarkCyan

                    $Findings |
                        Where-Object {
                            $_.Type -like 'WMI*'
                        } |
                        Select-Object `
                            Type,
                            Name,
                            Location,
                            Command |
                        Format-Table -Wrap -AutoSize
                }
            }
            catch {

                Write-Host "Failed to retrieve persistence information." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {

        Write-Host "`nFailed to perform persistence audit." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}