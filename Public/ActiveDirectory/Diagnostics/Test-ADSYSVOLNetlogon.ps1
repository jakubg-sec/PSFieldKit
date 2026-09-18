function Test-ADSYSVOLNetlogon {
    try {
        $Domain = Get-ADDomain -ErrorAction Stop
        $DomainControllers = Get-ADDomainController `
            -Filter * `
            -ErrorAction Stop

        Write-Host "`nActive Directory SYSVOL / NETLOGON Diagnostics" -ForegroundColor Cyan
        Write-Host "----------------------------------------------" -ForegroundColor DarkCyan
        Write-Host "Domain : $($Domain.DNSRoot)"
        Write-Host "DCs    : $($DomainControllers.Count)"
        Write-Host ""

        $Results = foreach ($DC in $DomainControllers) {
            Write-Host "Checking $($DC.HostName)..." -ForegroundColor Yellow

            $SYSVOLPath = "\\$($DC.HostName)\SYSVOL"
            $NETLOGONPath = "\\$($DC.HostName)\NETLOGON"

            $SYSVOLAvailable = Test-Path `
                -Path $SYSVOLPath `
                -ErrorAction SilentlyContinue

            $NETLOGONAvailable = Test-Path `
                -Path $NETLOGONPath `
                -ErrorAction SilentlyContinue

            $SYSVOLStatus = if ($SYSVOLAvailable) {
                'PASS'
            }
            else {
                'FAIL'
            }

            $NETLOGONStatus = if ($NETLOGONAvailable) {
                'PASS'
            }
            else {
                'FAIL'
            }

            $OverallStatus = if (
                $SYSVOLAvailable -and
                $NETLOGONAvailable
            ) {
                'PASS'
            }
            else {
                'FAIL'
            }

            [PSCustomObject]@{
                DomainController = $DC.HostName
                Site             = $DC.Site
                SYSVOL           = $SYSVOLStatus
                NETLOGON         = $NETLOGONStatus
                Status            = $OverallStatus
            }
        }

        Write-Host "`nSYSVOL / NETLOGON Results" -ForegroundColor Cyan
        Write-Host "-------------------------" -ForegroundColor DarkCyan

        $Results |
            Sort-Object DomainController |
            Format-Table `
                DomainController,
                Site,
                SYSVOL,
                NETLOGON,
                Status `
                -AutoSize

        $Failed = @(
            $Results |
            Where-Object {
                $_.Status -eq 'FAIL'
            }
        )

        Write-Host ""

        if ($Failed) {
            Write-Host "SYSVOL / NETLOGON problems detected." -ForegroundColor Red

            Write-Host "`nAffected domain controllers:" -ForegroundColor Red

            $Failed |
                Select-Object DomainController, Site, SYSVOL, NETLOGON |
                Format-Table -AutoSize
        }
        else {
            Write-Host "SYSVOL and NETLOGON are available on all domain controllers." `
                -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`nFailed to test SYSVOL / NETLOGON." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}