function New-PSFieldKitExchangeDAG {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$ExchangeContext
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains "Connected" -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host ""
        Write-Host "The Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    while ($true) {
        Clear-Host

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

        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                 CREATE DAG                   |" -ForegroundColor Cyan
        Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Server : {0,-35}|" -f $ServerName) -ForegroundColor White
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""

        try {
            $ExistingDAGs = @(Get-DatabaseAvailabilityGroup -ErrorAction Stop)

            if ($ExistingDAGs.Count -gt 0) {
                Write-Host "Existing DAGs:" -ForegroundColor DarkCyan

                foreach ($DAG in $ExistingDAGs) {
                    Write-Host "  - $($DAG.Name)"
                }

                Write-Host ""
            }
        }
        catch {
            Write-Host "Unable to retrieve existing DAGs." -ForegroundColor Yellow
            Write-Host $_.Exception.Message -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $DAGName = Read-Host "Enter DAG name"

        if ([string]::IsNullOrWhiteSpace($DAGName)) {
            Write-Host ""
            Write-Host "DAG name cannot be empty." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            continue
        }

        $ExistingDAG = $ExistingDAGs | Where-Object { $_.Name -ieq $DAGName }

        if ($ExistingDAG) {
            Write-Host ""
            Write-Host "A DAG with this name already exists." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            continue
        }

        Write-Host ""
        Write-Host "Witness Server" -ForegroundColor DarkCyan
        Write-Host "The witness server cannot be a DAG member."
        Write-Host ""

        $WitnessServer = Read-Host "Enter witness server"

        if ([string]::IsNullOrWhiteSpace($WitnessServer)) {
            Write-Host ""
            Write-Host "Witness server cannot be empty." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            continue
        }

        Write-Host ""
        Write-Host "Witness Directory" -ForegroundColor DarkCyan
        Write-Host "Example: C:\DAGWitness"
        Write-Host ""

        $WitnessDirectory = Read-Host "Enter witness directory"

        if ([string]::IsNullOrWhiteSpace($WitnessDirectory)) {
            Write-Host ""
            Write-Host "Witness directory cannot be empty." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            continue
        }

        Write-Host ""
        Write-Host "DAG IP Address" -ForegroundColor DarkCyan
        Write-Host "Enter one or more IP addresses separated by commas."
        Write-Host "Leave empty to use DHCP."
        Write-Host ""

        $IPAddressInput = Read-Host "Enter DAG IP address(es)"

        $IPAddressList = @()

        if (-not [string]::IsNullOrWhiteSpace($IPAddressInput)) {
            $IPAddressList = @(
                $IPAddressInput.Split(",") |
                ForEach-Object { $_.Trim() } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            )

            foreach ($IPAddress in $IPAddressList) {
                $ParsedIPAddress = $null

                if (-not [System.Net.IPAddress]::TryParse($IPAddress, [ref]$ParsedIPAddress)) {
                    Write-Host ""
                    Write-Host "Invalid IP address: $IPAddress" -ForegroundColor Red
                    Read-Host "`nPress Enter to continue" | Out-Null
                    continue
                }
            }
        }

        Write-Host ""
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                DAG SUMMARY                   |" -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  DAG Name       : {0,-26}|" -f $DAGName)
        Write-Host ("|  Witness Server : {0,-26}|" -f $WitnessServer)
        Write-Host ("|  Witness Dir    : {0,-26}|" -f $WitnessDirectory)

        if ($IPAddressList.Count -gt 0) {
            $DisplayIPs = $IPAddressList -join ", "

            if ($DisplayIPs.Length -gt 26) {
                $DisplayIPs = $DisplayIPs.Substring(0, 23) + "..."
            }

            Write-Host ("|  DAG IP         : {0,-26}|" -f $DisplayIPs)
        }
        else {
            Write-Host "|  DAG IP         : DHCP                     |"
        }

        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ""

        $Confirmation = Read-Host "Type CREATE to create the DAG"

        if ($Confirmation -cne "CREATE") {
            Write-Host ""
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        try {
            $NewDAGParameters = @{
                Name = $DAGName
                WitnessServer = $WitnessServer
                WitnessDirectory = $WitnessDirectory
                ErrorAction = "Stop"
            }

            if ($IPAddressList.Count -gt 0) {
                $NewDAGParameters.DatabaseAvailabilityGroupIPAddresses = @(
                    $IPAddressList | ForEach-Object {
                        [System.Net.IPAddress]::Parse($_)
                    }
                )
            }

            if ($PSCmdlet.ShouldProcess($DAGName, "Create Database Availability Group")) {
                New-DatabaseAvailabilityGroup @NewDAGParameters

                Write-Host ""
                Write-Host "DAG created successfully." -ForegroundColor Green
                Write-Host ""
                Write-Host "DAG Name       : $DAGName"
                Write-Host "Witness Server : $WitnessServer"
                Write-Host "Witness Dir    : $WitnessDirectory"

                if ($IPAddressList.Count -gt 0) {
                    Write-Host "DAG IP         : $($IPAddressList -join ", ")"
                }
                else {
                    Write-Host "DAG IP         : DHCP"
                }

                Write-Host ""
                Write-Host "The DAG was created without members." -ForegroundColor Yellow
                Write-Host "Use 'Add DAG Member' to add Mailbox servers." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host ""
            Write-Host "Failed to create DAG." -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }

        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }
}