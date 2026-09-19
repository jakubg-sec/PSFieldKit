function Show-SecurityMenu {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )
    while ($true) {
        Clear-Host
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                Security                      |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Local Accounts                          |"
        Write-Host "|  [2] Local Groups                            |"
        Write-Host "|  [3] Security Policy                         |"
        Write-Host "|  [4] Audit Policy                            |"
        Write-Host "|  [5] Certificates                            |"
        Write-Host "|  [6] Microsoft Defender                      |"
        Write-Host "|  [7] BitLocker                               |"
        Write-Host "|  [8] Logged-on Users                         |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow
        
        $Choice = Read-Host "`nSelect option"
        switch ($Choice) {
            '1' {
                Get-LocalAccounts -Context $Context
                Pause
            }
            '2' {
                Get-LocalGroups -Context $Context
                Pause
            }
            '3' {
                Get-SecurityPolicy -Context $Context
                Pause
            }
            '4' {
                Get-AuditPolicy -Context $Context
                Pause
            }
            '5' {
                Get-Certificates -Context $Context
                Pause
            }
            '6' {
                Get-DefenderStatus -Context $Context
                Pause
            }
            '7' {
                Get-BitLockerStatus -Context $Context
                Pause
            }
            '8' {
                Get-LoggedOnUsers -Context $Context
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