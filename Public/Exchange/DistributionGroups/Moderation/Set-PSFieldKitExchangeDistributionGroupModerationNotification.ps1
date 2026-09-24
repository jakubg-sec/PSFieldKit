function Set-PSFieldKitExchangeDistributionGroupModerationNotification {
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

    if (-not (Get-Command Set-DistributionGroup -ErrorAction SilentlyContinue)) {
        Write-Host "`nExchange cmdlet 'Set-DistributionGroup' is not available." -ForegroundColor Red
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

    $CurrentValue = [string]$Group.SendModerationNotifications

    if ([string]::IsNullOrWhiteSpace($CurrentValue)) {
        $CurrentValue = 'Always'
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Moderation Notifications               |" -ForegroundColor Cyan
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

    Write-Host "`nMODERATION STATUS" -ForegroundColor DarkCyan

    if ([bool]$Group.ModerationEnabled) {
        Write-Host "Moderation : Enabled" -ForegroundColor Green
    }
    else {
        Write-Host "Moderation : Disabled" -ForegroundColor Yellow
        Write-Host "Notification setting is stored but has no effect until moderation is enabled." -ForegroundColor Yellow
    }

    Write-Host "`nCURRENT NOTIFICATION SETTING" -ForegroundColor DarkCyan

    switch ($CurrentValue) {
        'Always' {
            Write-Host "Always - notify all senders when messages are not approved." -ForegroundColor Green
        }

        'Internal' {
            Write-Host "Internal - notify only senders from the organization." -ForegroundColor Green
        }

        'Never' {
            Write-Host "Never - do not send rejection notifications." -ForegroundColor Yellow
        }

        default {
            Write-Host $CurrentValue -ForegroundColor Yellow
        }
    }

    Write-Host "`nSELECT NEW SETTING" -ForegroundColor DarkCyan
    Write-Host "[1] Always    - Notify all senders"
    Write-Host "[2] Internal  - Notify internal senders only"
    Write-Host "[3] Never     - Do not notify senders"
    Write-Host "[0] Cancel"

    $Choice = Read-Host "`nSelect option"

    switch ($Choice) {
        '1' {
            $NewValue = 'Always'
        }

        '2' {
            $NewValue = 'Internal'
        }

        '3' {
            $NewValue = 'Never'
        }

        '0' {
            return
        }

        default {
            Write-Host "`nInvalid option." -ForegroundColor Red
            return
        }
    }

    if ($NewValue -eq $CurrentValue) {
        Write-Host "`nThe selected notification setting is already configured." -ForegroundColor Yellow
        return
    }

    Write-Host ""

    switch ($NewValue) {
        'Always' {
            Write-Host "All senders will receive a notification when their message is not approved." -ForegroundColor Yellow
        }

        'Internal' {
            Write-Host "Only senders from the organization will receive a notification when their message is not approved." -ForegroundColor Yellow
        }

        'Never' {
            Write-Host "No sender will receive a notification when a message is not approved." -ForegroundColor Yellow
        }
    }

    $Confirmation = Read-Host "Type YES to apply this setting"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating moderation notification setting..." -ForegroundColor Yellow

        Set-DistributionGroup `
            -Identity $Group.Identity `
            -SendModerationNotifications $NewValue `
            -ErrorAction Stop

        Write-Host "`nModeration notification setting updated successfully." -ForegroundColor Green
        Write-Host ("Group        : {0}" -f $Group.DisplayName)
        Write-Host ("Notifications : {0}" -f $NewValue) -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to update moderation notification setting." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}