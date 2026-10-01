function Show-PSFieldKitExchangeDAGMemberDetails {
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
    Write-Host "|              DAG MEMBER DETAILS              |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    try {
        $DAGs = @(Get-DatabaseAvailabilityGroup -Status -ErrorAction Stop)

        if ($DAGs.Count -eq 0) {
            Write-Host "No Database Availability Groups found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $Members = @()

        foreach ($DAG in $DAGs) {
            foreach ($Member in @($DAG.Servers)) {
                $Members += [PSCustomObject]@{
                    DAG  = $DAG.Name
                    Name = [string]$Member.Name
                }
            }
        }

        if ($Members.Count -eq 0) {
            Write-Host "No DAG members found." -ForegroundColor Yellow
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        Write-Host "Available DAG members:" -ForegroundColor DarkCyan
        Write-Host ""

        for ($Index = 0; $Index -lt $Members.Count; $Index++) {
            Write-Host ("[{0}] {1} ({2})" -f ($Index + 1), $Members[$Index].Name, $Members[$Index].DAG)
        }

        Write-Host ""
        Write-Host "[0] Cancel"
        Write-Host ""

        $Choice = Read-Host "Select member"

        if ($Choice -eq "0") {
            return
        }

        $SelectedIndex = 0

        if (
            -not [int]::TryParse($Choice, [ref]$SelectedIndex) -or
            $SelectedIndex -lt 1 -or
            $SelectedIndex -gt $Members.Count
        ) {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Read-Host "`nPress Enter to continue" | Out-Null
            return
        }

        $SelectedMember = $Members[$SelectedIndex - 1]

        $Server = Get-ExchangeServer -Identity $SelectedMember.Name -ErrorAction Stop
        $SelectedDAG = Get-DatabaseAvailabilityGroup -Identity $SelectedMember.DAG -Status -ErrorAction Stop

        $OperationalServer = $false

        foreach ($DAGMember in @($SelectedDAG.Servers)) {
            if ([string]$DAGMember.Name -eq $SelectedMember.Name) {
                $OperationalServer = $DAGMember.OperationalServer
                break
            }
        }

        if ($OperationalServer -eq $true) {
            $Status = "Healthy"
            $StatusColor = "Green"
        }
        else {
            $Status = "Unhealthy"
            $StatusColor = "Red"
        }

        Write-Host ""
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host ("|  Server : {0,-35}|" -f $SelectedMember.Name) -ForegroundColor Cyan
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
        Write-Host "|                                              |"
        Write-Host ("|  DAG                : {0,-20}|" -f $SelectedMember.DAG)
        Write-Host ("|  Status             : {0,-20}|" -f $Status) -ForegroundColor $StatusColor
        Write-Host ("|  Server Role        : {0,-20}|" -f $Server.ServerRole)
        Write-Host ("|  Edition            : {0,-20}|" -f $Server.Edition)
        Write-Host ("|  Admin Display Name : {0,-20}|" -f $Server.AdminDisplayName)
        Write-Host ("|  FQDN               : {0,-20}|" -f $Server.Fqdn)
        Write-Host "|                                              |"
        Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    }
    catch {
        Write-Host ""
        Write-Host "Failed to retrieve DAG member details." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}