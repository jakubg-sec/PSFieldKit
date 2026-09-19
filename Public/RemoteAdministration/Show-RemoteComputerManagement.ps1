function Show-RemoteComputerManagement {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Context
    )

    if ($Context.IsMultiTarget) {
        Write-Host "`nRemote Computer Management requires a single remote target." `
            -ForegroundColor Yellow
        return
    }

    if (-not $Context.IsRemote) {
        Write-Host "`nRemote Computer Management requires a remote target." `
            -ForegroundColor Yellow
        return
    }

    while ($true) {
        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|        Remote Computer Management            |" -ForegroundColor Cyan
        Write-Host "|               PSFieldKit                     |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host "|  [1] Computer Management                     |"
        Write-Host "|  [2] Event Viewer                            |"
        Write-Host "|  [3] Services                                |"
        Write-Host "|  [4] Task Scheduler                          |"
        Write-Host "|  [5] Disk Management                         |"
        Write-Host "|  [6] Device Manager                          |"
        Write-Host "|  [7] Shared Folders                          |"
        Write-Host "|                                              |"
        Write-Host "|  [0] Back                                    |"
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

        Write-Host "`nTarget: $($Context.ComputerName)" -ForegroundColor Yellow

        $Choice = Read-Host "`nSelect option"

        switch ($Choice) {
            '1' {
                Start-Process `
                    -FilePath 'compmgmt.msc' `
                    -ArgumentList "/computer:$($Context.ComputerName)"
            }

            '2' {
                Start-Process `
                    -FilePath 'eventvwr.msc' `
                    -ArgumentList "/computer:$($Context.ComputerName)"
            }

            '3' {
                Start-Process `
                    -FilePath 'services.msc' `
                    -ArgumentList "/computer:$($Context.ComputerName)"
            }

            '4' {
                Start-Process `
                    -FilePath 'taskschd.msc' `
                    -ArgumentList "/s", $Context.ComputerName
            }

            '5' {
                Start-Process `
                    -FilePath 'diskmgmt.msc' `
                    -ArgumentList "/computer:$($Context.ComputerName)"
            }

            '6' {
                Start-Process `
                    -FilePath 'devmgmt.msc' `
                    -ArgumentList "/computer:$($Context.ComputerName)"
            }

            '7' {
                Start-Process `
                    -FilePath 'fsmgmt.msc' `
                    -ArgumentList "/computer:$($Context.ComputerName)"
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