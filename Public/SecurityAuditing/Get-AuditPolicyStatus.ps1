function Get-AuditPolicyStatus {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    $ScriptBlock = {

        $AuditPolPath = "$env:SystemRoot\System32\auditpol.exe"

        if (-not (Test-Path -Path $AuditPolPath)) {
            throw "auditpol.exe was not found."
        }

        $Output = @(
            & $AuditPolPath /get /category:* /r 2>&1
        )

        if ($LASTEXITCODE -ne 0) {

            $ErrorMessage = ($Output | Out-String).Trim()

            if ([string]::IsNullOrWhiteSpace($ErrorMessage)) {
                $ErrorMessage = "auditpol.exe returned exit code $LASTEXITCODE."
            }

            throw $ErrorMessage
        }

        #
        # Get CSV data.
        #

        $CsvLines = @(
            $Output |
            Where-Object {
                $_ -is [string] -and
                $_ -match ','
            }
        )

        if ($CsvLines.Count -lt 2) {
            throw "No audit policy data was returned."
        }

        $CsvData = $CsvLines -join [Environment]::NewLine

        $Rows = @(
            $CsvData |
            ConvertFrom-Csv
        )

        if ($Rows.Count -eq 0) {
            throw "Audit policy data could not be parsed."
        }

        #
        # Parse audit policy rows.
        #
        # auditpol /r uses column names containing spaces:
        #
        # Machine Name
        # Policy Target
        # Subcategory
        # Subcategory GUID
        # Inclusion Setting
        # Exclusion Setting
        # Setting Value
        #

        $Policy = foreach ($Row in $Rows) {

            $Subcategory = [string]$Row.'Subcategory'
            $SubcategoryGuid = [string]$Row.'Subcategory GUID'
            $InclusionSetting = [string]$Row.'Inclusion Setting'
            $ExclusionSetting = [string]$Row.'Exclusion Setting'
            $SettingValue = [string]$Row.'Setting Value'

            #
            # Ignore audit options and global SACL rows.
            #

            if ([string]::IsNullOrWhiteSpace($Subcategory)) {
                continue
            }

            if ($Subcategory -like 'Option:*') {
                continue
            }

            if (
                [string]::IsNullOrWhiteSpace($SubcategoryGuid)
            ) {
                continue
            }

            [PSCustomObject]@{
                ComputerName     = [string]$Row.'Machine Name'
                PolicyTarget     = [string]$Row.'Policy Target'
                Subcategory      = $Subcategory
                SubcategoryGuid  = $SubcategoryGuid
                InclusionSetting = $InclusionSetting
                ExclusionSetting = $ExclusionSetting
                SettingValue     = $SettingValue
            }
        }

        $Policy = @($Policy)

        if ($Policy.Count -eq 0) {
            throw "Audit policy data could not be parsed."
        }

        #
        # Create setting summary.
        #

        $SettingSummary = @(
            $Policy |
            Group-Object -Property InclusionSetting |
            Sort-Object Count -Descending |
            Select-Object `
                @{Name = 'Setting'; Expression = { $_.Name }},
                Count
        )

        #
        # Return remoting-safe object.
        #

        [PSCustomObject]@{

            Policy = @($Policy)

            SettingSummary = @($SettingSummary)

            TotalEntries = $Policy.Count
        }
    }

    try {

        Write-Host "`nAudit Policy & Logging Check" -ForegroundColor Cyan
        Write-Host "----------------------------" -ForegroundColor DarkCyan

        foreach ($Target in $Context.Targets) {

            Write-Host "`nTarget: $($Target.ComputerName)" -ForegroundColor Yellow

            try {

                if ($Target.IsRemote) {

                    $Result = Invoke-Command `
                        -ComputerName $Target.ComputerName `
                        -ScriptBlock $ScriptBlock `
                        -ErrorAction Stop
                }
                else {

                    $Result = & $ScriptBlock
                }

                #
                # Audit Policy Summary
                #

                Write-Host "`nAudit Policy Summary" -ForegroundColor Cyan
                Write-Host "--------------------" -ForegroundColor DarkCyan

                Write-Host "Total Entries : $($Result.TotalEntries)"

                #
                # Audit Settings
                #

                if ($Result.SettingSummary.Count -gt 0) {

                    Write-Host "`nAudit Settings" -ForegroundColor Cyan
                    Write-Host "--------------" -ForegroundColor DarkCyan

                    $Result.SettingSummary |
                        Format-Table `
                            Setting,
                            Count `
                        -AutoSize
                }

                #
                # Audit Policy Details
                #

                Write-Host "`nAudit Policy Details" -ForegroundColor Cyan
                Write-Host "--------------------" -ForegroundColor DarkCyan

                $Result.Policy |
                    Select-Object `
                        Subcategory,
                        InclusionSetting,
                        ExclusionSetting,
                        SubcategoryGuid |
                    Sort-Object Subcategory |
                    Format-Table `
                        -Wrap `
                        -AutoSize
            }
            catch {

                Write-Host "Failed to retrieve audit policy." `
                    -ForegroundColor Red

                Write-Host $_.Exception.Message `
                    -ForegroundColor Yellow
            }
        }
    }
    catch {

        Write-Host "`nFailed to check audit policy status." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}