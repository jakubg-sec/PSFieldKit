function Get-ADDomainControllerInformation {

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

        [PSCustomObject]@{
            Name                = $DC.Name
            HostName            = $DC.HostName
            IPv4Address         = $DC.IPv4Address
            IPv6Address         = $DC.IPv6Address
            Domain              = $DC.Domain
            Forest              = $DC.Forest
            Site                = $DC.Site
            OperatingSystem     = $DC.OperatingSystem
            OSVersion           = $DC.OperatingSystemVersion
            Enabled             = $DC.Enabled
            GlobalCatalog       = $DC.IsGlobalCatalog
            ReadOnly            = $DC.IsReadOnly
            LDAPPort            = $DC.LdapPort
            SSLPort             = $DC.SSLPort
            ComputerObjectDN    = $DC.ComputerObjectDN
            DefaultPartition    = $DC.DefaultPartition
        } |
        Format-List
    }
    catch {

        Write-Host "`nFailed to retrieve domain controller information." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}