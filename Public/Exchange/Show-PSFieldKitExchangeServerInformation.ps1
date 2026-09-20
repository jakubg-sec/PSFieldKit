function Show-PSFieldKitExchangeServerInformation {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext
    )

    while ($true) {

        Clear-Host

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|          Exchange Server Information         |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"

        if (
            $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
            -not $ExchangeContext.Connected
        ) {

            Write-Host "|  Exchange session is not connected.          |" -ForegroundColor Red
            Write-Host "|                                              |"
            Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

            Read-Host "`nPress Enter to continue" | Out-Null

            return
        }

        $ServerName = "Unknown"

        if (
            $ExchangeContext.PSObject.Properties.Name -contains "ServerName" -and
            -not [string]::IsNullOrWhiteSpace([string]$ExchangeContext.ServerName)
        ) {

            $ServerName = [string]$ExchangeContext.ServerName
        }

        if ($ServerName.Length -gt 35) {

            $ServerName = $ServerName.Substring(0, 32) + "..."
        }

        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White

        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"

        try {

            $ExchangeServer = Get-ExchangeServer -Identity $ServerName -ErrorAction Stop

            $Name = "Unknown"
            $Edition = "Unknown"
            $Version = "Unknown"
            $Site = "Unknown"
            $Roles = "Unknown"

            if (
                $ExchangeServer.PSObject.Properties.Name -contains "Name" -and
                -not [string]::IsNullOrWhiteSpace([string]$ExchangeServer.Name)
            ) {

                $Name = [string]$ExchangeServer.Name
            }

            if (
                $ExchangeServer.PSObject.Properties.Name -contains "Edition" -and
                -not [string]::IsNullOrWhiteSpace([string]$ExchangeServer.Edition)
            ) {

                $Edition = [string]$ExchangeServer.Edition
            }

            if (
                $ExchangeServer.PSObject.Properties.Name -contains "AdminDisplayVersion" -and
                -not [string]::IsNullOrWhiteSpace([string]$ExchangeServer.AdminDisplayVersion)
            ) {

                $Version = [string]$ExchangeServer.AdminDisplayVersion
            }

            if (
                $ExchangeServer.PSObject.Properties.Name -contains "Site" -and
                -not [string]::IsNullOrWhiteSpace([string]$ExchangeServer.Site)
            ) {

                $Site = [string]$ExchangeServer.Site
            }

            if (
                $ExchangeServer.PSObject.Properties.Name -contains "ServerRole" -and
                $null -ne $ExchangeServer.ServerRole
            ) {

                $Roles = @(
                    $ExchangeServer.ServerRole
                ) -join ", "
            }

            if ($Name.Length -gt 35) {

                $Name = $Name.Substring(0, 32) + "..."
            }

            if ($Edition.Length -gt 35) {

                $Edition = $Edition.Substring(0, 32) + "..."
            }

            if ($Version.Length -gt 35) {

                $Version = $Version.Substring(0, 32) + "..."
            }

            if ($Site.Length -gt 35) {

                $Site = $Site.Substring(0, 32) + "..."
            }

            if ($Roles.Length -gt 35) {

                $Roles = $Roles.Substring(0, 32) + "..."
            }

            Write-Host "|  SERVER INFORMATION                          |" -ForegroundColor DarkCyan
            Write-Host ("|  Name   : {0,-35}|" -f $Name) -ForegroundColor White
            Write-Host ("|  Edition: {0,-35}|" -f $Edition) -ForegroundColor White
            Write-Host ("|  Version: {0,-35}|" -f $Version) -ForegroundColor White
            Write-Host ("|  Roles  : {0,-35}|" -f $Roles) -ForegroundColor White
            Write-Host ("|  Site   : {0,-35}|" -f $Site) -ForegroundColor White

            Write-Host "|                                              |"
            Write-Host "|  COMPONENT STATE                             |" -ForegroundColor DarkCyan

            try {

                $Components = @(
                    Get-ServerComponentState -Identity $ServerName -ErrorAction Stop
                )

                $ActiveCount = @(
                    $Components |
                        Where-Object {
                            $_.State -eq "Active"
                        }
                ).Count

                $InactiveCount = @(
                    $Components |
                        Where-Object {
                            $_.State -ne "Active"
                        }
                ).Count

                $ActiveColor = "Green"
                $InactiveColor = "Green"

                if ($InactiveCount -gt 0) {

                    $InactiveColor = "Yellow"
                }

                Write-Host ("|  Active   : {0,-35}|" -f $ActiveCount) -ForegroundColor $ActiveColor
                Write-Host ("|  Inactive : {0,-35}|" -f $InactiveCount) -ForegroundColor $InactiveColor
            }
            catch {

                Write-Host "|  Component state unavailable.               |" -ForegroundColor Yellow
            }

            Write-Host "|                                              |"
            Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
            Write-Host "|                                              |"
            Write-Host "|  [R] Refresh                                 |"
            Write-Host "|  [0] Back                                    |"
            Write-Host "|                                              |"
            Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

            $Choice = Read-Host "`nSelect option"

            switch ($Choice) {

                "R" {
                    continue
                }

                "r" {
                    continue
                }

                "0" {
                    return
                }

                default {

                    Write-Host ""
                    Write-Host "Invalid option." -ForegroundColor Red

                    Start-Sleep -Seconds 1
                }
            }
        }
        catch {

            Write-Host ""
            Write-Host "Failed to retrieve Exchange server information." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow

            Read-Host "`nPress Enter to continue" | Out-Null

            return
        }
    }
}