function Test-ADGPODiagnostics {

    try {

        $Domain = Get-ADDomain -ErrorAction Stop

        $PDC = $Domain.PDCEmulator

        Write-Host "`nGroup Policy Diagnostics" -ForegroundColor Cyan
        Write-Host "------------------------" -ForegroundColor DarkCyan
        Write-Host "Domain : $($Domain.DNSRoot)"
        Write-Host "PDC    : $PDC"
        Write-Host ""

        $Results = @()

        # Test 1 - Group Policy module
        try {

            Get-Command Get-GPO `
                -ErrorAction Stop |
                Out-Null

            $Results += [PSCustomObject]@{
                Test   = 'GroupPolicy Module'
                Status = 'PASS'
                Details = 'Group Policy cmdlets available'
            }
        }
        catch {

            $Results += [PSCustomObject]@{
                Test   = 'GroupPolicy Module'
                Status = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # Test 2 - SYSVOL
        $SYSVOL = "\\$($Domain.DNSRoot)\SYSVOL"

        if (Test-Path $SYSVOL) {

            $Results += [PSCustomObject]@{
                Test    = 'SYSVOL'
                Status  = 'PASS'
                Details = $SYSVOL
            }
        }
        else {

            $Results += [PSCustomObject]@{
                Test    = 'SYSVOL'
                Status  = 'FAIL'
                Details = "$SYSVOL unavailable"
            }
        }

        # Test 3 - NETLOGON
        $NETLOGON = "\\$PDC\NETLOGON"

        if (Test-Path $NETLOGON) {

            $Results += [PSCustomObject]@{
                Test    = 'NETLOGON'
                Status  = 'PASS'
                Details = $NETLOGON
            }
        }
        else {

            $Results += [PSCustomObject]@{
                Test    = 'NETLOGON'
                Status  = 'FAIL'
                Details = "$NETLOGON unavailable"
            }
        }

        # Test 4 - GPO enumeration
        try {

            $GPOs = Get-GPO `
                -All `
                -ErrorAction Stop

            $Results += [PSCustomObject]@{
                Test    = 'GPO Enumeration'
                Status  = 'PASS'
                Details = "$($GPOs.Count) GPO(s) found"
            }
        }
        catch {

            $Results += [PSCustomObject]@{
                Test    = 'GPO Enumeration'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # Test 5 - Domain GPO inheritance
        try {

            $Inheritance = Get-GPInheritance `
                -Target $Domain.DistinguishedName `
                -ErrorAction Stop

            $Results += [PSCustomObject]@{
                Test    = 'Domain GPO Inheritance'
                Status  = 'PASS'
                Details = "$($Inheritance.GpoLinks.Count) direct link(s)"
            }
        }
        catch {

            $Results += [PSCustomObject]@{
                Test    = 'Domain GPO Inheritance'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        # Test 6 - SYSVOL / NETLOGON DCDIAG checks
        try {

            $DCDiagOutput = & dcdiag.exe `
                "/s:$PDC" `
                '/test:sysvolcheck' `
                '/test:netlogons' `
                '/q' 2>&1

            $DCDiagText = ($DCDiagOutput | Out-String).Trim()

            if (
                $LASTEXITCODE -eq 0 -and
                [string]::IsNullOrWhiteSpace($DCDiagText)
            ) {

                $Results += [PSCustomObject]@{
                    Test    = 'DC SYSVOL / NETLOGON'
                    Status  = 'PASS'
                    Details = 'dcdiag reported no errors'
                }
            }
            else {

                $Results += [PSCustomObject]@{
                    Test    = 'DC SYSVOL / NETLOGON'
                    Status  = 'FAIL'
                    Details = $DCDiagText
                }
            }
        }
        catch {

            $Results += [PSCustomObject]@{
                Test    = 'DC SYSVOL / NETLOGON'
                Status  = 'FAIL'
                Details = $_.Exception.Message
            }
        }

        Write-Host "`nDiagnostic Results" -ForegroundColor Cyan
        Write-Host "------------------" -ForegroundColor DarkCyan

        $Results |
            Select-Object Test, Status, Details |
            Format-Table -Wrap -AutoSize

        $Failed = $Results |
            Where-Object {
                $_.Status -eq 'FAIL'
            }

        if ($Failed) {

            Write-Host "`nGPO diagnostics detected problems." `
                -ForegroundColor Red
        }
        else {

            Write-Host "`nNo GPO infrastructure problems detected." `
                -ForegroundColor Green
        }
    }
    catch {

        Write-Host "`nFailed to run GPO diagnostics." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}