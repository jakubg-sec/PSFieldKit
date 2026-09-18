function Get-ADForestFunctionalLevel {

    try {

        $Forest = Get-ADForest -ErrorAction Stop

        [PSCustomObject]@{
            Forest               = $Forest.Name
            ForestFunctionalLevel = $Forest.ForestMode
        } |
        Format-List
    }
    catch {

        Write-Host "`nFailed to retrieve forest functional level." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}