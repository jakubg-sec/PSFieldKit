function Get-ADDomainInformation {

    try {

        $Domain = Get-ADDomain -ErrorAction Stop

        [PSCustomObject]@{
            DNSRoot              = $Domain.DNSRoot
            NetBIOSName          = $Domain.NetBIOSName
            DomainMode           = $Domain.DomainMode
            DistinguishedName    = $Domain.DistinguishedName
            DomainSID            = $Domain.DomainSID.Value
            ParentDomain         = if ($Domain.ParentDomain) {
                $Domain.ParentDomain
            }
            else {
                '-'
            }
            PDCEmulator          = $Domain.PDCEmulator
            RIDMaster            = $Domain.RIDMaster
            InfrastructureMaster = $Domain.InfrastructureMaster
            ComputersContainer   = $Domain.ComputersContainer
            UsersContainer       = $Domain.UsersContainer
        }
    }
    catch {

        Write-Host "`nFailed to retrieve Active Directory domain information." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}