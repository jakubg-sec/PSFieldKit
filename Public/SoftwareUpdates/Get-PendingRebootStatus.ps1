function Get-PendingRebootStatus {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ScriptBlock = {
        $CBSRebootPending = Test-Path `
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'

        $WindowsUpdateRebootRequired = Test-Path `
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'

        $PendingFileRenameOperations = $false

        $PendingFileRenameValue = Get-ItemProperty `
            -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' `
            -Name 'PendingFileRenameOperations' `
            -ErrorAction SilentlyContinue

        if (
            $null -ne $PendingFileRenameValue.PendingFileRenameOperations -and
            $PendingFileRenameValue.PendingFileRenameOperations.Count -gt 0
        ) {
            $PendingFileRenameOperations = $true
        }

        $ComputerName = Get-ItemProperty `
            -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' `
            -Name 'ComputerName' `
            -ErrorAction SilentlyContinue

        $ActiveComputerName = Get-ItemProperty `
            -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' `
            -Name 'ComputerName' `
            -ErrorAction SilentlyContinue

        $ComputerRenamePending = $false

        if (
            $null -ne $ComputerName.ComputerName -and
            $null -ne $ActiveComputerName.ComputerName -and
            $ComputerName.ComputerName -ne $ActiveComputerName.ComputerName
        ) {
            $ComputerRenamePending = $true
        }

        $RebootPending = (
            $CBSRebootPending -or
            $WindowsUpdateRebootRequired -or
            $ComputerRenamePending -or
            $PendingFileRenameOperations
        )

        [PSCustomObject]@{
            RebootPending                = $RebootPending
            CBSRebootPending             = $CBSRebootPending
            WindowsUpdateRebootRequired = $WindowsUpdateRebootRequired
            PendingFileRenameOperations  = $PendingFileRenameOperations
            ComputerRenamePending       = $ComputerRenamePending
        }
    }

    try {
        Write-Host "`nPending Reboot Status" -ForegroundColor Cyan
        Write-Host "---------------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {
            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {
                if ($Target.IsRemote) {
                    $Status = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ErrorAction Stop
                }
                else {
                    $Status = & $ScriptBlock
                }

                if ($Status.RebootPending) {
                    Write-Host "Reboot Pending : YES" -ForegroundColor Red
                }
                else {
                    Write-Host "Reboot Pending : NO" -ForegroundColor Green
                }

                Write-Host
                Write-Host "Component Based Servicing : $($Status.CBSRebootPending)"
                Write-Host "Windows Update             : $($Status.WindowsUpdateRebootRequired)"
                Write-Host "Pending File Rename       : $($Status.PendingFileRenameOperations)"
                Write-Host "Computer Rename           : $($Status.ComputerRenamePending)"
            }
            catch {
                Write-Host "Failed to retrieve pending reboot status." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "`nFailed to retrieve pending reboot status." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}