function Get-LoggedOnUsers {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )
    try {
        if ($Context.IsRemote) {
            $Sessions = Invoke-Command `
                -ComputerName $Context.ComputerName `
                -ScriptBlock {
                    $Output = quser.exe 2>&1

                    if ($LASTEXITCODE -ne 0) {
                        throw ($Output -join "`n")
                    }

                    $Output
                } `
                -ErrorAction Stop
        }
        else {
            $Sessions = quser.exe 2>&1

            if ($LASTEXITCODE -ne 0) {
                throw ($Sessions -join "`n")
            }
        }

        if ($null -eq $Sessions -or $Sessions.Count -lt 2) {
            Write-Host "`nNo logged-on users found." -ForegroundColor Yellow
            return
        }

        $Users = foreach ($Line in $Sessions | Select-Object -Skip 1) {
            $Line = $Line.ToString().TrimEnd()

            if ([string]::IsNullOrWhiteSpace($Line)) {
                continue
            }

            if ($Line -match '^\s*>?(?<User>\S+)\s+(?:(?<SessionName>\S+)\s+)?(?<Id>\d+)\s+(?<State>\S+)\s+(?<Idle>\S+)\s+(?<LogonTime>.+)$') {
                [PSCustomObject]@{
                    User        = $Matches['User']
                    SessionName = $Matches['SessionName']
                    ID          = [int]$Matches['Id']
                    State       = $Matches['State']
                    IdleTime    = $Matches['Idle']
                    LogonTime   = $Matches['LogonTime']
                }
            }
        }

        if ($null -eq $Users -or $Users.Count -eq 0) {
            Write-Host "`nNo logged-on users found." -ForegroundColor Yellow
            return
        }

        Write-Host "`nLogged-on Users" -ForegroundColor Cyan
        Write-Host "---------------" -ForegroundColor DarkCyan
        Write-Host "Target: $($Context.ComputerName)" -ForegroundColor Yellow

        $Users |
            Sort-Object ID |
            Format-Table -AutoSize
    }
    catch {
        Write-Host "`nFailed to retrieve logged-on users from $($Context.ComputerName)." `
            -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}