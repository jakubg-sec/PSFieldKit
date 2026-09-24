function Show-PSFieldKitExchangeDistributionGroupModerationSettings {
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
        return
    }

    if (-not (Get-Command Get-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-DistributionGroup' is not available." -ForegroundColor Red
        return
    }

    if (-not (Get-Command Get-Recipient -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Get-Recipient' is not available." -ForegroundColor Red
        return
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        $Identity = Read-Host "Enter distribution group name, alias or email address"
    }

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        Write-Host "`nDistribution group identity cannot be empty." -ForegroundColor Yellow
        return
    }

    try {
        $Group = Get-DistributionGroup -Identity $Identity -ErrorAction Stop
    }
    catch {
        Write-Host "`nFailed to find distribution group '$Identity'." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Distribution Group Moderation         |" -ForegroundColor Cyan
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

    $ModerationEnabled = [bool]$Group.ModerationEnabled

    Write-Host "`nMODERATION" -ForegroundColor DarkCyan

    if ($ModerationEnabled) {
        Write-Host "Status                 : Enabled" -ForegroundColor Green
        Write-Host "Message approval       : Required"
    }
    else {
        Write-Host "Status                 : Disabled" -ForegroundColor Yellow
        Write-Host "Message approval       : Not required"
    }

    if ($Group.PSObject.Properties.Name -contains 'SendModerationNotifications') {
        Write-Host ("Notifications          : {0}" -f $Group.SendModerationNotifications)
    }

    if ($Group.PSObject.Properties.Name -contains 'BypassNestedModerationEnabled') {
        Write-Host ("Nested moderation     : {0}" -f $Group.BypassNestedModerationEnabled)
    }

    Write-Host "`nMODERATORS" -ForegroundColor DarkCyan

    $Moderators = @($Group.ModeratedBy)

    if ($Moderators.Count -eq 0) {
        Write-Host "No explicit moderators configured."

        if ($ModerationEnabled -and $Group.RecipientTypeDetails -eq 'MailUniversalDistributionGroup') {
            Write-Host "Distribution group owners will handle moderation."
        }
    }
    else {
        foreach ($Moderator in $Moderators) {
            try {
                $Recipient = Get-Recipient -Identity $Moderator -ErrorAction Stop

                Write-Host (" - {0}" -f $Recipient.DisplayName)

                if (-not [string]::IsNullOrWhiteSpace([string]$Recipient.PrimarySmtpAddress)) {
                    Write-Host ("   SMTP : {0}" -f $Recipient.PrimarySmtpAddress)
                }

                Write-Host ("   Type : {0}" -f $Recipient.RecipientTypeDetails)
            }
            catch {
                Write-Host (" - {0}" -f $Moderator)
                Write-Host "   Type : Unknown"
            }
        }

        Write-Host ("Total moderators      : {0}" -f $Moderators.Count) -ForegroundColor DarkGray
    }

    Write-Host "`nBYPASS MODERATION" -ForegroundColor DarkCyan

    $BypassSenders = @($Group.BypassModerationFromSendersOrMembers)

    if ($BypassSenders.Count -eq 0) {
        Write-Host "No senders or groups bypass moderation."
    }
    else {
        foreach ($BypassSender in $BypassSenders) {
            try {
                $Recipient = Get-Recipient -Identity $BypassSender -ErrorAction Stop

                Write-Host (" - {0}" -f $Recipient.DisplayName)

                if (-not [string]::IsNullOrWhiteSpace([string]$Recipient.PrimarySmtpAddress)) {
                    Write-Host ("   SMTP : {0}" -f $Recipient.PrimarySmtpAddress)
                }

                Write-Host ("   Type : {0}" -f $Recipient.RecipientTypeDetails)
            }
            catch {
                Write-Host (" - {0}" -f $BypassSender)
                Write-Host "   Type : Unknown"
            }
        }

        Write-Host ("Total bypass entries  : {0}" -f $BypassSenders.Count) -ForegroundColor DarkGray
    }

    Write-Host "`nSUMMARY" -ForegroundColor DarkCyan

    if ($ModerationEnabled) {
        Write-Host "Messages sent to this group require moderator approval." -ForegroundColor Yellow
    }
    else {
        Write-Host "Messages sent to this group do not require moderator approval." -ForegroundColor Green
    }

    if ($Moderators.Count -eq 0 -and $ModerationEnabled) {
        Write-Host "No explicit moderators are configured." -ForegroundColor Yellow
        Write-Host "For a distribution group, the group owners can handle moderation."
    }

    if ($BypassSenders.Count -gt 0) {
        Write-Host "Some senders or groups can bypass moderation." -ForegroundColor Cyan
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}