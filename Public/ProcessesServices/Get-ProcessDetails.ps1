function Get-ProcessDetails {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ProcessId = Read-Host "Enter process ID"

    if (-not [int]::TryParse($ProcessId, [ref]$ProcessId)) {
        Write-Host "`nInvalid process ID." -ForegroundColor Red
        return
    }

    try {
        if ($Context.IsRemote) {
            $Session = New-CimSession `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop

            try {
                $Process = Get-CimInstance `
                    -ClassName Win32_Process `
                    -CimSession $Session `
                    -Filter "ProcessId = $ProcessId" `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Process = Get-CimInstance `
                -ClassName Win32_Process `
                -Filter "ProcessId = $ProcessId" `
                -ErrorAction Stop
        }

        if ($null -eq $Process) {
            Write-Host "`nProcess with PID $ProcessId was not found on $($Context.ComputerName)." `
                -ForegroundColor Red
            return
        }

        $MemoryMB = [math]::Round(
            $Process.WorkingSetSize / 1MB,
            2
        )

        Write-Host "`nProcess Details" -ForegroundColor Cyan
        Write-Host "---------------" -ForegroundColor DarkCyan

        Write-Host "Target           : $($Context.ComputerName)"
        Write-Host "Name             : $($Process.Name)"
        Write-Host "Process ID       : $($Process.ProcessId)"
        Write-Host "Parent Process ID: $($Process.ParentProcessId)"
        Write-Host "Memory           : $MemoryMB MB"
        Write-Host "Threads          : $($Process.ThreadCount)"
        Write-Host "Handles          : $($Process.HandleCount)"
        Write-Host "Priority         : $($Process.Priority)"
        Write-Host "Executable Path  : $($Process.ExecutablePath)"
        Write-Host "Command Line     : $($Process.CommandLine)"
        Write-Host "Creation Date    : $($Process.CreationDate)"
    }
    catch {
        Write-Host "`nFailed to retrieve process details from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}