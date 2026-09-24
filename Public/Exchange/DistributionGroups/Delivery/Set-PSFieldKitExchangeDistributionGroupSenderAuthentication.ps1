function Set-PSFieldKitExchangeDistributionGroupSenderAuthentication {
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

    Clear-Host

    Write-Host "+----------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "|       Sender Authentication Settings         |" -ForegroundColor Cyan
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

    $CurrentValue = [bool]$Group.RequireSenderAuthenticationEnabled

    Write-Host "`nCURRENT SETTING" -ForegroundColor DarkCyan

    if ($CurrentValue) {
        Write-Host "Authenticated senders only : Enabled" -ForegroundColor Green
        Write-Host "External senders            : Blocked" -ForegroundColor Yellow
    }
    else {
        Write-Host "Authenticated senders only : Disabled" -ForegroundColor Yellow
        Write-Host "External senders            : Allowed" -ForegroundColor Green
    }

    Write-Host "`nSELECT NEW SETTING" -ForegroundColor DarkCyan
    Write-Host "[1] Require authenticated senders only"
    Write-Host "[2] Allow authenticated and external senders"
    Write-Host "[0] Cancel"

    $Choice = Read-Host "`nSelect option"

    switch ($Choice) {
        '1' {
            $NewValue = $true
        }

        '2' {
            $NewValue = $false
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
        Write-Host "`nThe selected setting is already configured." -ForegroundColor Yellow
        return
    }

    Write-Host ""

    if ($NewValue) {
        Write-Host "This will reject messages from unauthenticated external senders." -ForegroundColor Yellow
    }
    else {
        Write-Host "This will allow messages from unauthenticated external senders." -ForegroundColor Yellow
    }

    $Confirmation = Read-Host "Type YES to apply this setting"

    if ($Confirmation -cne 'YES') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "`nUpdating sender authentication setting..." -ForegroundColor Yellow

        Set-DistributionGroup `
            -Identity $Group.Identity `
            -RequireSenderAuthenticationEnabled $NewValue `
            -ErrorAction Stop

        Write-Host "`nSender authentication setting updated successfully." -ForegroundColor Green

        if ($NewValue) {
            Write-Host "Authenticated senders only : Enabled" -ForegroundColor Green
            Write-Host "External senders            : Blocked" -ForegroundColor Yellow
        }
        else {
            Write-Host "Authenticated senders only : Disabled" -ForegroundColor Yellow
            Write-Host "External senders            : Allowed" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`nFailed to update sender authentication setting." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
    }

    Read-Host "`nPress Enter to continue" | Out-Null
}