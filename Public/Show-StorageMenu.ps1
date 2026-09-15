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
        Write-Host "| [10] Disk Management                         |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                # Get-DiskInformation
            }

            '2' {
                # Get-PartitionInformation
            }

            '3' {
                # Get-VolumeInformation
            }

            '4' {
                # Get-FreeSpace
            }

            '5' {
                # Get-DiskHealth
            }

            '6' {
                # Get-MountedDrive
            }

            '7' {
                # Get-DiskUsage
            }

            '8' {
                # Get-StorageSpaces
            }

            '9' {
                # Update-Disk
            }

            '10' {
                # Show-DiskManagement
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