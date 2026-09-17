function Get-DiskInformation {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    try {

        if ($Context.IsRemote) {

            $Disks = Get-CimInstance `
                -ClassName Win32_DiskDrive `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop

            $LogicalDisks = Get-CimInstance `
                -ClassName Win32_LogicalDisk `
                -ComputerName $Context.ComputerName `
                -Filter "DriveType = 3" `
                -ErrorAction Stop
        }
        else {

            $Disks = Get-CimInstance `
                -ClassName Win32_DiskDrive `
                -ErrorAction Stop

            $LogicalDisks = Get-CimInstance `
                -ClassName Win32_LogicalDisk `
                -Filter "DriveType = 3" `
                -ErrorAction Stop
        }

        Write-Host "`nPhysical Disks" -ForegroundColor Cyan
        Write-Host "--------------" -ForegroundColor DarkCyan

        $PhysicalDiskInfo = foreach ($Disk in $Disks) {

            [PSCustomObject]@{
                Number       = $Disk.Index
                Model        = $Disk.Model
                SerialNumber = $Disk.SerialNumber
                MediaType    = $Disk.MediaType
                Interface    = $Disk.InterfaceType
                SizeGB       = [math]::Round($Disk.Size / 1GB, 2)
                Status       = $Disk.Status
            }
        }

        $PhysicalDiskInfo | Format-Table -AutoSize

        Write-Host "`nLogical Disks" -ForegroundColor Cyan
        Write-Host "-------------" -ForegroundColor DarkCyan

        $LogicalDiskInfo = foreach ($Disk in $LogicalDisks) {

            $UsedGB = ($Disk.Size - $Disk.FreeSpace) / 1GB
            $FreeGB = $Disk.FreeSpace / 1GB
            $SizeGB = $Disk.Size / 1GB

            $UsedPercent = if ($SizeGB -gt 0) {
                ($UsedGB / $SizeGB) * 100
            }
            else {
                0
            }

            $FreePercent = if ($SizeGB -gt 0) {
                ($FreeGB / $SizeGB) * 100
            }
            else {
                0
            }

            [PSCustomObject]@{
                Drive        = $Disk.DeviceID
                VolumeName   = $Disk.VolumeName
                FileSystem   = $Disk.FileSystem
                SizeGB       = [math]::Round($SizeGB, 2)
                UsedGB       = [math]::Round($UsedGB, 2)
                FreeGB       = [math]::Round($FreeGB, 2)
                UsedPercent  = [math]::Round($UsedPercent, 1)
                FreePercent  = [math]::Round($FreePercent, 1)
            }
        }

        $LogicalDiskInfo | Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve disk information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}