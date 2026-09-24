function Show-PSFieldKitExchangeDatabaseInformation {
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
        Write-Host "`nRetrieving mailbox database information..." -ForegroundColor Yellow

        $Database = Get-MailboxDatabase `
            -Identity $Identity `
            -Status `
            -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to retrieve mailbox database information." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|            Mailbox Database Info             |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $DisplayName = [string]$Database.Name

    if ($DisplayName.Length -gt 36) {
        $DisplayName = $DisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Database : {0,-33}|" -f $DisplayName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nGENERAL" -ForegroundColor DarkCyan

    Write-Host ("Name                  : {0}" -f $Database.Name)
    Write-Host ("Server                : {0}" -f $Database.Server)
    Write-Host ("Mounted               : {0}" -f $Database.Mounted)
    Write-Host ("Recovery              : {0}" -f $Database.Recovery)
    Write-Host ("Excluded Provisioning : {0}" -f $Database.IsExcludedFromProvisioning)

    Write-Host "`nSTORAGE" -ForegroundColor DarkCyan

    Write-Host ("EDB Path              : {0}" -f $Database.EdbFilePath)
    Write-Host ("Log Folder            : {0}" -f $Database.LogFolderPath)
    Write-Host ("Database Size         : {0}" -f $Database.DatabaseSize)
    Write-Host ("Available Mailbox     : {0}" -f $Database.AvailableNewMailboxSpace)

    Write-Host "`nLOGGING" -ForegroundColor DarkCyan

    Write-Host ("Circular Logging      : {0}" -f $Database.CircularLoggingEnabled)
    Write-Host ("Log Prefix            : {0}" -f $Database.LogFilePrefix)
    Write-Host ("Log Truncation       : {0}" -f $Database.LogTruncationInterval)

    Write-Host "`nQUOTAS" -ForegroundColor DarkCyan

    Write-Host ("Issue Warning Quota   : {0}" -f $Database.IssueWarningQuota)
    Write-Host ("Prohibit Send Quota   : {0}" -f $Database.ProhibitSendQuota)
    Write-Host ("Prohibit Send/Receive: {0}" -f $Database.ProhibitSendReceiveQuota)

    Write-Host "`nRETENTION" -ForegroundColor DarkCyan

    Write-Host ("Deleted Item Retention: {0}" -f $Database.DeletedItemRetention)
    Write-Host ("Mailbox Retention     : {0}" -f $Database.MailboxRetention)

    Write-Host "`nCLIENT SETTINGS" -ForegroundColor DarkCyan

    Write-Host ("Offline Address Book  : {0}" -f $Database.OfflineAddressBook)

    Write-Host "`nSTATUS" -ForegroundColor DarkCyan

    if ($Database.PSObject.Properties.Name -contains 'BackupInProgress') {
        Write-Host ("Backup In Progress    : {0}" -f $Database.BackupInProgress)
    }

    if ($Database.PSObject.Properties.Name -contains 'OnlineMaintenanceInProgress') {
        Write-Host ("Online Maintenance    : {0}" -f $Database.OnlineMaintenanceInProgress)
    }

    if ($Database.PSObject.Properties.Name -contains 'MountedOnServer') {
        Write-Host ("Mounted On Server     : {0}" -f $Database.MountedOnServer)
    }

    Write-Host "`nREPLICATION" -ForegroundColor DarkCyan

    if ($Database.PSObject.Properties.Name -contains 'ReplicationType') {
        Write-Host ("Replication Type      : {0}" -f $Database.ReplicationType)
    }

    if ($Database.PSObject.Properties.Name -contains 'MasterServerOrAvailabilityGroup') {
        Write-Host ("DAG / Master          : {0}" -f $Database.MasterServerOrAvailabilityGroup)
    }

    Write-Host "`nIDENTITY" -ForegroundColor DarkCyan

    Write-Host ("GUID                  : {0}" -f $Database.Guid)
    Write-Host ("Distinguished Name    : {0}" -f $Database.DistinguishedName)

    Read-Host "`nPress Enter to continue" | Out-Null
}