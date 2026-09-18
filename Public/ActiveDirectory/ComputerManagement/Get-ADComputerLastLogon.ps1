function Get-ADComputerLastLogon {

    $Identity = Read-Host "Enter computer name or Distinguished Name"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nComputer identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $Computer = Get-ADComputer `
            -Identity $Identity `
            -Properties `
                DNSHostName,
                LastLogonDate,
                LastLogonTimestamp,
                Enabled `
            -ErrorAction Stop

        $LastLogonTimestamp = if ($null -ne $Computer.LastLogonTimestamp) {
            [datetime]::FromFileTime($Computer.LastLogonTimestamp)
        }
        else {
            $null
        }

        [PSCustomObject]@{
            Name              = $Computer.Name
            DNSHostName       = $Computer.DNSHostName
            Enabled           = $Computer.Enabled
            LastLogonDate     = $Computer.LastLogonDate
            LastLogonTimestamp = $LastLogonTimestamp
        } |
        Format-List
    }
    catch {

        Write-Host "`nFailed to retrieve computer last logon information." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}