function Get-LocalGroups {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )
    try {
        if ($Context.IsRemote) {
            $Session = New-CimSession `
                -ComputerName $Context.ComputerName `
                -ErrorAction Stop
            try {
                $Groups = Get-CimInstance `
                    -ClassName Win32_Group `
                    -CimSession $Session `
                    -Filter "LocalAccount = True" `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Groups = Get-CimInstance `
                -ClassName Win32_Group `
                -Filter "LocalAccount = True" `
                -ErrorAction Stop
        }

        if ($null -eq $Groups -or $Groups.Count -eq 0) {
            Write-Host "`nNo local groups found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nLocal Groups" -ForegroundColor Cyan
        Write-Host "------------" -ForegroundColor DarkCyan
        Write-Host "Target: $($Context.ComputerName)" -ForegroundColor Yellow

        $Groups |
            Select-Object `
                Name,
                Description,
                Domain,
                SID |
            Sort-Object Name |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve local groups from $($Context.ComputerName)." `
            -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}