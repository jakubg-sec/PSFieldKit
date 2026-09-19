function Get-SecurityPolicy {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )
    try {
        $PolicyData = if ($Context.IsRemote) {
            Invoke-Command `
                -ComputerName $Context.ComputerName `
                -ScriptBlock {
                    $TempPath = Join-Path `
                        -Path $env:TEMP `
                        -ChildPath 'PSFieldKit-SecurityPolicy.inf'

                    try {
                        secedit.exe `
                            /export `
                            /cfg $TempPath `
                            /quiet | Out-Null

                        if (-not (Test-Path $TempPath)) {
                            throw "Security policy export file was not created."
                        }

                        Get-Content -Path $TempPath -ErrorAction Stop
                    }
                    finally {
                        if (Test-Path $TempPath) {
                            Remove-Item $TempPath -Force -ErrorAction SilentlyContinue
                        }
                    }
                } `
                -ErrorAction Stop
        }
        else {
            $TempPath = Join-Path `
                -Path $env:TEMP `
                -ChildPath 'PSFieldKit-SecurityPolicy.inf'

            try {
                secedit.exe `
                    /export `
                    /cfg $TempPath `
                    /quiet | Out-Null

                if (-not (Test-Path $TempPath)) {
                    throw "Security policy export file was not created."
                }

                Get-Content -Path $TempPath -ErrorAction Stop
            }
            finally {
                if (Test-Path $TempPath) {
                    Remove-Item $TempPath -Force -ErrorAction SilentlyContinue
                }
            }
        }

        $Policy = @{}
        $Section = $null

        foreach ($Line in $PolicyData) {
            if ([string]::IsNullOrWhiteSpace($Line)) {
                continue
            }

            if ($Line -match '^\[(.+)\]$') {
                $Section = $Matches[1]
                continue
            }

            if ($Line -match '^([^=]+)=(.*)$') {
                $Key = $Matches[1].Trim()
                $Value = $Matches[2].Trim()

                if ($null -eq $Section) {
                    continue
                }

                $Policy["$Section\$Key"] = $Value
            }
        }

        $Settings = @(
            [PSCustomObject]@{
                Setting = 'Minimum Password Length'
                Value = $Policy['System Access\MinimumPasswordLength']
            }
            [PSCustomObject]@{
                Setting = 'Maximum Password Age'
                Value = $Policy['System Access\MaximumPasswordAge']
            }
            [PSCustomObject]@{
                Setting = 'Minimum Password Age'
                Value = $Policy['System Access\MinimumPasswordAge']
            }
            [PSCustomObject]@{
                Setting = 'Password History Size'
                Value = $Policy['System Access\PasswordHistorySize']
            }
            [PSCustomObject]@{
                Setting = 'Password Complexity'
                Value = if ($Policy['System Access\PasswordComplexity'] -eq '1') {
                    'Enabled'
                }
                elseif ($Policy['System Access\PasswordComplexity'] -eq '0') {
                    'Disabled'
                }
                else {
                    $Policy['System Access\PasswordComplexity']
                }
            }
            [PSCustomObject]@{
                Setting = 'Lockout Threshold'
                Value = $Policy['System Access\LockoutBadCount']
            }
            [PSCustomObject]@{
                Setting = 'Lockout Duration'
                Value = $Policy['System Access\LockoutDuration']
            }
            [PSCustomObject]@{
                Setting = 'Reset Lockout Counter After'
                Value = $Policy['System Access\ResetLockoutCount']
            }
            [PSCustomObject]@{
                Setting = 'Administrator Account Enabled'
                Value = if ($Policy['System Access\EnableAdminAccount'] -eq '1') {
                    'Enabled'
                }
                elseif ($Policy['System Access\EnableAdminAccount'] -eq '0') {
                    'Disabled'
                }
                else {
                    $Policy['System Access\EnableAdminAccount']
                }
            }
            [PSCustomObject]@{
                Setting = 'Guest Account Enabled'
                Value = if ($Policy['System Access\EnableGuestAccount'] -eq '1') {
                    'Enabled'
                }
                elseif ($Policy['System Access\EnableGuestAccount'] -eq '0') {
                    'Disabled'
                }
                else {
                    $Policy['System Access\EnableGuestAccount']
                }
            }
        )

        Write-Host "`nSecurity Policy" -ForegroundColor Cyan
        Write-Host "---------------" -ForegroundColor DarkCyan
        Write-Host "Target: $($Context.ComputerName)" -ForegroundColor Yellow

        $Settings |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve security policy from $($Context.ComputerName)." `
            -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}