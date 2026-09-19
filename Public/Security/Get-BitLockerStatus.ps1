function Get-BitLockerStatus {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )
    try {
        if ($Context.IsRemote) {
            $BitLockerVolumes = Invoke-Command `
                -ComputerName $Context.ComputerName `
                -ScriptBlock {
                    Get-BitLockerVolume -ErrorAction Stop |
                        Select-Object `
                            MountPoint,
                            VolumeType,
                            VolumeStatus,
                            EncryptionPercentage,
                            EncryptionMethod,
                            LockStatus,
                            ProtectionStatus,
                            AutoUnlockEnabled,
                            @{Name = 'KeyProtectorTypes'; Expression = {
                                if ($null -eq $_.KeyProtector) {
                                    ''
                                }
                                else {
                                    ($_.KeyProtector.KeyProtectorType -join ', ')
                                }
                            }}
                } `
                -ErrorAction Stop
        }
        else {
            $BitLockerVolumes = Get-BitLockerVolume `
                -ErrorAction Stop |
                Select-Object `
                    MountPoint,
                    VolumeType,
                    VolumeStatus,
                    EncryptionPercentage,
                    EncryptionMethod,
                    LockStatus,
                    ProtectionStatus,
                    AutoUnlockEnabled,
                    @{Name = 'KeyProtectorTypes'; Expression = {
                        if ($null -eq $_.KeyProtector) {
                            ''
                        }
                        else {
                            ($_.KeyProtector.KeyProtectorType -join ', ')
                        }
                    }}
        }

        if ($null -eq $BitLockerVolumes -or $BitLockerVolumes.Count -eq 0) {
            Write-Host "`nNo BitLocker volumes found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nBitLocker Status" -ForegroundColor Cyan
        Write-Host "----------------" -ForegroundColor DarkCyan
        Write-Host "Target: $($Context.ComputerName)" -ForegroundColor Yellow

        $BitLockerVolumes |
            Sort-Object MountPoint |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve BitLocker status from $($Context.ComputerName)." `
            -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}