function Get-ADComputerInformation {

    $Identity = Read-Host "Enter computer name, DNS hostname or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nComputer identity cannot be empty." -ForegroundColor Red

        return
    }

    try {

        $Computer = Get-ADComputer `
            -Identity $Identity `
            -Properties `
                DNSHostName,
                Enabled,
                OperatingSystem,
                OperatingSystemVersion,
                IPv4Address,
                LastLogonDate,
                PasswordLastSet,
                Created,
                Modified,
                ManagedBy `
            -ErrorAction Stop

        [PSCustomObject]@{
            Name                = $Computer.Name
            SamAccountName      = $Computer.SamAccountName
            DNSHostName         = $Computer.DNSHostName
            IPv4Address         = $Computer.IPv4Address
            Enabled             = $Computer.Enabled
            OperatingSystem     = $Computer.OperatingSystem
            OSVersion           = $Computer.OperatingSystemVersion
            LastLogonDate       = $Computer.LastLogonDate
            PasswordLastSet     = $Computer.PasswordLastSet
            ManagedBy           = $Computer.ManagedBy
            Created             = $Computer.Created
            Modified            = $Computer.Modified
            DistinguishedName   = $Computer.DistinguishedName
        } |
        Format-List
    }
    catch {

        Write-Host "`nFailed to retrieve computer information." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}