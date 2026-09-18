function Get-ADGPOInformation {

    $Identity = Read-Host "Enter GPO name or GUID"

    if ([string]::IsNullOrWhiteSpace($Identity)) {

        Write-Host "`nGPO identity cannot be empty." `
            -ForegroundColor Red

        return
    }

    try {

        $Guid = [Guid]::Empty

        if ([Guid]::TryParse($Identity, [ref]$Guid)) {

            $GPO = Get-GPO `
                -Guid $Guid `
                -ErrorAction Stop
        }
        else {

            $GPO = Get-GPO `
                -Name $Identity `
                -ErrorAction Stop
        }

        [PSCustomObject]@{
            DisplayName       = $GPO.DisplayName
            Id                = $GPO.Id
            DomainName        = $GPO.DomainName
            Owner             = $GPO.Owner
            GpoStatus         = $GPO.GpoStatus
            Description       = $GPO.Description
            CreationTime      = $GPO.CreationTime
            ModificationTime  = $GPO.ModificationTime
            UserVersion       = $GPO.UserVersion
            ComputerVersion   = $GPO.ComputerVersion
            WmiFilter         = if ($GPO.WmiFilter) {
                $GPO.WmiFilter.Name
            }
            else {
                'None'
            }
        } | Format-List
    }
    catch {

        Write-Host "`nFailed to retrieve GPO information." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}