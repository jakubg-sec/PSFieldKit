function Get-ADDomainControllerServices {

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

        $ServicesToCheck = @(
            'NTDS'
            'Netlogon'
            'KDC'
            'DNS'
            'DFSR'
            'W32Time'
            'ADWS'
        )

        Write-Host "`nDomain Controller Services" -ForegroundColor Cyan
        Write-Host "--------------------------" -ForegroundColor DarkCyan
        Write-Host "DC: $($DC.HostName)`n"

        $Services = Get-CimInstance `
            -ClassName Win32_Service `
            -ComputerName $DC.HostName `
            -ErrorAction Stop

        $Services |
            Where-Object {
                $_.Name -in $ServicesToCheck
            } |
            Select-Object `
                Name,
                DisplayName,
                State,
                StartMode,
                StartName |
            Sort-Object Name |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve domain controller services." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}