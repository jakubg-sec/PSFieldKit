function Show-ADUserMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|               User Management                |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] User Information                        |"
        Write-Host "|  [2] Search Users                            |"
        Write-Host "|  [3] Create User                             |"
        Write-Host "|  [4] Disable User                            |"
        Write-Host "|  [5] Enable User                             |"
        Write-Host "|  [6] Unlock User                             |"
        Write-Host "|  [7] Reset Password                          |"
        Write-Host "|  [8] Remove User                             |"
        Write-Host "|  [9] Group Membership                        |"
        Write-Host "| [10] Account Status                          |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ADUserInformation
                Pause
            }

            '2' {
                Search-ADUsers
                Pause
            }

            '3' {
                New-ADUserAccount
                Pause
            }

            '4' {
                Disable-ADUserAccount
                Pause
            }

            '5' {
                Enable-ADUserAccount
                Pause
            }

            '6' {
                Unlock-ADUserAccount
                Pause
            }

            '7' {
                Reset-ADUserPassword
                Pause
            }

            '8' {
                Remove-ADUserAccount
                Pause
            }

            '9' {
                Show-ADUserGroupMembership
            }

            '10' {
                Get-ADUserAccountStatus
                Pause
            }

            '0' {
                return
            }

            default {
                Write-Host "`nInvalid option." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}