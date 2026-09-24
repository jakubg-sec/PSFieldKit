function Show-PSFieldKitExchangeDatabaseProvisioning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,
        [Parameter()]
        [string]$Identity
    )

    if (-not (Test-PSFieldKitExchangeConnection -ExchangeContext $ExchangeContext)) {
        return
    }

    if (-not (Get-Command Get-MailboxDatabase -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-MailboxDatabase' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter mailbox database name or identity"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDatabase identity cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Database = Get-MailboxDatabase -Identity $Identity -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to retrieve database '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Clear-Host
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|          Database Provisioning               |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"
    $DisplayName = [string]$Database.Name
    if ($DisplayName.Length -gt 33) {
        $DisplayName = $DisplayName.Substring(0, 30) + "..."
    }
    Write-Host ("|  Database : {0,-33}|" -f $DisplayName) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nMAILBOX PROVISIONING" -ForegroundColor DarkCyan
    Write-Host ("Excluded From Provisioning       : {0}" -f $Database.IsExcludedFromProvisioning)

    if ($Database.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningByOperator') {
        Write-Host ("Excluded By Operator             : {0}" -f $Database.IsExcludedFromProvisioningByOperator)
    }

    if ($Database.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningDueToLogicalCorruption') {
        Write-Host ("Excluded Due To Corruption      : {0}" -f $Database.IsExcludedFromProvisioningDueToLogicalCorruption)
    }

    if ($Database.PSObject.Properties.Name -contains 'IsExcludedFromProvisioningReason') {
        $Reason = $Database.IsExcludedFromProvisioningReason
        if ([string]::IsNullOrWhiteSpace([string]$Reason)) {
            $Reason = "None"
        }
        Write-Host ("Exclusion Reason                 : {0}" -f $Reason)
    }

    Write-Host "`nINITIAL PROVISIONING" -ForegroundColor DarkCyan
    Write-Host ("Excluded From Initial Provision  : {0}" -f $Database.IsExcludedFromInitialProvisioning)

    Write-Host "`nPROVISIONING SUSPENSION" -ForegroundColor DarkCyan
    Write-Host ("Suspended From Provisioning     : {0}" -f $Database.IsSuspendedFromProvisioning)

    Write-Host "`nAUTODAG MONITORING" -ForegroundColor DarkCyan
    if ($Database.PSObject.Properties.Name -contains 'AutoDagExcludeFromMonitoring') {
        Write-Host ("Excluded From AutoDAG Monitoring: {0}" -f $Database.AutoDagExcludeFromMonitoring)
    }
    else {
        Write-Host "Excluded From AutoDAG Monitoring: Not available"
    }

    Write-Host "`nPROVISIONING STATUS" -ForegroundColor DarkCyan

    $ProvisioningStatus = if ($Database.IsExcludedFromProvisioning) {
        "Excluded"
    }
    elseif ($Database.IsSuspendedFromProvisioning) {
        "Suspended"
    }
    else {
        "Available"
    }

    Write-Host ("Mailbox Provisioning             : {0}" -f $ProvisioningStatus)

    if ($Database.IsExcludedFromInitialProvisioning) {
        Write-Host "Initial Provisioning             : Excluded"
    }
    else {
        Write-Host "Initial Provisioning             : Available"
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}