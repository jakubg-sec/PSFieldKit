function Get-ADGPOPermissions {

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

        $Permissions = Get-GPPermissions `
            -Guid $GPO.Id `
            -All `
            -ErrorAction Stop

        Write-Host "`nGPO Permissions" -ForegroundColor Cyan
        Write-Host "---------------" -ForegroundColor DarkCyan
        Write-Host "GPO: $($GPO.DisplayName)"
        Write-Host ""

        $Permissions |
            Select-Object `
                @{Name='Trustee'; Expression={
                    $_.Trustee.Name
                }},
                Permission,
                TargetType,
                Inherited |
            Sort-Object Trustee |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve GPO permissions." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Yellow
    }
}