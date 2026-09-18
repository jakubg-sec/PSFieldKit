function Show-ADSearchMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|           Search Active Directory            |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Search Users                            |"
        Write-Host "|  [2] Search Computers                        |"
        Write-Host "|  [3] Search Groups                           |"
        Write-Host "|  [4] Search Organizational Units             |"
        Write-Host "|  [5] Search All Objects                      |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Search-ADUsers
                Pause
            }

            '2' {
                Search-ADComputers
                Pause
            }

            '3' {
                Search-ADGroups
                Pause
            }

            '4' {
                Search-ADOUs
                Pause
            }

            '5' {
                Search-ADObjects
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