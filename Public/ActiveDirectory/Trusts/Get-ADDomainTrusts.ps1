function Get-ADDomainTrusts {
    try {
        $Domain = Get-ADDomain -ErrorAction Stop

        $Trusts = Get-ADTrust `
            -Filter * `
            -Properties * `
            -ErrorAction Stop

        Write-Host "`nDomain Trusts" -ForegroundColor Cyan
        Write-Host "-------------" -ForegroundColor DarkCyan
        Write-Host "Domain: $($Domain.DNSRoot)"
        Write-Host ""

        if (-not $Trusts) {
            Write-Host "No domain trusts found." -ForegroundColor Yellow
            return
        }

        $Results = foreach ($Trust in $Trusts) {
            [PSCustomObject]@{
                Name                    = $Trust.Name
                Source                  = $Trust.Source
                Target                  = $Trust.Target
                Direction               = $Trust.Direction
                TrustType               = $Trust.TrustType
                ForestTransitive        = $Trust.ForestTransitive
                IntraForest             = $Trust.IntraForest
                UplevelOnly             = $Trust.UplevelOnly
                SelectiveAuthentication = $Trust.SelectiveAuthentication
                SIDFilteringQuarantined = $Trust.SIDFilteringQuarantined
            }
        }

        $Results |
            Sort-Object Target |
            Format-Table `
                Name,
                Source,
                Target,
                Direction,
                TrustType,
                ForestTransitive,
                IntraForest,
                SelectiveAuthentication,
                SIDFilteringQuarantined `
                -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve domain trusts." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}