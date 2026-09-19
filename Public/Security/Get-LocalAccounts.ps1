function Get-LocalAccounts {
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
                $Accounts = Get-CimInstance `
                    -ClassName Win32_UserAccount `
                    -CimSession $Session `
                    -Filter "LocalAccount = True" `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {
            $Accounts = Get-CimInstance `
                -ClassName Win32_UserAccount `
                -Filter "LocalAccount = True" `
                -ErrorAction Stop
        }

        if ($null -eq $Accounts -or $Accounts.Count -eq 0) {
            Write-Host "`nNo local accounts found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nLocal Accounts" -ForegroundColor Cyan
        Write-Host "--------------" -ForegroundColor DarkCyan
        Write-Host "Target: $($Context.ComputerName)" -ForegroundColor Yellow

        $Accounts |
            Select-Object `
                Name,
                FullName,
                Disabled,
                Lockout,
                PasswordRequired,
                PasswordExpires,
                Description,
                SID |
            Sort-Object Name |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve local accounts from $($Context.ComputerName)." `
            -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}