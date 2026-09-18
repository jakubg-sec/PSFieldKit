function Test-ADDomainControllerSYSVOL {

    $Identity = Read-Host "Enter domain controller name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nDomain controller name cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $DC = Get-ADDomainController `
            -Identity $Identity `
            -ErrorAction Stop

        $HostName = $DC.HostName

        $SYSVOLPath = "\\$HostName\SYSVOL"
        $NETLOGONPath = "\\$HostName\NETLOGON"

        Write-Host "`nDomain Controller SYSVOL / NETLOGON Test" `
            -ForegroundColor Cyan

        Write-Host "----------------------------------------" `
            -ForegroundColor DarkCyan

        Write-Host "DC       : $HostName"
        Write-Host "SYSVOL   : $SYSVOLPath"
        Write-Host "NETLOGON : $NETLOGONPath"
        Write-Host ""

        # SYSVOL
        $SYSVOLAvailable = Test-Path `
            -Path $SYSVOLPath `
            -ErrorAction SilentlyContinue

        # NETLOGON
        $NETLOGONAvailable = Test-Path `
            -Path $NETLOGONPath `
            -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            DomainController = $HostName
            SYSVOL           = if ($SYSVOLAvailable) {
                'Available'
            }
            else {
                'Unavailable'
            }
            NETLOGON         = if ($NETLOGONAvailable) {
                'Available'
            }
            else {
                'Unavailable'
            }
            Status           = if ($SYSVOLAvailable -and $NETLOGONAvailable) {
                'PASS'
            }
            else {
                'FAIL'
            }
        } |
        Format-List
    }
    catch {

        Write-Host "`nFailed to test SYSVOL / NETLOGON." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}