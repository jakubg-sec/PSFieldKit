function Get-ADDomainFunctionalLevel {

    try {

        $Domain = Get-ADDomain -ErrorAction Stop

        [PSCustomObject]@{
            Domain              = $Domain.DNSRoot
            DomainFunctionalLevel = $Domain.DomainMode
        } |
        Format-List
    }
    catch {

        Write-Host "`nFailed to retrieve domain functional level." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}