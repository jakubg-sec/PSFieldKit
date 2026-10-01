function Get-PSFieldKitExchangeDAGDetails {
    [CmdletBinding()]
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

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                 DAG DETAILS                  |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    try {
        $DAGs = @(Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop)

        if ($DAGs.Count -eq 0) {
            Write-Host "|  No Database Availability Groups found.      |" -ForegroundColor Yellow
            Write-Host "|                                              |"
            Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "Available DAGs:" -ForegroundColor DarkCyan
        Write-Host ""

        for ($Index = 0; $Index -lt $DAGs.Count; $Index++) {
            Write-Host ("[{0}] {1}" -f ($Index + 1), $DAGs[$Index].Name)
        }

        Write-Host ""
        Write-Host "[0] Cancel"
        Write-Host ""

        $Choice = Read-Host "Select DAG"

        if ($Choice -eq "0") {
            return
        }

        $SelectedIndex = 0

        if (
            -not [int]::TryParse($Choice, [ref]$SelectedIndex) -or
            $SelectedIndex -lt 1 -or
            $SelectedIndex -gt $DAGs.Count
        ) {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $SelectedDAG = $DAGs[$SelectedIndex - 1]

        $WitnessServer = [string]$SelectedDAG.WitnessServer
        $WitnessDirectory = [string]$SelectedDAG.WitnessDirectory
        $WitnessShareInUse = [string]$SelectedDAG.WitnessShareInUse
        $ReplicationPort = [string]$SelectedDAG.ReplicationPort
        $NetworkCompression = [string]$SelectedDAG.NetworkCompression
        $NetworkEncryption = [string]$SelectedDAG.NetworkEncryption
        $ManualNetworkConfiguration = [string]$SelectedDAG.ManualDagNetworkConfiguration
        $DatacenterActivationMode = [string]$SelectedDAG.DatacenterActivationMode

        if ([string]::IsNullOrWhiteSpace($WitnessServer)) {
            $WitnessServer = "Not configured"
        }

        if ([string]::IsNullOrWhiteSpace($WitnessDirectory)) {
            $WitnessDirectory = "Not configured"
        }

        if ([string]::IsNullOrWhiteSpace($WitnessShareInUse)) {
            $WitnessShareInUse = "Unknown"
        }

        if ([string]::IsNullOrWhiteSpace($ReplicationPort)) {
            $ReplicationPort = "Default"
        }

        if ([string]::IsNullOrWhiteSpace($NetworkCompression)) {
            $NetworkCompression = "Unknown"
        }

        if ([string]::IsNullOrWhiteSpace($NetworkEncryption)) {
            $NetworkEncryption = "Unknown"
        }

        if ([string]::IsNullOrWhiteSpace($ManualNetworkConfiguration)) {
            $ManualNetworkConfiguration = "Unknown"
        }

        if ([string]::IsNullOrWhiteSpace($DatacenterActivationMode)) {
            $DatacenterActivationMode = "Unknown"
        }

        $IPAddresses = @($SelectedDAG.DatabaseAvailabilityGroupIPAddresses)

        if ($IPAddresses.Count -eq 0) {
            $IPDisplay = "DHCP / Not configured"
        }
        else {
            $IPDisplay = ($IPAddresses | ForEach-Object {
                if ($_ -is [System.Net.IPAddress]) {
                    $_.IPAddressToString
                }
                else {
                    [string]$_
                }
            }) -join ", "
        }

        Write-Host ""
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ("|  DAG : {0,-37}|" -f $SelectedDAG.Name) -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  Witness Server      : {0,-20}|" -f $WitnessServer)
        Write-Host ("|  Witness Directory   : {0,-20}|" -f $WitnessDirectory)
        Write-Host ("|  Witness Share       : {0,-20}|" -f $WitnessShareInUse)
        Write-Host ("|  DAG IP Address      : {0,-20}|" -f $IPDisplay)
        Write-Host ("|  Replication Port    : {0,-20}|" -f $ReplicationPort)
        Write-Host ("|  Network Compression : {0,-20}|" -f $NetworkCompression)
        Write-Host ("|  Network Encryption  : {0,-20}|" -f $NetworkEncryption)
        Write-Host ("|  Manual Networks     : {0,-20}|" -f $ManualNetworkConfiguration)
        Write-Host ("|  DAC Mode            : {0,-20}|" -f $DatacenterActivationMode)
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve DAG details." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}