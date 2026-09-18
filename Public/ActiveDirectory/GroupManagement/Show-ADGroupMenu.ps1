function Show-ADGroupMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|              Group Management               |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Group Information                       |"
        Write-Host "|  [2] Search Groups                           |"
        Write-Host "|  [3] Create Group                            |"
        Write-Host "|  [4] Remove Group                            |"
        Write-Host "|  [5] Add Group Member                        |"
        Write-Host "|  [6] Remove Group Member                     |"
        Write-Host "|  [7] Group Members                           |"
        Write-Host "|  [8] User Group Membership                   |"
        Write-Host "|  [9] Nested Group Membership                 |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ADGroupInformation
                Pause
            }

            '2' {
                Search-ADGroups
                Pause
            }

            '3' {
                New-ADGroupAccount
                Pause
            }

            '4' {
                Remove-ADGroupAccount
                Pause
            }

            '5' {
                Add-ADGroupMemberAccount
                Pause
            }

            '6' {
                Remove-ADGroupMemberAccount
                Pause
            }

            '7' {
                Get-ADGroupMembers
                Pause
            }

            '8' {
                Get-ADUserGroupMembership
                Pause
            }

            '9' {
                Get-ADNestedGroupMembership
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