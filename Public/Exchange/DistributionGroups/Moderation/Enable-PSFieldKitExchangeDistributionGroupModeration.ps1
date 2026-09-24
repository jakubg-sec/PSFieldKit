function Enable-PSFieldKitExchangeDistributionGroupModeration {
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

    if ($Group.RecipientTypeDetails -eq 'DynamicDistributionGroup') {
        Write-Host "`nDynamic distribution groups cannot be moderated using this operation." -ForegroundColor Yellow
        return
    }

    if ([bool]$Group.ModerationEnabled) {
        Write-Host "`nModeration is already enabled for '$($Group.DisplayName)'." -ForegroundColor Yellow
        return
    }

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Enable Distribution Moderation         |" -ForegroundColor Cyan
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

    Write-Host "`nCURRENT STATUS" -ForegroundColor DarkCyan
    Write-Host "Moderation : Disabled" -ForegroundColor Yellow

    Write-Host "`nRESULT" -ForegroundColor DarkCyan
    Write-Host "Messages sent to this group will require moderator approval." -ForegroundColor Yellow
    Write-Host "If no explicit moderators are configured, the group owners can handle moderation." -ForegroundColor Yellow

    $Confirmation = Read-Host "`nType YES to enable moderation"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nEnabling moderation..." -ForegroundColor Yellow

        Set-DistributionGroup `
            -Identity $Group.Identity `
            -ModerationEnabled $true `
            -ErrorAction Stop

        Write-Host "`nDistribution group moderation enabled successfully." -ForegroundColor Green
        Write-Host ("Group      : {0}" -f $Group.DisplayName)
        Write-Host "Moderation : Enabled" -ForegroundColor Green
    }
    catch {
        Write-Host "`nFailed to enable distribution group moderation." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}