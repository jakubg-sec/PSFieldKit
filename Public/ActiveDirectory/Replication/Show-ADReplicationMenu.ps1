function Show-ADReplicationMenu {

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|               AD Replication                 |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Replication Status                      |"
        Write-Host "|  [2] Replication Partners                    |"
        Write-Host "|  [3] Replication Failures                    |"
        Write-Host "|  [4] Replication Metadata                    |"
        Write-Host "|  [5] Synchronize Replication                 |"
        Write-Host "|  [6] Replication Summary                     |"
        Write-Host "|  [7] Repadmin Diagnostics                    |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {

            '1' {
                Get-ADReplicationStatus
                Pause
            }

            '2' {
                Get-ADReplicationPartners
                Pause
            }

            '3' {
                Get-ADReplicationFailures
                Pause
            }

            '4' {
                Get-ADReplicationMetadata
                Pause
            }

            '5' {
                Sync-ADReplication
                Pause
            }

            '6' {
                Get-ADReplicationSummary
                Pause
            }

            '7' {
                Test-ADReplicationDiagnostics
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