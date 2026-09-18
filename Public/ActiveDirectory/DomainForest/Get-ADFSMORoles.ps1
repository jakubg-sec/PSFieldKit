function Get-ADFSMORoles {

    try {

        $Domain = Get-ADDomain -ErrorAction Stop
        $Forest = Get-ADForest -ErrorAction Stop

        [PSCustomObject]@{
            'PDC Emulator'          = $Domain.PDCEmulator
            'RID Master'            = $Domain.RIDMaster
            'Infrastructure Master' = $Domain.InfrastructureMaster
            'Schema Master'         = $Forest.SchemaMaster
            'Domain Naming Master'  = $Forest.DomainNamingMaster
        } |
        Format-List
    }
    catch {

        Write-Host "`nFailed to retrieve FSMO roles." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}