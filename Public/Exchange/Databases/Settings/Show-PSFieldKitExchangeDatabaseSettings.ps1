function Show-PSFieldKitExchangeDatabaseSettings {
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
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter mailbox database name or identity"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDatabase identity cannot be empty." -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    try {
        Write-Host "`nRetrieving database settings..." -ForegroundColor Yellow
        $Database = Get-MailboxDatabase `
            -Identity $Identity `
            -Status `
            -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to retrieve database '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "`nPress Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|            Database Settings                 |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $DisplayName = [string]$Database.Name
    if ($DisplayName.Length -gt 36) {
        $DisplayName = $DisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Database : {0,-33}|" -f $DisplayName) -ForegroundColor White
    Write-Host ("|  Server   : {0,-33}|" -f $Database.Server) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nGENERAL" -ForegroundColor DarkCyan
    Write-Host ("Name                  : {0}" -f $Database.Name)
    Write-Host ("Server                : {0}" -f $Database.Server)
    Write-Host ("Mounted               : {0}" -f $Database.Mounted)
    Write-Host ("Recovery              : {0}" -f $Database.Recovery)
    Write-Host ("Allow File Restore    : {0}" -f $Database.AllowFileRestore)
    Write-Host ("Mount At Startup      : {0}" -f $Database.MountAtStartup)

    Write-Host "`nSTORAGE" -ForegroundColor DarkCyan
    Write-Host ("EDB Path              : {0}" -f $Database.EdbFilePath)
    Write-Host ("Log Folder            : {0}" -f $Database.LogFolderPath)
    Write-Host ("Database Size         : {0}" -f $Database.DatabaseSize)
    Write-Host ("Available Mailbox     : {0}" -f $Database.AvailableNewMailboxSpace)

    Write-Host "`nLOGGING" -ForegroundColor DarkCyan
    Write-Host ("Circular Logging      : {0}" -f $Database.CircularLoggingEnabled)
    Write-Host ("Retain Until Backup   : {0}" -f $Database.RetainDeletedItemsUntilBackup)
    if ($Database.PSObject.Properties.Name -contains 'LogFilePrefix') {
        Write-Host ("Log File Prefix       : {0}" -f $Database.LogFilePrefix)
    }

    Write-Host "`nPROVISIONING" -ForegroundColor DarkCyan
    Write-Host ("Excluded Provisioning : {0}" -f $Database.IsExcludedFromProvisioning)
    Write-Host ("Initial Provisioning  : {0}" -f $Database.IsExcludedFromInitialProvisioning)
    Write-Host ("Suspended Provisioning: {0}" -f $Database.IsSuspendedFromProvisioning)

    if ($Database.PSObject.Properties.Name -contains 'AutoDagExcludeFromMonitoring') {
        Write-Host ("Auto DAG Monitoring   : {0}" -f $Database.AutoDagExcludeFromMonitoring)
    }

    Write-Host "`nQUOTAS" -ForegroundColor DarkCyan
    Write-Host ("Issue Warning Quota   : {0}" -f $Database.IssueWarningQuota)
    Write-Host ("Prohibit Send Quota   : {0}" -f $Database.ProhibitSendQuota)
    Write-Host ("Prohibit Send/Recv    : {0}" -f $Database.ProhibitSendReceiveQuota)

    if ($Database.PSObject.Properties.Name -contains 'RecoverableItemsQuota') {
        Write-Host ("Recoverable Items     : {0}" -f $Database.RecoverableItemsQuota)
    }

    if ($Database.PSObject.Properties.Name -contains 'RecoverableItemsWarningQuota') {
        Write-Host ("Recoverable Warning   : {0}" -f $Database.RecoverableItemsWarningQuota)
    }

    Write-Host "`nRETENTION" -ForegroundColor DarkCyan
    Write-Host ("Deleted Item Retention: {0}" -f $Database.DeletedItemRetention)
    Write-Host ("Mailbox Retention     : {0}" -f $Database.MailboxRetention)

    Write-Host "`nMAINTENANCE" -ForegroundColor DarkCyan

    if ($Database.PSObject.Properties.Name -contains 'MaintenanceSchedule') {
        Write-Host ("Maintenance Schedule  : {0}" -f $Database.MaintenanceSchedule)
    }

    if ($Database.PSObject.Properties.Name -contains 'BackgroundDatabaseMaintenance') {
        Write-Host ("Background Maintenance: {0}" -f $Database.BackgroundDatabaseMaintenance)
    }

    if ($Database.PSObject.Properties.Name -contains 'IndexEnabled') {
        Write-Host ("Index Enabled         : {0}" -f $Database.IndexEnabled)
    }

    if ($Database.PSObject.Properties.Name -contains 'EventHistoryRetentionPeriod') {
        Write-Host ("Event History Retention: {0}" -f $Database.EventHistoryRetentionPeriod)
    }

    Write-Host "`nADDRESS BOOK" -ForegroundColor DarkCyan
    Write-Host ("Offline Address Book  : {0}" -f $Database.OfflineAddressBook)

    Write-Host "`nJOURNALING" -ForegroundColor DarkCyan
    if (
        $Database.PSObject.Properties.Name -contains 'JournalRecipient' -and
        $null -ne $Database.JournalRecipient
    ) {
        Write-Host ("Journal Recipient     : {0}" -f $Database.JournalRecipient)
    }
    else {
        Write-Host "Journal Recipient     : None"
    }

    Write-Host "`nDATABASE MOUNT" -ForegroundColor DarkCyan
    if ($Database.PSObject.Properties.Name -contains 'AutoDatabaseMountDial') {
        Write-Host ("Auto Mount Dial       : {0}" -f $Database.AutoDatabaseMountDial)
    }

    if ($Database.PSObject.Properties.Name -contains 'MountedOnServer') {
        Write-Host ("Mounted On Server     : {0}" -f $Database.MountedOnServer)
    }

    Write-Host "`nIDENTITY" -ForegroundColor DarkCyan
    Write-Host ("GUID                  : {0}" -f $Database.Guid)
    Write-Host ("Distinguished Name    : {0}" -f $Database.DistinguishedName)

    Read-Host "`nPress Enter to continue" | Out-Null
}