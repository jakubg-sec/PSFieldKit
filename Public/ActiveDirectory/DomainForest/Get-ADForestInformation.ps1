function Get-ADForestInformation {

    try {

        $Forest = Get-ADForest -ErrorAction Stop

        [PSCustomObject]@{
            Name                = $Forest.Name
            RootDomain          = $Forest.RootDomain
            ForestMode          = $Forest.ForestMode
            Domains             = $Forest.Domains -join ', '
            GlobalCatalogs      = $Forest.GlobalCatalogs -join ', '
            Sites               = $Forest.Sites -join ', '
            SchemaMaster        = $Forest.SchemaMaster
            DomainNamingMaster  = $Forest.DomainNamingMaster
            PartitionsContainer = $Forest.PartitionsContainer
        }
    }
    catch {

        Write-Host "`nFailed to retrieve Active Directory forest information." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}