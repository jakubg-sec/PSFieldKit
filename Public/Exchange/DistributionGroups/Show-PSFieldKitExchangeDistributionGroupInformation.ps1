function Show-PSFieldKitExchangeDistributionGroupInformation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ExchangeContext,
        [Parameter()]
        [string]$Identity
    )

    if (
        $ExchangeContext.PSObject.Properties.Name -notcontains 'Connected' -or
        -not $ExchangeContext.Connected
    ) {
        Write-Host "`nThe Exchange session is not connected." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if (-not (Get-Command Get-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-DistributionGroup' is not available." -ForegroundColor Red
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter distribution group name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDistribution group identity cannot be empty." -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    try {
        $Group = Get-DistributionGroup `
            -Identity $Identity `
            -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to find distribution group '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Read-Host "Press Enter to continue" | Out-Null
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Distribution Group Information         |" -ForegroundColor Cyan
    Write-Host "|                 PSFieldKit                   |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|                                              |"

    $DisplayName = [string]$Group.DisplayName
    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        $DisplayName = [string]$Group.Name
    }

    if ($DisplayName.Length -gt 36) {
        $DisplayName = $DisplayName.Substring(0, 33) + "..."
    }

    Write-Host ("|  Group : {0,-36}|" -f $DisplayName) -ForegroundColor White
    Write-Host "|                                              |"
    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan

    Write-Host "`nGENERAL" -ForegroundColor DarkCyan
    Write-Host ("Display Name       : {0}" -f $Group.DisplayName)
    Write-Host ("Name               : {0}" -f $Group.Name)
    Write-Host ("Alias              : {0}" -f $Group.Alias)
    Write-Host ("Identity           : {0}" -f $Group.Identity)
    Write-Host ("Group Type         : {0}" -f $Group.RecipientTypeDetails)
    Write-Host ("Primary SMTP       : {0}" -f $Group.PrimarySmtpAddress)

    if ($Group.PSObject.Properties.Name -contains 'SamAccountName') {
        Write-Host ("SAM Account Name   : {0}" -f $Group.SamAccountName)
    }

    if ($Group.PSObject.Properties.Name -contains 'DistinguishedName') {
        Write-Host ("Distinguished Name : {0}" -f $Group.DistinguishedName)
    }

    Write-Host "`nOWNERS" -ForegroundColor DarkCyan
    $ManagedBy = @($Group.ManagedBy)

    if ($ManagedBy.Count -eq 0) {
        Write-Host "Managed By         : None"
    }
    else {
        foreach ($Owner in $ManagedBy) {
            try {
                $Recipient = Get-Recipient `
                    -Identity $Owner `
                    -ErrorAction Stop

                Write-Host (
                    "Managed By         : {0} <{1}>" -f
                    $Recipient.DisplayName,
                    $Recipient.PrimarySmtpAddress
                )
            }
            catch {
                Write-Host ("Managed By         : {0}" -f $Owner)
            }
        }
    }

    Write-Host "`nDELIVERY" -ForegroundColor DarkCyan

    if ($Group.PSObject.Properties.Name -contains 'RequireSenderAuthenticationEnabled') {
        Write-Host ("Require Auth       : {0}" -f $Group.RequireSenderAuthenticationEnabled)
    }

    if ($Group.PSObject.Properties.Name -contains 'HiddenFromAddressListsEnabled') {
        Write-Host ("Hidden From GAL    : {0}" -f $Group.HiddenFromAddressListsEnabled)
    }

    if ($Group.PSObject.Properties.Name -contains 'ModerationEnabled') {
        Write-Host ("Moderation         : {0}" -f $Group.ModerationEnabled)
    }

    if ($Group.PSObject.Properties.Name -contains 'SendModerationNotifications') {
        Write-Host ("Moderation Notify  : {0}" -f $Group.SendModerationNotifications)
    }

    Write-Host "`nMEMBERSHIP SETTINGS" -ForegroundColor DarkCyan

    if ($Group.PSObject.Properties.Name -contains 'MemberJoinRestriction') {
        Write-Host ("Member Join        : {0}" -f $Group.MemberJoinRestriction)
    }

    if ($Group.PSObject.Properties.Name -contains 'MemberDepartRestriction') {
        Write-Host ("Member Depart      : {0}" -f $Group.MemberDepartRestriction)
    }

    Write-Host "`nMESSAGE SIZE" -ForegroundColor DarkCyan

    if ($Group.PSObject.Properties.Name -contains 'MaxReceiveSize') {
        Write-Host ("Max Receive Size   : {0}" -f $Group.MaxReceiveSize)
    }

    if ($Group.PSObject.Properties.Name -contains 'MaxSendSize') {
        Write-Host ("Max Send Size      : {0}" -f $Group.MaxSendSize)
    }

    Write-Host "`nEMAIL ADDRESSES" -ForegroundColor DarkCyan

    $EmailAddresses = @(
        $Group.EmailAddresses |
            ForEach-Object {
                $_.ToString()
            }
    )

    if ($EmailAddresses.Count -eq 0) {
        Write-Host "None"
    }
    else {
        foreach ($Address in $EmailAddresses) {
            Write-Host " - $Address"
        }
    }

    Write-Host "`nADDITIONAL" -ForegroundColor DarkCyan

    if ($Group.PSObject.Properties.Name -contains 'Notes') {
        Write-Host ("Notes              : {0}" -f $Group.Notes)
    }

    if ($Group.PSObject.Properties.Name -contains 'OrganizationalUnit') {
        Write-Host ("Organizational Unit : {0}" -f $Group.OrganizationalUnit)
    }

    if ($Group.PSObject.Properties.Name -contains 'WhenCreated') {
        Write-Host ("Created            : {0}" -f $Group.WhenCreated)
    }

    if ($Group.PSObject.Properties.Name -contains 'WhenChanged') {
        Write-Host ("Modified           : {0}" -f $Group.WhenChanged)
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}