function Show-StorageMenu {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    while ($true) {
        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|            Storage & Disks                   |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Disk Information                        |"
        Write-Host "|  [2] Partition Information                   |"
        Write-Host "|  [3] Volume Information                      |"
        Write-Host "|  [4] Free Space                              |"
        Write-Host "|  [5] Disk Health                             |"
        Write-Host "|  [6] Mounted Drives                          |"
        Write-Host "|  [7] Disk Usage                              |"
        Write-Host "|  [8] Storage Spaces                          |"
        Write-Host "|  [9] Rescan Disks                            |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Get-DiskInformation -Context $Context
                Pause
            }

            '2' {
                Get-PartitionInformation -Context $Context
                Pause
            }

            '3' {
                Get-VolumeInformation -Context $Context
                Pause
            }

            '4' {
                Get-FreeSpace -Context $Context
                Pause
            }

            '5' {
                Get-DiskHealth -Context $Context
                Pause
            }

            '6' {
                Get-MountedDrives -Context $Context
                Pause
            }

            '7' {
                Get-DiskUsage -Context $Context
                Pause
            }

            '8' {
                Get-StorageSpaces -Context $Context
                Pause
            }

            '9' {
                Update-PSFieldKitDisk -Context $Context
                Pause
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