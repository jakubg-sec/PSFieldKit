function Get-FirewallInformation {

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
                $Profiles = Get-NetFirewallProfile `
                    -CimSession $Session `
                    -ErrorAction Stop
            }
            finally {
                Remove-CimSession $Session
            }
        }
        else {

            $Profiles = Get-NetFirewallProfile `
                -ErrorAction Stop
        }

        $FirewallInfo = foreach ($Prof in $Profiles) {

            [PSCustomObject]@{
                Profile          = $Prof.Name
                Enabled          = $Prof.Enabled
                DefaultInbound   = $Prof.DefaultInboundAction
                DefaultOutbound  = $Prof.DefaultOutboundAction
                AllowLocalRules  = $Prof.AllowLocalFirewallRules
                AllowLocalIPsec  = $Prof.AllowLocalIPsecRules
                LogAllowed       = $Prof.LogAllowed
                LogBlocked       = $Prof.LogBlocked
                LogFile          = $Prof.LogFileName
            }
        }

        $FirewallInfo |
            Sort-Object Profile |
            Format-Table -AutoSize
    }
    catch {

        Write-Host "`nFailed to retrieve firewall information from $($Context.ComputerName)." `
            -ForegroundColor Red

        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }
}